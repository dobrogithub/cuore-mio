//
//  DevicesViewController.swift
//  Cuore Mio
//
//  Created by Paolo Dobrowolny on 10/18/25.
//

import UIKit
import CoreBluetooth

class DevicesViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let tableView: UITableView = {
        let table = UITableView()
        table.translatesAutoresizingMaskIntoConstraints = false
        table.register(UITableViewCell.self, forCellReuseIdentifier: "DeviceCell")
        return table
    }()
    
    private let scanButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Scan for Devices", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        button.backgroundColor = UIColor.systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 12
        button.translatesAutoresizingMaskIntoConstraints = false
        return button
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = true
        indicator.translatesAutoresizingMaskIntoConstraints = false
        return indicator
    }()
    
    private let statusLabel: UILabel = {
        let label = UILabel()
        label.text = "Tap 'Scan for Devices' to start"
        label.font = UIFont.systemFont(ofSize: 14, weight: .regular)
        label.textColor = UIColor.systemGray
        label.textAlignment = .center
        label.numberOfLines = 0
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    // MARK: - Properties
    
    private var discoveredDevices: [CBPeripheral] = []
    private let bluetoothManager = BluetoothManager.shared
    private var isScanning = false
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = .systemBackground
        title = "Devices"
        
        setupUI()
        setupActions()
        setupBluetoothCallbacks()
        
        // Add close button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .close,
            target: self,
            action: #selector(closeTapped)
        )
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.addSubview(tableView)
        view.addSubview(scanButton)
        view.addSubview(activityIndicator)
        view.addSubview(statusLabel)
        
        tableView.delegate = self
        tableView.dataSource = self
        
        NSLayoutConstraint.activate([
            // Table view - top section
            tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: statusLabel.topAnchor, constant: -20),
            
            // Status label
            statusLabel.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            statusLabel.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            statusLabel.bottomAnchor.constraint(equalTo: scanButton.topAnchor, constant: -12),
            
            // Scan button - bottom
            scanButton.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            scanButton.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            scanButton.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -20),
            scanButton.heightAnchor.constraint(equalToConstant: 50),
            
            // Activity indicator - center of scan button
            activityIndicator.centerXAnchor.constraint(equalTo: scanButton.centerXAnchor),
            activityIndicator.centerYAnchor.constraint(equalTo: scanButton.centerYAnchor)
        ])
    }
    
    private func setupActions() {
        scanButton.addTarget(self, action: #selector(scanButtonTapped), for: .touchUpInside)
    }
    
    private func setupBluetoothCallbacks() {
        bluetoothManager.onDeviceDiscovered = { [weak self] devices in
            guard let self = self else { return }
            
            // Merge with existing devices (don't lose connected device)
            var allDevices = devices
            
            // Add connected device if not already in list
            if let connectedDevice = self.bluetoothManager.getConnectedDevice() {
                if !allDevices.contains(where: { $0.identifier == connectedDevice.identifier }) {
                    allDevices.insert(connectedDevice, at: 0)
                    print("Keeping connected device in list")
                }
            }
            
            self.discoveredDevices = allDevices
            self.tableView.reloadData()
            
            if devices.isEmpty {
                self.statusLabel.text = "Scanning for devices..."
            } else {
                self.statusLabel.text = "Found \(allDevices.count) device(s)"
            }
        }
        
        bluetoothManager.onConnectionStatusChanged = { [weak self] isConnected, deviceName in
            print("DevicesViewController received connection status: \(isConnected), device: \(deviceName ?? "nil")")
            if isConnected {
                // Connection successful - dismiss this screen after a short delay
                // This gives time for the notification to propagate to ViewController
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    print("DevicesViewController dismissing...")
                    self?.dismiss(animated: true)
                }
            }
        }
        
        bluetoothManager.onBluetoothStateChanged = { [weak self] state in
            switch state {
            case .poweredOff:
                self?.statusLabel.text = "Bluetooth is turned off"
                self?.scanButton.isEnabled = false
            case .unauthorized:
                self?.statusLabel.text = "Bluetooth access not authorized"
                self?.scanButton.isEnabled = false
            case .unsupported:
                self?.statusLabel.text = "Bluetooth is not supported on this device"
                self?.scanButton.isEnabled = false
            case .poweredOn:
                self?.statusLabel.text = "Tap 'Scan for Devices' to start"
                self?.scanButton.isEnabled = true
            default:
                self?.statusLabel.text = "Bluetooth is not ready"
                self?.scanButton.isEnabled = false
            }
        }
        
        bluetoothManager.onConnectionError = { [weak self] errorMessage in
            DispatchQueue.main.async {
                self?.showConnectionError(errorMessage)
            }
        }
    }
    
    private func showConnectionError(_ message: String) {
        let alert = UIAlertController(
            title: "Connection Issue",
            message: message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default) { [weak self] _ in
            self?.resetConnectionUI()
        })
        present(alert, animated: true)
    }
    
    private func resetConnectionUI() {
        activityIndicator.stopAnimating()
        scanButton.isEnabled = true
        statusLabel.text = "Connection failed. Try another device."
    }
    
    // MARK: - Actions
    
    @objc private func scanButtonTapped() {
        if isScanning {
            stopScanning()
        } else {
            startScanning()
        }
    }
    
    @objc private func closeTapped() {
        bluetoothManager.stopScanning()
        dismiss(animated: true)
    }
    
    // MARK: - Scanning
    
    private func startScanning() {
        isScanning = true
        discoveredDevices.removeAll()
        
        // If there's a connected device, add it to the list
        if let connectedDevice = bluetoothManager.getConnectedDevice() {
            discoveredDevices.append(connectedDevice)
            print("Added currently connected device to list: \(connectedDevice.name ?? "Unknown")")
        }
        
        tableView.reloadData()
        
        scanButton.setTitle("Stop Scanning", for: .normal)
        scanButton.backgroundColor = UIColor.systemRed
        activityIndicator.startAnimating()
        statusLabel.text = "Scanning for devices..."
        
        bluetoothManager.startScanning()
        
        // Auto-stop scanning after 30 seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + 30) { [weak self] in
            if self?.isScanning == true {
                self?.stopScanning()
            }
        }
    }
    
    private func stopScanning() {
        isScanning = false
        bluetoothManager.stopScanning()
        
        scanButton.setTitle("Scan for Devices", for: .normal)
        scanButton.backgroundColor = UIColor.systemBlue
        activityIndicator.stopAnimating()
        
        if discoveredDevices.isEmpty {
            statusLabel.text = "No devices found. Try again."
        } else {
            statusLabel.text = "Found \(discoveredDevices.count) device(s). Tap to connect."
        }
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension DevicesViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return discoveredDevices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DeviceCell", for: indexPath)
        let device = discoveredDevices[indexPath.row]
        
        // Configure cell
        cell.textLabel?.text = device.name ?? "Unknown Device"
        cell.accessoryType = .disclosureIndicator
        
        // Highlight if this is the connected device
        if let connectedDevice = bluetoothManager.getConnectedDevice(),
           connectedDevice.identifier == device.identifier {
            cell.accessoryType = .checkmark
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .semibold)
        } else {
            cell.textLabel?.font = UIFont.systemFont(ofSize: 17, weight: .regular)
        }
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedDevice = discoveredDevices[indexPath.row]
        
        // Show connecting indicator
        statusLabel.text = "Connecting to \(selectedDevice.name ?? "device")..."
        activityIndicator.startAnimating()
        scanButton.isEnabled = false
        
        // Attempt connection
        bluetoothManager.connect(to: selectedDevice)
    }
}

