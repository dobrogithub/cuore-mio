# Implementation Steps: Cuore Mio

## Step 1: Project Setup and Main Screen UI
**Goal:** Set up the project structure and create the main screen with all UI elements (non-functional).

**Tasks:**
- Configure Info.plist with required permissions:
  - `NSBluetoothAlwaysUsageDescription`
  - `NSLocationAlwaysAndWhenInUseUsageDescription`
  - `NSLocationWhenInUseUsageDescription`
  - `UIBackgroundModes` array with `location` and `bluetooth-central`
- Modify `ViewController.swift` to create main screen layout:
  - Chart container view (placeholder for now)
  - Connection status label (e.g., "Not Connected")
  - Current BPM label (large, prominent)
  - "Start Sleep Session" button (large, centered)
  - "Devices" button (top-right navigation)
- Set up Auto Layout constraints for all UI elements
- Implement button state toggle: "Start Sleep Session" ↔ "Stop Sleep Session"
- Style UI elements (colors, fonts, sizing)

**Deliverables:**
- Main screen with complete UI layout
- Button that toggles text when tapped (no functionality yet)
- Static labels showing placeholder text

**Dependencies:** None

---

## Step 2: Bluetooth Device Scanning and Pairing
**Goal:** Create the Devices screen and implement Bluetooth discovery and connection.

**Tasks:**
- Create new `DevicesViewController.swift`:
  - UITableView to list discovered devices
  - "Scan" button
  - Loading indicator
- Implement Core Bluetooth functionality:
  - Create `BluetoothManager.swift` (singleton)
  - Set up `CBCentralManager`
  - Scan for peripherals with Heart Rate Service (0x180D)
  - Store discovered devices in array
  - Update table view with device names
- Implement device selection:
  - Connect to selected peripheral
  - Discover Heart Rate Service and Measurement Characteristic
  - Notify `ViewController` of connection status
- Add navigation:
  - Present `DevicesViewController` when "Devices" button tapped
  - Return to main screen after successful connection
- Handle Bluetooth states (powered on/off, unauthorized, etc.)

**Deliverables:**
- Working Devices screen with scan and connect functionality
- `BluetoothManager` that manages peripheral discovery and connection
- Connection status updates on main screen

**Dependencies:** Step 1

---

## Step 3: Heart Rate Data Reception and Chart Display
**Goal:** Receive heart rate data from the chest strap and display it on a scrollable line chart.

**Tasks:**
- Implement heart rate data reception in `BluetoothManager`:
  - Subscribe to Heart Rate Measurement Characteristic (0x2A37)
  - Parse BPM value from characteristic data
  - Create data model: `HeartRateDataPoint(timestamp: Date, bpm: Int)`
  - Notify `ViewController` with new data points
- Create `HeartRateDataManager.swift` (singleton):
  - Store array of `HeartRateDataPoint` objects in memory
  - Provide methods: `addDataPoint()`, `clearData()`, `getAllData()`
