//
//  BluetoothManager.swift
//  Cuore Mio
//
//  Created by Paolo Dobrowolny on 10/18/25.
//

import Foundation
import CoreBluetooth

// Notification names for Bluetooth events
extension Notification.Name {
    static let bluetoothDeviceDiscovered = Notification.Name("bluetoothDeviceDiscovered")
    static let bluetoothConnectionStatusChanged = Notification.Name("bluetoothConnectionStatusChanged")
    static let bluetoothStateChanged = Notification.Name("bluetoothStateChanged")
    static let bluetoothConnectionError = Notification.Name("bluetoothConnectionError")
}

class BluetoothManager: NSObject {
    
    // MARK: - Singleton
    
    static let shared = BluetoothManager()
    
    // MARK: - Properties
    
    private var centralManager: CBCentralManager!
    private var connectedPeripheral: CBPeripheral?
    private var discoveredPeripherals: [CBPeripheral] = []
    
    // Heart Rate Service UUID
    private let heartRateServiceUUID = CBUUID(string: "180D")
    private let heartRateMeasurementUUID = CBUUID(string: "2A37")
    
    // Auto-reconnect
    private var shouldAutoReconnect = false
    private var lastConnectedPeripheralIdentifier: UUID?
    
    // Callbacks
    var onDeviceDiscovered: (([CBPeripheral]) -> Void)?
    var onConnectionStatusChanged: ((Bool, String?) -> Void)?
    var onBluetoothStateChanged: ((CBManagerState) -> Void)?
    var onConnectionError: ((String) -> Void)?
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    // MARK: - Public Methods
    
    func startScanning() {
        guard centralManager.state == .poweredOn else {
            print("Bluetooth is not powered on")
            return
        }
        
        discoveredPeripherals.removeAll()
        onDeviceDiscovered?([])
        
        // Scan for ALL peripherals (not just those advertising Heart Rate Service)
        // Many heart rate monitors (like Coospo H6) don't advertise their service UUID
        // We'll check for Heart Rate Service after connection
        centralManager.scanForPeripherals(
            withServices: nil,
            options: [CBCentralManagerScanOptionAllowDuplicatesKey: false]
        )
        
        print("Started scanning for heart rate devices...")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        print("Stopped scanning")
    }
    
    func connect(to peripheral: CBPeripheral) {
        stopScanning()
        peripheral.delegate = self
        centralManager.connect(peripheral, options: nil)
        print("Attempting to connect to \(peripheral.name ?? "Unknown Device")")
    }
    
    func disconnect() {
        guard let peripheral = connectedPeripheral else { return }
        shouldAutoReconnect = false
        lastConnectedPeripheralIdentifier = nil
        centralManager.cancelPeripheralConnection(peripheral)
        print("Disconnecting from device")
    }
    
    func enableAutoReconnect() {
        shouldAutoReconnect = true
        if let peripheral = connectedPeripheral {
            lastConnectedPeripheralIdentifier = peripheral.identifier
        }
    }
    
    func disableAutoReconnect() {
        shouldAutoReconnect = false
    }
    
    func getDiscoveredDevices() -> [CBPeripheral] {
        return discoveredPeripherals
    }
    
    func getConnectedDevice() -> CBPeripheral? {
        return connectedPeripheral
    }
    
    func isConnected() -> Bool {
        return connectedPeripheral != nil
    }
}

// MARK: - CBCentralManagerDelegate

