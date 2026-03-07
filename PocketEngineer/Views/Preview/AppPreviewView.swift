import SwiftUI
import WebKit

struct AppPreviewView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss
    @State private var isLoading = true
    @State private var reloadToken = UUID()
    @State private var currentURL: String = ""
    @State private var pageTitle: String = ""
    @State private var showConsole = false
    @State private var consoleLogs: [ConsoleEntry] = []

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // URL bar
                urlBar

                ZStack {
                    WebView(
                        urlString: url,
                        isLoading: $isLoading,
                        currentURL: $currentURL,
                        pageTitle: $pageTitle,
                        consoleLogs: $consoleLogs,
                        reloadToken: reloadToken
                    )

                    if isLoading {
                        loadingOverlay
                    }
                }

                if showConsole {
                    consoleView
                }
            }
            .background(Color.surface)
            .navigationTitle(pageTitle.isEmpty ? "Preview" : pageTitle)
            .iOSNavigationBarTitleDisplayMode()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.textSecondary)
                    }
                }
                ToolbarItem(placement: .automatic) {
                    HStack(spacing: 14) {
                        Button {
                            reloadToken = UUID()
                        } label: {
                            Image(systemName: "arrow.clockwise")
                                .foregroundColor(.textSecondary)
                        }

                        Button {
                            showConsole.toggle()
                        } label: {
                            Image(systemName: "terminal")
                                .foregroundColor(showConsole ? .accent : .textSecondary)
                        }

                        Button {
                            if let link = URL(string: url) {
                                #if os(iOS)
                                UIApplication.shared.open(link)
                                #endif
                            }
                        } label: {
                            Image(systemName: "safari")
                                .foregroundColor(.textSecondary)
                        }
                    }
                }
            }
        }
    }

    private var urlBar: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(isLoading ? Color.yellow : Color.accent)
                .frame(width: 6, height: 6)

            Text(currentURL.isEmpty ? url : currentURL)
                .font(.system(.caption2, design: .monospaced))
                .foregroundColor(.textSecondary)
                .lineLimit(1)
                .truncationMode(.middle)

            Spacer()

            Button {
                #if os(iOS)
                UIPasteboard.general.string = currentURL.isEmpty ? url : currentURL
                #endif
            } label: {
                Image(systemName: "doc.on.doc")
                    .font(.caption2)
                    .foregroundColor(.textTertiary)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Color.surfaceRaised)
    }

    private var loadingOverlay: some View {
        VStack(spacing: 12) {
            ProgressView()
                .scaleEffect(1.0)
                .tint(.accent)
            Text("loading...")
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.textTertiary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surface.opacity(0.85))
    }

    private var consoleView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Console header
            HStack {
                Text("console")
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.semibold)
                    .foregroundColor(.textSecondary)

                Spacer()

                Text("\(consoleLogs.count)")
                    .font(.system(.caption2, design: .monospaced))
                    .foregroundColor(.textTertiary)

                Button {
                    consoleLogs.removeAll()
                } label: {
                    Image(systemName: "trash")
                        .font(.system(size: 10))
                        .foregroundColor(.textTertiary)
                }
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(Color.surfaceBorder)

            // Console output
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 2) {
                    if consoleLogs.isEmpty {
                        Text("no output")
                            .font(.system(.caption2, design: .monospaced))
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                    } else {
                        ForEach(consoleLogs) { entry in
                            HStack(alignment: .top, spacing: 6) {
                                Text(entry.level.icon)
                                    .font(.system(size: 9))
                                Text(entry.message)
                                    .font(.system(.caption2, design: .monospaced))
                                    .foregroundColor(entry.level.color)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 2)
                        }
                    }
                }
            }
            .frame(height: 120)
            .background(Color.surface)
        }
    }
}

// MARK: - Console

struct ConsoleEntry: Identifiable {
    let id = UUID()
    let level: ConsoleLevel
    let message: String
    let timestamp: Date = Date()
}

enum ConsoleLevel {
    case log, warn, error

