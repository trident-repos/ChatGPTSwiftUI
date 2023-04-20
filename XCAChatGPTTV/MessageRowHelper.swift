//
//  MessageRowHelper.swift
//  XCAChatGPTTV
//
//  Created by Alfian Losari on 15/04/23.
//

import Foundation
import SwiftUI

struct MessageRowViewHelper {
    static func rowsFor(parserResult: ParserResult) -> [(UUID, AttributedString)] {
        let nsAttributed = NSAttributedString(parserResult.attributedString)
        let rawString = nsAttributed.string
  
        let separated = rawString.components(separatedBy: .newlines)
  
        var rows = [(UUID, AttributedString)]()
        var start = 0
        for separate in separated {
            let range = NSMakeRange(start, separate.count)
            let str = nsAttributed.attributedSubstring(from: range)
            
            if separate == "", parserResult.isCodeBlock {
                rows.append((UUID(), AttributedString(" ")))
            } else {
                rows.append((UUID(), AttributedString(str)))
            }
            start += range.length + "\n".count
        }
        return rows
    }
    
    static func rowsFor(text: String) -> [String] {
        var rows = [String]()
        let maxLinesPerRow = 8
        var currentRowText = ""
        var currentLineSum = 0
        
        for char in text {
            currentRowText += String(char)
            if char == "\n" {
                currentLineSum += 1
            }
            if currentLineSum >= maxLinesPerRow {
                rows.append(currentRowText)
                currentLineSum = 0
                currentRowText = ""
            }
        }
        rows.append(currentRowText)
        return rows
    }
        
}
