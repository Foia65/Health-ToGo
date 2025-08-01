import SwiftUI

// MARK: - Reusable Health Summary View

struct HealthSummaryView: View {
    let summary: HealthDataSummary
    let dataType: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if summary.isCumulative {
                // Show total for cumulative data (steps, distance, calories)
                if let total = summary.totalValue {
                    Text("Total \(dataType): \(total.formatted()) \(unit)")
                        .font(.headline)
                }
                Text("Average Daily \(dataType): \(summary.averageDailyValue.formatted()) \(unit)")
            } else {
                // Show range and average for discrete data (heart rate, weight)
                Text("Average \(dataType): \(summary.averageDailyValue.formatted()) \(unit)")
                    .font(.headline)
                
                if let min = summary.minValue, let max = summary.maxValue {
                    Text("Range: \(min.formatted()) - \(max.formatted()) \(unit)")
                }
            }
            
            Text("Days with Data: \(summary.activeDays.formatted())")
            Text("Date Range: \(summary.dateRange)")
        }
    }
}

// MARK: - Reusable Daily Health Data View

import SwiftUI

// MARK: - Reusable Daily Health Data View

struct DailyHealthDataView: View {
    let dataPoint: HealthDataPoint
    let dataType: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(dataPoint.date, style: .date)
                .font(.headline)

            HStack {
                Text("\(formattedValue(for: Double(dataPoint.value))) \(unit)")
                Spacer()
                if dataPoint.value == 0 {
                    Image(systemName: "xmark.circle")
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(.vertical, 4)
    }

    // Format value with 1 decimal point only for weight
    private func formattedValue(for value: Double) -> String {
        if dataType == "Weight" {
            return String(format: "%.1f", value)
        } else {
            return String(format: "%.0f", value)  // No decimals for steps, etc.
        }
    }

}


// MARK: - Reusable Date Controls View

struct DateControlsView: View {
    @Binding var fetchAllData: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    let onDateChange: () -> Void
    
    var body: some View {
        Section(header: Text("Settings")) {
            Toggle("Fetch All Historical Data", isOn: $fetchAllData)
                .onChange(of: fetchAllData) {
                    if fetchAllData {
                        startDate = Date.distantPast
                        endDate = Date()
                    } else {
                        startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                        // invece di usare semplicement Date() che spesso riporta zero dati, puntiamo alle 23:59 di ieri
                        endDate = {
                            let calendar = Calendar.current
                            let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
                            return calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday)!
                        }()
                    }
                    onDateChange()
                }
            
            if !fetchAllData {
                DatePicker("Start Date",
                           selection: $startDate,
                           in: ...endDate,
                           displayedComponents: .date)
                .onChange(of: startDate) { onDateChange() }
                
                DatePicker("End Date",
                           selection: $endDate,
                           in: startDate...Date(),
                           displayedComponents: .date)
                .onChange(of: endDate) { onDateChange() }
            }
        }
    }
}