    var icon: String {
        switch self {
        case .log: return ">"
        case .warn: return "!"
        case .error: return "x"
        }
    }

    var color: Color {
        switch self {
        case .log: return .textSecondary
        case .warn: return .yellow
        case .error: return .red
        }
    }
}

// MARK: - WebView

#if os(iOS)
struct WebView: UIViewRepresentable {
    let urlString: String
    @Binding var isLoading: Bool
    @Binding var currentURL: String
    @Binding var pageTitle: String
    @Binding var consoleLogs: [ConsoleEntry]
    let reloadToken: UUID

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeUIView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.allowsInlineMediaPlayback = true

        // Inject console capture script
        let consoleScript = WKUserScript(
            source: """
            (function() {
                var origLog = console.log;
                var origWarn = console.warn;
                var origError = console.error;
                console.log = function() {
                    origLog.apply(console, arguments);
                    window.webkit.messageHandlers.consoleLog.postMessage({level: 'log', message: Array.from(arguments).join(' ')});
                };
                console.warn = function() {
                    origWarn.apply(console, arguments);
                    window.webkit.messageHandlers.consoleLog.postMessage({level: 'warn', message: Array.from(arguments).join(' ')});
                };
                console.error = function() {
                    origError.apply(console, arguments);
                    window.webkit.messageHandlers.consoleLog.postMessage({level: 'error', message: Array.from(arguments).join(' ')});
                };
                window.onerror = function(msg, url, line) {
                    window.webkit.messageHandlers.consoleLog.postMessage({level: 'error', message: msg + ' (' + url + ':' + line + ')'});
                };
            })();
            """,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: false
        )
        config.userContentController.addUserScript(consoleScript)
        config.userContentController.add(context.coordinator, name: "consoleLog")

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.navigationDelegate = context.coordinator
        webView.allowsBackForwardNavigationGestures = true
        webView.scrollView.contentInsetAdjustmentBehavior = .automatic
        webView.isOpaque = false
        webView.backgroundColor = .clear

        if let url = URL(string: urlString) {
            webView.load(URLRequest(url: url))
        }
        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        if context.coordinator.lastReloadToken != reloadToken {
            context.coordinator.lastReloadToken = reloadToken
            if let url = URL(string: urlString) {
                webView.load(URLRequest(url: url))
            }
        }
    }

    class Coordinator: NSObject, WKNavigationDelegate, WKScriptMessageHandler {
        let parent: WebView
        var lastReloadToken: UUID

        init(parent: WebView) {
            self.parent = parent
            self.lastReloadToken = parent.reloadToken
        }

        func webView(_ webView: WKWebView, didStartProvisionalNavigation navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = true
            }
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.currentURL = webView.url?.absoluteString ?? ""
                self.parent.pageTitle = webView.title ?? ""
            }
        }

        func webView(_ webView: WKWebView, didFail navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
            }
        }

        func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
            DispatchQueue.main.async {
                self.parent.isLoading = false
                self.parent.consoleLogs.append(
                    ConsoleEntry(level: .error, message: "Failed to load: \(error.localizedDescription)")
                )
            }
        }

        // Console log capture
        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            guard let body = message.body as? [String: String],
                  let levelStr = body["level"],
                  let msg = body["message"] else { return }

            let level: ConsoleLevel
            switch levelStr {
            case "warn": level = .warn
            case "error": level = .error
            default: level = .log
            }

            DispatchQueue.main.async {
                self.parent.consoleLogs.append(ConsoleEntry(level: level, message: msg))
                // Keep last 200 entries
                if self.parent.consoleLogs.count > 200 {
                    self.parent.consoleLogs.removeFirst(self.parent.consoleLogs.count - 200)
                }
            }
        }
    }
}
#else
struct WebView: View {
    let urlString: String
    @Binding var isLoading: Bool
    @Binding var currentURL: String
    @Binding var pageTitle: String
    @Binding var consoleLogs: [ConsoleEntry]
    let reloadToken: UUID

    var body: some View {
        Text("Preview not available on macOS")
            .foregroundColor(.secondary)
    }
}
#endif
