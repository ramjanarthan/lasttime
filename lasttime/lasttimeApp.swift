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
