import SwiftUI

struct NewSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var selectedTemplate: ProjectTemplate?
    let onCreate: (String, String?) -> Void

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Templates
                    VStack(alignment: .leading, spacing: 10) {
                        Text("template")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.textTertiary)
                            .padding(.horizontal)

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 8) {
                                ForEach(ProjectTemplate.templates) { template in
                                    templateCard(template)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.top, 8)

                    // Session name
                    VStack(alignment: .leading, spacing: 8) {
                        Text("name")
                            .font(.system(.caption, design: .monospaced))
                            .foregroundColor(.textTertiary)

                        TextField("describe what to build", text: $title)
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
                            .textInputAutocapitalization(.sentences)
                            #endif
                    }
                    .padding(.horizontal)

                    Text("Claude will work on your remote server. Code edits are auto-approved.")
                        .font(.system(.caption2, design: .monospaced))
                        .foregroundColor(.textTertiary)
                        .padding(.horizontal)
                }
            }
            .background(Color.surface)
            .navigationTitle("New Session")
            .iOSNavigationBarTitleDisplayMode()
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundColor(.textSecondary)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Create") {
                        let sessionTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
                        if !sessionTitle.isEmpty {
                            onCreate(sessionTitle, selectedTemplate?.prompt)
                            dismiss()
                        }
                    }
                    .foregroundColor(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .textTertiary : .accent)
                    .disabled(title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
        .preferredColorScheme(.dark)
        .presentationDetents([.medium, .large])
    }

    private func templateCard(_ template: ProjectTemplate) -> some View {
        let isSelected = selectedTemplate?.name == template.name
        return Button {
            selectedTemplate = template
            if template.prompt != nil && title.isEmpty {
                title = template.name
            }
            if template.prompt == nil {
                selectedTemplate = nil
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: template.icon)
                    .font(.system(size: 18))
                    .foregroundColor(isSelected ? .accent : .textSecondary)
                    .frame(width: 40, height: 40)
                    .background(isSelected ? Color.accent.opacity(0.15) : Color.surfaceRaised)
                    .clipShape(RoundedRectangle(cornerRadius: 8))

                Text(template.name)
                    .font(.system(.caption2, design: .monospaced))
                    .fontWeight(.medium)
                    .foregroundColor(isSelected ? .accent : .textPrimary)

                Text(template.description)
                    .font(.system(size: 9, design: .monospaced))
                    .foregroundColor(.textTertiary)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 90)
            .padding(.vertical, 10)
            .padding(.horizontal, 6)
            .background(isSelected ? Color.accent.opacity(0.05) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .stroke(isSelected ? Color.accent.opacity(0.3) : Color.surfaceBorder, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}
