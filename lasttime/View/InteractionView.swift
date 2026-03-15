//
//  InteractionView.swift
//  lasttime
//
//  Created by Ram Janarthan on 15/3/26.
//

import Foundation
import SwiftUI

struct InteractionView: View {
    @State var viewModel: SpeechToTextViewModel
    
    var body: some View {
        ScrollView {
            VStack(spacing: 4) {
                ForEach(viewModel.interactionContent, id: \.self.id) { item in
                    switch item.type {
                    case .user:
                        Text(item.displayContent)
                            .italic()
                    case .agent:
                        Text(item.displayContent)
                            .bold()
                    case .system:
                        Text(item.displayContent)
                    }
                }
            }
        }
    }
}
