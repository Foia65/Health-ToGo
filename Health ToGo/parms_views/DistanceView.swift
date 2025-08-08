import SwiftUI
import HealthKit

struct DistanceView: View {
    // This reads as "get the date 7 days ago, or if that fails for any reason, use today's date."
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
    @State private var endDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) ?? today
    }()

    @State private var distanceData: [HealthDataPoint] = [] // qui vengono salvati i dati estratti
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fetchAllData = false
    @State private var showPremiumAlert = false
    @State private var premiumAlertType: PremiumAlertType = .csvExport
    @State private var showPremiumInfo = false
    
    @AppStorage("isPremiumUser") private var isPremiumUser = false

    @StateObject private var healthKitManager = HealthKitManager()

    var body: some View {
        NavigationStack {
            VStack {
                ZStack {
                    List {
                        // Titolo
                        Section {
                            HStack {
                                Image(systemName: "speedometer")
                                    .font(.largeTitle)
                                    .foregroundStyle(.blue)
                                Text("Walk/Run distance")
                                    .font(.title.bold())
                                 //   .padding(.bottom, 8)
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
                            onDateChange: fetchDistanceData, onFetchAllDataToggle: handleFetchAllDataToggle
                            
                        )
                        
                        // Summary Section
                        if !distanceData.isEmpty {
                            Section(header: Text("Summary")) {
                                HealthSummaryView(
                                    summary: healthDataSummary,
                                    dataType: "Distance",
                                    unit: "meters"
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
                            //   .opacity(isPremiumUser ? 1.0 : 0.6)
                        }
                        
                        // Detailed Data Section
                        Section(header: Text("Daily distance Data")) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else if let error = errorMessage {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                            } else if distanceData.isEmpty {
                                Text("No distance data available")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(distanceData) { dataPoint in
                                    DailyHealthDataView(
                                        dataPoint: dataPoint,
                                        dataType: "Distance",
                                        unit: "meters"
                                    )
                                }
                            }
                        }
                    }
                    .blur(radius: isLoading ? 2 : 0)
                    .disabled(isLoading)
                    .refreshable {
                        fetchDistanceData()
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
                        LoadingOverlayView(message: "Fetching distance data...")
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
            data: distanceData,
            startDate: startDate,
            endDate: endDate,
            fetchAllData: fetchAllData,
            isCumulative: true  // distance is cumulative
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
        healthKitManager.requestAuthorization(for: [.distanceWalkingRunning]) { result in
            switch result {
            case .success:
                fetchDistanceData()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchDistanceData() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        distanceData = []  // svuota l'array con i metri

        healthKitManager.fetchData(
            for: .distanceWalkingRunning,
            startDate: startDate,
            endDate: endDate,
            fetchAll: fetchAllData
        ) { result in
            isLoading = false

            switch result {
            case .success(let data):
                distanceData = data
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func exportCSV() {
        // Check if user is premium before allowing export
         guard isPremiumUser else {
             premiumAlertType = .csvExport
             showPremiumAlert = true
             return
         }
        
        CSVExporter.exportHealthData(
            data: distanceData,
            startDate: startDate,
            endDate: endDate,
            dataType: "Distance"
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
            fetchDistanceData()
        }
    }
}

// MARK: - Premium Alert Type Enum

// enum PremiumAlertType {
//     case csvExport
//     case allData
// }

// MARK: - Preview

struct DistanceView_Previews: PreviewProvider {
    static var previews: some View {
        DistanceView()
    }
}
