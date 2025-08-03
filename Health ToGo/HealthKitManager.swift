import Foundation
import HealthKit

// Use a consistent calendar with the current timezone
private let calendar: Calendar = {
    var cal = Calendar.current
    cal.timeZone = TimeZone.current
    return cal
}()

// MARK: - HealthKit Manager

class HealthKitManager: ObservableObject {
    private let healthStore = HKHealthStore()

    // MARK: - Authorization

    func requestAuthorization(
        for types: [HKQuantityTypeIdentifier],
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(.failure(HealthKitError.notAvailable))
            return
        }

        let quantityTypes = types.compactMap { HKQuantityType.quantityType(forIdentifier: $0) }

        guard !quantityTypes.isEmpty else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }

        healthStore.requestAuthorization(toShare: nil, read: Set(quantityTypes)) { success, error in
            DispatchQueue.main.async {
                if success {
                    completion(.success(()))
                } else {
                    completion(.failure(error ?? HealthKitError.authorizationDenied))
                }
            }
        }
    }

    // MARK: - Data Fetching

    func fetchData(
        for type: HKQuantityTypeIdentifier,
        startDate: Date,
        endDate: Date,
        fetchAll: Bool = false,
        completion: @escaping (Result<[HealthDataPoint], Error>) -> Void
    ) {
        guard let quantityType = HKQuantityType.quantityType(forIdentifier: type) else {
            completion(.failure(HealthKitError.dataTypeNotAvailable))
            return
        }

        if fetchAll {
            fetchAllData(for: quantityType, completion: completion)
        } else {
            fetchDataInRange(
                for: quantityType,
                startDate: startDate,
                endDate: endDate,
                completion: completion
            )
        }
    }

    // MARK: - Private Methods

//    private func fetchDataInRange(
//        for quantityType: HKQuantityType,
//        startDate: Date,
//        endDate: Date,
//        completion: @escaping (Result<[HealthDataPoint], Error>) -> Void
//    ) {
//        let predicate = HKQuery.predicateForSamples(
//            withStart: startDate,
//            end: endDate,
//            options: .strictStartDate
//        )
//        
//        // Determine the appropriate statistics option based on data type
//        let statisticsOptions = getStatisticsOptions(for: quantityType)
//        
//        let query = HKStatisticsCollectionQuery(
//            quantityType: quantityType,
//            quantitySamplePredicate: predicate,
//            options: statisticsOptions,
//            anchorDate: startDate,
//            intervalComponents: DateComponents(day: 1)
//        )
//        
//        query.initialResultsHandler = { query, results, error in
//            DispatchQueue.main.async {
//                if let error = error {
//                    completion(.failure(error))
//                    return
//                }
//                
//                guard let results = results else {
//                    completion(.failure(HealthKitError.noResults))
//                    return
//                }
//                
//                let dataPoints = self.processStatisticsResults(results, statisticsOptions: statisticsOptions, startDate: startDate, endDate: endDate)
//                completion(.success(dataPoints))
//            }
//        }
//        
//        healthStore.execute(query)
//    }

    private func fetchDataInRange(
            for quantityType: HKQuantityType,
            startDate: Date,
            endDate: Date,
            completion: @escaping (Result<[HealthDataPoint], Error>) -> Void
        ) {
            // Fix 1: Ensure we're using the start of day in the current timezone
            let adjustedStartDate = calendar.startOfDay(for: startDate)
            let adjustedEndDate = calendar.date(bySettingHour: 23, minute: 59, second: 59, of: endDate) ?? endDate

            let predicate = HKQuery.predicateForSamples(
                withStart: adjustedStartDate,
                end: adjustedEndDate,
                options: .strictStartDate
            )

            // Determine the appropriate statistics option based on data type
            let statisticsOptions = getStatisticsOptions(for: quantityType)

            // Fix 2: Use calendar's timezone for interval components
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: statisticsOptions,
                anchorDate: adjustedStartDate,
                intervalComponents: DateComponents(day: 1)
            )

            query.initialResultsHandler = { _, results, error in
                DispatchQueue.main.async {
                    if let error = error {
                        completion(.failure(error))
                        return
                    }

                    guard let results = results else {
                        completion(.failure(HealthKitError.noResults))
                        return
                    }

                    let dataPoints = self.processStatisticsResults(
                        results,
                        statisticsOptions: statisticsOptions,
                        startDate: adjustedStartDate,
                        endDate: adjustedEndDate
                    )
                    completion(.success(dataPoints))
                }
            }

            healthStore.execute(query)
        }
    private func fetchAllData(
        for quantityType: HKQuantityType,
        completion: @escaping (Result<[HealthDataPoint], Error>) -> Void
    ) {
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: nil, options: .strictStartDate)

        let query = HKSampleQuery(
            sampleType: quantityType,
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
        ) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    completion(.failure(error))
                    return
                }

                guard let samples = samples as? [HKQuantitySample] else {
                    completion(.failure(HealthKitError.noDataAvailable))
                    return
                }

                let dataPoints = self.processRawSamples(samples)
                completion(.success(dataPoints))
            }
        }

        healthStore.execute(query)
    }

    // MARK: - Data Processing

