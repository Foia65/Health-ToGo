import SwiftUI
import HealthKit

struct HeartRateView: View {
    // State variables - identical structure to StepsView
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
    // invece di usare Date() che spesso riporta zero, puntiamo alle 23:59 di ieri
    @State private var endDate: Date = {
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!
    }()
    
    @State private var heartRateData: [HealthDataPoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fetchAllData = false
    
    // HealthKit manager - same instance
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    // Titolo
                    Section {
                            Text("❤️ Heart Rate")
                                .font(.largeTitle.bold())
                                .padding(.bottom, 8)
                        }
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    
                    // Date Controls Section - exactly the same component
                    DateControlsView(
                        fetchAllData: $fetchAllData,
                        startDate: $startDate,
                        endDate: $endDate,
                        onDateChange: fetchHeartRateData
                    )
                    
                    // Summary Section - same component, different labels
                    if !heartRateData.isEmpty {
                        Section(header: Text("Summary")) {
                            HealthSummaryView(
                                summary: healthDataSummary,
                                dataType: "Heart Rate",
                                unit: "BPM"
                            )
                        }
                    }
                    
                    // Export Section - same component, different data type
                    Section(header: Text("Export")) {
                        Button(action: exportCSV) {
                            Label("Export as CSV", systemImage: "doc.text")
                        }
                        .buttonStyle(.bordered)
                    }
                    
                    // Detailed Data Section - same component, different labels
                    Section(header: Text("Daily Heart Rate Data")) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                        } else if heartRateData.isEmpty {
                            Text("No heart rate data available")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(heartRateData) { dataPoint in
                                DailyHealthDataView(
                                    dataPoint: dataPoint,
                                    dataType: "Heart Rate",
                                    unit: "BPM"
                                )
                            }
                        }
                    }
                }
                .blur(radius: isLoading ? 2 : 0)
                .disabled(isLoading)
               // .navigationTitle("❤️ Heart Rate Analytics")  // Different title and emoji
                .refreshable {
                    fetchHeartRateData()
                }
                .onAppear {
                    requestHealthKitAuthorization()
                }
                
                // Loading overlay - same component, different message
                if isLoading {
                    LoadingOverlayView(message: "Fetching heart rate data...")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var healthDataSummary: HealthDataSummary {
        HealthDataSummary(
            data: heartRateData,
            startDate: startDate,
            endDate: endDate,
            fetchAllData: fetchAllData,
            isCumulative: false  // Heart rate is not cumulative
        )
    }
    
    // MARK: - Methods
    
    private func requestHealthKitAuthorization() {
        // Only change: different HKQuantityTypeIdentifier
        healthKitManager.requestAuthorization(for: [.heartRate]) { result in
            switch result {
            case .success:
                fetchHeartRateData()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func fetchHeartRateData() {
        guard !isLoading else { return }
        
        isLoading = true
        errorMessage = nil
        heartRateData = []  // Different variable name
        
        // Only change: different HKQuantityTypeIdentifier
        healthKitManager.fetchData(
            for: .heartRate,
            startDate: startDate,
            endDate: endDate,
            fetchAll: fetchAllData
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let data):
                heartRateData = data  // Different variable name
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func exportCSV() {
        CSVExporter.exportHealthData(
            data: heartRateData,  // Different data source
            startDate: startDate,
            endDate: endDate,
            dataType: "HeartRate"  // Different data type name
        ) { error in
            errorMessage = error
        }
    }
}

// MARK: - Preview

struct HeartRateView_Previews: PreviewProvider {
    static var previews: some View {
        HeartRateView()
    }
}
