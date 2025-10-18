# HealthKit Integration Summary

## Overview
Apple Health (HealthKit) integration has been successfully added to Cuore Mio. The app now automatically saves all collected heart rate data to the Health app.

## What Was Added

### 1. New Files Created
- **`HealthKitManager.swift`**: Manages all HealthKit operations including:
  - Authorization requests
  - Saving individual heart rate samples
  - Batch saving multiple samples
  - Checking authorization status

### 2. Updated Files

#### `Info.plist`
Added HealthKit privacy descriptions:
- `NSHealthShareUsageDescription`: "We need access to save your heart rate data to Apple Health."
- `NSHealthUpdateUsageDescription`: "We need access to save your heart rate data to Apple Health."

#### `Cuore Mio.entitlements`
Created entitlements file with HealthKit capability enabled.

#### `project.pbxproj`
Updated build settings to include the entitlements file in both Debug and Release configurations.

#### `ViewController.swift`
- Imported HealthKit framework
- Added reference to `HealthKitManager`
- Added `setupHealthKit()` method that requests authorization on app launch

#### `HeartRateDataManager.swift`
- Imported HealthKit framework
- Modified `addDataPoint()` to automatically save each heart rate reading to HealthKit

## How It Works

### Authorization Flow
1. When the app launches, it requests HealthKit authorization
2. User is prompted to allow the app to write heart rate data to Health
3. Authorization is requested only once; subsequent launches use the stored preference

### Automatic Data Syncing
- **Real-time saving**: Every heart rate reading received from the chest strap is automatically saved to HealthKit
- **Timestamp preserved**: Each reading is saved with its original timestamp
- **Background operation**: Data continues to be saved to HealthKit even when the app is in the background

### Data Format
- Heart rate samples are saved as `HKQuantitySample` objects
- Unit: BPM (beats per minute)
- Each sample has a timestamp matching when the reading was received
- Data appears in the Health app under "Heart Rate"

## Testing the Integration

### 1. First Launch
1. Open the app
2. You should see a HealthKit permission prompt asking to allow heart rate data writing
3. Tap "Allow" to grant permission

### 2. During a Session
1. Connect to your heart rate monitor
2. Start a sleep session
3. Heart rate data will be automatically saved to HealthKit in real-time

### 3. Verify in Health App
1. Open the Health app on your iPhone
2. Navigate to Browse → Heart → Heart Rate
3. You should see your heart rate data from Cuore Mio sessions
4. Data points will show with the "Cuore Mio" source label

## Permission States

The app handles three HealthKit permission states:

1. **Not Determined**: User hasn't been asked yet → Authorization prompt shown
2. **Sharing Authorized**: User granted permission → Data is saved normally
3. **Sharing Denied**: User denied permission → Data is not saved to HealthKit (but still collected in-app)

## Privacy Considerations

- The app only **writes** heart rate data to HealthKit (no reading)
- Users can revoke HealthKit permission at any time via Settings → Privacy → Health → Cuore Mio
- If permission is revoked, the app continues to function normally but won't save to HealthKit

## Error Handling

The integration includes comprehensive error handling:
- Checks if HealthKit is available (not available on iPad)
- Verifies authorization status before saving
- Logs success/failure of each save operation
- Gracefully handles permission denial

## Developer Notes

### HealthKit Availability
- HealthKit is only available on iPhone (not iPad)
- The code checks availability before making any HealthKit calls
- On unsupported devices, the feature is silently disabled

### Performance
- Each heart rate sample is saved individually as it arrives
- Saves are performed asynchronously (non-blocking)
- Minimal impact on app performance

### Future Enhancements (Optional)
If you want to extend this feature, you could:
1. Add batch saving at session end instead of real-time saving
2. Add a UI indicator showing HealthKit sync status
3. Add retry logic for failed saves
4. Allow users to toggle HealthKit syncing on/off
5. Add export of historical sessions to HealthKit

## Build Instructions

To enable HealthKit in Xcode:
1. Open the project in Xcode
2. Select the "Cuore Mio" target
3. Go to "Signing & Capabilities" tab
4. HealthKit should already be enabled (via the entitlements file)
5. If not, click "+ Capability" and add "HealthKit"

## Troubleshooting

### "No such module 'HealthKit'" error
- Clean the build folder (Product → Clean Build Folder)
- Rebuild the project

### Data not appearing in Health app
- Check that HealthKit permission was granted
- Check console logs for save errors
- Verify the Health app is showing data from "All Sources"

### Permission prompt not showing
- Delete and reinstall the app to reset HealthKit permissions
- Check that Info.plist contains the health usage descriptions

## Summary

HealthKit integration is now fully functional! Every heart rate reading collected during a sleep session will automatically be saved to Apple Health, allowing users to:
- View all their heart rate data in one place
- Share data with healthcare providers
- Use data in other health apps
- Build long-term health trends

The integration works seamlessly in the background without requiring any user interaction beyond the initial permission grant.

