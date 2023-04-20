//
//  ViewModel.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 02/02/23.
//

import Foundation
import SwiftUI
import AVKit

enum ScrollingToCommandType: Equatable {
    case none
    case top
    case bottom
}

struct ScrollingToCommand: Equatable {
    let id = UUID()
    let type: ScrollingToCommandType
}

class ViewModel: ObservableObject {
    
    @Published var isInteractingWithChatGPT = false
    @Published var messages: [MessageRow] = []
    @Published var inputMessage: String = ""
    @Published var scrollingToCommand = ScrollingToCommand(type: .none)
    
    #if !os(watchOS)
    private var synthesizer: AVSpeechSynthesizer?
    #endif
    
    private let api: ChatGPTAPI
    
    init(api: ChatGPTAPI, enableSpeech: Bool = false) {
        self.api = api
        if enableSpeech {
            #if !os(watchOS)
            synthesizer = .init()
            #endif
        }
    }
    
    @MainActor
    func sendTapped() async {
        let text = inputMessage
        inputMessage = ""
        await send(text: text)
    }
    
    @MainActor
    func clearMessages() {
        stopSpeaking()
        api.deleteHistoryList()
        withAnimation { [weak self] in
            self?.messages = []
        }
    }
    
    @MainActor
    func retry(message: MessageRow) async {
        guard let index = messages.firstIndex(where: { $0.id == message.id }) else {
            return
        }
        self.messages.remove(at: index)
        await send(text: message.sendText)
    }
    
    @MainActor
    private func send(text: String) async {
        isInteractingWithChatGPT = true
        let parser = ParserTask()
        let send = await parser.parseAwait(text: text)
        
        var streamText = ""
        var messageRow = MessageRow(
            isInteractingWithChatGPT: true,
            sendImage: "profile",
            send: .Attributed(.init(string: text, results: send)),
            responseImage: "openai",
            responseError: nil)
        
        self.messages.append(messageRow)
        
        let parserThresholdTextCount = 64
        do {
            let stream = try await api.sendMessageStream(text: text)
            var parserTextCount = 0
            for try await text in stream {
                streamText += text
                parserTextCount += text.count
                if parserTextCount >= parserThresholdTextCount || text.contains("```") {
                    parser.parse(text: streamText)
                    parserTextCount = 0
                }
                
                if let currentOutput = parser.output, !currentOutput.results.isEmpty {
                    let suffixText = streamText.trimmingPrefix(currentOutput.string)
                    var results = currentOutput.results
                    let lastResult = results[results.count - 1]
                    var lastAttrString = lastResult.attributedString
                    if lastResult.isCodeBlock {
                        
                    #if os(macOS)
                        lastAttrString.append(AttributedString(String(suffixText), attributes: .init([.font: NSFont.preferredFont(forTextStyle: .body).apply(newTraits: .monoSpace), .foregroundColor: NSColor.white])))
                    #else
                        lastAttrString.append(AttributedString(String(suffixText), attributes: .init([.font: UIFont.preferredFont(forTextStyle: .body).apply(newTraits: .traitMonoSpace), .foregroundColor: UIColor.white])))
                    #endif
                    } else {
                        lastAttrString.append(AttributedString(String(suffixText)))
                    }
                    results[results.count - 1] = ParserResult(attributedString: lastAttrString, isCodeBlock: lastResult.isCodeBlock, codeBlockLanguage: lastResult.codeBlockLanguage)
                    messageRow.response = .Attributed(.init(string: streamText, results: results))
                } else {
                    messageRow.response = .Attributed(.init(string: streamText, results: [
                        ParserResult(attributedString: AttributedString(stringLiteral: streamText), isCodeBlock: false, codeBlockLanguage: nil)
                    ]))
                }
                self.messages[self.messages.count - 1] = messageRow
            }
        } catch {
            messageRow.responseError = error.localizedDescription
            messageRow.response = .rawText(streamText)
        }

        func completeResponse(messageRow: inout MessageRow) {
            messageRow.isInteractingWithChatGPT = false
            self.messages[self.messages.count - 1] = messageRow
            self.isInteractingWithChatGPT = false
            self.speakLastResponse()
        }
        
        if let result = parser.output?.string, result != streamText {
            parser.parse(text: streamText) {
                Task { @MainActor [weak self]  in
                    guard self != nil else { return }
                    messageRow.response = .Attributed(.init(string: streamText, results: parser.output?.results ?? []))
                    completeResponse(messageRow: &messageRow)
                }
            }
        } else {
            completeResponse(messageRow: &messageRow)
        }
    }
    
    func speakLastResponse() {
        return
        #if !os(watchOS)
        guard let synthesizer, let responseText = self.messages.last?.responseText, !responseText.isEmpty else {
            return
        }
        stopSpeaking()
        let utterance = AVSpeechUtterance(string: responseText)
        utterance.voice = .init(language: "en-US")
        utterance.rate = 0.5
        utterance.pitchMultiplier = 0.8
        utterance.postUtteranceDelay = 0.2
        synthesizer.speak(utterance )
        #endif
    }
    
    func stopSpeaking() {
        #if !os(watchOS)
        synthesizer?.stopSpeaking(at: .immediate)
        #endif
    }
    
}
