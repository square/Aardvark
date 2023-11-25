//
//  Copyright 2023 Block, Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Foundation
import MetricKit

@available(iOS 13, *)
@objc(ARKMetricsAttachmentGenerator)
public final class MetricsAttachmentGenerator: NSObject {

    // MARK: - Public Static Methods

    public static func latestMetricsAttachment(metrics: Set<Metric> = Set(Metric.allCases)) -> ARKBugReportAttachment? {
        guard let metricsPayload = MXMetricManager.shared.pastPayloads
            .sorted(by: { $0.timeStampEnd < $1.timeStampEnd })
            .last
        else {
            return nil
        }

        let dateFormatter = ISO8601DateFormatter()

        return ARKBugReportAttachment(
            fileName: "Application Metrics (\(dateFormatter.string(from: metricsPayload.timeStampBegin)) - \(dateFormatter.string(from: metricsPayload.timeStampEnd))).txt",
            data: Data(metricsPayload.attachmentDescription(for: metrics).utf8),
            dataMIMEType: "text/plain"
        )
    }

    public static func allMetricsAttachments(metrics: Set<Metric> = Set(Metric.allCases)) -> [ARKBugReportAttachment] {
        let dateFormatter = ISO8601DateFormatter()

        return MXMetricManager.shared.pastPayloads.map { metricsPayload in
            return ARKBugReportAttachment(
                fileName: "Application Metrics (\(dateFormatter.string(from: metricsPayload.timeStampBegin)) - \(dateFormatter.string(from: metricsPayload.timeStampEnd))).txt",
                data: Data(metricsPayload.attachmentDescription(for: metrics).utf8),
                dataMIMEType: "text/plain"
            )
        }
    }

    // MARK: - Public Types

    public enum Metric: CaseIterable {

        // Metrics for debugging performance

        case applicationExit
        case applicationTime
        case memoryUsage

        // Metrics for debugging responsiveness

        case applicationLaunch
        case applicationResponsiveness
        case animationResponsiveness

        // Metrics for debugging battery usage

        case cpuUsage
        case gpuUsage
        case displayUsage
        case locationActivity

        // Metrics for network data

        case networkActivity
        case cellularConditions

        // Metrics for disk access

        case diskIO

    }

}

// MARK: -

@available(iOS 13, *)
extension MXMetricPayload {

    fileprivate func attachmentDescription(for includedMetrics: Set<MetricsAttachmentGenerator.Metric>) -> String {
        var descriptions: [String] = []

        let dateFormatter = ISO8601DateFormatter()
        descriptions.append(
            """
            Metrics for \(dateFormatter.string(from: timeStampBegin)) to \(dateFormatter.string(from: timeStampEnd))

            App Version: \(latestApplicationVersion)\(includesMultipleApplicationVersions ? " and older versions" : "")
            """
        )

        let measurementFormattter = MeasurementFormatter()
        measurementFormattter.unitStyle = .short

        if #available(iOS 14, *), let metrics = applicationExitMetrics, includedMetrics.contains(.applicationExit) {
            descriptions.append(
                """
                # of Foreground Exits by Reason:
                  Normal:                   \(metrics.foregroundExitData.cumulativeNormalAppExitCount)
                  Abnormal:                 \(metrics.foregroundExitData.cumulativeAbnormalExitCount)
                  App Watchdog:             \(metrics.foregroundExitData.cumulativeAppWatchdogExitCount)
                  Memory Limit:             \(metrics.foregroundExitData.cumulativeMemoryResourceLimitExitCount)
                  Bad Access:               \(metrics.foregroundExitData.cumulativeBadAccessExitCount)
                  Illegal Instruction:      \(metrics.foregroundExitData.cumulativeIllegalInstructionExitCount)

                # of Background Exits by Reason:
                  Normal:                   \(metrics.backgroundExitData.cumulativeNormalAppExitCount)
                  Abnormal:                 \(metrics.backgroundExitData.cumulativeAbnormalExitCount)
                  App Watchdog:             \(metrics.backgroundExitData.cumulativeAppWatchdogExitCount)
                  CPU Limit:                \(metrics.backgroundExitData.cumulativeCPUResourceLimitExitCount)
                  Memory Limit:             \(metrics.backgroundExitData.cumulativeMemoryResourceLimitExitCount)
                  Memory Pressure:          \(metrics.backgroundExitData.cumulativeMemoryPressureExitCount)
                  Suspended w/ Locked File: \(metrics.backgroundExitData.cumulativeSuspendedWithLockedFileExitCount)
                  Bad Access:               \(metrics.backgroundExitData.cumulativeBadAccessExitCount)
                  Illegal Instruction:      \(metrics.backgroundExitData.cumulativeIllegalInstructionExitCount)
                  Background Task Timeout:  \(metrics.backgroundExitData.cumulativeBackgroundTaskAssertionTimeoutExitCount)
                """
            )
        }

        if let metrics = applicationTimeMetrics, includedMetrics.contains(.applicationTime) {
            descriptions.append(
                """
                Cumulative Time by Application State:
                  Foreground:               \(measurementFormattter.string(from: metrics.cumulativeForegroundTime))
                  Background:               \(measurementFormattter.string(from: metrics.cumulativeBackgroundTime))
                  Background Audio:         \(measurementFormattter.string(from: metrics.cumulativeBackgroundAudioTime))
                  Background Location:      \(measurementFormattter.string(from: metrics.cumulativeBackgroundLocationTime))
                """
            )
        }

        if let metrics = memoryMetrics, includedMetrics.contains(.memoryUsage) {
            descriptions.append(
                """
                Average Suspended Memory:   \(measurementFormattter.string(from: metrics.averageSuspendedMemory.averageMeasurement))
                Peak Memory Usage:          \(measurementFormattter.string(from: metrics.peakMemoryUsage))
                """
            )
        }

