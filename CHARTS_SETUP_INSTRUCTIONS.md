# Charts Library Setup Instructions

## Adding DGCharts via Swift Package Manager

To complete Step 3 implementation, you need to add the DGCharts library to your project. Follow these steps:

### Steps to Add the Charts Library:

1. **Open Xcode Project**
   - Open `Cuore Mio.xcodeproj` in Xcode

2. **Access Swift Package Manager**
   - In Xcode, select your project in the Project Navigator (top-left)
   - Select the "Cuore Mio" target
   - Click on the "Package Dependencies" tab

3. **Add Package**
   - Click the "+" button at the bottom of the package list
   - In the search bar (top-right), paste the following URL:
     ```
     https://github.com/danielgindi/Charts.git
     ```
   - Press Enter/Return

4. **Select Version**
   - Under "Dependency Rule", select "Up to Next Major Version"
   - Ensure the version is set to `5.0.0` or later
   - Click "Add Package"

5. **Add to Target**
   - In the package selection window, ensure "DGCharts" is checked
   - Ensure it's being added to the "Cuore Mio" target
   - Click "Add Package"

6. **Verify Installation**
   - The package should now appear in your Project Navigator under "Package Dependencies"
   - Build the project (⌘+B) to ensure there are no errors

### Alternative: Manual Package.swift Configuration

If you prefer to add the package manually, you can add this to your project's Package Dependencies:

```swift
dependencies: [
    .package(url: "https://github.com/danielgindi/Charts.git", from: "5.0.0")
]
```

### Troubleshooting

If you encounter any issues:

1. **Clean Build Folder**: Product → Clean Build Folder (⇧⌘K)
2. **Reset Package Caches**: File → Packages → Reset Package Caches
3. **Update Packages**: File → Packages → Update to Latest Package Versions
4. **Restart Xcode**: Close and reopen Xcode

### What's Already Implemented

The code has been updated to use DGCharts:

✅ `HeartRateDataManager.swift` - Stores heart rate data points in memory
✅ `BluetoothManager.swift` - Subscribes to HR notifications, parses BPM values, implements auto-reconnect
✅ `ViewController.swift` - Integrates LineChartView with real-time updates

### Testing the Implementation

Once the Charts library is added:

1. Build and run the app on your iPhone
2. Tap "Devices" and scan for your heart rate monitor
3. Connect to the device
4. The current BPM should start updating in real-time
5. The chart will display heart rate data over time
6. The chart is horizontally scrollable to view historical data

### Features Implemented

- ✅ Real-time BPM display (large number at top)
- ✅ Scrollable line chart with time on X-axis (HH:MM format)
- ✅ BPM values on Y-axis (40-200 range)
- ✅ Automatic chart updates as new data arrives
- ✅ Auto-reconnect if device disconnects
- ✅ Red gradient line chart with smooth bezier curves
- ✅ Auto-scroll to show latest data (10-minute window)
- ✅ In-memory data storage (up to 8 hours of data)

### Next Steps

After adding the Charts library and testing:

- Step 4: Implement background location services
- Step 5: Add session management
- Step 6: Testing and refinement

For any issues, refer to the DGCharts documentation:
https://github.com/danielgindi/Charts

