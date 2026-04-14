//
//  lasttimeApp.swift
//  lasttime
//
//  Created by Ram Janarthan on 9/3/26.
//

import SwiftUI

@main
struct lasttimeApp: App {
    var body: some Scene {
        MenuBarExtra("LastTime", systemImage: "person.fill.questionmark") {
            if ProcessInfo.processInfo.isTesting {
                Text("Testing")
            } else {
                MenuBarView()
                    .overlay(alignment: .topTrailing) {
                        Button(
                            "Quit",
                            systemImage: "xmark.circle.fill"
                        ) {
                            NSApp.terminate(nil)
                        }
                        .labelStyle(.iconOnly)
                        .buttonStyle(.plain)
                        .padding(6)
                    }
                    .frame(width: 300, height: 180)
            }
        }
        .menuBarExtraStyle(.window)
    }
}

extension ProcessInfo {
    var isTesting: Bool {
        environment["XCTestSessionIdentifier"] != nil
    }
}
