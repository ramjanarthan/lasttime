//
//  lasttimeApp.swift
//  lasttime
//
//  Created by Ram Janarthan on 9/3/26.
//

import SwiftUI

@main
struct lasttimeApp: App {
    let container: AppContainer
    
    init() {
        container = AppContainer()
    }
    
    var body: some Scene {
        MenuBarExtra("LastTime", systemImage: "person.fill.questionmark") {
            if ProcessInfo.processInfo.isTesting {
                Text("Testing")
            } else {
                MenuBarView(container: container)
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
