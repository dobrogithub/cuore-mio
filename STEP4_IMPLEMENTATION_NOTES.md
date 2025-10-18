# Step 4 Implementation: Background Location Services

## Summary
Implemented background location services to keep the app active while in the background during sleep tracking sessions.

## Files Created
- **LocationManager.swift**: Singleton class that manages Core Location services

## Files Modified
- **ViewController.swift**: 
  - Added `import CoreLocation`
  - Added `LocationManager.shared` reference
  - Updated `sessionButtonTapped()` to start/stop location tracking

## Implementation Details

### LocationManager.swift
The singleton class provides:

1. **Battery-Efficient Configuration**:
   - Uses `kCLLocationAccuracyThreeKilometers` for low accuracy
   - Monitors significant location changes instead of continuous updates
   - Sets `allowsBackgroundLocationUpdates = true`
   - Sets `pausesLocationUpdatesAutomatically = false`

2. **Permission Handling**:
   - Requests "Always Allow" location permission
   - Handles all authorization states (.notDetermined, .authorizedAlways, .authorizedWhenInUse, .denied, .restricted)
   - Shows alert with "Open Settings" option if permission is denied
   - Automatically upgrades from "When In Use" to "Always Allow" if needed

3. **Public Methods**:
   - `startTracking()`: Starts location updates for background operation
   - `stopTracking()`: Stops location updates

4. **CLLocationManagerDelegate**:
   - Handles authorization changes
   - Logs location updates (for debugging)
   - Handles location errors

### ViewController Integration
- Location tracking starts when "Start Sleep Session" is tapped
- Location tracking stops when "Stop Sleep Session" is tapped
- Minimal integration: just 4 lines added to the session button handler

## Permission Messages (Already in Info.plist)
- `NSLocationAlwaysAndWhenInUseUsageDescription`: "We need location services to keep tracking your heart rate continuously"
- `NSLocationWhenInUseUsageDescription`: "We need location services to keep tracking your heart rate continuously"
- `UIBackgroundModes`: ["location", "bluetooth-central"]

## iOS Location Permission Flow (Two-Step Process)
iOS requires a specific two-step flow for location permissions:

**Step 1**: Request "When In Use" permission
- When status is `.notDetermined`, call `requestWhenInUseAuthorization()`
- User sees dialog: "Allow While Using App" / "Don't Allow"

**Step 2**: Request "Always" permission upgrade
- After "When In Use" is granted, start location tracking
- Then call `requestAlwaysAuthorization()` 
- User sees dialog: "Change to Always Allow" / "Keep While Using App" / "Don't Allow"

The LocationManager implements this flow automatically:
1. First session start → Requests "When In Use"
2. After granting "When In Use" → Auto-requests "Always" upgrade (with 1-second delay)
3. Tracking works immediately with "When In Use", but needs "Always" for true background operation

## Testing Notes
To test background operation:
1. Start a session (will request "When In Use" permission first)
2. Grant "When In Use" permission
3. Wait 1 second - will automatically request "Always" permission upgrade
4. Grant "Always Allow" permission (or select "Change to Always Allow")
5. Minimize the app
6. Check Xcode console for location update logs
7. Verify Bluetooth connection remains active

## Next Steps
Step 5 will implement full session management including:
- Clearing data on new session start
- Managing session state across app lifecycle
- Device connection requirements before session start

