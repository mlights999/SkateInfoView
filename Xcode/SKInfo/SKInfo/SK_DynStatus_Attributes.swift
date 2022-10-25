//
//  File.swift
//  SKInfo
//
//  Created by Matthew Panizza on 10/1/22.
//

import Foundation
import ActivityKit
import WidgetKit

public struct SkateAttributes: ActivityAttributes {
    public typealias SkateState = ContentState

    public struct ContentState: Codable, Hashable {
        // We dont need dynamic data
    }

    var endDate: Date
}

struct TimerActivityWidget: Widget {
    var body: some WidgetConfiguration {
        ActivityConfiguration(for: TimerAttributes.self) { context in
            // This is the live activity view
                Text(context.attributes.endDate, style: .timer)
                    .padding()
         } dynamicIsland: { context in

            DynamicIsland {
                    // This content will be shown when user expands the island

                DynamicIslandExpandedRegion(.center) {
                        Text(context.attributes.endDate, style: .timer)
                }

            } compactLeading: {
                // When the island is wider than the display cutout
            } compactTrailing: {
               // When the island is wider than the display cutout
                    Image(systemName: "timer")
            } minimal: {
               // This is used when there are multiple activities
                    Image(systemName: "timer")
            }
        }
    }
}
