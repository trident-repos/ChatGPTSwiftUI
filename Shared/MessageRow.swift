//
//  MessageRow.swift
//  XCAChatGPT
//
//  Created by Alfian Losari on 02/02/23.
//

import SwiftUI

struct AttributedOutput: Sendable {
    var string: String
    var results: [ParserResult]
}

enum MesssageRowType: Sendable {
    case Attributed(AttributedOutput)
    case rawText(String)
    
    
    var text: String {
        switch self {
        case .Attributed(let output):
            return output.string
        case .rawText(let string):
            return string
        }
    }
}

struct MessageRow: Sendable, Identifiable {
    
    let id = UUID()
    
    var isInteractingWithChatGPT: Bool
    
    let sendImage: String
    let send: MesssageRowType
    
    var sendText: String {
        send.text
    }
    
    let responseImage: String
    var response: MesssageRowType?
    
    var responseError: String?
    
    
    var responseText: String? {
        response?.text
    }
    
}


