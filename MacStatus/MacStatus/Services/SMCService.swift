import Foundation
import IOKit

nonisolated public struct SMCParamStruct {
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

nonisolated public final class SMCService: @unchecked Sendable {
    // Every connection call and cache access is serialized by this lock.
    private let lock = NSLock()
    public static let shared = SMCService()
    private var conn: io_connect_t = 0
    
    private var reconnectThrottle = MonotonicThrottle()

    private init() {}

    private func openConnection() {
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
        lock.lock()
        defer { lock.unlock() }
        if conn == 0,
           reconnectThrottle.shouldRun(
               now: ProcessInfo.processInfo.systemUptime,
               minimumInterval: 30
           ) {
            openConnection()
        }
        guard conn != 0 else { return nil }
        
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
            if res != kIOReturnSuccess || outKey.result != 0 || outKey.kIDataSize == 0 {
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
            IOServiceClose(conn)
            conn = 0
            keyInfoCache.removeAll()
            return nil
        }
        guard outVal.result == 0 else { return nil }
        
        let typeBytes = (0..<4).map { UInt8((outKey.kIDataType >> ((3 - $0) * 8)) & 0xff) }
        let type = String(bytes: typeBytes, encoding: .ascii) ?? ""
        let bytes = withUnsafeBytes(of: outVal.bytes) { Array($0) }
        return SMCValueDecoder.decode(bytes: bytes, type: type, size: Int(outKey.kIDataSize))
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
