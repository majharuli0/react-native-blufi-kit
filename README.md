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
*   `BlufiClient.ts`: TypeScript wrapper for the native modules.

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

---

## 💻 Usage

Import `BlufiClient` in your code.

```typescript
import { BlufiClient } from './blufi/BlufiClient'; // Adjust path as needed

// 1. Initialize
const blufi = BlufiClient.getInstance();

// 2. Setup Listeners (Important!)
blufi.onStatusChange((res) => {
  console.log("Connection Status:", res.msg);
  if (res.connected) {
    console.log("✅ Device Connected!");
  }
});

blufi.onLog((log) => console.log("Blufi Log:", log));

// 3. Request Permissions & Scan
async function start() {
  const hasPerms = await blufi.requestPermissions();
  if (!hasPerms) return;

  blufi.startScan((device) => {
    console.log('Found:', device.name, device.mac);
    
    // Stop scanning and connect
    blufi.stopScan();
    connectToDevice(device.mac);
  });
}

// 4. Connect & Provision
async function connectToDevice(mac: string) {
  try {
    // Initiate connection (Wait for onStatusChange for actual connection)
    await blufi.connect(mac);
    
    // Note: You should wait for "Connected" status before negotiating security
    // For simplicity, we show the flow here, but in a real app, trigger these after the status change.
    
    setTimeout(async () => {
        await blufi.negotiateSecurity();
        await blufi.configureWifi('MyWifiSSID', 'MyWifiPassword');
    }, 2000); // Small delay to ensure connection is stable
    
  } catch (error) {
    console.error("Error:", error);
  }
}
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
