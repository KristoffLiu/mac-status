import Foundation

/// Fixed chart bounds: changing pixel style must never resize the surrounding card.
nonisolated struct MonitorPixelGrid {
    let columns: Int
    let rows: Int
    let size: Double
    let gap: Double
    let separateRows: Bool
    let separateColumns: Bool

    init(width: Double, height: Double, size: Double, gap: Double, grouping: Int) {
        self.size = Self.bounded(size, in: 2...20, fallback: 5)
        self.gap = Self.bounded(gap, in: 0...4, fallback: 1.5)
        separateRows = grouping == 1 || grouping == 3
        separateColumns = grouping == 2 || grouping == 3
        columns = Self.count(length: width, size: self.size, gap: self.gap, grouped: separateColumns)
        rows = Self.count(length: height, size: self.size, gap: self.gap, grouped: separateRows)
    }

    static func bounded(_ value: Double, in range: ClosedRange<Double>, fallback: Double) -> Double {
        value.isFinite ? min(range.upperBound, max(range.lowerBound, value)) : fallback
    }

    private static func count(length: Double, size: Double, gap: Double, grouped: Bool) -> Int {
        guard length.isFinite, length >= size else { return 0 }
        var count = min(2048, Int(min(2048, (length + gap) / (size + gap))))
        while count > 0 && extent(count: count, size: size, gap: gap, grouped: grouped) > length {
            count -= 1
        }
        return count
    }

    private static func extent(count: Int, size: Double, gap: Double, grouped: Bool) -> Double {
        Double(count) * size + Double(max(0, count - 1)) * gap
            + (grouped ? Double(max(0, count - 1) / 4) * gap : 0)
    }

    var width: Double { Self.extent(count: columns, size: size, gap: gap, grouped: separateColumns) }
    var height: Double { Self.extent(count: rows, size: size, gap: gap, grouped: separateRows) }
    func x(_ column: Int) -> Double { Double(column) * (size + gap) + (separateColumns ? Double(column / 4) * gap : 0) }
    func y(_ row: Int) -> Double { Double(row) * (size + gap) + (separateRows ? Double(row / 4) * gap : 0) }
}

nonisolated enum MonitorHistory {
    static func ratio(_ value: Double) -> Double {
        MonitorPixelGrid.bounded(value, in: 0...1, fallback: 0)
    }

    /// All samples share one scale; old points must not retain their former scale.
    static func scale(_ first: [Double], _ second: [Double], minimum: Double) -> Double {
        (first + second).filter { $0.isFinite }.reduce(minimum, max)
    }

    /// Keep the full sample window visible even when pixel size or card width changes.
    /// A bucket retains its peak so brief spikes remain visible.
    static func columns(_ samples: [Double], count: Int, scale: Double = 1) -> [Double] {
        guard count > 0 else { return [] }
        guard !samples.isEmpty, scale.isFinite, scale > 0 else {
            return Array(repeating: 0, count: count)
        }
        return (0..<count).map { column in
            let start = column * samples.count / count
            let end = min(samples.count, max(start + 1, (column + 1) * samples.count / count))
            return samples[start..<end].reduce(0) { max($0, ratio($1 / scale)) }
        }
    }
}
