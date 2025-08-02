import SwiftUI
import HealthKit

struct WeightView: View {
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!

    @State private var endDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) ?? today
    }()
    
    @State private var massData: [HealthDataPoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fetchAllData = false
    @State private var showPremiumAlert = false
    @State private var showPremiumInfo = false

    @AppStorage("isPremiumUser") private var isPremiumUser = false

    // HealthKit manager - same instance
    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    List {
                        // Titolo
                        Section {
                            HStack {
                                Image(systemName: "figure.arms.open")
                                    .font(.largeTitle.bold())
                                    .foregroundStyle(.blue)
                                Text("Weight")
                                    .font(.largeTitle.bold())
                            }
                            .padding(.bottom, 8)

                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)

                        // Date Controls Section 
                        DateControlsView(
                            fetchAllData: $fetchAllData,
                            startDate: $startDate,
                            endDate: $endDate,
                            isPremiumUser: $isPremiumUser,
                            onDateChange: fetchMassData,
                        )

                        // Summary Section
                        if !massData.isEmpty {
                            Section(header: Text("Summary")) {
                                HealthSummaryView(
                                    summary: healthDataSummary,
                                    dataType: "Weight",
                                    unit: "Kg",
                                )
                            }
                        }

                        // Export Section
                        Section(header: Text("Export")) {
                            Button(action: exportCSV) {
                                Label("Export as CSV", systemImage: "doc.text")
                                if !isPremiumUser {
                                    Spacer()
                                    Image(systemName: "crown.fill")
                                        .foregroundColor(.orange)
                                        .font(.caption)
                                }
                            }
                            .buttonStyle(.bordered)
                        }

                        // Detailed Data Section
                        Section(header: Text("Daily Weight Data")) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else if let error = errorMessage {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                            } else if massData.isEmpty {
                                Text("No weight data available")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(massData) { dataPoint in
                                    DailyHealthDataView(
                                        dataPoint: dataPoint,
                                        dataType: "Weight",
                                        unit: "Kg",
                                    )
                                }
                            }
                        }
                    }
                    .blur(radius: isLoading ? 2 : 0)
                    .disabled(isLoading)
                    .refreshable {
                        fetchMassData()
                    }
                    .onAppear {
                        requestHealthKitAuthorization()
                    }
//                    .alert("Premium Feature Required", isPresented: $showPremiumAlert) {
//                        Button("Upgrade to Premium") {
//                            showPremiumInfo = true
//                        }
//                        Button("Cancel", role: .cancel) { }
//                    } message: {
//                      Text(premiumAlertMessage)
//                    }

                    // Loading overlay - same component, different message
                    if isLoading {
                        LoadingOverlayView(message: "Fetching weight data...")
                    }
                }

//                if !isPremiumUser {
//                    BannerContentView()
//                        .background(Color(UIColor.systemBackground))
//                        .frame(height: 60)
//                }
            }
        }
    }

    // MARK: - Computed Properties

    private var healthDataSummary: HealthDataSummary {
        HealthDataSummary(
            data: massData,
            startDate: startDate,
            endDate: endDate,
            fetchAllData: fetchAllData,
            isCumulative: false  // Weight is not cumulative
        )
    }


    // MARK: - Methods

    private func requestHealthKitAuthorization() {
        // Only change: different HKQuantityTypeIdentifier
        healthKitManager.requestAuthorization(for: [.bodyMass]) { result in
            switch result {
            case .success:
                fetchMassData()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchMassData() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        massData = []  // Different variable name

        // Only change: different HKQuantityTypeIdentifier
        healthKitManager.fetchData(
            for: .bodyMass,
            startDate: startDate,
            endDate: endDate,
            fetchAll: fetchAllData
        ) { result in
            isLoading = false

            switch result {
            case .success(let data):
                // massData = data
                // Filter out days with no weight measurement (value = 0)
                    massData = data.filter { $0.value > 0 }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportCSV() {

        CSVExporter.exportHealthData(
            data: massData,
            startDate: startDate,
            endDate: endDate,
            dataType: "Weight"
        ) { error in
            errorMessage = error
        }
    }
}

// MARK: - Preview

struct WeightView_Previews: PreviewProvider {
    static var previews: some View {
        WeightView()
    }
}

