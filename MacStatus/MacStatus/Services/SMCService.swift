import Foundation
import IOKit

public struct SMCParamStruct {
    var key: UInt32 = 0
    var versMajor: UInt8 = 0
    var versMinor: UInt8 = 0
    var versBuild: UInt8 = 0
    var versResvd: UInt8 = 0
    var versRel: UInt16 = 0
    var pad0: UInt16 = 0
    var pLimVers: UInt16 = 0
    var pLimLen: UInt16 = 0
    var pLimCpu: UInt32 = 0
    var pLimGpu: UInt32 = 0
    var pLimMem: UInt32 = 0
    var kIDataSize: UInt32 = 0
    var kIDataType: UInt32 = 0
    var kIDataAttr: UInt8 = 0
    var pad1: UInt8 = 0
    var pad2: UInt16 = 0
    var result: UInt8 = 0
    var status: UInt8 = 0
    var data8: UInt8 = 0
    var pad3: UInt8 = 0
    var data32: UInt32 = 0
    var bytes: (UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8, UInt8) = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0)
}

public class SMCService {
    public static let shared = SMCService()
    private var conn: io_connect_t = 0
    
    private init() {
        let dict = IOServiceMatching("AppleSMC")
        var iter: io_iterator_t = 0
        let matchRes = IOServiceGetMatchingServices(kIOMainPortDefault, dict, &iter)
        
        guard matchRes == kIOReturnSuccess else {
            print("SMCService: IOServiceGetMatchingServices failed with \(matchRes)")
            return
        }
        
        let smc = IOIteratorNext(iter)
        guard smc != 0 else {
            print("SMCService: IOIteratorNext returned 0! AppleSMC not found in registry.")
            if iter != 0 { IOObjectRelease(iter) }
            return
        }
        
        let openRes = IOServiceOpen(smc, mach_task_self_, 0, &conn)
        if openRes != kIOReturnSuccess {
            print("SMCService: IOServiceOpen failed with kern_return_t: \(openRes)")
        } else {
            print("SMCService: Successfully opened connection \(conn)")
        }
        
        IOObjectRelease(smc)
        if iter != 0 {
            IOObjectRelease(iter)
        }
    }
    
    deinit {
        if conn != 0 {
            IOServiceClose(conn)
        }
    }
    
    private func fourCharToInt(_ str: String) -> UInt32 {
        var value: UInt32 = 0
        let chars = Array(str.utf8)
        for i in 0..<min(4, chars.count) {
            value = (value << 8) | UInt32(chars[i])
        }
        return value
    }
    
    private var keyInfoCache: [UInt32: SMCParamStruct] = [:]
    
    public func readFloat(key: String) -> Double? {
        guard conn != 0 else {
            print("SMCService: Connection is 0!")
            return nil
        }
        
        let keyNumeric = fourCharToInt(key)
        var size = MemoryLayout<SMCParamStruct>.size
        var res: kern_return_t
        var outKey: SMCParamStruct
        
        if let cachedInfo = keyInfoCache[keyNumeric] {
            outKey = cachedInfo
        } else {
            var inKey = SMCParamStruct()
            inKey.key = keyNumeric
            inKey.data8 = 9 // kSMCGetKeyInfo
            outKey = inKey
            
            res = IOConnectCallStructMethod(conn, 2, &inKey, size, &outKey, &size)
            if res != kIOReturnSuccess || outKey.kIDataSize == 0 {
                // Not ideal to print all the time if keys don't exist (e.g. TC0P on some Macs)
                return nil
            }
            keyInfoCache[keyNumeric] = outKey
        }
        
        var inVal = SMCParamStruct()
        inVal.key = keyNumeric
        inVal.kIDataSize = outKey.kIDataSize
        inVal.data8 = 5 // kSMCReadKey
        var outVal = inVal
        
        res = IOConnectCallStructMethod(conn, 2, &inVal, size, &outVal, &size)
        if res != kIOReturnSuccess {
            return nil
        }
        
        // Convert to Float
        let b = outVal.bytes
        let arr: [UInt8] = [b.0, b.1, b.2, b.3]
        let floatVal = arr.withUnsafeBytes { $0.load(as: Float.self) }
        
        return Double(floatVal)
    }
    
    public var systemTotalPower: Double? {
        return readFloat(key: "PSTR")
    }
    
    public var batteryPower: Double? {
        return readFloat(key: "BATP")
    }
    
    public var adapterVoltage: Double? {
        return readFloat(key: "VD0R")
    }
    
    public var adapterCurrent: Double? {
        return readFloat(key: "ID0R")
    }
}
