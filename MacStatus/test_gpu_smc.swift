import Foundation

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

public class SMCServiceTest {
    private var conn: io_connect_t = 0
    
    init() {
        let dict = IOServiceMatching("AppleSMC")
        var iter: io_iterator_t = 0
        IOServiceGetMatchingServices(kIOMainPortDefault, dict, &iter)
        let smc = IOIteratorNext(iter)
        IOServiceOpen(smc, mach_task_self_, 0, &conn)
    }
    
    private func fourCharToInt(_ str: String) -> UInt32 {
        var value: UInt32 = 0
        let chars = Array(str.utf8)
        for i in 0..<min(4, chars.count) {
            value = (value << 8) | UInt32(chars[i])
        }
        return value
    }
    
    public func readFloat(key: String) -> Double? {
        var inKey = SMCParamStruct()
        inKey.key = fourCharToInt(key)
        inKey.data8 = 9
        var outKey = inKey
        var size = MemoryLayout<SMCParamStruct>.size
        
        var res = IOConnectCallStructMethod(conn, 2, &inKey, size, &outKey, &size)
        if res != kIOReturnSuccess || outKey.kIDataSize == 0 { return nil }
        
        var inVal = SMCParamStruct()
        inVal.key = fourCharToInt(key)
        inVal.kIDataSize = outKey.kIDataSize
        inVal.data8 = 5
        var outVal = inVal
        
        res = IOConnectCallStructMethod(conn, 2, &inVal, size, &outVal, &size)
        if res != kIOReturnSuccess { return nil }
        
        let typeStr = String(bytes: [
            UInt8((outKey.kIDataType >> 24) & 0xFF),
            UInt8((outKey.kIDataType >> 16) & 0xFF),
            UInt8((outKey.kIDataType >> 8) & 0xFF),
            UInt8(outKey.kIDataType & 0xFF)
        ], encoding: .ascii) ?? ""
        
        let b = outVal.bytes
        
        if typeStr == "flt " {
            let arr: [UInt8] = [b.0, b.1, b.2, b.3]
            let floatVal = arr.withUnsafeBytes { $0.load(as: Float.self) }
            return Double(floatVal)
        } else if typeStr == "ui16" || typeStr == "ui8 " {
             return Double(b.0)
        }
        return nil
    }
}

let smc = SMCServiceTest()
let keys: [String] = ["PGRP", "PG0R", "PSTR"]
for key in keys {
    if let val = smc.readFloat(key: key) {
        print("\(key): \(val)")
    } else {
        print("\(key): NOT FOUND or NOT FLOAT")
    }
}
