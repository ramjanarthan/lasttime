//
//  SwiftUIView.swift
//  lasttime
//
//  Created by Ram Janarthan on 14/4/26.
//

import SwiftUI

struct MenuBarView: View {
    @State var viewModel = ViewModel()
    
    var body: some View {
        VStack(alignment: .center) {
            Text(viewModel.userInput?.displayContent ?? "")
                .padding()
                .border(Color.gray)
            Image(systemName: "hourglass")
            Text(viewModel.systemResponse?.displayContent ?? "")
                .padding()
                .border(Color.gray)
        }
        .padding()
        .onAppear {
            Task {
                await viewModel.handleEvent(.onAppear)
            }
        }
        .onDisappear {
            Task {
                await viewModel.handleEvent(.onDisappear)
            }
        }
    }
}

#Preview {
    MenuBarView()
}
