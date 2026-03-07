import Foundation

/// Provisions an EC2 instance with Claude Code directly from the user's AWS account
actor EC2ProvisioningService {
    enum ProvisioningState: Sendable {
        case idle
        case creatingKeyPair
        case creatingSecurityGroup
        case launchingInstance
        case waitingForInstance
        case installingClaudeCode
        case ready(host: String, keyPem: String)
        case error(String)
    }

    struct ProvisionedInstance: Sendable {
        let instanceId: String
        let publicIP: String
        let privateKeyPem: String
        let securityGroupId: String
        let keyPairName: String
        let region: String
    }

    private let awsAccessKey: String
    private let awsSecretKey: String
    private let region: String
    private let anthropicKey: String
    private let devTools: DevToolConfig

    init(awsAccessKey: String, awsSecretKey: String, region: String, anthropicKey: String, devTools: DevToolConfig = DevToolConfig()) {
        self.awsAccessKey = awsAccessKey
        self.awsSecretKey = awsSecretKey
        self.region = region
        self.anthropicKey = anthropicKey
        self.devTools = devTools
    }

    /// Full provisioning flow — returns a ready-to-connect instance
    func provision(onStateChange: @escaping @Sendable (ProvisioningState) -> Void) async throws -> ProvisionedInstance {
        let signer = AWSSigV4(accessKey: awsAccessKey, secretKey: awsSecretKey, region: region, service: "ec2")
        let keyName = "pocket-engineer-\(UUID().uuidString.prefix(8).lowercased())"
        let sgName = "pocket-engineer-\(UUID().uuidString.prefix(8).lowercased())"

        // Step 1: Create Key Pair
        onStateChange(.creatingKeyPair)
        let (privateKey, _) = try await createKeyPair(signer: signer, keyName: keyName)

        // Step 2: Create Security Group
        onStateChange(.creatingSecurityGroup)
        let sgId = try await createSecurityGroup(signer: signer, name: sgName)
        try await authorizeSSH(signer: signer, sgId: sgId)
        try await authorizePort(signer: signer, sgId: sgId, port: 8080)
        if devTools.enableDocker {
            try await authorizePort(signer: signer, sgId: sgId, port: 3000)
        }

        // Step 3: Launch Instance
        onStateChange(.launchingInstance)
        let userData = buildUserData()
        let instanceId = try await runInstance(signer: signer, keyName: keyName, sgId: sgId, userData: userData)

        // Step 4: Wait for running + public IP
        onStateChange(.waitingForInstance)
        let publicIP = try await waitForInstance(signer: signer, instanceId: instanceId)

        // Step 5: Wait for tools installation (user-data installs full toolkit ~2min)
        onStateChange(.installingClaudeCode)
        try await Task.sleep(for: .seconds(120))

        onStateChange(.ready(host: publicIP, keyPem: privateKey))

        return ProvisionedInstance(
            instanceId: instanceId,
            publicIP: publicIP,
            privateKeyPem: privateKey,
            securityGroupId: sgId,
            keyPairName: keyName,
            region: region
        )
    }

    // MARK: - AWS EC2 API Calls

    private func ec2Request(signer: AWSSigV4, params: [String: String]) async throws -> Data {
        var components = URLComponents(string: "https://ec2.\(region).amazonaws.com/")!
        var queryItems = [URLQueryItem(name: "Version", value: "2016-11-15")]
        for (key, value) in params.sorted(by: { $0.key < $1.key }) {
            queryItems.append(URLQueryItem(name: key, value: value))
        }
        components.queryItems = queryItems

        let request = signer.signedRequest(method: "GET", url: components.url!)
        let (data, response) = try await URLSession.shared.data(for: request)

        if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode >= 400 {
            let body = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw ProvisioningError.awsError(httpResponse.statusCode, body)
        }
        return data
    }

    private func createKeyPair(signer: AWSSigV4, keyName: String) async throws -> (String, String) {
        let data = try await ec2Request(signer: signer, params: [
            "Action": "CreateKeyPair",
            "KeyName": keyName,
            "KeyType": "ed25519"
        ])
        let xml = String(data: data, encoding: .utf8) ?? ""
        guard let pem = extractXML(xml, tag: "keyMaterial") else {
            throw ProvisioningError.parseError("Failed to extract key material")
        }
        let keyId = extractXML(xml, tag: "keyPairId") ?? keyName
        return (pem, keyId)
    }

    private func createSecurityGroup(signer: AWSSigV4, name: String) async throws -> String {
        let data = try await ec2Request(signer: signer, params: [
            "Action": "CreateSecurityGroup",
            "GroupName": name,
            "GroupDescription": "Pocket Engineer - auto-provisioned"
        ])
        let xml = String(data: data, encoding: .utf8) ?? ""
        guard let sgId = extractXML(xml, tag: "groupId") else {
            throw ProvisioningError.parseError("Failed to extract security group ID")
        }
        return sgId
    }

    private func authorizeSSH(signer: AWSSigV4, sgId: String) async throws {
        _ = try await ec2Request(signer: signer, params: [
            "Action": "AuthorizeSecurityGroupIngress",
            "GroupId": sgId,
            "IpPermissions.1.IpProtocol": "tcp",
            "IpPermissions.1.FromPort": "22",
            "IpPermissions.1.ToPort": "22",
            "IpPermissions.1.IpRanges.1.CidrIp": "0.0.0.0/0",
            "IpPermissions.1.IpRanges.1.Description": "SSH from anywhere"
        ])
    }

    private func authorizePort(signer: AWSSigV4, sgId: String, port: Int) async throws {
        _ = try await ec2Request(signer: signer, params: [
            "Action": "AuthorizeSecurityGroupIngress",
            "GroupId": sgId,
            "IpPermissions.1.IpProtocol": "tcp",
            "IpPermissions.1.FromPort": "\(port)",
            "IpPermissions.1.ToPort": "\(port)",
            "IpPermissions.1.IpRanges.1.CidrIp": "0.0.0.0/0",
            "IpPermissions.1.IpRanges.1.Description": "App port"
        ])
    }

    private func runInstance(signer: AWSSigV4, keyName: String, sgId: String, userData: String) async throws -> String {
        // Resolve AMI for the region
        let amiId = try await resolveAMI(signer: signer)

        let data = try await ec2Request(signer: signer, params: [
            "Action": "RunInstances",
            "ImageId": amiId,
            "InstanceType": "t3.medium",
            "KeyName": keyName,
            "SecurityGroupId.1": sgId,
            "MinCount": "1",
            "MaxCount": "1",
            "UserData": Data(userData.utf8).base64EncodedString(),
            "TagSpecification.1.ResourceType": "instance",
            "TagSpecification.1.Tag.1.Key": "Name",
            "TagSpecification.1.Tag.1.Value": "PocketEngineer",
            "TagSpecification.1.Tag.2.Key": "ManagedBy",
            "TagSpecification.1.Tag.2.Value": "PocketEngineer"
        ])
        let xml = String(data: data, encoding: .utf8) ?? ""
        guard let instanceId = extractXML(xml, tag: "instanceId") else {
            throw ProvisioningError.parseError("Failed to extract instance ID from: \(xml.prefix(500))")
        }
        return instanceId
    }

    private func resolveAMI(signer: AWSSigV4) async throws -> String {
        // Find the latest Amazon Linux 2023 AMI
        let data = try await ec2Request(signer: signer, params: [
            "Action": "DescribeImages",
            "Owner.1": "amazon",
            "Filter.1.Name": "name",
            "Filter.1.Value.1": "al2023-ami-2023*-x86_64",
            "Filter.2.Name": "state",
            "Filter.2.Value.1": "available",
            "Filter.3.Name": "architecture",
            "Filter.3.Value.1": "x86_64"
        ])
        let xml = String(data: data, encoding: .utf8) ?? ""

        // Extract all image IDs and names, pick the latest
        let imageIds = extractAllXML(xml, tag: "imageId")
        if let first = imageIds.first {
            return first
        }

        // Fallback to known AMIs per region
        let fallbackAMIs: [String: String] = [
            "us-east-1": "ami-0c02fb55956c7d316",
            "us-east-2": "ami-089a545a9ed9893b6",
            "us-west-1": "ami-0ed05376b59b90e46",
            "us-west-2": "ami-0dc8f589abe99f538",
            "eu-west-1": "ami-0d71ea30463e0ff8d",
            "eu-central-1": "ami-0c956e207f9d113d5",
            "ap-south-1": "ami-0cca134ec43cf708f",
            "ap-southeast-1": "ami-0b20f552f63953f0e",
        ]
        if let ami = fallbackAMIs[region] {
            return ami
        }
        throw ProvisioningError.parseError("No AMI found for region \(region)")
    }

    private func waitForInstance(signer: AWSSigV4, instanceId: String) async throws -> String {
        for _ in 0..<30 {
            try await Task.sleep(for: .seconds(10))
            let data = try await ec2Request(signer: signer, params: [
                "Action": "DescribeInstances",
                "InstanceId.1": instanceId
            ])
            let xml = String(data: data, encoding: .utf8) ?? ""

            if let ip = extractXML(xml, tag: "publicIpAddress"), !ip.isEmpty {
                return ip
            }
        }
        throw ProvisioningError.timeout("Instance did not get a public IP after 5 minutes")
    }

    // MARK: - User Data Script

    private func buildUserData() -> String {
        var script = """
        #!/bin/bash
        set -e
        exec > /var/log/pocket-engineer-setup.log 2>&1

        # --- Core system packages (always installed) ---
        dnf install -y nodejs20 npm git tmux python3 python3-pip jq tar gzip unzip which

        # --- Claude Code (always installed) ---
        npm install -g @anthropic-ai/claude-code

        # --- Python essentials (always installed) ---
        pip3 install --upgrade pip
        pip3 install flask requests boto3

        """

        // Conditional tool installs
        if devTools.enableGitHub {
            script += """

            # --- GitHub CLI ---
            dnf install -y gh

            """
            if !devTools.gitHubToken.isEmpty {
                script += """
                su - ec2-user -c 'mkdir -p ~/.config/gh && cat > ~/.config/gh/hosts.yml << GHEOF
                github.com:
                    oauth_token: \(devTools.gitHubToken)
                    user: ""
                    git_protocol: https
                GHEOF
                '

                """
            }
        }

        if devTools.enableVercel {
            script += """

            # --- Vercel ---
            npm install -g vercel

            """
            if !devTools.vercelToken.isEmpty {
                script += "echo 'export VERCEL_TOKEN=\(devTools.vercelToken)' >> /home/ec2-user/.bashrc\n"
            }
        }

        if devTools.enableSupabase {
            script += """

            # --- Supabase ---
            npm install -g supabase

            """
            if !devTools.supabaseToken.isEmpty {
                script += "echo 'export SUPABASE_ACCESS_TOKEN=\(devTools.supabaseToken)' >> /home/ec2-user/.bashrc\n"
            }
        }

        if devTools.enableDocker {
            script += """

            # --- Docker ---
            dnf install -y docker
            systemctl enable docker
            systemctl start docker
            usermod -aG docker ec2-user

            """
        }

        if devTools.enableCodex {
            script += """

            # --- OpenAI Codex ---
            npm install -g @openai/codex

            """
            if !devTools.openaiKey.isEmpty {
                script += "echo 'export OPENAI_API_KEY=\(devTools.openaiKey)' >> /home/ec2-user/.bashrc\n"
            }
        }

        if devTools.enableAwsCli {
            script += """

            # --- AWS CLI v2 ---
            curl -sL "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o /tmp/awscli.zip
            unzip -q /tmp/awscli.zip -d /tmp
            /tmp/aws/install
            rm -rf /tmp/aws /tmp/awscli.zip
            echo 'export AWS_ACCESS_KEY_ID=\(awsAccessKey)' >> /home/ec2-user/.bashrc
            echo 'export AWS_SECRET_ACCESS_KEY=\(awsSecretKey)' >> /home/ec2-user/.bashrc
            echo 'export AWS_DEFAULT_REGION=\(region)' >> /home/ec2-user/.bashrc

            """
        }

        script += """

        # --- Anthropic API Key ---
        echo 'export ANTHROPIC_API_KEY=\(anthropicKey)' >> /home/ec2-user/.bashrc

        # --- Projects directory ---
        mkdir -p /home/ec2-user/projects
        chown -R ec2-user:ec2-user /home/ec2-user/projects

        # --- Git config ---
        su - ec2-user -c 'git config --global user.name "Pocket Engineer"'
        su - ec2-user -c 'git config --global user.email "engineer@pocketengineer.app"'

        # --- tmux config ---
        cat > /home/ec2-user/.tmux.conf << 'TMUXEOF'
        set -g mouse on
        set -g history-limit 50000
        set -g status-style 'bg=#1e1e2e fg=#cdd6f4'
        TMUXEOF
        chown ec2-user:ec2-user /home/ec2-user/.tmux.conf

        # Signal completion
        touch /home/ec2-user/.pocket-engineer-ready
        """

        return script
    }

    // MARK: - XML Helpers

    private func extractXML(_ xml: String, tag: String) -> String? {
        guard let startRange = xml.range(of: "<\(tag)>"),
              let endRange = xml.range(of: "</\(tag)>", range: startRange.upperBound..<xml.endIndex) else {
            return nil
        }
        return String(xml[startRange.upperBound..<endRange.lowerBound])
    }

    private func extractAllXML(_ xml: String, tag: String) -> [String] {
        var results: [String] = []
        var searchStart = xml.startIndex
        while let startRange = xml.range(of: "<\(tag)>", range: searchStart..<xml.endIndex),
              let endRange = xml.range(of: "</\(tag)>", range: startRange.upperBound..<xml.endIndex) {
            results.append(String(xml[startRange.upperBound..<endRange.lowerBound]))
            searchStart = endRange.upperBound
        }
        return results
    }
}

enum ProvisioningError: Error, LocalizedError {
    case awsError(Int, String)
    case parseError(String)
    case timeout(String)

    var errorDescription: String? {
        switch self {
        case .awsError(let code, let body):
            // Try to extract clean message from AWS XML
            if let msgRange = body.range(of: "<Message>"),
               let endRange = body.range(of: "</Message>") {
                let message = String(body[msgRange.upperBound..<endRange.lowerBound])
                return "AWS Error (\(code)): \(message)"
            }
            return "AWS Error (\(code)): \(String(body.prefix(200)))"
        case .parseError(let msg): return msg
        case .timeout(let msg): return msg
        }
    }
}
