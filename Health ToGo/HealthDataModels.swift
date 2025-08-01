import Foundation

// MARK: - Data Models

struct HealthDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
    
    init(date: Date, value: Double) {
        self.date = date
        self.value = Int(value.rounded())
    }
}

// MARK: - Health Data Summary

struct HealthDataSummary {
    let totalValue: Int?  // Optional - nil for discrete data
    let averageDailyValue: Int
    let activeDays: Int
    let dateRange: String
    let minValue: Int?    // For discrete data
    let maxValue: Int?    // For discrete data
    let isCumulative: Bool
    
    init(data: [HealthDataPoint], startDate: Date, endDate: Date, fetchAllData: Bool, isCumulative: Bool) {
        self.isCumulative = isCumulative
        
        let activeDays = data.filter { $0.value > 0 }
        self.activeDays = activeDays.count
        
        if isCumulative {
            // For cumulative data (steps, distance, calories)
            self.totalValue = data.reduce(0) { $0 + $1.value }
            self.minValue = nil
            self.maxValue = nil
            
            if !activeDays.isEmpty {
                let total = activeDays.reduce(0) { $0 + $1.value }
                self.averageDailyValue = Int((Double(total) / Double(activeDays.count)).rounded())
            } else {
                self.averageDailyValue = 0
            }
        } else {
            // For discrete data (heart rate, weight, blood pressure)
            self.totalValue = nil
            
            if !activeDays.isEmpty {
                let values = activeDays.map { $0.value }
                self.minValue = values.min()
                self.maxValue = values.max()
                
                let total = activeDays.reduce(0) { $0 + $1.value }
                self.averageDailyValue = Int((Double(total) / Double(activeDays.count)).rounded())
            } else {
                self.minValue = nil
                self.maxValue = nil
                self.averageDailyValue = 0
            }
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
