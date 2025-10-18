//
//  HealthKitManager.swift
//  Cuore Mio
//
//  Manages HealthKit integration for saving heart rate data to Apple Health
//

import Foundation
import HealthKit

class HealthKitManager {
    
    // MARK: - Singleton
    
    static let shared = HealthKitManager()
    
    // MARK: - Properties
    
    private let healthStore = HKHealthStore()
    private var isAuthorized = false
    
    // Heart rate type
    private let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    // MARK: - Initialization
    
    private init() {}
    
    // MARK: - Public Methods
    
    /// Check if HealthKit is available on this device
    func isHealthKitAvailable() -> Bool {
        return HKHealthStore.isHealthDataAvailable()
    }
    
    /// Request authorization to write heart rate data to HealthKit
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        guard isHealthKitAvailable() else {
            print("HealthKit is not available on this device")
            completion(false, NSError(domain: "HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device"]))
            return
        }
        
        // Define the data types we want to write
        let typesToWrite: Set<HKSampleType> = [heartRateType]
        
        // Request authorization
        healthStore.requestAuthorization(toShare: typesToWrite, read: nil) { [weak self] success, error in
            if let error = error {
                print("HealthKit authorization error: \(error.localizedDescription)")
                self?.isAuthorized = false
                completion(false, error)
                return
            }
            
            if success {
                print("HealthKit authorization granted")
                self?.isAuthorized = true
                completion(true, nil)
            } else {
                print("HealthKit authorization denied")
                self?.isAuthorized = false
                completion(false, nil)
            }
        }
    }
    
    /// Check current authorization status
    func checkAuthorizationStatus() -> HKAuthorizationStatus {
        return healthStore.authorizationStatus(for: heartRateType)
    }
    
    /// Save a single heart rate data point to HealthKit
    func saveHeartRate(bpm: Int, timestamp: Date, completion: ((Bool, Error?) -> Void)? = nil) {
        guard isHealthKitAvailable() else {
            print("HealthKit not available - skipping save")
            completion?(false, nil)
            return
        }
        
        // Check authorization status
        let authStatus = checkAuthorizationStatus()
        guard authStatus == .sharingAuthorized else {
            print("HealthKit not authorized - skipping save (status: \(authStatus.rawValue))")
            completion?(false, nil)
            return
        }
        
        // Create heart rate quantity
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        let heartRateQuantity = HKQuantity(unit: heartRateUnit, doubleValue: Double(bpm))
        
        // Create heart rate sample
        let heartRateSample = HKQuantitySample(
            type: heartRateType,
            quantity: heartRateQuantity,
            start: timestamp,
            end: timestamp
        )
        
        // Save to HealthKit
        healthStore.save(heartRateSample) { success, error in
            if let error = error {
                print("Error saving heart rate to HealthKit: \(error.localizedDescription)")
                completion?(false, error)
                return
            }
            
            if success {
                print("Successfully saved heart rate (\(bpm) BPM) to HealthKit")
                completion?(true, nil)
            } else {
                print("Failed to save heart rate to HealthKit")
                completion?(false, nil)
            }
        }
    }
    
    /// Save multiple heart rate data points to HealthKit (batch save)
    func saveHeartRateBatch(_ dataPoints: [HeartRateDataPoint], completion: ((Bool, Error?) -> Void)? = nil) {
        guard isHealthKitAvailable() else {
            print("HealthKit not available - skipping batch save")
            completion?(false, nil)
            return
        }
        
        // Check authorization status
        let authStatus = checkAuthorizationStatus()
        guard authStatus == .sharingAuthorized else {
            print("HealthKit not authorized - skipping batch save")
            completion?(false, nil)
            return
        }
        
        guard !dataPoints.isEmpty else {
            completion?(true, nil)
            return
        }
        
        // Create heart rate samples
        let heartRateUnit = HKUnit.count().unitDivided(by: .minute())
        var samples: [HKQuantitySample] = []
        
        for dataPoint in dataPoints {
            let heartRateQuantity = HKQuantity(unit: heartRateUnit, doubleValue: Double(dataPoint.bpm))
            let heartRateSample = HKQuantitySample(
                type: heartRateType,
                quantity: heartRateQuantity,
                start: dataPoint.timestamp,
                end: dataPoint.timestamp
            )
            samples.append(heartRateSample)
        }
        
        // Save batch to HealthKit
        healthStore.save(samples) { success, error in
            if let error = error {
                print("Error saving heart rate batch to HealthKit: \(error.localizedDescription)")
                completion?(false, error)
                return
            }
            
            if success {
                print("Successfully saved \(samples.count) heart rate samples to HealthKit")
                completion?(true, nil)
            } else {
                print("Failed to save heart rate batch to HealthKit")
                completion?(false, nil)
            }
        }
    }
    
    /// Get authorization status as a user-friendly string
    func getAuthorizationStatusString() -> String {
        let status = checkAuthorizationStatus()
        switch status {
        case .notDetermined:
            return "Not Determined"
        case .sharingDenied:
            return "Denied"
        case .sharingAuthorized:
            return "Authorized"
        @unknown default:
            return "Unknown"
        }
    }
}

