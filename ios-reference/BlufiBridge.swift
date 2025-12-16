import Foundation
import CoreBluetooth
import React

@objc(BlufiBridge)
public class BlufiBridge: RCTEventEmitter, BlufiDelegate {
    
    var blufiClient: BlufiClient!
    var connectedPeripheral: CBPeripheral?
    
    override init() {
        super.init()
        blufiClient = BlufiClient()
        blufiClient.blufiDelegate = self
    }
    
    @objc func connect(_ deviceId: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
        // Re-init client to ensure fresh state (Fixes crash on re-connection)
        if (blufiClient != nil) {
            blufiClient.close()
            blufiClient.blufiDelegate = nil
        }
        blufiClient = BlufiClient()
        blufiClient.blufiDelegate = self
        
        // deviceId on iOS is the UUID string
        blufiClient.connect(deviceId)
        resolve(true)
    }
    
    @objc func disconnect() {
        blufiClient.close()
        sendEvent(withName: "BlufiStatus", body: ["status": "Disconnected", "state": 0])
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
        
        blufiClient.configure(params)
        resolve(true)
    }
    
    @objc func postCustomData(_ data: String, resolve: @escaping RCTPromiseResolveBlock, reject: @escaping RCTPromiseRejectBlock) {
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
        if status == StatusSuccess {
            sendEvent(withName: "BlufiStatus", body: ["status": "Connected", "state": 2])
        } else {
            sendEvent(withName: "BlufiStatus", body: ["status": "Connection Failed", "state": 0])
        }
    }
    
    public func blufi(_ client: BlufiClient, didNegotiateSecurity status: BlufiStatusCode) {
        sendEvent(withName: "BlufiStatus", body: ["status": "Security Result: \(status.rawValue)"])
    }
    
    public func blufi(_ client: BlufiClient, didPostConfigureParams status: BlufiStatusCode) {
        sendEvent(withName: "BlufiStatus", body: ["status": "Configure Params: \(status.rawValue)"])
    }
    
    public func blufi(_ client: BlufiClient, didReceiveCustomData data: Data, status: BlufiStatusCode) {
        if let dataStr = String(data: data, encoding: .utf8) {
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
             sendEvent(withName: "BlufiStatus", body: ["status": "Device Status: OpMode \(resp.opMode)"])
        }
    }
    
    public func blufi(_ client: BlufiClient, didReceiveError errCode: Int) {
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