extension BluetoothManager: CBCentralManagerDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        onBluetoothStateChanged?(central.state)
        
        switch central.state {
        case .poweredOn:
            print("Bluetooth is powered on")
        case .poweredOff:
            print("Bluetooth is powered off")
        case .unauthorized:
            print("Bluetooth is unauthorized")
        case .unsupported:
            print("Bluetooth is not supported")
        case .resetting:
            print("Bluetooth is resetting")
        case .unknown:
            print("Bluetooth state is unknown")
        @unknown default:
            print("Unknown Bluetooth state")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // Avoid duplicates
        if !discoveredPeripherals.contains(where: { $0.identifier == peripheral.identifier }) {
            discoveredPeripherals.append(peripheral)
            print("Discovered: \(peripheral.name ?? "Unknown Device")")
            onDeviceDiscovered?(discoveredPeripherals)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        print("Connected to \(peripheral.name ?? "Unknown Device")")
        
        connectedPeripheral = peripheral
        lastConnectedPeripheralIdentifier = peripheral.identifier
        
        // Discover services
        peripheral.discoverServices([heartRateServiceUUID])
        
        // Notify connection status via both callback and notification
        let deviceName = peripheral.name ?? "Unknown Device"
        print("Notifying connection status: connected=true, device=\(deviceName)")
        onConnectionStatusChanged?(true, deviceName)
        
        // Post notification for multiple observers
        NotificationCenter.default.post(
            name: .bluetoothConnectionStatusChanged,
            object: nil,
            userInfo: ["isConnected": true, "deviceName": deviceName]
        )
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        print("Disconnected from \(peripheral.name ?? "Unknown Device")")
        
        if let error = error {
            print("Disconnection error: \(error.localizedDescription)")
        }
        
        connectedPeripheral = nil
        print("Notifying connection status: connected=false")
        onConnectionStatusChanged?(false, nil)
        
        // Post notification for multiple observers
        NotificationCenter.default.post(
            name: .bluetoothConnectionStatusChanged,
            object: nil,
            userInfo: ["isConnected": false]
        )
        
        // Auto-reconnect if enabled
        if shouldAutoReconnect && peripheral.identifier == lastConnectedPeripheralIdentifier {
            print("Attempting auto-reconnect...")
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                guard let self = self else { return }
                if self.shouldAutoReconnect {
                    self.connect(to: peripheral)
                }
            }
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("Failed to connect to \(peripheral.name ?? "Unknown Device")")
        
        if let error = error {
            print("Connection error: \(error.localizedDescription)")
        }
        
        print("Notifying connection status: failed to connect")
        onConnectionStatusChanged?(false, nil)
        
        // Post notification for multiple observers
        NotificationCenter.default.post(
            name: .bluetoothConnectionStatusChanged,
            object: nil,
            userInfo: ["isConnected": false]
        )
    }
}

// MARK: - CBPeripheralDelegate

extension BluetoothManager: CBPeripheralDelegate {
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            print("Error discovering services: \(error.localizedDescription)")
            onConnectionError?("Error discovering services: \(error.localizedDescription)")
            return
        }
        
        guard let services = peripheral.services else {
            print("No services found on device")
            onConnectionError?("This device doesn't expose any services")
            return
        }
        
        // Check if device has Heart Rate Service
        var hasHeartRateService = false
        for service in services {
            if service.uuid == heartRateServiceUUID {
                hasHeartRateService = true
                print("Found Heart Rate Service")
                // Discover characteristics for this service
                peripheral.discoverCharacteristics([heartRateMeasurementUUID], for: service)
            }
        }
        
        if !hasHeartRateService {
            print("Warning: Device does not have Heart Rate Service")
            onConnectionError?("This device doesn't appear to be a heart rate monitor")
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            print("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        
        guard let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == heartRateMeasurementUUID {
                print("Found Heart Rate Measurement Characteristic")
                // Subscribe to heart rate notifications
                peripheral.setNotifyValue(true, for: characteristic)
                print("Subscribed to heart rate notifications")
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error receiving characteristic update: \(error.localizedDescription)")
            return
        }
        
        guard characteristic.uuid == heartRateMeasurementUUID else { return }
        guard let data = characteristic.value else { return }
        
        // Parse heart rate value
        if let bpm = parseHeartRate(from: data) {
            print("Received heart rate: \(bpm) BPM")
            // Store data point
            HeartRateDataManager.shared.addDataPoint(bpm: bpm)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print("Error changing notification state: \(error.localizedDescription)")
            return
        }
        
        if characteristic.uuid == heartRateMeasurementUUID {
            if characteristic.isNotifying {
                print("Successfully subscribed to heart rate notifications")
            } else {
                print("Unsubscribed from heart rate notifications")
            }
        }
    }
    
    // MARK: - Heart Rate Parsing
    
    private func parseHeartRate(from data: Data) -> Int? {
        guard data.count >= 2 else { return nil }
        
        // First byte contains flags
        let flags = data[0]
        
        // Bit 0 of flags indicates BPM format
        // 0 = UINT8, 1 = UINT16
        let isBPMUInt16 = (flags & 0x01) != 0
        
        var bpm: Int
        
        if isBPMUInt16 {
            // BPM is 2 bytes (UINT16), little endian
            guard data.count >= 3 else { return nil }
            bpm = Int(data[1]) | (Int(data[2]) << 8)
        } else {
            // BPM is 1 byte (UINT8)
            bpm = Int(data[1])
        }
        
        return bpm
    }
}

