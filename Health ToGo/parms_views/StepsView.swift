import SwiftUI
import HealthKit

struct StepsView: View {
    // State variables
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())! // 1 week ago
    @State private var endDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) ?? today
    }()
    
    @State private var stepData: [HealthDataPoint] = [] // qui vengono salvati i dati estratti
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fetchAllData = false
    @State private var showPremiumAlert = false
    

    @AppStorage("isPremiumUser") private var isPremiumUser = false
    
    @StateObject private var healthKitManager = HealthKitManager()
    
    var body: some View {
        NavigationStack {
            ZStack {
                List {
                    // Titolo
                    Section {
                            Text("🚶Steps")
                                .font(.largeTitle.bold())
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
                        onDateChange: fetchStepData
                    )
                    
                    // Summary Section
                    if !stepData.isEmpty {
                        Section(header: Text("Summary")) {
                            HealthSummaryView(
                                summary: healthDataSummary,
                                dataType: "Steps",
                                unit: "steps"
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
                    Section(header: Text("Daily Step Data")) {
                        if isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if let error = errorMessage {
                            Text("Error: \(error)")
                                .foregroundColor(.red)
                        } else if stepData.isEmpty {
                            Text("No step data available")
                                .foregroundColor(.secondary)
                        } else {
                            ForEach(stepData) { dataPoint in
                                DailyHealthDataView(
                                    dataPoint: dataPoint,
                                    dataType: "Steps",
                                    unit: "steps"
                                )
                            }
                        }
                    }
                }
                .blur(radius: isLoading ? 2 : 0)
                .disabled(isLoading)
                // .navigationTitle("🚶Steps Analytics")
                .refreshable {
                    fetchStepData()
                }
                .onAppear {
                    requestHealthKitAuthorization()
                }
                
                // Loading overlay
                if isLoading {
                    LoadingOverlayView(message: "Fetching step data...")
                }
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var healthDataSummary: HealthDataSummary {
        HealthDataSummary(
            data: stepData,
            startDate: startDate,
            endDate: endDate,
            fetchAllData: fetchAllData,
            isCumulative: true  // Steps are cumulative
        )
    }
    
    // MARK: - Methods
    private func requestHealthKitAuthorization() {
        healthKitManager.requestAuthorization(for: [.stepCount]) { result in
            switch result {
            case .success:
                fetchStepData()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func fetchStepData() {
        guard !isLoading else { return }
        isLoading = true
        errorMessage = nil
        stepData = []  // svuota l'array con gli step
        
        healthKitManager.fetchData(
            for: .stepCount,
            startDate: startDate,
            endDate: endDate,
            fetchAll: fetchAllData
        ) { result in
            isLoading = false
            
            switch result {
            case .success(let data):
                stepData = data
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }
    
    private func exportCSV() {
        CSVExporter.exportHealthData(
            data: stepData,
            startDate: startDate,
            endDate: endDate,
            dataType: "Steps"
        ) { error in
            errorMessage = error
        }
    }
}

// MARK: - Preview

struct StepsView_Previews: PreviewProvider {
    static var previews: some View {
        StepsView()
    }
}
