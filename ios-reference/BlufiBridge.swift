import Foundation
import CoreBluetooth
import React

@objc(BlufiBridge)
public class BlufiBridge: RCTEventEmitter, BlufiDelegate {
    
    var blufiClient: BlufiClient!
    var currId: String?
    
    override init() {
        super.init()
        blufiClient = BlufiClient()
        blufiClient.blufiDelegate = self
        blufiClient.centralManagerDelete = self
    }
    
    private func sendLog(_ message: String) {
        sendEvent(withName: "BlufiLog", body: ["log": message])
    }

    private func sendStatus(_ status: String) {
        sendEvent(withName: "BlufiStatus", body: ["status": status])
    }

    @objc func connect(_ deviceId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // Re-init client to ensure fresh state (Fixes crash on re-connection)
        if (blufiClient != nil) {
            blufiClient.close()
            blufiClient.blufiDelegate = nil
        }
        currId = deviceId
        blufiClient = BlufiClient()
        blufiClient.blufiDelegate = self
        blufiClient.centralManagerDelete = self
        
        sendLog("Connecting to device: \(deviceId)")
        // deviceId on iOS is the UUID string
        blufiClient.connect(deviceId)
        resolve(true)
    }

    @objc func getDeviceId(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        resolve(currId)
    }

    @objc func disconnect() {
        sendLog("Manual disconnect requested")
        currId = nil
        blufiClient.close()
        sendStatus("Disconnected")
    }
    
    @objc func negotiateSecurity(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        blufiClient.negotiateSecurity()
        resolve(true)
    }
    
    @objc func configureWifi(_ ssid: String, password: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let params = BlufiConfigureParams()
        params.opMode = OpModeSta
        params.staSsid = ssid
        params.staPassword = password
        
        sendLog("Configuring WiFi: SSID=\(ssid)")
        blufiClient.configure(params)
        resolve(true)
    }
    
    @objc func postCustomData(_ data: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        sendLog("Posting Custom Data: \(data)")
        if let dataBytes = data.data(using: .utf8) {
            blufiClient.postCustomData(dataBytes)
            resolve(true)
        } else {
            reject("ERR_DATA", "Failed to convert string to bytes", nil)
        }
    }
    
    @objc func requestDeviceWifiScan(_ resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        blufiClient.requestDeviceScan()
        resolve(true)
    }
    
    @objc func setOpMode(_ opMode: Int, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        let params = BlufiConfigureParams()
        // Determine OpMode from integer (1 = STA, 2 = SoftAP, 3 = SoftAP+STA)
        if (opMode == 1) { params.opMode = OpModeSta }
        else if (opMode == 2) { params.opMode = OpModeSoftAP }
        else if (opMode == 3) { params.opMode = OpModeStaSoftAP }
        else { params.opMode = OpModeSta } // Default
        
        blufiClient.configure(params)
        resolve(true)
    }
    
    @objc func requestDeviceVersion() {
        blufiClient.requestDeviceVersion()
    }
    
    @objc func requestDeviceStatus() {
        blufiClient.requestDeviceStatus()
    }
    
    // MARK: - BlufiDelegate
    
    public func blufi(_ client: BlufiClient, gattPrepared status: BlufiStatusCode, service: CBService?, writeChar: CBCharacteristic?, notifyChar: CBCharacteristic?) {
        sendLog("GATT Prepared status: \(status.rawValue)")
        if status == StatusSuccess {
            sendEvent(withName: "BlufiStatus", body: ["status": "Connected", "state": 2])
        } else {
            sendEvent(withName: "BlufiStatus", body: ["status": "Connection Failed", "state": 0])
        }
    }
    
    public func blufi(_ client: BlufiClient, didNegotiateSecurity status: BlufiStatusCode) {
        sendLog("Security negotiation status: \(status.rawValue)")
        sendEvent(withName: "BlufiStatus", body: ["status": "Security Result: \(status.rawValue)"])
    }
    
    public func blufi(_ client: BlufiClient, didPostConfigureParams status: BlufiStatusCode) {
        sendLog("Post configure params status: \(status.rawValue)")
        sendEvent(withName: "BlufiStatus", body: ["status": "Configure Params: \(status.rawValue)"])
    }
    
    public func blufi(_ client: BlufiClient, didReceiveCustomData data: Data, status: BlufiStatusCode) {
        if let dataStr = String(data: data, encoding: .utf8) {
            sendLog("Received Custom Data: \(dataStr)")
            sendEvent(withName: "BlufiData", body: ["data": dataStr])
        }
    }
    
    public func blufi(_ client: BlufiClient, didReceiveDeviceScanResponse scanResults: [BlufiScanResponse]?, status: BlufiStatusCode) {
        DispatchQueue.main.async {
            var data: [[String: Any]] = []
            if let results = scanResults {
                for result in results {
                    data.append(["ssid": result.ssid, "rssi": result.rssi])
                }
            }
            
            // Emit standard event matching Android payload
            self.sendEvent(withName: "BlufiDeviceScanResult", body: ["data": data])
            
            // Also emit status for logging
            self.sendEvent(withName: "BlufiStatus", body: ["status": "Device Scan Result: \(status.rawValue)"])
        }
    }
    
    public func blufi(_ client: BlufiClient, didReceiveDeviceVersionResponse response: BlufiVersionResponse?, status: BlufiStatusCode) {
        if let resp = response {
             // sendEvent(withName: "BlufiStatus", body: ["status": "Device Version: \(resp.versionString ?? "Unknown")"]) 
        }
    }
    
    public func blufi(_ client: BlufiClient, didReceiveDeviceStatusResponse response: BlufiStatusResponse?, status: BlufiStatusCode) {
        if let resp = response {
             sendLog("Device Status Response: \(status.rawValue), OpMode: \(resp.opMode)")
             sendEvent(withName: "BlufiStatus", body: ["status": "Device Status: OpMode \(resp.opMode)"])
        }
    }
    
    public func blufi(_ client: BlufiClient, didPostCustomData data: Data, status: BlufiStatusCode) {
        if let dataStr = String(data: data, encoding: .utf8) {
            sendLog("Post Custom Data (\(dataStr)) status: \(status.rawValue)")
        }
    }
    
    public func blufi(_ client: BlufiClient, didReceiveError errCode: Int) {
        sendLog("Blufi Error: \(errCode)")
        sendEvent(withName: "BlufiStatus", body: ["status": "Error: \(errCode)"])
    }
    
    // MARK: - RCTEventEmitter
    
    public override func supportedEvents() -> [String]! {
        return ["BlufiStatus", "BlufiLog", "BlufiData", "BlufiDeviceScanResult"]
    }
    
    public override static func requiresMainQueueSetup() -> Bool {
        return true
    }
}

extension BlufiBridge: CBCentralManagerDelegate {
    public func centralManagerDidUpdateState(_ central: CBCentralManager) {
        sendLog("Central Manager State: \(central.state.rawValue)")
    }
    
    public func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        sendLog("Peripheral Disconnected: \(peripheral.identifier.uuidString)")
        sendStatus("Disconnected")
    }
}
