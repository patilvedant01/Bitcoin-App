//
//  ConnectionStatus.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import Foundation
import SwiftUI

enum ConnectionStatus {
    case disconnected
    case connecting
    case connected
    
    var displayText: String {
        switch self {
        case .disconnected: return "Disconnected"
        case .connecting: return "Connecting..."
        case .connected: return "Connected"
        }
    }
    
    var color: Color {
        switch self {
        case .disconnected: return .red
        case .connecting: return .orange
        case .connected: return .green
        }
    }
}
