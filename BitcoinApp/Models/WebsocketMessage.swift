//
//  WebsocketMessage.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import Foundation

struct WebSocketMessage: Codable {
    let op: String
    let x: TransactionData?
}

struct TransactionData: Codable {
    let hash: String
    let time: Int
    let out: [TransactionOutput]
}

struct TransactionOutput: Codable {
    let value: Int64
}
