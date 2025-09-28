//
//  TransactionListView.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import SwiftUI

struct TransactionListView: View {
    let transactions: [Transaction]
    let onClearQueue: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Transaction Queue Header
            HStack {
                Text("Recent High-Value Transactions")
                    .font(.title2)
                    .fontWeight(.semibold)
                
                Spacer()
                
                Button("Clear Queue") {
                    onClearQueue()
                }
                .foregroundColor(.red)
                .disabled(transactions.isEmpty)
            }
            .padding(.horizontal)
            .padding(.bottom, 16)
            
            // Transaction List
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(transactions) { transaction in
                        TransactionRowView(transaction: transaction)
                    }
                }
                .padding(.horizontal)
            }
        }
    }
}
