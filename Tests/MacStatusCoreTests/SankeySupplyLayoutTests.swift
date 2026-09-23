import Foundation
import Testing
@testable import MacStatusCore

struct SankeySupplyLayoutTests {
    @Test func smallBatteryContributionRemainsVisible() {
        let layout = SankeySupplyLayout(adapterPower: 31.23, batteryPower: 2.29)
        #expect(layout.sourceHeight <= 140)
        #expect(abs(layout.sourceHeight - layout.systemHeight) <= 12)
        #expect(layout.batteryPortHeight >= 24)
        #expect(layout.adapterPortHeight > layout.batteryPortHeight)
    }

    @Test func sourcePortsStayContiguousAndReadable() {
        for adapter in [0.01, 2.29, 30, 70, 140] {
            for battery in [0.01, 2.29, 30, 70, 140] {
                for sinks in [0.0, 180.0] {
                    let layout = SankeySupplyLayout(adapterPower: adapter, batteryPower: battery, sinksHeight: sinks)
                    #expect(layout.adapterHeight >= 48)
                    #expect(layout.batteryHeight >= 48)
                    #expect(layout.adapterPortHeight >= 24)
                    #expect(layout.batteryPortHeight >= 24)
                    #expect(abs(layout.adapterPortHeight + layout.batteryPortHeight - layout.systemHeight) < 0.001)
                    #expect(layout.systemHeight >= sinks)
                }
            }
        }
    }

    @Test func singleSourceUsesTheWholeSystemPort() {
        for watts in [0.01, 2.29, 33.52, 140] {
            let battery = SankeySupplyLayout(adapterPower: 0, batteryPower: watts)
            #expect(battery.adapterHeight == 0)
            #expect(battery.adapterPortHeight == 0)
            #expect(battery.batteryPortHeight == battery.systemHeight)
            #expect(battery.sourceHeight == battery.systemHeight)
            let adapter = SankeySupplyLayout(adapterPower: watts, batteryPower: 0)
            #expect(adapter.batteryHeight == 0)
            #expect(adapter.batteryPortHeight == 0)
            #expect(adapter.sourceHeight == adapter.systemHeight)
        }
    }
}
