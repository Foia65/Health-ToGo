// La vista della pressione è diversa da tutte le altre
// perchè legge due serie di dati (systolid e diastolic)
// e poi le accoppia0

import SwiftUI
import HealthKit

struct BloodPressureView: View {
    // State variables
    @State private var startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())! // 1 week ago

    @State private var endDate: Date = {
        let calendar = Calendar.current
        let today = Date()
        return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: today) ?? today
    }()

    @State private var systolicData: [HealthDataPoint] = []
    @State private var diastolicData: [HealthDataPoint] = []
    @State private var combinedData: [BloodPressureDataPoint] = []
    @State private var isLoading = false
    @State private var errorMessage: String?
    @State private var fetchAllData = false
    @State private var premiumAlertType: PremiumAlertType = .csvExport
    @State private var showPremiumAlert = false
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
                            Text("🩺 Blood Pressure")
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
                            onDateChange: fetchBloodPressureData,
                            onFetchAllDataToggle: handleFetchAllDataToggle
                            
                        )
                        
                        // Summary Section
                        if !combinedData.isEmpty {
                            Section(header: Text("Summary")) {
                                BloodPressureSummaryView(
                                    combinedData: combinedData,
                                    startDate: startDate,
                                    endDate: endDate,
                                    fetchAllData: fetchAllData
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
                        Section(header: Text("Daily Blood Pressure Data")) {
                            if isLoading {
                                ProgressView()
                                    .frame(maxWidth: .infinity)
                            } else if let error = errorMessage {
                                Text("Error: \(error)")
                                    .foregroundColor(.red)
                            } else if combinedData.isEmpty {
                                Text("No blood pressure data available")
                                    .foregroundColor(.secondary)
                            } else {
                                ForEach(combinedData.filter { $0.hasData }) { dataPoint in
                                    BloodPressureDataView(dataPoint: dataPoint)
                                }
                            }
                        }
                    }
                    .blur(radius: isLoading ? 2 : 0)
                    .disabled(isLoading)
                    .refreshable {
                        fetchBloodPressureData()
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
        healthKitManager.requestAuthorization(for: [.bloodPressureSystolic, .bloodPressureDiastolic]) { result in
            switch result {
            case .success:
                fetchBloodPressureData()
            case .failure(let error):
                errorMessage = error.localizedDescription
            }
        }
    }

    private func fetchBloodPressureData() {
        guard !isLoading else { return }

        isLoading = true
        errorMessage = nil
        systolicData = []
        diastolicData = []
        combinedData = []

        let group = DispatchGroup()
        var systolicError: Error?
        var diastolicError: Error?

        // Fetch systolic data
        group.enter()
        healthKitManager.fetchData(
            for: .bloodPressureSystolic,
            startDate: startDate,
            endDate: endDate,
            fetchAll: fetchAllData
        ) { result in
            switch result {
            case .success(let data):
                systolicData = data
            case .failure(let error):
                systolicError = error
            }
            group.leave()
        }

        // Fetch diastolic data
        group.enter()
        healthKitManager.fetchData(
            for: .bloodPressureDiastolic,
            startDate: startDate,
            endDate: endDate,
            fetchAll: fetchAllData
        ) { result in
            switch result {
            case .success(let data):
                diastolicData = data
            case .failure(let error):
                diastolicError = error
            }
            group.leave()
        }

        // Combine the data when both are complete
        group.notify(queue: .main) {
            isLoading = false

            if let error = systolicError ?? diastolicError {
                errorMessage = error.localizedDescription
                return
            }

            combinedData = combineBloodPressureData(systolic: systolicData, diastolic: diastolicData)
        }
    }

    private func combineBloodPressureData(systolic: [HealthDataPoint], diastolic: [HealthDataPoint]) -> [BloodPressureDataPoint] {
        let calendar = Calendar.current
        var combinedDict: [Date: BloodPressureDataPoint] = [:]

        // Process systolic data
        for dataPoint in systolic {
            let dayStart = calendar.startOfDay(for: dataPoint.date)
            if combinedDict[dayStart] == nil {
                combinedDict[dayStart] = BloodPressureDataPoint(date: dayStart, systolic: nil, diastolic: nil)
            }
            combinedDict[dayStart]?.systolic = Int(dataPoint.value.rounded())
        }

        // Process diastolic data
        for dataPoint in diastolic {
            let dayStart = calendar.startOfDay(for: dataPoint.date)
            if combinedDict[dayStart] == nil {
                combinedDict[dayStart] = BloodPressureDataPoint(date: dayStart, systolic: nil, diastolic: nil)
            }
            combinedDict[dayStart]?.diastolic = Int(dataPoint.value.rounded())
        }

        // Convert to array and sort by date
        return combinedDict.values.sorted { $0.date < $1.date }
    }

    private func exportCSV() {
        // Check if user is premium before allowing export
         guard isPremiumUser else {
             premiumAlertType = .csvExport
             showPremiumAlert = true
             return
         }
        BloodPressureCSVExporter.exportBloodPressureData(
            data: combinedData,
            startDate: startDate,
            endDate: endDate
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
                fetchBloodPressureData()
            }
        }
    
}

// MARK: - Blood Pressure Data Models

struct BloodPressureDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    var systolic: Int?
    var diastolic: Int?

    var hasData: Bool {
        return (systolic != nil && systolic! > 0) || (diastolic != nil && diastolic! > 0)
    }

    var formattedReading: String {
        switch (systolic, diastolic) {
        case (let sys?, let dia?) where sys > 0 && dia > 0:
            return "\(sys)/\(dia)"
        case (let sys?, _) where sys > 0:
            return "\(sys)/??"
        case (_, let dia?) where dia > 0:
            return "??/\(dia)"
        default:
            return "No data"
        }
    }

}

