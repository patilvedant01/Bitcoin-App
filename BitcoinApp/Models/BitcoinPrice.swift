//
//  BitcoinPrice.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import Foundation

struct BitcoinPriceResponse: Codable {
    let bitcoin: BitcoinPrice
}

struct BitcoinPrice: Codable {
    let usd: Double
}
