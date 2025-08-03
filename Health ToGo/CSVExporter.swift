import Foundation
import UIKit

// MARK: - CSV Exporter

class CSVExporter {

    static func exportHealthData(
        data: [HealthDataPoint],
        startDate: Date,
        endDate: Date,
        dataType: String = "Steps",
        onError: @escaping (String) -> Void
    ) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyyMMdd"

        let filename = "\(dataType)_\(dateFormatter.string(from: startDate))_to_\(dateFormatter.string(from: endDate)).csv"

        var csvString = "Date,\(dataType)\n"

        let rowDateFormatter = DateFormatter()
        rowDateFormatter.dateFormat = "yyyy-MM-dd"

        for dataPoint in data {
            let dateString = rowDateFormatter.string(from: dataPoint.date)
            csvString += "\(dateString),\(dataPoint.value)\n"
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
                .first(where: { $0.isKeyWindow })?.rootViewController?.present(activityVC, animated: true)
        } catch {
            onError("Export failed: \(error.localizedDescription)")
        }
    }
}
