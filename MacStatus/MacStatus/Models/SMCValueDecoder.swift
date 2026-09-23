import Foundation

nonisolated enum SMCValueDecoder {
    /// SMC numeric types have explicit sizes; unknown types must not become plausible watts.
    static func decode(bytes: [UInt8], type: String, size: Int) -> Double? {
        guard size > 0, bytes.count >= size else { return nil }
        let value: Double
        switch (type, size) {
        case ("flt ", 4):
            let bits = UInt32(bytes[0]) | UInt32(bytes[1]) << 8 | UInt32(bytes[2]) << 16 | UInt32(bytes[3]) << 24
            value = Double(Float(bitPattern: bits))
        case ("sp78", 2):
            value = Double(Int16(bitPattern: UInt16(bytes[0]) << 8 | UInt16(bytes[1]))) / 256
        case ("fpe2", 2):
            value = Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1])) / 4
        case ("ui8 ", 1): value = Double(bytes[0])
        case ("ui16", 2): value = Double(UInt16(bytes[0]) << 8 | UInt16(bytes[1]))
        case ("ui32", 4):
            value = Double(UInt32(bytes[0]) << 24 | UInt32(bytes[1]) << 16 | UInt32(bytes[2]) << 8 | UInt32(bytes[3]))
        default: return nil
        }
        return value.isFinite ? value : nil
    }
}
