import SwiftUI

struct SessionListView: View {
    @Bindable var viewModel: SessionListViewModel
    let serverConfig: ServerConfig?
    let onSelectSession: (Session) -> Void

    var body: some View {
        Group {
            if viewModel.sessions.isEmpty {
                ContentUnavailableView(
                    "No Sessions",
                    systemImage: "bubble.left.and.bubble.right",
                    description: Text("Start a new session to begin working with Claude.")
                )
            } else {
                List {
                    ForEach(viewModel.sessions, id: \.id) { session in
                        Button {
                            onSelectSession(session)
                        } label: {
                            SessionRowView(session: session)
                        }
                        .tint(.primary)
                    }
                    .onDelete { offsets in
                        viewModel.deleteSessions(at: offsets)
                    }
                }
                .listStyle(.plain)
            }
        }
        .onAppear {
            viewModel.fetchSessions()
        }
    }
}
