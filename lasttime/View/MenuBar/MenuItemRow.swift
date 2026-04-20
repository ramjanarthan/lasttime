//
//  MenuItemRow.swift
//  lasttime
//
//  Created by Ram Janarthan on 20/4/26.
//

import SwiftUI

struct MenuItemRow: View {
    let title: String
    let shortcut: String?
    let action: () -> Void

    @State private var isHovering = false

    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Text(title)
                    .foregroundStyle(.primary)

                Spacer(minLength: 12)

                if let shortcut {
                    Text(shortcut)
                        .foregroundStyle(.secondary)
                }
            }
            .font(.system(size: 13))
            .padding(8)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(isHovering ? Color.accentColor.opacity(0.18) : Color.clear)
            )
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .onHover { hovering in
            isHovering = hovering
        }
    }
}
