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
                    Text("Total \(dataType): \(formattedValue(total, for: dataType)) \(unit)")
                        .font(.headline)
                }
                Text("Average Daily \(dataType): \(formattedValue(summary.averageDailyValue, for: dataType)) \(unit)")
            } else {
                // Show range and average for discrete data (heart rate, weight)
                Text("Average \(dataType): \(formattedValue(summary.averageDailyValue, for: dataType)) \(unit)")
                    .font(.headline)

                if let min = summary.minValue, let max = summary.maxValue {
                    Text("Range: \(formattedValue(min, for: dataType)) - \(formattedValue(max, for: dataType)) \(unit)")
                }
            }

            Text("Days with Data: \(summary.activeDays.formatted())")
            Text("Date Range: \(summary.dateRange)")
        }
    }

    // Format value based on data type - 1 decimal for weight, thousands separator for steps
    private func formattedValue(_ value: Double, for dataType: String) -> String {
        if dataType == "Weight" {
            return String(format: "%.1f", value)
        } else {
            // Use thousands separator for steps and other count-based data
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        }
    }
}

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
            // Use thousands separator for steps and other count-based data
            let formatter = NumberFormatter()
            formatter.numberStyle = .decimal
            formatter.maximumFractionDigits = 0
            return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.0f", value)
        }
    }
}

// MARK: - Reusable Date Controls View

import SwiftUI

// MARK: - Reusable Date Controls View

struct DateControlsView: View {
    @Binding var fetchAllData: Bool
    @Binding var startDate: Date
    @Binding var endDate: Date
    @Binding var isPremiumUser: Bool
    let onDateChange: () -> Void
    let onFetchAllDataToggle: () -> Void

    var body: some View {
        Section(header: Text("Settings")) {
            HStack {
                Toggle("Fetch All Historical Data", isOn: Binding(
                    get: { fetchAllData },
                    set: { newValue in
                        // Check premium status BEFORE changing the toggle
                        if newValue && !isPremiumUser {
                            // Don't change the toggle state, just show the alert
                            onFetchAllDataToggle()
                        } else {
                            // Premium user or turning off - proceed normally
                            fetchAllData = newValue
                            if fetchAllData {
                                startDate = Date.distantPast
                                endDate = Date()
                            } else {
                                startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
                                let calendar = Calendar.current
                                let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
                                endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? Date()
                            }
                            onDateChange()
                        }
                    }
                ))

                // Add the crown icon for premium feature
                if !isPremiumUser {
                    Image(systemName: "crown.fill")
                        .foregroundColor(.orange)
                        .font(.caption)
                }
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

//struct DateControlsView: View {
//    @Binding var fetchAllData: Bool
//    @Binding var startDate: Date
//    @Binding var endDate: Date
//    @Binding var isPremiumUser: Bool // Add this binding
//    let onDateChange: () -> Void
//    let onFetchAllDataToggle: () -> Void // New callback for premium check
//
//    var body: some View {
//            Section(header: Text("Settings")) {
//                HStack {
//                    Toggle("Fetch All Historical Data", isOn: $fetchAllData)
//                        .onChange(of: fetchAllData) {
//                            if fetchAllData {
//                                startDate = Date.distantPast
//                                endDate = Date()
//                            } else {
//                                startDate = Calendar.current.date(byAdding: .day, value: -7, to: Date())!
//                                let calendar = Calendar.current
//                                let yesterday = calendar.date(byAdding: .day, value: -1, to: Date())!
//                                endDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: yesterday) ?? Date()
//                            }
//                            onFetchAllDataToggle()
//                        }
//
//                    // Add the crown icon for premium feature
//                    if !isPremiumUser {
//                        Image(systemName: "crown.fill")
//                            .foregroundColor(.orange)
//                            .font(.caption)
//                    }
//                }
//
//                if !fetchAllData {
//                    DatePicker("Start Date",
//                               selection: $startDate,
//                               in: ...endDate,
//                               displayedComponents: .date)
//                    .onChange(of: startDate) { onDateChange() }
//
//                    DatePicker("End Date",
//                               selection: $endDate,
//                               in: startDate...Date(),
//                               displayedComponents: .date)
//                    .onChange(of: endDate) { onDateChange() }
//                }
//            }
//        }
//    }
//    