        if let metrics = applicationLaunchMetrics, includedMetrics.contains(.applicationLaunch) {
            if #available(iOS 15.2, *) {
                descriptions.append(histogramDescription(for: metrics.histogrammedOptimizedTimeToFirstDraw, named: "Optimized Time to First Draw"))
            }
            descriptions.append(histogramDescription(for: metrics.histogrammedTimeToFirstDraw, named: "Time to First Draw"))
            descriptions.append(histogramDescription(for: metrics.histogrammedApplicationResumeTime, named: "Application Resume Time"))
            if #available(iOS 16.0, *) {
                descriptions.append(histogramDescription(for: metrics.histogrammedExtendedLaunch, named: "Extended Launch Time"))
            }
        }

        if let metrics = applicationResponsivenessMetrics, includedMetrics.contains(.applicationResponsiveness) {
            descriptions.append(histogramDescription(for: metrics.histogrammedApplicationHangTime, named: "Application Hang Time"))
        }

        if #available(iOS 14, *), let metrics = animationMetrics, includedMetrics.contains(.animationResponsiveness) {
            descriptions.append(
                """
                Scroll Hitch Time Ratio:    \(measurementFormattter.string(from: metrics.scrollHitchTimeRatio))
                """
            )
        }

        if let metrics = cpuMetrics, includedMetrics.contains(.cpuUsage) {
            descriptions.append(
                """
                Cumulative CPU Time:        \(measurementFormattter.string(from: metrics.cumulativeCPUTime))
                """
            )
        }

        if let metrics = gpuMetrics, includedMetrics.contains(.gpuUsage) {
            descriptions.append(
                """
                Cumulative GPU Time:        \(measurementFormattter.string(from: metrics.cumulativeGPUTime))
                """
            )
        }

        if let averagePixelLuminance = displayMetrics?.averagePixelLuminance, includedMetrics.contains(.displayUsage) {
            descriptions.append(
                """
                Average Pixel Luminance:    \(measurementFormattter.string(from: averagePixelLuminance.averageMeasurement))
                """
            )
        }

        if let metrics = locationActivityMetrics, includedMetrics.contains(.locationActivity) {
            descriptions.append(
                """
                Cumulative Time by Accuracy:
                  Best for Navigation:      \(measurementFormattter.string(from: metrics.cumulativeBestAccuracyForNavigationTime))
                  Best:                     \(measurementFormattter.string(from: metrics.cumulativeBestAccuracyTime))
                  Nearest 10 Meters:        \(measurementFormattter.string(from: metrics.cumulativeNearestTenMetersAccuracyTime))
                  100 Meters:               \(measurementFormattter.string(from: metrics.cumulativeHundredMetersAccuracyTime))
                  1 Kilometer:              \(measurementFormattter.string(from: metrics.cumulativeKilometerAccuracyTime))
                  3 Kilometer:              \(measurementFormattter.string(from: metrics.cumulativeThreeKilometersAccuracyTime))
                """
            )
        }

        if let metrics = networkTransferMetrics, includedMetrics.contains(.networkActivity) {
            descriptions.append(
                """
                Cumulative Cellular Down:   \(measurementFormattter.string(from: metrics.cumulativeCellularDownload))
                Cumulative Cellular Up:     \(measurementFormattter.string(from: metrics.cumulativeCellularUpload))
                Cumulative WiFi Down:       \(measurementFormattter.string(from: metrics.cumulativeWifiDownload))
                Cumulative WiFi Up:         \(measurementFormattter.string(from: metrics.cumulativeWifiUpload))
                """
            )
        }

        if let metrics = cellularConditionMetrics, includedMetrics.contains(.cellularConditions) {
            descriptions.append(histogramDescription(for: metrics.histogrammedCellularConditionTime, named: "Cellular Condition Time"))
        }

        if let metrics = diskIOMetrics, includedMetrics.contains(.diskIO) {
            descriptions.append(
                """
                Cumulative Logical Writes:  \(measurementFormattter.string(from: metrics.cumulativeLogicalWrites))
                """
            )
        }

        return descriptions.joined(separator: "\n\n")
    }

    private func histogramDescription<Unit>(for histogram: MXHistogram<Unit>, named name: String) -> String {
        let valueFormatter = MeasurementFormatter()

        let barsFormatter = NumberFormatter()
        barsFormatter.maximumFractionDigits = 2

        var buckets: [(String, Int)] = []
        for bucket in histogram.bucketEnumerator {
            let bucket = bucket as! MXHistogramBucket<Unit>
            if Unit.self == MXUnitSignalBars.self {
                let bucketStartString = barsFormatter.string(from: NSNumber(value: bucket.bucketStart.value))!
                let bucketEndString = barsFormatter.string(from: NSNumber(value: bucket.bucketEnd.value))!
                buckets.append(
                    (
                        "\(bucketStartString)\(bucket.bucketEnd == bucket.bucketStart ? "" : " - " + bucketEndString) bars",
                        bucket.bucketCount
                    )
                )
            } else {
                buckets.append(
                    (
                        "\(valueFormatter.string(from: bucket.bucketStart)) - \(valueFormatter.string(from: bucket.bucketEnd))",
                        bucket.bucketCount
                    )
                )
            }
        }

        let longestBucketLabelLength = buckets.reduce(22, { max($0, $1.0.count) })

        var description = "\(name):"
        for bucket in buckets {
            description.append("\n  \(bucket.0)")
            description.append(String(repeating: " ", count: longestBucketLabelLength + 4 - bucket.0.count))
            description.append("\(bucket.1)")
        }
        if buckets.isEmpty {
            description.append("\n  (no data available)")
        }
        return description
    }

}
