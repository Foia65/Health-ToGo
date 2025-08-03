import SwiftUI

// MARK: - Reusable Loading Overlay

struct LoadingOverlayView: View {
    let message: String

    var body: some View {
        VStack {
            ProgressView(message)
                .progressViewStyle(CircularProgressViewStyle())
                .padding()
                .background(.ultraThinMaterial)
                .cornerRadius(12)
                .shadow(radius: 10)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.black.opacity(0.3).ignoresSafeArea())
        .transition(.opacity)
    }
}
