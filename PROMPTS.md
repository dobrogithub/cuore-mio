# AI Agent Prompts for Cuore Mio Implementation

## Instructions
Use these prompts when working with an AI agent to implement each step. Always provide both the PRD and Implementation Steps documents as context, then use the appropriate prompt below.

---

## Step 1 Prompt

```
Based on PRD.md, implement only Step 1 from IMPLEMENTATION_STEPS.md: "Project Setup and Main Screen UI"

Do not implement other steps. Focus only on:
1. Configuring Info.plist with required permissions
2. Creating the main screen UI layout in ViewController.swift
3. Adding all UI elements (chart placeholder, labels, buttons)
4. Implementing button toggle behavior (text only, no functionality)
5. Setting up Auto Layout constraints

The chart should be a placeholder view for now (just a UIView with a background color).
The buttons should not have any real functionality yet, just toggle the text when tapped.

Keep the code minimal and focused only on UI setup.
```

---

## Step 2 Prompt

```
Based on PRD.md, implement only Step 2 from IMPLEMENTATION_STEPS.md: "Bluetooth Device Scanning and Pairing"

Do not implement other steps. Focus only on:
1. Creating DevicesViewController.swift with a table view to list devices
2. Creating BluetoothManager.swift singleton to handle Core Bluetooth
3. Implementing device scanning for Heart Rate Service (0x180D)
4. Implementing device connection when user taps a device
5. Updating the main screen connection status when connected
6. Adding navigation from main screen to Devices screen

Do not implement heart rate data parsing or chart rendering yet.
The BluetoothManager should only scan, connect, and report connection status at this stage.

Keep the code minimal and focused only on device discovery and connection.
```

---

## Step 3 Prompt

```
Based on PRD.md, implement only Step 3 from IMPLEMENTATION_STEPS.md: "Heart Rate Data Reception and Chart Display"

Do not implement other steps. Focus only on:
1. Implementing heart rate data reception in BluetoothManager
2. Parsing BPM values from Heart Rate Measurement Characteristic (0x2A37)
3. Creating HeartRateDataManager.swift to store data points in memory
4. Implementing the scrollable line chart to display heart rate data
5. Updating the current BPM label in real-time
6. Implementing auto-reconnect logic

Use the Charts library (https://github.com/danielgindi/Charts) for the chart implementation.
Add it via Swift Package Manager.

The chart should:
- Show time on X-axis (HH:MM format)
- Show BPM on Y-axis (40-200 range)
- Be horizontally scrollable
- Update in real-time as new data arrives

Keep the code minimal and focused only on data reception and visualization.
```

---

## Step 4 Prompt

```
Based on PRD.md, implement only Step 4 from IMPLEMENTATION_STEPS.md: "Background Location Services"

Do not implement other steps. Focus only on:
1. Creating LocationManager.swift singleton to handle Core Location
2. Requesting "Always Allow" location permission
3. Starting location updates when "Start Sleep Session" is tapped
4. Stopping location updates when "Stop Sleep Session" is tapped
5. Configuring for background operation (allowsBackgroundLocationUpdates = true)

Use the location permission message from PRD.md:
"We need location services to keep tracking your heart rate continuously"

Configure location manager for battery-efficient background operation:
- Use significantLocationChanges or low accuracy continuous updates
- Set allowsBackgroundLocationUpdates = true
- Set pausesLocationUpdatesAutomatically = false

Do not implement full session management yet, just the location service control.

Keep the code minimal and focused only on background location functionality.
```

---

## Step 5 Prompt

```
Based on PRD.md, implement only Step 5 from IMPLEMENTATION_STEPS.md: "Session Management and Data Lifecycle"

Do not implement other steps. Focus only on:
1. Implementing complete session state management
2. Clearing data when a new session starts
3. Keeping data visible after session ends
4. Properly integrating location services with session control
5. Handling app lifecycle (backgrounding/foregrounding)
6. Adding safeguards (require connection, check permissions)

Session start should:
- Clear previous heart rate data
- Start location services
- Update button text to "Stop Sleep Session"

Session stop should:
- Stop location services
- Keep data visible on chart
- Update button text to "Start Sleep Session"

Ensure data is only cleared when:
- A new session starts
- The app is terminated

Keep the code minimal and focused only on session and lifecycle management.
```

---

## Step 6 Prompt

```
Based on PRD.md, implement only Step 6 from IMPLEMENTATION_STEPS.md: "Testing and Refinement"

Do not add new features. Focus only on:
1. Testing all functionality thoroughly
2. Fixing any bugs discovered
3. Refining UI/UX (styling, spacing, colors)
4. Adding loading indicators where helpful
5. Handling edge cases gracefully
6. Optimizing performance if needed

Test these scenarios:
- Device scanning and connection
- Heart rate data reception and chart display
- Background operation (minimize app during session)
- Auto-reconnect on disconnection
- Permission denial handling
- Session start/stop multiple times
- App termination and relaunch

Fix any issues found and ensure the app meets all requirements from PRD.md.

Keep changes focused on polish and bug fixes, not new features.
```

---

## General Guidelines for All Prompts

When providing context to the AI agent, always include:
1. The PRD.md file
2. The IMPLEMENTATION_STEPS.md file
3. The specific step prompt from above
4. The current project files (if continuing from previous steps)

Example context structure:
```
I have a Swift iOS project. Here are the key documents:

[Paste PRD.md contents]

[Paste IMPLEMENTATION_STEPS.md contents]

[Paste current project files if applicable]

Now, [Paste specific step prompt]
```

Remember: Each step should be implemented independently. The AI should focus only on the current step and not jump ahead to future functionality.

