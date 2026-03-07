import SwiftUI
import CoreImage.CIFilterBuiltins

struct QRCodeView: View {
    let url: String
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Text("Scan to view demo")
                .font(.title2)
                .fontWeight(.bold)

            if let qrImage = generateQRCode(from: url) {
                Image(uiImage: qrImage)
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 250, height: 250)
                    .padding(20)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .shadow(color: .black.opacity(0.1), radius: 10)
            }

            Text(url)
                .font(.system(.caption, design: .monospaced))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            HStack(spacing: 16) {
                Button {
                    #if os(iOS)
                    UIPasteboard.general.string = url
                    #endif
                } label: {
                    Label("Copy URL", systemImage: "doc.on.doc")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.brandPurple)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.brandPurple.opacity(0.1))
                        .clipShape(Capsule())
                }

                Button {
                    dismiss()
                } label: {
                    Text("Done")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(Color.brandPurple)
                        .clipShape(Capsule())
                }
            }

            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.systemBackgroundColor)
    }

    private func generateQRCode(from string: String) -> UIImage? {
        guard let data = string.data(using: .ascii) else { return nil }
        let filter = CIFilter(name: "CIQRCodeGenerator")
        filter?.setValue(data, forKey: "inputMessage")
        filter?.setValue("H", forKey: "inputCorrectionLevel")
        guard let output = filter?.outputImage else { return nil }
        let scaled = output.transformed(by: CGAffineTransform(scaleX: 10, y: 10))
        return UIImage(ciImage: scaled)
    }
}