- Implement chart using `Charts` library or custom drawing:
  - If using library: Add Charts via Swift Package Manager (https://github.com/danielgindi/Charts)
  - If custom: Use `UIBezierPath` and `CAShapeLayer` to draw line chart
  - Configure chart:
    - X-axis: Time (HH:MM)
    - Y-axis: BPM (40-200)
    - Scrollable horizontally
    - Auto-update when new data arrives
- Update current BPM label in real-time
- Implement auto-reconnect logic:
  - Detect peripheral disconnection
  - Automatically attempt reconnection
  - Update connection status label

**Deliverables:**
- Real-time heart rate data displayed as large BPM number
- Scrollable line chart showing all session data
- Auto-reconnect on disconnection

**Dependencies:** Step 2

---

## Step 4: Background Location Services
**Goal:** Keep the app active in the background using location services.

**Tasks:**
- Create `LocationManager.swift` (singleton):
  - Set up `CLLocationManager`
  - Request "Always Allow" permission
  - Configure for background location updates
  - Use `.significantLocationChanges` or continuous updates
- Integrate location management with session control:
  - Start location updates when "Start Sleep Session" tapped
  - Stop location updates when "Stop Sleep Session" tapped
- Handle permission states:
  - Request permission on first session start
  - Handle user denial gracefully
  - Show alert if permission denied
- Test background behavior:
  - Verify app continues running when minimized
  - Verify Bluetooth connection maintained
  - Verify heart rate data continues to be received

**Deliverables:**
- Working background location service
- Location updates start/stop with session
- App remains active when minimized during session

**Dependencies:** Step 3

---

## Step 5: Session Management and Data Lifecycle
**Goal:** Properly manage session state and data lifecycle.

**Tasks:**
- Implement session state management in `ViewController`:
  - Track session state: `.idle`, `.active`
  - Update UI based on state
  - Update button text based on state
- Implement session start logic:
  - Clear previous heart rate data
  - Start location services
  - Begin collecting data (if device connected)
  - Update button to "Stop Sleep Session"
- Implement session stop logic:
  - Stop location services
  - Keep data visible on chart
  - Update button to "Start Sleep Session"
- Handle app lifecycle:
  - Maintain session state when app backgrounds
  - Continue data collection in background
  - Properly restore UI when app returns to foreground
- Add safeguards:
  - Require device connection before starting session (or show warning)
  - Prevent starting session if location permission denied

**Deliverables:**
- Complete session start/stop functionality
- Data cleared on new session start
- Data persists until new session or app termination
- Proper state management across app lifecycle

**Dependencies:** Step 4

---

## Step 6: Testing and Refinement
**Goal:** Test all functionality and fix any issues.

**Tasks:**
- Functional testing:
  - Test device scanning and connection
  - Test heart rate data reception and display
  - Test chart scrolling and rendering
  - Test session start/stop
  - Test background operation (leave app for extended period)
  - Test auto-reconnect on device disconnection
- Permission testing:
  - Test permission request flows
  - Test behavior when permissions denied
  - Verify background location works with "Always Allow"
- Edge case testing:
  - Test with device that doesn't support HRS
  - Test starting session without connected device
  - Test rapid session start/stop
  - Test app termination and relaunch
  - Test Bluetooth off/on during session
- UI/UX refinement:
  - Adjust chart appearance
  - Improve button styling
  - Add loading indicators where needed
  - Ensure labels update correctly
- Performance:
  - Verify memory usage is reasonable
  - Check for memory leaks
  - Optimize chart rendering if needed

**Deliverables:**
- Fully tested and working app
- Bug fixes for any discovered issues
- Polished UI/UX
- Documented any known limitations

**Dependencies:** Step 5

---

## Implementation Notes

### Recommended Chart Library
- **Charts by Daniel Gindi**: https://github.com/danielgindi/Charts
  - Swift Package Manager: `https://github.com/danielgindi/Charts.git`
  - Use `LineChartView` for heart rate display
  - Supports scrolling and real-time updates

### Heart Rate Service Details
- Service UUID: `0x180D`
- Heart Rate Measurement Characteristic UUID: `0x2A37`
- Data format: First byte is flags, second byte (or more) is BPM value
  - If bit 0 of flags is 0: BPM is 1 byte (UINT8)
  - If bit 0 of flags is 1: BPM is 2 bytes (UINT16)

### Background Location Configuration
```swift
locationManager.allowsBackgroundLocationUpdates = true
locationManager.pausesLocationUpdatesAutomatically = false
locationManager.desiredAccuracy = kCLLocationAccuracyThreeKilometers // Low accuracy sufficient
locationManager.startMonitoringSignificantLocationChanges() // Battery efficient
```

### Testing Tips
- Use Bluetooth simulator apps for testing without physical device
- Monitor Xcode console for background activity logs
- Use Debug → Simulate Location to trigger location updates
- Check Settings → Privacy → Location Services to verify permission state

