//
//  Transaction.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//
import Foundation

struct Transaction: Identifiable, Codable {
    let id = UUID()
    let hash: String
    let valueInSatoshis: Int64
    let timestamp: Date
    var valueInUSD: Double = 0.0
    
    enum CodingKeys: String, CodingKey {
        case hash, valueInSatoshis = "value", timestamp = "time"
    }
    
    init(hash: String, valueInSatoshis: Int64, timestamp: Date, valueInUSD: Double = 0.0) {
        self.hash = hash
        self.valueInSatoshis = valueInSatoshis
        self.timestamp = timestamp
        self.valueInUSD = valueInUSD
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        hash = try container.decode(String.self, forKey: .hash)
        valueInSatoshis = try container.decode(Int64.self, forKey: .valueInSatoshis)
        let timestampInt = try container.decode(Int.self, forKey: .timestamp)
        timestamp = Date(timeIntervalSince1970: TimeInterval(timestampInt))
    }
}
