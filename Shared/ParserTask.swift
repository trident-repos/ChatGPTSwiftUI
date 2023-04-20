//
//  ParserTask.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 09/04/23.
//

import Foundation
import Markdown

class ParserTask {
    
    var output: AttributedOutput?
    var markdownParser = MarkdownAttributedStringParser()
    
    func parse(text: String, completion: (() -> ())? = nil) {
        Task.detached(priority: .userInitiated) { [weak self] in
            guard let self else { return }
            if let output = self.output, output.string == text {
                return
            }
            
            let document = Document(parsing: text)
            self.output = .init(string: text, results: markdownParser.parserResults(from: document))
            completion?()
        }
    }
    
    func parseAwait(text: String) async -> [ParserResult] {
        let document = Document(parsing: text)
        return markdownParser.parserResults(from: document)
    }
}
