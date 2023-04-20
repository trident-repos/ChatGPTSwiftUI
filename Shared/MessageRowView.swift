//
//  MessageRowView.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 02/02/23.
//

import SwiftUI

struct MessageRowView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    let message: MessageRow
    let retryCallback: (MessageRow) -> Void
    
    var imageSize: CGSize {
        #if os(iOS) || os(macOS)
        CGSize(width: 25, height: 25)
        #elseif os(watchOS)
        CGSize(width: 20, height: 20)
        #else
        CGSize(width: 80, height: 80)
        #endif
    }
    
    var body: some View {
        VStack(spacing: 0) {
            messageRow(rowType: message.send, image: message.sendImage, bgColor: colorScheme == .light ? .white : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 0.5))
            if let response = message.response {
                Divider()
                messageRow(rowType: response, image: message.responseImage, bgColor: colorScheme == .light ? .gray.opacity(0.1) : Color(red: 52/255, green: 53/255, blue: 65/255, opacity: 1), responseError: message.responseError, showDotLoading: message.isInteractingWithChatGPT)
                Divider()
            }
        }
    }
    
    func messageRow(rowType: MesssageRowType, image: String, bgColor: Color, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        #if os(watchOS)
        VStack(alignment: .leading, spacing: 8) {
            messageRowContent(rowType: rowType, image: image, responseError: responseError, showDotLoading: showDotLoading)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
        #else
        HStack(alignment: .top, spacing: 24) {
            messageRowContent(rowType: rowType, image: image, responseError: responseError, showDotLoading: showDotLoading)
        }
        #if os(tvOS)
        .padding(32)
        #else
        .padding(16)
        #endif
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(bgColor)
        #endif
    }
    
    @ViewBuilder
    func messageRowContent(rowType: MesssageRowType, image: String, responseError: String? = nil, showDotLoading: Bool = false) -> some View {
        if image.hasPrefix("http"), let url = URL(string: image) {
            AsyncImage(url: url) { image in
                image
                    .resizable()
                    .frame(width: imageSize.width, height: imageSize.height)
            } placeholder: {
                ProgressView()
            }

        } else {
            Image(image)
                .resizable()
                .frame(width: imageSize.width, height: imageSize.height)
        }
        
        VStack(alignment: .leading) {
            switch rowType {
            case .Attributed(let output):
                attributedView(results: output.results)
                
            case .rawText(let text):
                if !text.isEmpty {
                    #if os(tvOS)
                    ForEach(MessageRowViewHelper.rowsFor(text: text), id: \.self) { text in
                        Text(text)
                            .focusable(!message.isInteractingWithChatGPT)
                            .multilineTextAlignment(.leading)
                    }
                    #else
                    Text(text)
                        .multilineTextAlignment(.leading)
                        #if os(iOS) || os(macOS)
                        .textSelection(.enabled)
                        #endif
                    #endif
                }
            }
          
            if let error = responseError {
                Text("Error: \(error)")
                    .foregroundColor(.red)
                    .multilineTextAlignment(.leading)
                
                Button("Regenerate response") {
                    retryCallback(message)
                }
                .foregroundColor(.accentColor)
                .padding(.top)
            }
            
            if showDotLoading {
                #if os(tvOS)
                ProgressView()
                    .progressViewStyle(.circular)
                    .padding()
                #else
                DotLoadingView()
                    .frame(width: 60, height: 30)
                #endif
            }
        }
    }
    
    func attributedView(results: [ParserResult]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(results) { parsed in
                if parsed.isCodeBlock {
                    CodeblockView(parserResult: parsed, isInteractingWithChatGPT: message.isInteractingWithChatGPT)
                            .padding(.bottom, 24)
                } else {
                    #if !os(tvOS)
                    Text(parsed.attributedString)
                        #if os(iOS) || os(macOS)
                        .textSelection(.enabled)
                        #endif
                    #else
                    ForEach(MessageRowViewHelper.rowsFor(parserResult: parsed), id: \.0) { result in
                        FocusedAttributedText(attrText: result.1, shouldFocus: !message.isInteractingWithChatGPT)
                    }
                    #endif
                }
            }
        }
    }
}

struct MessageRowView_Previews: PreviewProvider {
    
    static let message = MessageRow(
        isInteractingWithChatGPT: true, sendImage: "profile",
        send: .rawText("What is SwiftUI?"),
        responseImage: "openai",
        response: .rawText("SwiftUI is a user interface framework that allows developers to design and develop user interfaces for iOS, macOS, watchOS, and tvOS applications using Swift, a programming language developed by Apple Inc."))
    
    static let message2 = MessageRow(
        isInteractingWithChatGPT: false, sendImage: "profile",
        send: .rawText("What is SwiftUI?"),
        responseImage: "openai", response: .rawText(""),
        responseError: "ChatGPT is currently not available")
        
    static var previews: some View {
        NavigationStack {
            ScrollView {
                MessageRowView(message: message, retryCallback: { messageRow in
                })
                MessageRowView(message: message2, retryCallback: { messageRow in
                })
            }
            .frame(width: 400)
            .previewLayout(.sizeThatFits)
        }
    }
}
