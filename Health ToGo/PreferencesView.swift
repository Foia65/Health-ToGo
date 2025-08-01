import SwiftUI

struct PreferencesView: View {
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("About and Support")) {
                        NavigationLink(
                            destination: AboutHealthToGoView()
                        ) {
                            Label {
                                Text("About Health ToGo")
                            } icon: {
                                Image(systemName: "info.circle.fill")
                            }
                        }
                        
                    }
                    
#if DEBUG
                    Section(header: Text("DEBUG")) {
                        NavigationLink(
                            destination: TestPremium()
                        ) {
                            Label {
                                Text("Test Premium") // Unstyled text
                            } icon: {
                                Image(systemName: "hammer.fill")
                            }
                        }
                    }
#endif

                }
            }
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Close") {
                        dismiss()
                    }
                }
            }
        }   // end toolbar
    }
}

#Preview {
    PreferencesView()
}
