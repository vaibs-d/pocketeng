import SwiftUI
import SwiftData
import AVFoundation

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var step: OnboardingStep = .welcome
    @State private var host = ""
    @State private var sshKeyText = ""
    @State private var errorMessage: String?
    @State private var showScanner = false

    let onComplete: (String, Data) -> Void

    enum OnboardingStep {
        case welcome, connect, connecting, done
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Progress
                GeometryReader { geo in
                    Rectangle()
                        .fill(Color.accent)
                        .frame(width: geo.size.width * progressValue, height: 2)
                }
                .frame(height: 2)

                switch step {
                case .welcome:
                    welcomeStep
                case .connect:
                    connectStep
                case .connecting:
                    connectingStep
                case .done:
                    EmptyView()
                }
            }
            .background(Color.surface)
            .navigationTitle("setup")
            .iOSNavigationBarTitleDisplayMode()
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Welcome

    private var welcomeStep: some View {
        VStack(spacing: 24) {
            Spacer()

            Text(">_")
                .font(.system(size: 56, weight: .light, design: .monospaced))
                .foregroundColor(.accent)

            Text("pocket engineer")
                .font(.system(.title, design: .monospaced))
                .fontWeight(.bold)
                .foregroundColor(.textPrimary)

            Text("your cloud dev environment,\nfrom your phone.")
                .font(.system(.subheadline, design: .monospaced))
                .foregroundColor(.textSecondary)
                .multilineTextAlignment(.center)

            Spacer()

            VStack(spacing: 8) {
                Text("run this on your laptop first:")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.textTertiary)

                Text("pocket-engineer init")
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.accent)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 10)
                    .background(Color.accent.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
                    .overlay(
                        RoundedRectangle(cornerRadius: 6)
                            .stroke(Color.accent.opacity(0.2), lineWidth: 1)
                    )
            }

            Spacer()

            Button {
                withAnimation { step = .connect }
            } label: {
                Text("connect to server")
                    .font(.system(.subheadline, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.surface)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.textPrimary)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
        }
    }

    // MARK: - Connect

    private var connectStep: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                Text("connect")
                    .font(.system(.title2, design: .monospaced))
                    .fontWeight(.bold)
                    .foregroundColor(.textPrimary)
                    .padding(.top)

                Text("scan the QR code from your terminal\nor enter details manually.")
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.textSecondary)

                // Scan button
                Button {
                    showScanner = true
                } label: {
                    HStack(spacing: 12) {
                        Image(systemName: "qrcode.viewfinder")
                            .font(.title3)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("scan QR code")
                                .font(.system(.subheadline, design: .monospaced))
                                .fontWeight(.semibold)
                            Text("from pocket-engineer init")
                                .font(.system(.caption2, design: .monospaced))
                                .foregroundColor(.textSecondary)
                        }
                        Spacer()
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundColor(.textPrimary)
                    .padding(14)
                    .background(Color.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.surfaceBorder, lineWidth: 1)
                    )
                }
                .sheet(isPresented: $showScanner) {
                    QRScannerView { scannedData in
                        showScanner = false
                        handleQRCode(scannedData)
                    }
                }

                // Divider
                HStack {
                    Rectangle().fill(Color.surfaceBorder).frame(height: 1)
                    Text("or")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)
                    Rectangle().fill(Color.surfaceBorder).frame(height: 1)
                }
                .padding(.vertical, 4)

                // Manual
                VStack(alignment: .leading, spacing: 8) {
                    Text("host")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.textTertiary)
                    TextField("54.123.45.67", text: $host)
                        .textFieldStyle(.plain)
                        .font(.system(.subheadline, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .padding(12)
                        .background(Color.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.surfaceBorder, lineWidth: 1)
                        )
                        #if os(iOS)
                        .keyboardType(.numbersAndPunctuation)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("ssh key")
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.textTertiary)
                    TextEditor(text: $sshKeyText)
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textPrimary)
                        .scrollContentBackground(.hidden)
                        .frame(minHeight: 100)
                        .padding(8)
                        .background(Color.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                        .overlay(
                            RoundedRectangle(cornerRadius: 6)
                                .stroke(Color.surfaceBorder, lineWidth: 1)
                        )
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled()
                        #endif

                    Text("paste .pem key from ~/.pocket-engineer/")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)
                }

                if let error = errorMessage {
                    Text(error)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundColor(.red)
                }

                Spacer(minLength: 20)

                Button {
                    connectToServer()
                } label: {
                    Text("connect")
                        .font(.system(.subheadline, design: .monospaced))
                        .fontWeight(.semibold)
                        .foregroundColor(manualEntryValid ? .surface : .textTertiary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(manualEntryValid ? Color.textPrimary : Color.surfaceRaised)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
                .disabled(!manualEntryValid)

                Button("back") {
                    withAnimation { step = .welcome }
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.textTertiary)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 24)
        }
    }

    // MARK: - Connecting

    private var connectingStep: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.2)
                .tint(.accent)

            Text("connecting...")
                .font(.system(.title3, design: .monospaced))
                .fontWeight(.medium)
                .foregroundColor(.textPrimary)

            Text(host)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.textTertiary)

            if let error = errorMessage {
                Text(error)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundColor(.red)
                    .padding(.horizontal)

                Button("retry") {
                    connectToServer()
                }
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.accent)
            }

            Spacer()
        }
    }

    // MARK: - Logic

    private func handleQRCode(_ data: String) {
        guard data.hasPrefix("pe://") else {
            errorMessage = "invalid QR code"
            return
        }

        let stripped = String(data.dropFirst(5))
        let parts = stripped.components(separatedBy: "?")
        guard let hostPort = parts.first else {
            errorMessage = "invalid QR format"
            return
        }

        host = hostPort.components(separatedBy: ":").first ?? ""

        if parts.count > 1 {
            let query = parts[1]
            if query.hasPrefix("key=") {
                let b64Key = String(query.dropFirst(4))
                if let keyData = Data(base64Encoded: b64Key),
                   let keyString = String(data: keyData, encoding: .utf8) {
                    sshKeyText = keyString
                }
            }
        }

        if !host.isEmpty && !sshKeyText.isEmpty {
            connectToServer()
        }
    }

    private func connectToServer() {
        errorMessage = nil
        let trimmedHost = host.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedKey = sshKeyText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedHost.isEmpty, !trimmedKey.isEmpty else {
            errorMessage = "host and ssh key required"
            return
        }

        withAnimation { step = .connecting }

        guard let keyData = trimmedKey.data(using: .utf8) else {
            errorMessage = "invalid key data"
            withAnimation { step = .connect }
            return
        }

        host = trimmedHost
        onComplete(trimmedHost, keyData)
    }

    private var manualEntryValid: Bool {
        !host.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !sshKeyText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var progressValue: Double {
        switch step {
        case .welcome: return 0.0
        case .connect: return 0.5
        case .connecting: return 0.8
        case .done: return 1.0
        }
    }
}

