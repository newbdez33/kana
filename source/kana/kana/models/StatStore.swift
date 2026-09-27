//
//  StatStore.swift
//  kana
//
//  Answer-time statistics, kept as a small JSON file in Application Support.
//  Only answers given within the time limit (cost > 0) are counted.
//

import Foundation

struct StatSummary: Codable {
    var totalCount: Int = 0
    var totalCost: Double = 0
    var recentCosts: [Double] = []
}

final class StatStore {

    static let shared = StatStore()

    private let fileURL: URL
    private var summary: StatSummary

    init(fileURL: URL? = nil) {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        self.fileURL = fileURL ?? directory.appendingPathComponent("stats.json")
        if let data = try? Data(contentsOf: self.fileURL),
           let saved = try? JSONDecoder().decode(StatSummary.self, from: data) {
            summary = saved
        } else {
            summary = StatSummary()
        }
    }

    func add(cost: Double, isCorrect: Bool) {
        guard cost > 0 else { return }
        summary.totalCount += 1
        summary.totalCost += cost
        summary.recentCosts.append(cost)
        if summary.recentCosts.count > AppConfig.statisticsLastCount {
            summary.recentCosts.removeFirst(summary.recentCosts.count - AppConfig.statisticsLastCount)
        }
        save()
    }

    var totalCount: Int {
        return summary.totalCount
    }

    var totalAvgTime: Double {
        guard summary.totalCount > 0 else { return 0 }
        return summary.totalCost / Double(summary.totalCount)
    }

    var lastAvgTime: Double {
        guard !summary.recentCosts.isEmpty else { return 0 }
        return summary.recentCosts.reduce(0, +) / Double(summary.recentCosts.count)
    }

    private func save() {
        do {
            try FileManager.default.createDirectory(at: fileURL.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(summary)
            try data.write(to: fileURL, options: .atomic)
        } catch {
            // Statistics are best effort; losing one record is acceptable.
        }
    }
}
