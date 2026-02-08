# 🚀 react-native-blufi-kit

A **robust, self-contained, and portable** solution for integrating Espressif's Blufi (Wi-Fi Provisioning) into React Native applications.

---

## 📦 Contents

- `ios-reference/`: Native iOS source files (Swift/Obj-C) and Podspec.
- `scripts/`: Automation scripts (`setup-ios.js`, `setup-android.js`).
- `BlufiClient.ts`: TypeScript wrapper for the Native Module.

---

## 🚀 Installation & Setup

### 1. Configure `package.json`

```json
"scripts": {
  "setup:ios": "node blufi/scripts/setup-ios.js",
  "setup:android": "node blufi/scripts/setup-android.js"
}
```

### 2. Run Setup

```bash
# iOS
npm run setup:ios
cd ios && pod install

# Android
npm run setup:android
```

---

## 💻 API Reference

### 1. Importing & Initialization

```typescript
import { NativeModules, NativeEventEmitter } from "react-native";

const { BlufiBridge, BluetoothScannerModule } = NativeModules;

// Emitters for listening to events
const blufiEmitter = BlufiBridge ? new NativeEventEmitter(BlufiBridge) : null;
const scannerEmitter = BluetoothScannerModule
  ? new NativeEventEmitter(BluetoothScannerModule)
  : null;
```

### 2. `BluetoothScannerModule` Methods

Used for finding nearby Blufi-enabled devices.

| Method        | Description                      |
| :------------ | :------------------------------- |
| `startScan()` | Begins scanning for BLE devices. |
| `stopScan()`  | Stops the current scan.          |

**Events (`scannerEmitter`):**

- `DeviceFound`: returns `{ name: string, mac: string, rssi: number }`.
- `ScanError`: returns `{ error: string }`.

---

### 3. `BlufiBridge` Methods

Core methods for security, configuration, and data exchange.

| Method                  | Parameters         | Description                                                                  |
| :---------------------- | :----------------- | :--------------------------------------------------------------------------- |
| `connect`               | `deviceId: string` | Connects to a device via its MAC (Android) or UUID (iOS).                    |
| `disconnect`            | -                  | Closes the connection.                                                       |
| `negotiateSecurity`     | -                  | Establishes a secure session (required before configuring Wi-Fi).            |
| `configureWifi`         | `ssid, password`   | Sends Wi-Fi credentials to the device.                                       |
| `postCustomData`        | `data: string`     | Sends custom strings (e.g., MQTT server: `1:192.168.1.1`).                   |
| `requestDeviceVersion`  | -                  | Triggers a `BlufiLog` response containing the firmware version.              |
| `requestDeviceStatus`   | -                  | Triggers a `BlufiStatus` response with Wi-Fi connection state.               |
| `requestDeviceWifiScan` | -                  | Asks the device to scan for networks (responds via `BlufiDeviceScanResult`). |
| `setOpMode`             | `mode: number`     | Sets ESP32 mode (1: STA, 2: SoftAP, 3: SoftAP+STA).                          |

---

### 4. Event Listeners (`blufiEmitter`)

These listeners are essential for monitoring the provisioning progress.

| Event                       | Field                 | Description                                                          |
| :-------------------------- | :-------------------- | :------------------------------------------------------------------- |
| **`BlufiLog`**              | `log: string`         | Detailed native logs for debugging and progress tracking.            |
| **`BlufiStatus`**           | `status: string`      | High-level status updates (e.g., "Connected", "Security Result: 0"). |
|                             | `state: number`       | `0` (Disconnected), `2` (Connected).                                 |
|                             | `staConnectionStatus` | Wi-Fi result: `0` (Idle), `1` (Connecting), `5` (Success).           |
| **`BlufiData`**             | `data: string`        | Raw custom data received back from the device.                       |
| **`BlufiDeviceScanResult`** | `data: Array`         | List of SSIDs found by the device.                                   |

---

## 🛠 Features & Best Practices

1.  **Unified Log Handler**: Recommended to consolidate `BlufiLog` and `BlufiStatus` into a single UI log stream for easier troubleshooting.
2.  **Auto-Reboot Detection**: Listen for the "Disconnected" log message after sending Wi-Fi credentials; this indicates the device has accepted the configuration and is rebooting.
3.  **Permissions**: On Android 12+, ensure your app requests `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` permissions even if the setup script adds them to the Manifest.
4.  **Security First**: Always call `negotiateSecurity()` immediately after a successful connection before sending Wi-Fi or MQTT data.

---

## 🤝 Support

The system is built on the official Espressif Blufi SDK (v2.2.0). Native source code is available in `ios-reference/` and `android/` folders for full transparency.
