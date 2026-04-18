//
//  lasttimeApp.swift
//  lasttime
//
//  Created by Ram Janarthan on 9/3/26.
//

import SwiftUI

@main
struct lasttimeApp: App {
    @NSApplicationDelegateAdaptor private var appDelegate: MyAppDelegate
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        MenuBarExtra("LastTime", systemImage: "person.fill.questionmark") {
            if ProcessInfo.processInfo.isTesting {
                Text("Testing")
            } else {
                MenuBarView()
            }
        }
        .menuBarExtraStyle(.window)
        .onChange(of: scenePhase, { oldValue, newValue in
            print("Old value2: \(oldValue) & New value: \(newValue)")
        })
    }
}

extension ProcessInfo {
    var isTesting: Bool {
        environment["XCTestSessionIdentifier"] != nil
    }
}
