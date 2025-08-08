import SwiftUI

struct ContentView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showingSettings = false
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    var body: some View {
        NavigationStack {
            VStack {
                Form {
                    Section(header: Text("Body Measures")) {
                        NavigationLink(
                            destination: WeightView()
                        ) {
                            Label {
                                Text("Weight")
                            }icon: {
                                Image(systemName: "figure.arms.open")
                            }
                        }

                        NavigationLink(
                            destination: BMIView()
                        ) {
                            Label {
                                Text("BMI (Body Mass Index)")
                            }icon: {
                                Image(systemName: "figure.arms.open")
                                    .foregroundStyle(.green)
                            }
                        }

                        NavigationLink(
                            destination: BodyFatView()
                        ) {
                            Label {
                                Text("Body Fat (%)")
                            }icon: {
                                Image(systemName: "figure.arms.open")
                                    .foregroundStyle(.purple)
                            }
                        }

                    } // end Body measures section

                    Section(header: Text("Heart")) {
                        NavigationLink(
                            destination: HeartRateView()
                        ) {
                            Label {
                                Text("Heart Rate")
                            }icon: {
                                Image(systemName: "heart.fill")
                                    .foregroundStyle(.red)
                            }
                        }

                        NavigationLink(
                            destination: BloodPressureView()
                        ) {
                            Label {
                                Text("Blood Pressure")
                            }icon: {
                                Image(systemName: "stethoscope")
                                    // .foregroundStyle(.red)
                            }
                        }

                    }  // end heart section

                    Section(header: Text("Activity & Fitness")) {

                        NavigationLink(
                            destination: StepsView()
                        ) {
                            Label {
                                Text("Steps")
                            }icon: {
                                Image(systemName: "figure.walk")
                            }
                        }

                        NavigationLink(
                            destination: DistanceView()
                        ) {
                            Label {
                                Text("Distance")
                            }icon: {
                                Image(systemName: "speedometer")
                            }
                        }

                        NavigationLink(
                            destination: GenericView()
                        ) {
                            Label {
                                Text("Calories burned")
                            }icon: {
                                Image(systemName: "flame.fill")
                                    .foregroundStyle(.red)
                            }
                        }

                    } // end Activity & Fitness  section
                } // end Form

                                if !isPremiumUser {
                                    BannerContentView()
                                        .background(Color(UIColor.systemBackground))
                                        .frame(height: 60)
                                }

            }  // end Vstack
            .navigationTitle("Health To Go")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { settingsToolbarItem }
            .fullScreenCover(isPresented: $showingSettings) {
                PreferencesView()
            }
        } // end NavigationStack
    }  // end Body

    private var settingsToolbarItem: some ToolbarContent {
        ToolbarItem(placement: .navigationBarTrailing) {
            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 11, weight: .medium))
                //   .foregroundColor(primaryColor)
                    .padding(8) // Aggiungi padding
                    .background(
                        Circle() // Racchiudi in un cerchio
                            .fill(Color.secondary.opacity(0.15)) // Sfondo semi-trasparente
                    )
            }
        }
    }
}

#Preview {
    ContentView()
}
