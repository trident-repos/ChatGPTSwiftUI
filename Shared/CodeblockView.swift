//
//  CodeblockView.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 15/04/23.
//

import SwiftUI
import Markdown

struct CodeblockView: View {
    
    let parserResult: ParserResult
    let isInteractingWithChatGPT: Bool
    @State var isCopied: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                if let codeblockLanguage = parserResult.codeBlockLanguage {
                    Text("\(codeblockLanguage.capitalized)")
                        .font(.headline.monospaced())
                        .foregroundColor(.white)
                } else {
                    Text("</>")
                        .font(.headline.monospaced())
                        .foregroundColor(.white)
                }
                
                Spacer()
                #if os(iOS) || os(macOS)
                button
                #endif
            }
            #if !os(tvOS)
            .padding()
            #else
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
            #endif
            .background(Color(red: 9/255, green: 49/255, blue: 69/255))
                                 
            #if !os(tvOS)
            ScrollView(.horizontal, showsIndicators: true) {
                Text(parserResult.attributedString)
                    .padding(.horizontal, 16)
                    #if os(iOS) || os(macOS)
                    .textSelection(.enabled)
                    #endif
            }
            #else
            ForEach(MessageRowViewHelper.rowsFor(parserResult: parserResult), id: \.0) { result in
                FocusedAttributedText(attrText: result.1, shouldFocus: !isInteractingWithChatGPT)
                    .padding(.horizontal, 32)
            }
            #endif
        }
        .background(HighlighterConstants.color)
        .cornerRadius(8)
    }
    
    var button: some View {
        HStack {
            Spacer()
            if isCopied {
                HStack {
                    Text("Copied")
                        .foregroundColor(.white)
                        .font(.subheadline.monospaced().bold())
                    Image(systemName: "checkmark.circle.fill")
                        .imageScale(.large)
                        .symbolRenderingMode(.multicolor)
                }.frame(alignment: .trailing)
                
            } else {
                Button {
                    let string = String(parserResult.attributedString.characters[...])
                    #if os(iOS)
                    UIPasteboard.general.string = string
                    #elseif os(macOS)
                    NSPasteboard.general.setString(string, forType: .string)
                    #endif
                    withAnimation {
                        isCopied = true
                    }
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                        withAnimation {
                            isCopied = false
                        }
                    }
                } label: {
                    Image(systemName: "doc.on.doc")
                }
                #if os(macOS)
                .buttonStyle(.borderedProminent)
                #else
                .foregroundColor(Color.white)
                #endif
            }
        }
    }
}

struct CodeblockView_Previews: PreviewProvider {
    
    static let codeText = """
    ```swift
    let api = ChatGPTAPI(apiKey: "API_KEY")

    Task {
        do {
            let stream = try await api.sendMessageStream(text: "What is ChatGPT?")
            for try await line in stream {
                print(line)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    ```
    """
    
    static var result: ParserResult {
        var parser = MarkdownAttributedStringParser()
        let document = Document(parsing: codeText)
        let results = parser.parserResults(from: document)
        return results[0]
    }
    
    static var previews: some View {
        CodeblockView(parserResult: result, isInteractingWithChatGPT: false)
            .previewLayout(.sizeThatFits)
    }
}
