import SwiftUI

struct ProjectContextSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var context: String
    let onSave: (String) -> Void

    @State private var editedContext: String = ""

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 16) {
                Text("Set persistent context that Claude uses for every message in this session.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .padding(.horizontal)

                TextEditor(text: $editedContext)
                    .font(.system(.body, design: .monospaced))
                    .padding(8)
                    .background(Color.systemGray6Color)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .padding(.horizontal)

                VStack(alignment: .leading, spacing: 8) {
                    Text("Examples:")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundColor(.secondary)
                    Text("• \"We sell fraud detection ML models. Customer is a travel booking company.\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• \"Use blue branding (#1a73e8). Target audience is healthcare.\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text("• \"Always build with Python Flask. Make UIs mobile-responsive.\"")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)

                Spacer()
            }
            .padding(.top, 8)
            .navigationTitle("Project Context")
            .iOSNavigationBarTitleDisplayMode()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        onSave(editedContext)
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
        .onAppear {
            editedContext = context
        }
    }
}
