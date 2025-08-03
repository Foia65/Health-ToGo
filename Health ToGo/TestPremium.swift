import SwiftUI

struct TestPremium: View {
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    var body: some View {

        Toggle("Premium User", isOn: $isPremiumUser)
            .padding(.horizontal, 80)
    }
}

#Preview {
    TestPremium()
}
