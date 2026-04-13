import Foundation

public struct SMCKeyData_vers_t {
    var major: UInt8 = 0
    var minor: UInt8 = 0
    var build: UInt8 = 0
    var reserved: UInt8 = 0
    var release: UInt16 = 0
}

public struct SMCParamStruct {
    var key: UInt32 = 0
    var vers: SMCKeyData_vers_t = SMCKeyData_vers_t()
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

public class SMCDumper {
    private var conn: io_connect_t = 0
    
    init() {
        let dict = IOServiceMatching("AppleSMC")
        var iter: io_iterator_t = 0
        IOServiceGetMatchingServices(kIOMainPortDefault, dict, &iter)
        let smc = IOIteratorNext(iter)
        IOServiceOpen(smc, mach_task_self_, 0, &conn)
    }
    
    private func intToFourChar(_ val: UInt32) -> String {
        let bytes: [UInt8] = [
            UInt8((val >> 24) & 0xFF),
            UInt8((val >> 16) & 0xFF),
            UInt8((val >> 8) & 0xFF),
            UInt8(val & 0xFF)
        ]
        return String(bytes: bytes, encoding: .ascii) ?? "????"
    }
    
    func dump() {
        var inKey = SMCParamStruct()
        inKey.data8 = 11 // kSMCGetNumKeys
        var outKey = SMCParamStruct()
        var size = MemoryLayout<SMCParamStruct>.size
        let res = IOConnectCallStructMethod(conn, 2, &inKey, size, &outKey, &size)
        if res != kIOReturnSuccess { return }
        
        let numKeys = outKey.data32
        
        for i in 0..<numKeys {
            var inCmd = SMCParamStruct()
            inCmd.data8 = 12 // kSMCReadIndex
            inCmd.data32 = i
            var outCmd = SMCParamStruct()
            var size2 = MemoryLayout<SMCParamStruct>.size
            let r2 = IOConnectCallStructMethod(conn, 2, &inCmd, size2, &outCmd, &size2)
            if r2 == kIOReturnSuccess {
                let name = intToFourChar(outCmd.key)
                let type = intToFourChar(outCmd.kIDataType)
                if name.hasPrefix("PG") || name.hasPrefix("P") {
                    print("\(name): type \(type)")
                }
            }
        }
    }
}

let dumper = SMCDumper()
dumper.dump()
