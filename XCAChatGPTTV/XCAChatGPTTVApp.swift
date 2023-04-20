//
//  XCAChatGPTTVApp.swift
//  XCAChatGPTTV
//
//  Created by Alfian Losari on 05/02/23.
//

import SwiftUI

@main
struct XCAChatGPTTVApp: App {
    
    @StateObject var vm = ViewModel(api: ChatGPTAPI(apiKey: "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"), enableSpeech: true)
    @FocusState var isTextFieldFocused: Bool
    @FocusState var isBottomButtonFocused: Bool
    
    var body: some Scene {
        WindowGroup {
            VStack {
                Text("XCA ChatGPT").font(.largeTitle)
                HStack(alignment: .top) {
                    ContentView(vm: vm)
                        .focusSection()
                        .cornerRadius(32)
                        .overlay {
                            if vm.messages.isEmpty {
                                Text("Click send to start interacting with ChatGPT")
                                    .multilineTextAlignment(.center)
                                    .font(.headline)
                                    .foregroundColor(Color(UIColor.placeholderText))
                            } else {
                                EmptyView()
                            }
                        }
                    
                    VStack {
                        TextField("Send", text: $vm.inputMessage)
                        .multilineTextAlignment(.center)
                        .frame(width: 176)
                        .focused($isTextFieldFocused)
                        .disabled(vm.isInteractingWithChatGPT)
                        .onSubmit {
                            Task { @MainActor in
                                isBottomButtonFocused = true
                                await vm.sendTapped()                                
                            }
                        }
                        .onChange(of: isTextFieldFocused) { _  in
                            vm.inputMessage = ""
                        }
                        
                        Button("Clear", role: .destructive) {
                            vm.clearMessages()
                        }
                        .frame(width: 176)
                        .disabled(vm.isInteractingWithChatGPT || vm.messages.isEmpty)
                        
                        ProgressView()
                            .progressViewStyle(.circular)
                            .padding()
                            .opacity(vm.isInteractingWithChatGPT ? 1 : 0)

                        Spacer()
                        
                        Button {
                            guard !vm.isInteractingWithChatGPT else { return }
                            vm.scrollingToCommand = .init(type: .top)
                        } label: {
                            Image(systemName: "arrow.up.to.line.compact")
                        }
                        
                        .opacity(vm.isInteractingWithChatGPT ? 0 : 1)
                        .focused($isBottomButtonFocused)
                        
                        Button {
                            guard !vm.isInteractingWithChatGPT else { return }
                            vm.scrollingToCommand = .init(type: .bottom)
                        } label: {
                            Image(systemName: "arrow.down.to.line.compact")
                        }
                        .opacity(vm.isInteractingWithChatGPT ? 0 : 1)
                    }
                    .focusSection()
                }
            }
        }
    }
}

