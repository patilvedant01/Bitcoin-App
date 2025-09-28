//
//  Untitled.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//
import SwiftUI

struct ConnectionStatusView: View {
    let status: ConnectionStatus
    
    var body: some View {
        HStack {
            Circle()
                .fill(status.color)
                .frame(width: 12, height: 12)
            Text(status.displayText)
                .font(.headline)
                .foregroundColor(status.color)
        }
    }
}
