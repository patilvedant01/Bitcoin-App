//
//  TransactionRowView.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import SwiftUI

// MARK: - Views
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Hash:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(transaction.hash)
                    .font(.caption)
                    .monospaced()
            }
            
            HStack {
                Text("Amount:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text("$\(transaction.valueInUSD, specifier: "%.2f")")
                    .font(.headline)
                    .foregroundColor(.primary)
            }
            
            HStack {
                Text("Time:")
                    .font(.caption)
                    .foregroundColor(.secondary)
                Spacer()
                Text(formatDate(transaction.timestamp))
                    .font(.caption)
                    .monospaced()
            }
        }
        .padding()
        .background(Color(UIColor.systemGray6))
        .cornerRadius(8)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd-MM-yyyy HH:mm:ss '+05:30'"
        formatter.timeZone = TimeZone(identifier: "Asia/Kolkata")
        return formatter.string(from: date)
    }
}

struct TransactionRowView_Preview: PreviewProvider {
    static var previews: some View {
        TransactionRowView(transaction: Transaction(
            hash: "a1075db55d416d3ca199f55b6084e2115b9345e16c5cf302fc80e9d5fbf5d48d",
            valueInSatoshis: 15000000, // 0.15 BTC
            timestamp: Date(),
            valueInUSD: 6500.75
        ))
        .padding()
        .previewLayout(.sizeThatFits)
    }
}
