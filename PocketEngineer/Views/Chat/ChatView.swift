import SwiftUI

struct ChatView: View {
    @Bindable var viewModel: ChatViewModel
    @State private var showShareSheet = false
    @State private var showQRCode = false
    @State private var showProjectContext = false

    var body: some View {
        VStack(spacing: 0) {
            SessionStatusBanner(
                status: viewModel.sessionStatus,
                errorMessage: viewModel.errorMessage
            )

            if let url = viewModel.deployedURL {
                MiniPreviewBar(
                    url: url,
                    onTap: { viewModel.showPreview = true },
                    onRefresh: { Task { await viewModel.deploy() } }
                )
            }

            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(viewModel.messages, id: \.id) { message in
                            VStack(spacing: 0) {
                                MessageBubbleView(message: message)

                                if message.role == .assistant && !message.sortedToolActivities.isEmpty {
                                    ForEach(message.sortedToolActivities, id: \.id) { activity in
                                        ToolActivityView(activity: activity)
                                    }
                                }
                            }
                            .id(message.id)
                        }

                        if viewModel.isStreaming && !viewModel.currentToolActivities.isEmpty {
                            VStack(spacing: 0) {
                                ForEach(viewModel.currentToolActivities, id: \.id) { activity in
                                    ToolActivityView(activity: activity)
                                }
                            }
                            .id("tools")
                        }

                        Color.clear
                            .frame(height: 1)
                            .id("bottom")
                    }
                    .padding(.top, 4)
                    .padding(.bottom, 16)
                }
                .background(Color.surface)
                .onChange(of: viewModel.messages.count) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        proxy.scrollTo("bottom", anchor: .bottom)
                    }
                }
                .onChange(of: viewModel.currentStreamingText) {
                    proxy.scrollTo("bottom", anchor: .bottom)
                }
            }

            InputBarView(
                text: $viewModel.inputText,
                isStreaming: viewModel.isStreaming,
                onSend: { Task { await viewModel.sendMessage() } },
                onCancel: { viewModel.cancelTask() }
            )
        }
        .background(Color.surface)
        .navigationTitle(viewModel.session.title)
        .iOSNavigationBarTitleDisplayMode()
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .automatic) {
                HStack(spacing: 12) {
                    Button {
                        Task { await viewModel.deploy() }
                    } label: {
                        if viewModel.isDeploying {
                            ProgressView()
                                .scaleEffect(0.7)
                                .tint(.textSecondary)
                        } else {
                            Image(systemName: "rocket.fill")
                                .foregroundColor(viewModel.deployedURL != nil ? .accent : .textSecondary)
                        }
                    }
                    .disabled(viewModel.isDeploying || viewModel.isStreaming)

                    Menu {
                        Button {
                            showProjectContext = true
                        } label: {
                            Label("Project Context", systemImage: "doc.text")
                        }

                        Button {
                            showShareSheet = true
                        } label: {
                            Label("Share", systemImage: "square.and.arrow.up")
                        }
                        .disabled(viewModel.messages.isEmpty)

                        if viewModel.sessionStatus == .error {
                            Button {
                                Task { await viewModel.retryLastMessage() }
                            } label: {
                                Label("Retry", systemImage: "arrow.clockwise")
                            }
                        }
                        if viewModel.deployedURL != nil {
                            Button {
                                viewModel.showPreview = true
                            } label: {
                                Label("Open Preview", systemImage: "eye")
                            }
                            Button {
                                showQRCode = true
                            } label: {
                                Label("QR Code", systemImage: "qrcode")
                            }
                        }
                    } label: {
                        Image(systemName: "ellipsis")
                            .foregroundColor(.textSecondary)
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            #if os(iOS)
            let items: [Any] = viewModel.deployedURL != nil
                ? [viewModel.shareableText, URL(string: viewModel.deployedURL!)!] as [Any]
                : [viewModel.shareableText]
            ActivityView(activityItems: items)
                .presentationDetents([.medium])
            #endif
        }
        .sheet(isPresented: $viewModel.showPreview) {
            if let url = viewModel.deployedURL {
                AppPreviewView(url: url)
            }
        }
        .fullScreenCover(isPresented: $showQRCode) {
            if let url = viewModel.deployedURL {
                QRCodeView(url: url)
            }
        }
        .sheet(isPresented: $showProjectContext) {
            ProjectContextSheet(
                context: Binding(
                    get: { viewModel.session.projectContext ?? "" },
                    set: { _ in }
                ),
                onSave: { newContext in
                    viewModel.updateProjectContext(newContext)
                }
            )
        }
    }

}

#if os(iOS)
struct ActivityView: UIViewControllerRepresentable {
    let activityItems: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#endif
