import Foundation
import Metal
import IOKit

func testGPU() {
    print("Testing GPU Utilization via IOKit...")
    let dict = IOServiceMatching("IOAccelerator")
    var iter: io_iterator_t = 0
    IOServiceGetMatchingServices(kIOMainPortDefault, dict, &iter)
    
    defer { IOObjectRelease(iter) }
    
    var service = IOIteratorNext(iter)
    while service != 0 {
        defer { IOObjectRelease(service); service = IOIteratorNext(iter) }
        
        var props: Unmanaged<CFMutableDictionary>?
        IORegistryEntryCreateCFProperties(service, &props, kCFAllocatorDefault, 0)
        
        if let dict = props?.takeRetainedValue() as? [String: Any] {
            if let perfStats = dict["PerformanceStatistics"] as? [String: Any] {
                print("Found PerformanceStatistics!")
                for key in perfStats.keys {
                    print(" - \(key): \(perfStats[key] ?? "nil")")
                }
            }
        }
    }
}

testGPU()
