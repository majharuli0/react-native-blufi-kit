# 🚀 react-native-blufi-kit

A **robust, self-contained, and portable** solution for integrating Espressif's Blufi (Wi-Fi Provisioning) into React Native applications. 

Designed to solve the build and runtime issues found in unmaintained libraries like `react-native-blufi` (kefudev) and `orbitsystems`.

---

## 🧐 Why this Kit?

If you are trying to implement Espressif Blufi in React Native, you likely faced these issues with existing libraries:
*   ❌ **Build Failures**: Incompatibility with modern Gradle, Android 12+, or iOS 16+.
*   ❌ **Missing Permissions**: Crashes on Android 12+ due to missing `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` permissions.
*   ❌ **Linking Errors**: "Module not found" or null pointer exceptions at runtime.
*   ❌ **Abandoned**: Most libraries haven't been updated in years.

**This Kit Solves It By:**
*   ✅ **Providing Raw Source Code**: No compiled binaries or hidden dependencies. You get the actual Swift and Java files.
*   ✅ **Automated Setup Scripts**: One-command setup for iOS and Android (`npm run setup:ios`, `npm run setup:android`).
*   ✅ **Modern Android Support**: Automatically handles Android 12+ Bluetooth permissions in `AndroidManifest.xml`.
*   ✅ **Modern iOS Support**: Written in Swift with proper `Podspec` and `Info.plist` configuration.
*   ✅ **TypeScript Client**: Includes a ready-to-use `BlufiClient.ts` wrapper.

---

## 📦 Contents

*   `ios-reference/`: Native iOS source files (Swift/Obj-C) and Podspec.
*   `scripts/`: Automation scripts (`setup-ios.js`, `setup-android.js`).

---

## 🚀 Installation Guide

### 1. Copy Files
Copy the `react-native-blufi-kit` folder into your project (e.g., into a `blufi` folder).

```bash
cp -r react-native-blufi-kit /path/to/your/project/blufi
```

### 2. Install Dependencies
This kit uses `react-native-permissions` for runtime permission checks (optional but recommended).

```bash
npm install react-native-permissions
```

### 3. Configure `package.json`
Add the setup scripts to your `package.json`. Adjust the path to where you copied the scripts.

```json
"scripts": {
  "setup:ios": "node blufi/scripts/setup-ios.js",
  "setup:android": "node blufi/scripts/setup-android.js"
}
```

### 4. Run Setup

#### 🍎 iOS Setup
1.  **Prebuild** (if using Expo):
    ```bash
    npx expo prebuild --platform ios
    ```
2.  **Run Script**:
    ```bash
    npm run setup:ios
    ```
    *This copies the Swift/Obj-C files, updates `Podfile`, and adds Bluetooth permissions to `Info.plist`.*
3.  **Install Pods**:
    ```bash
    cd ios && pod install && cd ..
    ```

#### 🤖 Android Setup
1.  **Prebuild** (if using Expo):
    ```bash
    npx expo prebuild --platform android
    ```
2.  **Run Script**:
    ```bash
    npm run setup:android
    ```
    *This generates the Java modules, patches `build.gradle`, and injects required permissions into `AndroidManifest.xml`.*

### 5. Rebuild App (Crucial!)
Since this kit adds native code (Swift/Java), you **must rebuild** your app. Hot reload will not work for the initial setup.

```bash
# iOS
npx expo run:ios

# Android
npx expo run:android
```

---

## 💻 Usage

Since this kit provides direct access to the native modules, you can use them directly in your React Native code.

### 1. Import Native Modules

```typescript
import { NativeModules, NativeEventEmitter, Platform, PermissionsAndroid } from 'react-native';

const { BlufiBridge, BluetoothScannerModule } = NativeModules;

// Create Emitters
const blufiEmitter = BlufiBridge ? new NativeEventEmitter(BlufiBridge) : null;
const scannerEmitter = BluetoothScannerModule ? new NativeEventEmitter(BluetoothScannerModule) : null;
```

### 2. Setup Listeners (useEffect)

It is **critical** to set up listeners to receive status updates, logs, and scan results.

```typescript
useEffect(() => {
  // --- Blufi Listeners ---
  const statusSub = blufiEmitter?.addListener("BlufiStatus", (event) => {
    console.log("Status:", event.status); // "Connected", "Disconnected", or "Security Result: 0"
    if (event.status === "Connected" || event.state === 2) {
      console.log("✅ Device Connected");
    }
  });

  const logSub = blufiEmitter?.addListener("BlufiLog", (event) => {
    console.log("Blufi Log:", event.log);
  });

  const dataSub = blufiEmitter?.addListener("BlufiData", (event) => {
    console.log("Received Data:", event.data);
  });

  // --- Scanner Listeners ---
  const scanSub = scannerEmitter?.addListener("DeviceFound", (device) => {
    console.log("Found Device:", device.name, device.mac, device.rssi);
  });

  const scanErrorSub = scannerEmitter?.addListener("ScanError", (event) => {
    console.error("Scan Error:", event.error);
  });

  return () => {
    statusSub?.remove();
    logSub?.remove();
    dataSub?.remove();
    scanSub?.remove();
    scanErrorSub?.remove();
  };
}, []);
```

### 3. Scanning & Connecting

```typescript
// Start Scan
if (BluetoothScannerModule) {
  BluetoothScannerModule.startScan();
}

// Stop Scan & Connect
async function connect(macAddress: string) {
  BluetoothScannerModule.stopScan();
  try {
    await BlufiBridge.connect(macAddress);
    // Wait for "BlufiStatus" event to confirm connection
  } catch (error) {
    console.error("Connection failed", error);
  }
}
```

### 4. Provisioning (After Connection)

Once you receive the `Connected` status event:

```typescript
// 1. Negotiate Security
await BlufiBridge.negotiateSecurity();

// 2. Configure Wi-Fi
await BlufiBridge.configureWifi("SSID", "PASSWORD");

// 3. Configure MQTT (Custom Data)
// Send IP
await BlufiBridge.postCustomData("1:192.168.1.50");
// Send Port
await BlufiBridge.postCustomData("2:1883");
// Finalize
await BlufiBridge.postCustomData("8:0");
```

---

## 🛠 Troubleshooting

*   **iOS: "Developer Mode disabled"**: Go to Settings > Privacy & Security > Developer Mode on your iPhone and enable it.
*   **iOS: "Module not found"**: Ensure you ran `pod install` inside `ios/` after running the setup script.
*   **Android: "Unable to locate Java Runtime"**: Ensure you have JDK 17 installed (`java -version`).
*   **Android: Build Failures**: Ensure you ran `npx expo prebuild` *before* running `npm run setup:android`.

---

## 🤝 Contributing

We welcome contributions! If you find a bug or want to improve the scripts, please check `CONTRIBUTING.md`.
