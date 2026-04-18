//
//  MyAppDelegate.swift
//  lasttime
//
//  Created by Ram Janarthan on 17/4/26.
//

import Foundation
import SwiftUI

class MyAppDelegate: NSObject, NSApplicationDelegate, ObservableObject {
    weak var transcriptionManager: TranscriptionManager?
    
    func applicationWillTerminate(_ notification: Notification) {
//        transcriptionManager?.stopTranscription()
        print("Goodbye!")
    }
}
