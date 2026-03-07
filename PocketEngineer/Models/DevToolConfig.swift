import Foundation

struct DevToolConfig: Sendable {
    var enableGitHub: Bool = false
    var gitHubToken: String = ""
    var enableVercel: Bool = false
    var vercelToken: String = ""
    var enableSupabase: Bool = false
    var supabaseToken: String = ""
    var enableDocker: Bool = false
    var enableCodex: Bool = false
    var openaiKey: String = ""
    var enableAwsCli: Bool = true
}