//    private func processStatisticsResults(
//        _ results: HKStatisticsCollection,
//        statisticsOptions: HKStatisticsOptions,
//        startDate: Date,
//        endDate: Date
//    ) -> [HealthDataPoint] {
//        var dataPoints: [HealthDataPoint] = []
//        
//        results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
//            let value: Double
//            let unit = self.getUnit(for: statistics.quantityType) // Use correct unit
//            
//            // Use appropriate method based on statistics options
//            if statisticsOptions.contains(.cumulativeSum) {
//                value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
//            } else if statisticsOptions.contains(.discreteAverage) {
//                value = statistics.averageQuantity()?.doubleValue(for: unit) ?? 0
//            } else {
//                value = 0
//            }
//            
//            dataPoints.append(HealthDataPoint(date: statistics.startDate, value: value))
//        }
//        
//        return dataPoints
//    }
//    
//    private func processRawSamples(_ samples: [HKQuantitySample]) -> [HealthDataPoint] {
//        var dailyData: [Date: [Double]] = [:]
//        let calendar = Calendar.current
//        
//        for sample in samples {
//            let date = calendar.startOfDay(for: sample.startDate)
//            let value = sample.quantity.doubleValue(for: getUnit(for: sample.quantityType))
//            
//            if dailyData[date] == nil {
//                dailyData[date] = []
//            }
//            dailyData[date]?.append(value)
//        }
//        
//        // For discrete data (like heart rate), calculate daily average
//        // For cumulative data (like steps), sum the values
//        return dailyData.compactMap { (date, values) in
//            guard !values.isEmpty else { return nil }
//            
//            let finalValue: Double
//            if isCumulativeDataType(for: samples.first?.quantityType) {
//                finalValue = values.reduce(0, +) // Sum for cumulative data
//            } else {
//                finalValue = values.reduce(0, +) / Double(values.count) // Average for discrete data
//            }
//            
//            return HealthDataPoint(date: date, value: finalValue)
//        }
//        .sorted { $0.date < $1.date }
//    }

    private func processStatisticsResults(
            _ results: HKStatisticsCollection,
            statisticsOptions: HKStatisticsOptions,
            startDate: Date,
            endDate: Date
        ) -> [HealthDataPoint] {
            var dataPoints: [HealthDataPoint] = []

            results.enumerateStatistics(from: startDate, to: endDate) { statistics, _ in
                let value: Double
                let unit = self.getUnit(for: statistics.quantityType)

                // Use appropriate method based on statistics options
                if statisticsOptions.contains(.cumulativeSum) {
                    value = statistics.sumQuantity()?.doubleValue(for: unit) ?? 0
                } else if statisticsOptions.contains(.discreteAverage) {
                    value = statistics.averageQuantity()?.doubleValue(for: unit) ?? 0
                } else {
                    value = 0
                }

                // Fix 3: Use the start of day in current timezone for consistency
                let normalizedDate = calendar.startOfDay(for: statistics.startDate)
                dataPoints.append(HealthDataPoint(date: normalizedDate, value: value))
            }

            return dataPoints
        }

        private func processRawSamples(_ samples: [HKQuantitySample]) -> [HealthDataPoint] {
            var dailyData: [Date: [Double]] = [:]

            for sample in samples {
                // Fix 4: Normalize the date to start of day in current timezone
                let normalizedDate = calendar.startOfDay(for: sample.startDate)
                let value = sample.quantity.doubleValue(for: getUnit(for: sample.quantityType))

                if dailyData[normalizedDate] == nil {
                    dailyData[normalizedDate] = []
                }
                dailyData[normalizedDate]?.append(value)
            }

            // For discrete data (like heart rate), calculate daily average
            // For cumulative data (like steps), sum the values
            return dailyData.compactMap { (date, values) in
                guard !values.isEmpty else { return nil }

                let finalValue: Double
                if isCumulativeDataType(for: samples.first?.quantityType) {
                    finalValue = values.reduce(0, +) // Sum for cumulative data
                } else {
                    finalValue = values.reduce(0, +) / Double(values.count) // Average for discrete data
                }

                return HealthDataPoint(date: date, value: finalValue)
            }
            .sorted { $0.date < $1.date }
        }

    // MARK: - Helper Methods

    private func getStatisticsOptions(for quantityType: HKQuantityType) -> HKStatisticsOptions {
        switch quantityType.identifier {
        // Cumulative data types
        case HKQuantityTypeIdentifier.stepCount.rawValue,
             HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
             HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
             HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
             HKQuantityTypeIdentifier.flightsClimbed.rawValue:
            return .cumulativeSum

        // Discrete data types (use average)
        case HKQuantityTypeIdentifier.heartRate.rawValue,
             HKQuantityTypeIdentifier.bodyMass.rawValue,
             HKQuantityTypeIdentifier.height.rawValue,
             HKQuantityTypeIdentifier.bodyMassIndex.rawValue,
             HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
            return .discreteAverage

        default:
            return .discreteAverage
        }
    }

    static func isCumulativeDataType(for identifier: HKQuantityTypeIdentifier) -> Bool {
        let cumulativeTypes: [HKQuantityTypeIdentifier] = [
            .stepCount,
            .distanceWalkingRunning,
            .activeEnergyBurned,
            .basalEnergyBurned,
            .flightsClimbed
        ]

        return cumulativeTypes.contains(identifier)
    }

    private func getUnit(for quantityType: HKQuantityType) -> HKUnit {
        switch quantityType.identifier {
        case HKQuantityTypeIdentifier.bodyMass.rawValue:
            return HKUnit.gramUnit(with: .kilo) // ✅ Show kilograms with decimal precision

        case HKQuantityTypeIdentifier.stepCount.rawValue,
             HKQuantityTypeIdentifier.flightsClimbed.rawValue:
            return HKUnit.count()

        case HKQuantityTypeIdentifier.heartRate.rawValue:
            return HKUnit(from: "count/min")

        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
            return HKUnit.mile() // or meter for metric

        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
             HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
            return HKUnit.kilocalorie()

        case HKQuantityTypeIdentifier.height.rawValue:
            return HKUnit.meter()

        case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
            return HKUnit.millimeterOfMercury()

        default:
            return HKUnit.count()
        }
    }

