//
//  ViewController.swift
//  Cuore Mio
//
//  Created by Paolo Dobrowolny on 10/18/25.
//

import UIKit
import CoreBluetooth
import CoreLocation
import DGCharts
import HealthKit

class ViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let chartView: LineChartView = {
        let chart = LineChartView()
        chart.translatesAutoresizingMaskIntoConstraints = false
        chart.backgroundColor = UIColor.systemGray6
        chart.layer.cornerRadius = 12
        chart.layer.borderWidth = 1
        chart.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Chart configuration
        chart.rightAxis.enabled = false
        chart.leftAxis.labelFont = UIFont.systemFont(ofSize: 12)
        chart.leftAxis.labelTextColor = .label
        chart.leftAxis.axisMinimum = 40
        chart.leftAxis.axisMaximum = 200
        chart.leftAxis.gridColor = UIColor.systemGray4
        
        chart.xAxis.labelPosition = .bottom
        chart.xAxis.labelFont = UIFont.systemFont(ofSize: 12)
        chart.xAxis.labelTextColor = .label
        chart.xAxis.gridColor = UIColor.systemGray4
        chart.xAxis.valueFormatter = TimeValueFormatter()
        
        chart.legend.enabled = false
        chart.doubleTapToZoomEnabled = false
        chart.pinchZoomEnabled = false
        chart.scaleYEnabled = false
        
        // Enable horizontal scrolling
        chart.dragEnabled = true
        chart.setScaleEnabled(true)
        chart.scaleXEnabled = true
        
        chart.noDataText = "No heart rate data yet"
        chart.noDataFont = UIFont.systemFont(ofSize: 16)
        chart.noDataTextColor = .systemGray
        
