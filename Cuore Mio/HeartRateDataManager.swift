//
//  HeartRateDataManager.swift
//  Cuore Mio
//
//  Heart rate data storage and management
//

import Foundation
import HealthKit

// Data model for heart rate measurements
struct HeartRateDataPoint {
    let timestamp: Date
    let bpm: Int
}

// Notification for new heart rate data
extension Notification.Name {
    static let heartRateDataReceived = Notification.Name("heartRateDataReceived")
}

class HeartRateDataManager {
    
    // MARK: - Singleton
    
    static let shared = HeartRateDataManager()
    
    // MARK: - Properties
    
    private var dataPoints: [HeartRateDataPoint] = []
    private let maxDataPoints = 28800 // 8 hours at 1 reading/second
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    func addDataPoint(bpm: Int) {
        let dataPoint = HeartRateDataPoint(timestamp: Date(), bpm: bpm)
        dataPoints.append(dataPoint)
        
        // Limit data points to prevent memory issues
        if dataPoints.count > maxDataPoints {
            dataPoints.removeFirst()
        }
        
        // Save to HealthKit automatically
        HealthKitManager.shared.saveHeartRate(bpm: bpm, timestamp: dataPoint.timestamp) { success, error in
            if success {
                print("Heart rate saved to HealthKit: \(bpm) BPM")
            } else if let error = error {
                print("Failed to save to HealthKit: \(error.localizedDescription)")
            }
        }
        
        // Notify observers of new data
        NotificationCenter.default.post(
            name: .heartRateDataReceived,
            object: nil,
            userInfo: ["bpm": bpm, "dataPoint": dataPoint]
        )
    }
    
    func getAllData() -> [HeartRateDataPoint] {
        return dataPoints
    }
    
    func clearData() {
        dataPoints.removeAll()
        print("Cleared all heart rate data")
    }
    
    func getDataCount() -> Int {
        return dataPoints.count
    }
    
    func getLatestBPM() -> Int? {
        return dataPoints.last?.bpm
    }
}

