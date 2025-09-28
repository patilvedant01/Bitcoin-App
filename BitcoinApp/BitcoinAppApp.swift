//
//  BitcoinAppApp.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import SwiftUI

@main
struct BitcoinMonitorApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView(
                viewModel: TransactionViewModel(
                    priceService: BitcoinPriceService(),
                    webSocketService: WebSocketService()
                )
            )
        }
    }
}
