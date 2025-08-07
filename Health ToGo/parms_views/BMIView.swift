import SwiftUI
import HealthKit

struct BMIView: View {
    // This reads as "get the date 7 days ago, or if that fails for any reason, use today's date."
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()

    @State private var endDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) ?? today
    }()

    @State private var BMIData: [HealthDataPoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fetchAllData = false
    @State private var showPremiumAlert = false
    @State private var premiumAlertType: PremiumAlertType = .csvExport
    @State private var showPremiumInfo = false

    @AppStorage("isPremiumUser") private var isPremiumUser = false

    // HealthKit manager
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
                                    .foregroundStyle(.green)
                                Text("Body Mass Index")
                                    .font(.largeTitle.bold())
                                    .padding(.bottom, 8)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        
                        // Date Controls Section
                        DateControlsView(
                            fetchAllData: $fetchAllData,
                            startDate: $startDate,
                            endDate: $endDate,
                            isPremiumUser: $isPremiumUser,
                            onDateChange: fetchBMIData,
                            onFetchAllDataToggle: handleFetchAllDataToggle
                        )
                        
                        // Summary Section
                        if !BMIData.isEmpty {
                            Section(header: Text("Summary")) {
                                HealthSummaryView(
                                    summary: healthDataSummary,
                                    dataType: "BMI",
                                    unit: ""
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
                        Section(header: Text("Daily BMI Data")) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else if let error = errorMessage {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                            } else if BMIData.isEmpty {
                                Text("No BMI data available")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(BMIData) { dataPoint in
                                    DailyHealthDataView(
                                        dataPoint: dataPoint,
                                        dataType: "BMI",
                                        unit: ""
                                    )
                                }
                            }
                        }
                    }
                    .blur(radius: isLoading ? 2 : 0)
                    .disabled(isLoading)
                    .refreshable {
                        fetchBMIData()
                    }
                    .onAppear {
                        requestHealthKitAuthorization()
                    }
                    .alert("Premium Feature Required", isPresented: $showPremiumAlert) {
                        Button("Upgrade to Premium") {
                            showPremiumInfo = true
                        }
                        Button("Cancel", role: .cancel) {
                            // Reset the toggle if user cancels fetch all data
                            if premiumAlertType == .allData {
                                fetchAllData = false
                            }
                        }
                    } message: {
                        Text(premiumAlertMessage)
                    }
                    
                    // Loading overlay
                    if isLoading {
                        LoadingOverlayView(message: "Fetching BMI data...")
                    }
                }
                
                if !isPremiumUser {
                    BannerContentView()
                        .background(Color(UIColor.systemBackground))
                        .frame(height: 60)
                }
            }
        }
        .sheet(isPresented: $showPremiumInfo) {
                   PremiumInfo()
               }
    }

    // MARK: - Computed Properties

    private var healthDataSummary: HealthDataSummary {
        HealthDataSummary(
            data: BMIData,
            startDate: startDate,
            endDate: endDate,
            fetchAllData: fetchAllData,
            isCumulative: false  // BMI is not cumulative
        )
    }

    private var premiumAlertMessage: String {
         switch premiumAlertType {
         case .csvExport:
             return "CSV export is only available for premium users. Upgrade to access this feature and export your health data."
         case .allData:
             return "Fetching all historical data is only available for premium users. Upgrade to access your complete health history."
         }
     }
    
    // MARK: - Methods

    private func requestHealthKitAuthorization() {
        // Only change: different HKQuantityTypeIdentifier
        healthKitManager.requestAuthorization(for: [.bodyMassIndex]) { result in
            switch result {
            case .success:
                fetchBMIData()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchBMIData() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        BMIData = []  // Different variable name

        // Only change: different HKQuantityTypeIdentifier
        healthKitManager.fetchData(
            for: .bodyMassIndex,
            startDate: startDate,
            endDate: endDate,
            fetchAll: fetchAllData
        ) { result in
            isLoading = false

            switch result {
            case .success(let data):
                // Filter out days with no  measurement (value = 0)
                BMIData = data.filter { $0.value > 0 }
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportCSV() {
        guard isPremiumUser else {
              premiumAlertType = .csvExport
              showPremiumAlert = true
              return
          }
        CSVExporter.exportHealthData(
            data: BMIData,  // Different data source
            startDate: startDate,
            endDate: endDate,
            dataType: "BMI"  // Different data type name
        ) { error in
            errorMessage = error
        }
    }

    private func handleFetchAllDataToggle() {
        // For non-premium users trying to enable fetch all data
        if !isPremiumUser {
            premiumAlertType = .allData
            showPremiumAlert = true
        } else {
            // Premium user - proceed with data fetch
            fetchBMIData()
        }
    }
}

struct BMIView_Previews: PreviewProvider {
    static var previews: some View {
        BMIView()
    }
}