// MARK: - Blood Pressure Summary View

struct BloodPressureSummaryView: View {
    let combinedData: [BloodPressureDataPoint]
    let startDate: Date
    let endDate: Date
    let fetchAllData: Bool

    private var summary: BloodPressureSummary {
        BloodPressureSummary(
            data: combinedData,
            startDate: startDate,
            endDate: endDate,
            fetchAllData: fetchAllData
        )
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let avgSys = summary.averageSystolic, let avgDia = summary.averageDiastolic {
                Text("Average: \(avgSys)/\(avgDia) mmHg")
                    .font(.headline)
            }

            if let minSys = summary.minSystolic, let maxSys = summary.maxSystolic,
               let minDia = summary.minDiastolic, let maxDia = summary.maxDiastolic {
                Text("Systolic Range: \(minSys) - \(maxSys) mmHg")
                Text("Diastolic Range: \(minDia) - \(maxDia) mmHg")
            }

            Text("Readings: \(summary.totalReadings)")
            Text("Date Range: \(summary.dateRange)")
        }
    }

}

// MARK: - Blood Pressure Summary Data

struct BloodPressureSummary {
    let averageSystolic: Int?
    let averageDiastolic: Int?
    let minSystolic: Int?
    let maxSystolic: Int?
    let minDiastolic: Int?
    let maxDiastolic: Int?
    let totalReadings: Int
    let dateRange: String

    init(data: [BloodPressureDataPoint], startDate: Date, endDate: Date, fetchAllData: Bool) {
        let validReadings = data.filter { $0.hasData }
        self.totalReadings = validReadings.count

        let systolicValues = validReadings.compactMap { $0.systolic }
        let diastolicValues = validReadings.compactMap { $0.diastolic }

        if !systolicValues.isEmpty {
            self.averageSystolic = Int(Double(systolicValues.reduce(0, +)) / Double(systolicValues.count))
            self.minSystolic = systolicValues.min()
            self.maxSystolic = systolicValues.max()
        } else {
            self.averageSystolic = nil
            self.minSystolic = nil
            self.maxSystolic = nil
        }

        if !diastolicValues.isEmpty {
            self.averageDiastolic = Int(Double(diastolicValues.reduce(0, +)) / Double(diastolicValues.count))
            self.minDiastolic = diastolicValues.min()
            self.maxDiastolic = diastolicValues.max()
        } else {
            self.averageDiastolic = nil
            self.minDiastolic = nil
            self.maxDiastolic = nil
        }

        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none

        if fetchAllData {
            self.dateRange = "All available data"
        } else {
            self.dateRange = "\(formatter.string(from: startDate)) to \(formatter.string(from: endDate))"
        }
    }
}

// MARK: - Blood Pressure Data Row View

struct BloodPressureDataView: View {
    let dataPoint: BloodPressureDataPoint

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dataPoint.date, style: .date)
                .font(.headline)

            HStack {
                Text(dataPoint.formattedReading)
                    .font(.title3)
                    .fontWeight(.medium)

                Spacer()

                if !dataPoint.hasData {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Blood Pressure CSV Exporter

class BloodPressureCSVExporter {

    static func exportBloodPressureData(
        data: [BloodPressureDataPoint],
        startDate: Date,
        endDate: Date,
        onError: @escaping (String) -> Void
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        let filename = "BloodPressure_\(dateFormatter.string(from: startDate))_to_\(dateFormatter.string(from: endDate)).csv"

        var csvString = "Date,Systolic,Diastolic\n"

        let rowDateFormatter = DateFormatter()
        rowDateFormatter.dateFormat = "yyyy-MM-dd"

        for dataPoint in data.filter({ $0.hasData }) {
            let dateString = rowDateFormatter.string(from: dataPoint.date)
            let systolic = dataPoint.systolic?.description ?? ""
            let diastolic = dataPoint.diastolic?.description ?? ""
            csvString += "\(dateString),\(systolic),\(diastolic)\n"
        }

        saveAndShare(data: csvString, filename: filename, onError: onError)
    }

    private static func saveAndShare(
        data: String,
        filename: String,
        onError: @escaping (String) -> Void
    ) {
        let tempDir = FileManager.default.temporaryDirectory
        let fileURL = tempDir.appendingPathComponent(filename)

        do {
            try data.write(to: fileURL, atomically: true, encoding: .utf8)

            let activityVC = UIActivityViewController(
                activityItems: [fileURL],
                applicationActivities: nil
            )

            // For iPad support
            if let popover = activityVC.popoverPresentationController {
                popover.sourceView = UIApplication.shared.connectedScenes
                    .compactMap { $0 as? UIWindowScene }
                    .flatMap { $0.windows }
                    .first(where: { $0.isKeyWindow })?.rootViewController?.view
                popover.sourceRect = CGRect(
                    x: UIScreen.main.bounds.width/2,
                    y: UIScreen.main.bounds.height,
                    width: 0,
                    height: 0
                )
            }

            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap { $0.windows }
                .first(where: { $0.isKeyWindow })?
                .rootViewController?
                .present(
                    activityVC,
                    animated: true
                )
        } catch {
            onError("Export failed: \(error.localizedDescription)")
        }
    }
}

// MARK: - Preview

struct BloodPressureView_Previews: PreviewProvider {
    static var previews: some View {
        BloodPressureView()
    }
}