// MARK: - QR Scanner

struct QRScannerView: UIViewControllerRepresentable {
    let onScan: (String) -> Void

    func makeUIViewController(context: Context) -> QRScannerController {
        let controller = QRScannerController()
        controller.onScan = onScan
        return controller
    }

    func updateUIViewController(_ uiViewController: QRScannerController, context: Context) {}
}

class QRScannerController: UIViewController, AVCaptureMetadataOutputObjectsDelegate {
    var onScan: ((String) -> Void)?
    private var captureSession: AVCaptureSession?
    private var didScan = false

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let session = AVCaptureSession()
        guard let device = AVCaptureDevice.default(for: .video),
              let input = try? AVCaptureDeviceInput(device: device) else {
            showFallback()
            return
        }

        session.addInput(input)
        let output = AVCaptureMetadataOutput()
        session.addOutput(output)
        output.setMetadataObjectsDelegate(self, queue: .main)
        output.metadataObjectTypes = [.qr]

        let preview = AVCaptureVideoPreviewLayer(session: session)
        preview.frame = view.bounds
        preview.videoGravity = .resizeAspectFill
        view.layer.addSublayer(preview)
        captureSession = session

        let label = UILabel()
        label.text = "scan QR from terminal"
        label.textColor = .white
        label.font = .monospacedSystemFont(ofSize: 14, weight: .medium)
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -40),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor)
        ])

        DispatchQueue.global(qos: .userInitiated).async {
            session.startRunning()
        }
    }

    func metadataOutput(_ output: AVCaptureMetadataOutput, didOutput metadataObjects: [AVMetadataObject], from connection: AVCaptureConnection) {
        guard !didScan,
              let object = metadataObjects.first as? AVMetadataMachineReadableCodeObject,
              let value = object.stringValue else { return }
        didScan = true
        captureSession?.stopRunning()
        dismiss(animated: true) {
            self.onScan?(value)
        }
    }

    private func showFallback() {
        let label = UILabel()
        label.text = "camera not available\nenter details manually"
        label.textColor = .white
        label.font = .monospacedSystemFont(ofSize: 14, weight: .regular)
        label.numberOfLines = 0
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        ])
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.dismiss(animated: true)
        }
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        captureSession?.stopRunning()
    }
}
