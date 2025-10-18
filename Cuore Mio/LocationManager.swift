//
//  LocationManager.swift
//  Cuore Mio
//
//  Created by Paolo Dobrowolny on 10/18/25.
//

import UIKit
import CoreLocation

class LocationManager: NSObject {
    
    // MARK: - Singleton
    
    static let shared = LocationManager()
    
    // MARK: - Properties
    
    private let locationManager: CLLocationManager
    private var isTracking = false
    
    // MARK: - Initialization
    
    private override init() {
        locationManager = CLLocationManager()
        super.init()
        
        setupLocationManager()
    }
    
    // MARK: - Setup
    
    private func setupLocationManager() {
        locationManager.delegate = self
        
        // Configure for battery-efficient background operation
        locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers
        locationManager.allowsBackgroundLocationUpdates = true
        locationManager.pausesLocationUpdatesAutomatically = false
    }
    
    // MARK: - Public Methods
    
    /// Start location tracking for background operation
    func startTracking() {
        // Check authorization status
        let status = locationManager.authorizationStatus
        
        switch status {
        case .notDetermined:
            // iOS requires a two-step process:
            // 1. First request "When In Use" permission
            // 2. Then request "Always" permission after tracking starts
            print("Requesting When In Use permission (step 1 of 2)")
            locationManager.requestWhenInUseAuthorization()
            // Will continue to step 2 in delegate callback
            
        case .authorizedAlways:
            // Permission already granted, start tracking
            print("Already have Always permission - starting tracking")
            startLocationUpdates()
            
        case .authorizedWhenInUse:
            // Start tracking first, then request upgrade to "Always"
            print("Have When In Use permission - starting tracking and requesting Always upgrade")
            startLocationUpdates()
            // Request upgrade to Always after a short delay to ensure tracking is active
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                print("Requesting Always permission upgrade (step 2 of 2)")
                self?.locationManager.requestAlwaysAuthorization()
            }
            
        case .denied, .restricted:
            // Show alert to user
            showLocationPermissionAlert()
            
        @unknown default:
            print("Unknown location authorization status")
        }
    }
    
    /// Stop location tracking
    func stopTracking() {
        guard isTracking else { return }
        
        locationManager.stopMonitoringSignificantLocationChanges()
        isTracking = false
        print("Location tracking stopped")
    }
    
    // MARK: - Private Methods
    
    private func startLocationUpdates() {
        guard !isTracking else { return }
        
        // Use significant location changes for battery efficiency
        locationManager.startMonitoringSignificantLocationChanges()
        isTracking = true
        print("Location tracking started (significant changes)")
    }
    
    private func showLocationPermissionAlert() {
        DispatchQueue.main.async {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return
            }
            
            let alert = UIAlertController(
                title: "Location Permission Required",
                message: "To keep tracking your heart rate in the background, please enable \"Always Allow\" location access in Settings.",
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "Open Settings", style: .default) { _ in
                if let settingsURL = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(settingsURL)
                }
            })
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
            
            rootViewController.present(alert, animated: true)
        }
    }
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {
    
    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        print("Location authorization changed: \(status.rawValue)")
        
        switch status {
        case .authorizedAlways:
            print("Location authorization: Always - starting location updates")
            startLocationUpdates()
            
        case .authorizedWhenInUse:
            print("Location authorization: When In Use - will request Always upgrade")
            // Start tracking first
            startLocationUpdates()
            // Then request Always permission upgrade after a short delay
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
                print("Requesting Always permission upgrade (step 2 of 2)")
                self?.locationManager.requestAlwaysAuthorization()
            }
            
        case .denied, .restricted:
            print("Location authorization: Denied or Restricted")
            showLocationPermissionAlert()
            
        case .notDetermined:
            print("Location authorization: Not Determined")
            
        @unknown default:
            print("Location authorization: Unknown")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        // We don't need to do anything with the location data
        // We're just using this to keep the app active in the background
        if let location = locations.last {
            print("Location updated: \(location.coordinate.latitude), \(location.coordinate.longitude)")
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location manager failed with error: \(error.localizedDescription)")
    }
}