//    private func getUnit(for quantityType: HKQuantityType) -> HKUnit {
//        switch quantityType.identifier {
//        case HKQuantityTypeIdentifier.stepCount.rawValue,
//             HKQuantityTypeIdentifier.flightsClimbed.rawValue:
//            return HKUnit.count()
//            
//        case HKQuantityTypeIdentifier.heartRate.rawValue:
//            return HKUnit(from: "count/min") // BPM
//            
//        case HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue:
//            return HKUnit.mile() // or HKUnit.meter() for metric
//            
//        case HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
//             HKQuantityTypeIdentifier.basalEnergyBurned.rawValue:
//            return HKUnit.kilocalorie()
//            
//        case HKQuantityTypeIdentifier.bodyMass.rawValue:
//            // return HKUnit.pound() // or HKUnit.gramUnit(with: .kilo) for metric
//            return HKUnit.gramUnit(with: .kilo)
//            
//        case HKQuantityTypeIdentifier.height.rawValue:
//            return HKUnit.inch() // or HKUnit.meter() for metric
//            
//        case HKQuantityTypeIdentifier.bloodPressureSystolic.rawValue,
//             HKQuantityTypeIdentifier.bloodPressureDiastolic.rawValue:
//            return HKUnit.millimeterOfMercury()
//            
//        default:
//            return HKUnit.count()
//        }
//    }

    private func isCumulativeDataType(for quantityType: HKQuantityType?) -> Bool {
        guard let quantityType = quantityType else { return false }

        let cumulativeTypes: [String] = [
            HKQuantityTypeIdentifier.stepCount.rawValue,
            HKQuantityTypeIdentifier.distanceWalkingRunning.rawValue,
            HKQuantityTypeIdentifier.activeEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.basalEnergyBurned.rawValue,
            HKQuantityTypeIdentifier.flightsClimbed.rawValue
        ]

        return cumulativeTypes.contains(quantityType.identifier)
    }
}

// MARK: - HealthKit Errors

enum HealthKitError: LocalizedError {
    case notAvailable
    case dataTypeNotAvailable
    case authorizationDenied
    case noResults
    case noDataAvailable

    var errorDescription: String? {
        switch self {
        case .notAvailable:
            return "HealthKit not available on this device"
        case .dataTypeNotAvailable:
            return "Data type not available"
        case .authorizationDenied:
            return "Authorization denied"
        case .noResults:
            return "No results returned"
        case .noDataAvailable:
            return "No data available"
        }
    }
}
