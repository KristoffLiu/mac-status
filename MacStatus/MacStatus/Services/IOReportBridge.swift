import Foundation

// MARK: - IOReport Private API Bridge (Runtime Loading)
// We use dlopen/dlsym to avoid linker errors with private libraries.

class IOReportReader {
    private typealias IOReportCopyChannelsInGroupFunc = @convention(c) (CFString?, CFString?, Int32, Int64, Int32) -> CFDictionary?
    private typealias IOReportCreateSamplesFunc = @convention(c) (CFDictionary, Int32, Int32) -> CFDictionary?
    private typealias IOReportCreateSamplesDeltaFunc = @convention(c) (CFDictionary, CFDictionary, Int32) -> CFDictionary?
    private typealias IOReportIterateFunc = @convention(c) (CFDictionary, @convention(block) (CFDictionary) -> Int32) -> Int32
    private typealias IOReportChannelGetChannelNameFunc = @convention(c) (CFDictionary) -> CFString?
    private typealias IOReportSimpleGetIntegerValueFunc = @convention(c) (CFDictionary, Int32) -> Int64

    private var _IOReportCopyChannelsInGroup: IOReportCopyChannelsInGroupFunc?
    private var _IOReportCreateSamples: IOReportCreateSamplesFunc?
    private var _IOReportCreateSamplesDelta: IOReportCreateSamplesDeltaFunc?
    private var _IOReportIterate: IOReportIterateFunc?
    private var _IOReportChannelGetChannelName: IOReportChannelGetChannelNameFunc?
    private var _IOReportSimpleGetIntegerValue: IOReportSimpleGetIntegerValueFunc?

    private var previousSamples: CFDictionary?
    private var handle: UnsafeMutableRawPointer?

    init() {
        // Load the private library at runtime
        handle = dlopen("/usr/lib/libIOReport.dylib", RTLD_NOW)
        if let handle = handle {
            _IOReportCopyChannelsInGroup = unsafeBitCast(dlsym(handle, "IOReportCopyChannelsInGroup"), to: IOReportCopyChannelsInGroupFunc.self)
            _IOReportCreateSamples = unsafeBitCast(dlsym(handle, "IOReportCreateSamples"), to: IOReportCreateSamplesFunc.self)
            _IOReportCreateSamplesDelta = unsafeBitCast(dlsym(handle, "IOReportCreateSamplesDelta"), to: IOReportCreateSamplesDeltaFunc.self)
            _IOReportIterate = unsafeBitCast(dlsym(handle, "IOReportIterate"), to: IOReportIterateFunc.self)
            _IOReportChannelGetChannelName = unsafeBitCast(dlsym(handle, "IOReportChannelGetChannelName"), to: IOReportChannelGetChannelNameFunc.self)
            _IOReportSimpleGetIntegerValue = unsafeBitCast(dlsym(handle, "IOReportSimpleGetIntegerValue"), to: IOReportSimpleGetIntegerValueFunc.self)
        } else {
            print("Failed to load libIOReport.dylib")
        }
    }

    deinit {
        if let handle = handle {
            dlclose(handle)
        }
    }

    func getPowerDeltas(group: String, subgroup: String?, pollInterval: TimeInterval) -> [String: Double] {
        guard let copyChannels = _IOReportCopyChannelsInGroup,
              let createSamples = _IOReportCreateSamples,
              let createDelta = _IOReportCreateSamplesDelta,
              let iterate = _IOReportIterate,
              let getName = _IOReportChannelGetChannelName,
              let getInt = _IOReportSimpleGetIntegerValue else {
            return [:]
        }

        guard let channels = copyChannels(group as CFString, subgroup as CFString?, 0, 0, 0) else {
            return [:]
        }
        
        guard let currentSamples = createSamples(channels, 0, 0) else {
            return [:]
        }
        
        defer { previousSamples = currentSamples }
        
        guard let prev = previousSamples else {
            return [:] // Need two samples to calculate delta
        }
        
        guard let delta = createDelta(prev, currentSamples, 0) else {
            return [:]
        }
        
        var results: [String: Double] = [:]
        
        _ = iterate(delta) { sample -> Int32 in
            if let name = getName(sample) as String? {
                let value = getInt(sample, 0)
                // Energy in nJ / 1e9 = J. J / interval = W.
                let wattage = (Double(value) / 1_000_000_000.0) / pollInterval
                results[name] = wattage
            }
            return 0
        }
        
        return results
    }
}
