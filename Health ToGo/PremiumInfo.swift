import SwiftUI

struct PremiumInfo: View {
    @State private var isPurchasing = false
    @State private var showPurchaseSuccess = false
    @State private var showPurchaseError = false

    var body: some View {
        VStack(spacing: 0) {
            // Header
            VStack(spacing: 12) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 40))
                    .foregroundColor(.yellow)
                    .padding(.top, 30)

                Text("Go Premium")
                    .font(.system(size: 28, weight: .bold))

                Text("Unlock the full potential of the app")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .padding(.bottom, 20)

            Divider()

            // Features List
            VStack(spacing: 20) {
                PremiumFeatureRow(
                    icon: "square.and.arrow.down",
                    title: "CSV Export",
                    description: "Export your complete health data for analysis in Excel or other tools"
                )

                PremiumFeatureRow(
                    icon: "clock.arrow.circlepath",
                    title: "Fetch All Historical Data",
                    description: "Access your complete health history, not just recent data"
                )

                PremiumFeatureRow(
                    icon: "xmark.circle",
                    title: "Remove Ads",
                    description: "Enjoy an ad-free experience with no distractions"
                )
            }
            .padding(.vertical, 25)

            Divider()

            // Pricing
            VStack(spacing: 8) {
                Text("Only")
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text("3.99€")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.primary)

                Text("One-time payment • No subscription")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding(.vertical, 20)

            // Purchase Button
            Button(action: initiatePurchase) {
                HStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Upgrade Now")
                            .font(.headline)
                    }
                }
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.blue)
                .cornerRadius(12)
            }
            .padding(.horizontal)
            .disabled(isPurchasing)

            // Restore Purchases
            Button(action: restorePurchases) {
                Text("Restore Purchases")
                    .font(.footnote)
                    .foregroundColor(.blue)
            }
            .padding(.vertical, 10)

            // Terms and Privacy
            HStack(spacing: 20) {
                Button("Terms of Service") {
                    // Open terms URL
                }
                Button("Privacy Policy") {
                    // Open privacy URL
                }
            }
            .font(.caption2)
            .foregroundColor(.secondary)
            .padding(.bottom, 20)
        }
        .background(Color(.systemBackground))
        .cornerRadius(16)
        .shadow(radius: 10)
        .padding(.horizontal, 20)
        .alert("Purchase Successful", isPresented: $showPurchaseSuccess) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Thank you for upgrading to Premium! All features are now unlocked.")
        }
        .alert("Purchase Failed", isPresented: $showPurchaseError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text("Could not complete the purchase. Please try again later.")
        }
    }

    private func initiatePurchase() {
        isPurchasing = true
        // Simulate purchase process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isPurchasing = false
            // In a real app, you would handle the actual purchase here
            // This is just for demonstration:
            let success = Bool.random() // Simulate random success/failure
            if success {
                showPurchaseSuccess = true
            } else {
                showPurchaseError = true
            }
        }
    }

    private func restorePurchases() {
        isPurchasing = true
        // Simulate restore process
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isPurchasing = false
            // In a real app, you would handle actual purchase restoration
            showPurchaseSuccess = true
        }
    }
}

struct PremiumFeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.blue)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)

                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal)
    }
}

struct PremiumInfo_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            PremiumInfo()
                .previewDisplayName("Light Mode")

            PremiumInfo()
                .preferredColorScheme(.dark)
                .previewDisplayName("Dark Mode")
        }
    }
}
