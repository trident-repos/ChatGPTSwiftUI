//
//  FocusedAttributedText.swift
//  XCAChatGPTTV
//
//  Created by Alfian Losari on 15/04/23.
//

import SwiftUI

struct FocusedAttributedText: View {
    
    @FocusState var isFocused
    @State var isHighlighted: Bool = false
    @State var higlightOpacity = 0.0
    let attrText: AttributedString
    let shouldFocus: Bool
    
    var body: some View {
        if NSAttributedString(attrText).string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            Text(attrText)
        } else {
            ZStack {
                Text(attrText)
                    .padding(isHighlighted ? 16 : 0)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .overlay {
                RoundedRectangle(cornerRadius: 16)
                    .stroke(.blue, lineWidth: 5)
                    .opacity(higlightOpacity)
                    .opacity(isHighlighted ? 1 : 0)
            }
            .focusable(shouldFocus)
            .focused($isFocused)
            .onChange(of: isFocused) { newValue in
                isHighlighted = newValue
                withAnimation(.linear(duration: 0.7).repeatForever(autoreverses: true)) {
                    higlightOpacity = 1
                }
            }
        }
    }
}