        return chart
    }()
    
    private let connectionStatusLabel: UILabel = {
        let label = UILabel()
        label.text = "Not Connected"
        label.font = UIFont.systemFont(ofSize: 16, weight: .medium)
        label.textColor = UIColor.systemRed
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let currentBPMLabel: UILabel = {
        let label = UILabel()
        label.text = "-- BPM"
        label.font = UIFont.systemFont(ofSize: 72, weight: .bold)
        label.textColor = UIColor.label
        label.textAlignment = .center
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    private let sessionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Start Sleep Session", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .semibold)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let devicesButton: UIBarButtonItem = {
        let button = UIBarButtonItem(title: "Devices", style: .plain, target: nil, action: nil)
        return button
    }()
    
    // MARK: - Properties
    
    // Session state enum
    private enum SessionState {
        case idle
        case active
    }
    
    private var sessionState: SessionState = .idle
    private let bluetoothManager = BluetoothManager.shared
    private let dataManager = HeartRateDataManager.shared
    private let locationManager = LocationManager.shared
    private let healthKitManager = HealthKitManager.shared
    private var sessionStartTime: Date?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Cuore Mio"
        
        setupUI()
        setupActions()
        setupBluetoothCallbacks()
        setupHeartRateObserver()
        setupAppLifecycleObservers()
        setupHealthKit()
        
        // Enable auto-reconnect for seamless background operation
        bluetoothManager.enableAutoReconnect()
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Add subviews
        view.addSubview(chartView)
        view.addSubview(connectionStatusLabel)
        view.addSubview(currentBPMLabel)
        view.addSubview(sessionButton)
        
        // Add devices button to navigation bar
        navigationItem.rightBarButtonItem = devicesButton
        
        // Setup constraints
        NSLayoutConstraint.activate([
            // Connection status label - top
            connectionStatusLabel.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            connectionStatusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            connectionStatusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Current BPM label - below connection status
            currentBPMLabel.topAnchor.constraint(equalTo: connectionStatusLabel.bottomAnchor, constant: 20),
            currentBPMLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            currentBPMLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            
            // Chart view - middle section
            chartView.topAnchor.constraint(equalTo: currentBPMLabel.bottomAnchor, constant: 30),
            chartView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            chartView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            chartView.heightAnchor.constraint(equalToConstant: 250),
            
            // Session button - bottom
            sessionButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            sessionButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            sessionButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -30),
            sessionButton.heightAnchor.constraint(equalToConstant: 56)
        ])
    }
    
    private func setupActions() {
        sessionButton.addTarget(self, action: #selector(sessionButtonTapped), for: .touchUpInside)
        devicesButton.target = self
        devicesButton.action = #selector(devicesButtonTapped)
    }
    
    private func setupBluetoothCallbacks() {
        // Listen for connection status changes via NotificationCenter
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleConnectionStatusChanged(_:)),
            name: .bluetoothConnectionStatusChanged,
            object: nil
        )
        
        // Check initial connection state
        if let connectedDevice = bluetoothManager.getConnectedDevice() {
            updateConnectionStatus(isConnected: true, deviceName: connectedDevice.name)
        }
    }
    
    @objc private func handleConnectionStatusChanged(_ notification: Notification) {
        print("ViewController received connection status notification")
        guard let userInfo = notification.userInfo else {
            print("No userInfo in notification")
            return
        }
        
        let isConnected = userInfo["isConnected"] as? Bool ?? false
        let deviceName = userInfo["deviceName"] as? String
        
        print("ViewController updating UI: isConnected=\(isConnected), deviceName=\(deviceName ?? "nil")")
        
        DispatchQueue.main.async { [weak self] in
            self?.updateConnectionStatus(isConnected: isConnected, deviceName: deviceName)
        }
    }
    
    private func setupHeartRateObserver() {
        // Listen for heart rate data updates
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(handleHeartRateData(_:)),
            name: .heartRateDataReceived,
            object: nil
        )
    }
    
    private func setupAppLifecycleObservers() {
        // Listen for app going to background
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appDidEnterBackground),
            name: UIApplication.didEnterBackgroundNotification,
            object: nil
        )
        
        // Listen for app coming to foreground
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(appWillEnterForeground),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
    }
    
    private func setupHealthKit() {
        // Request HealthKit authorization on app launch
        guard healthKitManager.isHealthKitAvailable() else {
            print("HealthKit is not available on this device")
            return
        }
        
        healthKitManager.requestAuthorization { success, error in
            if success {
                print("HealthKit authorization granted")
            } else if let error = error {
                print("HealthKit authorization failed: \(error.localizedDescription)")
            } else {
                print("HealthKit authorization denied by user")
            }
        }
    }
    
    @objc private func handleHeartRateData(_ notification: Notification) {
        guard let userInfo = notification.userInfo,
              let bpm = userInfo["bpm"] as? Int else { return }
        
        DispatchQueue.main.async { [weak self] in
            self?.updateBPMLabel(bpm: bpm)
            self?.updateChart()
        }
    }
    
    @objc private func appDidEnterBackground() {
        print("App entering background - session state: \(sessionState == .active ? "active" : "idle")")
        // Session state and location tracking persist automatically
    }
    
    @objc private func appWillEnterForeground() {
        print("App entering foreground - session state: \(sessionState == .active ? "active" : "idle")")
        // Refresh UI to reflect current state
        DispatchQueue.main.async { [weak self] in
            self?.updateSessionButtonState()
            self?.updateChart()
            
            // Update connection status
            if let device = self?.bluetoothManager.getConnectedDevice() {
                self?.updateConnectionStatus(isConnected: true, deviceName: device.name)
            } else {
                self?.updateConnectionStatus(isConnected: false, deviceName: nil)
            }
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Actions
    
    @objc private func sessionButtonTapped() {
        switch sessionState {
        case .idle:
            startSession()
        case .active:
            stopSession()
        }
    }
    
    private func startSession() {
        // Safeguard 1: Check if device is connected
        guard bluetoothManager.isConnected() else {
            showAlert(
                title: "Device Not Connected",
                message: "Please connect to a heart rate monitor before starting a session. Tap 'Devices' to connect."
            )
            return
        }
        
        // Safeguard 2: Check location permission
        let locationStatus = CLLocationManager.authorizationStatus()
        if locationStatus == .denied || locationStatus == .restricted {
            showAlert(
                title: "Location Permission Required",
                message: "This app needs \"Always Allow\" location permission to keep tracking your heart rate in the background. Please enable it in Settings."
            )
            return
        }
        
        // Clear previous session data
        print("Starting new session - clearing previous data")
        dataManager.clearData()
        
        // Update session state
        sessionState = .active
        sessionStartTime = Date()
        
        // Start location services for background operation
        print("Starting location tracking for background operation")
        locationManager.startTracking()
        
        // Update UI
        updateSessionButtonState()
        updateChart() // Clear chart display
        
        print("Sleep session started")
    }
    
    private func stopSession() {
        // Stop location services
        print("Stopping location tracking")
        locationManager.stopTracking()
        
        // Update session state
        sessionState = .idle
        sessionStartTime = nil
        
        // Update UI (data remains visible on chart)
        updateSessionButtonState()
        
        print("Sleep session stopped - data remains visible")
    }
    
    private func showAlert(title: String, message: String) {
        let alert = UIAlertController(
            title: title,
            message: message,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        
        present(alert, animated: true)
    }
    
    @objc private func devicesButtonTapped() {
        let devicesVC = DevicesViewController()
        let navController = UINavigationController(rootViewController: devicesVC)
        navController.modalPresentationStyle = .pageSheet
        present(navController, animated: true)
    }
    
    // MARK: - UI Updates
    
    private func updateSessionButtonState() {
        switch sessionState {
        case .active:
            sessionButton.setTitle("Stop Sleep Session", for: .normal)
            sessionButton.backgroundColor = UIColor.systemRed
        case .idle:
            sessionButton.setTitle("Start Sleep Session", for: .normal)
            sessionButton.backgroundColor = UIColor.systemBlue
        }
    }
    
    private func updateConnectionStatus(isConnected: Bool, deviceName: String?) {
        if isConnected, let name = deviceName {
            connectionStatusLabel.text = "Connected to \(name)"
            connectionStatusLabel.textColor = UIColor.systemGreen
        } else {
            connectionStatusLabel.text = "Not Connected"
            connectionStatusLabel.textColor = UIColor.systemRed
            currentBPMLabel.text = "-- BPM"
        }
    }
    
    private func updateBPMLabel(bpm: Int) {
        currentBPMLabel.text = "\(bpm) BPM"
    }
    
    private func updateChart() {
        let dataPoints = dataManager.getAllData()
        
        guard !dataPoints.isEmpty else {
            chartView.data = nil
            chartView.notifyDataSetChanged()
            return
        }
        
        // Create chart data entries
        var entries: [ChartDataEntry] = []
        
        for dataPoint in dataPoints {
            let xValue = dataPoint.timestamp.timeIntervalSince1970
            let yValue = Double(dataPoint.bpm)
            entries.append(ChartDataEntry(x: xValue, y: yValue))
        }
        
        // Create dataset
        let dataSet = LineChartDataSet(entries: entries, label: "Heart Rate")
        dataSet.drawCirclesEnabled = false
        dataSet.drawValuesEnabled = false
        dataSet.lineWidth = 2.0
        dataSet.setColor(UIColor.systemRed)
        dataSet.mode = .cubicBezier
        dataSet.cubicIntensity = 0.2
        
        // Fill gradient
        let gradientColors = [UIColor.systemRed.withAlphaComponent(0.5).cgColor,
                            UIColor.systemRed.withAlphaComponent(0.0).cgColor]
        let gradient = CGGradient(colorsSpace: nil, colors: gradientColors as CFArray, locations: nil)!
        dataSet.fillAlpha = 1.0
        dataSet.fill = LinearGradientFill(gradient: gradient, angle: 90.0)
        dataSet.drawFilledEnabled = true
        
        // Update chart
        let lineChartData = LineChartData(dataSet: dataSet)
        chartView.data = lineChartData
        
        // Auto-scroll to show latest data
        chartView.setVisibleXRangeMaximum(600) // Show 10 minutes worth of data
        chartView.moveViewToX(entries.last?.x ?? 0)
        
        chartView.notifyDataSetChanged()
    }
}

// MARK: - Time Value Formatter

class TimeValueFormatter: AxisValueFormatter {
    private let dateFormatter: DateFormatter
    
    init() {
        dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH:mm"
    }
    
    func stringForValue(_ value: Double, axis: AxisBase?) -> String {
        let date = Date(timeIntervalSince1970: value)
        return dateFormatter.string(from: date)
    }
}

