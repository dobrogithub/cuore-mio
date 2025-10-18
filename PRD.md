# Product Requirements Document: Cuore Mio Heart Rate Monitor

## Overview
Cuore Mio is a minimalist iOS app that continuously monitors heart rate during sleep using a Bluetooth chest strap (Coospo H6 or similar). The app uses location services to remain active in the background, ensuring uninterrupted heart rate data collection.

## Core Problem
Standard iOS apps suspend in the background, causing Bluetooth connections to chest straps to disconnect. By leveraging location services, the app remains active and maintains the Bluetooth connection throughout the night.

## Target Devices
- iPhone running iOS 14.0 or later
- Bluetooth Low Energy (BLE) heart rate chest straps supporting Heart Rate Service (HRS)

## User Flow
1. User opens app → sees main screen with empty/previous session chart
2. User taps "Devices" → scans for and pairs with chest strap
3. User returns to main screen → sees connection status
4. User taps "Start Sleep Session" → app requests location permissions (if needed)
5. App begins tracking heart rate and updates chart in real-time
6. User minimizes app → app continues tracking in background using location services
7. User wakes up and opens app → views complete sleep session data
8. User taps "Stop Sleep Session" → tracking stops, data remains visible
9. Starting a new session clears previous data

## Features

### 1. Main Screen
**Components:**
- Scrollable line chart displaying heart rate (BPM) over time
- Large button: "Start Sleep Session" / "Stop Sleep Session" (toggles)
- Connection status indicator: "Connected to [Device Name]" or "Not Connected"
- Current BPM display (prominent number)
- "Devices" button to access pairing screen

**Behavior:**
- Chart displays entire current/last session data
- Chart is horizontally scrollable if data exceeds screen width
- Y-axis: BPM (40-200 range typical)
- X-axis: Time (HH:MM format)
- Button toggles state when tapped

### 2. Devices/Pairing Screen
**Components:**
- List of discovered Bluetooth heart rate devices
- "Scan" button to search for devices
- Loading indicator during scan
- Selected/connected device highlighted

**Behavior:**
- Scanning discovers BLE devices advertising Heart Rate Service
- Tapping a device initiates connection
- Successful connection returns user to main screen
- Connection persists across app launches (reconnects automatically)

### 3. Heart Rate Monitoring
**Data Source:**
- Bluetooth Low Energy Heart Rate Service (UUID: 0x180D)
- Heart Rate Measurement Characteristic (UUID: 0x2A37)

**Data Handling:**
- Receive heart rate updates (typically every 1 second)
- Store data points in memory: timestamp + BPM value
- Update chart in real-time during active session
- Auto-reconnect if chest strap disconnects

### 4. Background Tracking
**Location Services:**
- Request "Always Allow" location permission
- Start location updates when "Start Sleep Session" tapped
- Use significant location changes or background location updates
- Purpose string: "We need location services to keep tracking your heart rate continuously"

**Background Behavior:**
- App remains active in background during sleep session
- Bluetooth connection to chest strap maintained
- Heart rate data continues to be received and stored
- Stop location updates when "Stop Sleep Session" tapped

### 5. Session Management
**Session Lifecycle:**
- Session starts: Clear previous data, begin collecting new data
- Session active: Collect and display heart rate data
- Session ends: Stop collection, keep data visible
- New session: Clear previous data
- App termination: All data lost (no persistence)

**Data Storage:**
- In-memory only (array of timestamp-BPM pairs)
- No local database or file storage
- Data persists until new session starts or app terminates

## Non-Requirements (Explicitly Out of Scope)
- User authentication/signup
- Data export or sharing
- Persistent storage across app launches
- Multiple device connections
- Heart rate zones or analysis
- Notifications or alerts
- Settings or customization options
- iPad support

## Technical Requirements

### Permissions
- Bluetooth: Required for heart rate monitor connection
- Location (Always): Required for background operation

### Background Modes
- Location updates: To keep app active
- Bluetooth-central: To maintain BLE connection (may not be sufficient alone)

### Info.plist Requirements
```xml
NSBluetoothAlwaysUsageDescription: "We need Bluetooth to connect to your heart rate monitor."
NSLocationAlwaysAndWhenInUseUsageDescription: "We need location services to keep tracking your heart rate continuously"
NSLocationWhenInUseUsageDescription: "We need location services to keep tracking your heart rate continuously"
UIBackgroundModes: ["location", "bluetooth-central"]
```

## UI/UX Principles
- **Minimal**: No unnecessary features or screens
- **Clear**: Connection status always visible
- **Simple**: One-button session control
- **Reliable**: Auto-reconnect, background operation

## Success Criteria
- App maintains Bluetooth connection for 8+ hours while in background
- Heart rate data collected continuously without gaps
- Chart clearly displays sleep session data
- Zero user authentication friction

