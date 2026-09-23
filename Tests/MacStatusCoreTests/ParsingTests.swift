import Testing
@testable import MacStatusCore

struct ParsingTests {
    @Test func sensorTypesAndSizesAreValidated() {
        #expect(SMCValueDecoder.decode(bytes: [0, 0, 0x20, 0x42], type: "flt ", size: 4) == 40)
        #expect(SMCValueDecoder.decode(bytes: [0xff, 0x80], type: "sp78", size: 2) == -0.5)
        #expect(SMCValueDecoder.decode(bytes: [1, 0], type: "fpe2", size: 2) == 64)
        #expect(SMCValueDecoder.decode(bytes: [1, 0], type: "ui16", size: 2) == 256)
        #expect(SMCValueDecoder.decode(bytes: [0, 0, 0x80, 0x7f], type: "flt ", size: 4) == nil)
        #expect(SMCValueDecoder.decode(bytes: [0], type: "flt ", size: 4) == nil)
        #expect(SMCValueDecoder.decode(bytes: [0, 0, 0, 0], type: "abcd", size: 4) == nil)
    }
    @Test func processNamesMayContainSpaces() {
        let rows = ProcessOutputParser.cpu(" 123 12.5 /Applications/My Editor.app/Editor\n999 nan bogus\n")
        #expect(rows == [ProcessUsage(pid: 123, name: "/Applications/My Editor.app/Editor", value: 12.5)])
    }
    @Test func energyUsesSecondSampleAndRejectsMissingOutput() {
        let rows = ProcessOutputParser.energy("Processes: first\nPID COMMAND POWER\n1 old 99\nProcesses: second\nPID COMMAND POWER\n42 My Editor 12.5\n")
        #expect(rows == [ProcessUsage(pid: 42, name: "My Editor", value: 12.5)])
        #expect(ProcessOutputParser.energy("Permission denied") == nil)
    }
}
