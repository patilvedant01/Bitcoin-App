//
//  WebSocketViewModel.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//
import Foundation
import Combine
import UIKit

class TransactionViewModel: ObservableObject {
    @Published var connectionStatus: ConnectionStatus = .disconnected
    @Published var transactions: [Transaction] = []
    @Published var viewState: ViewState = .initial
    
    private let priceService: BitcoinPriceServiceProtocol
    private var webSocketService: WebSocketServiceProtocol
    
    private var cancellables = Set<AnyCancellable>()
    private let maxTransactions = 5
    private let minimumValueUSD = 100.0
    private var currentBTCPrice: Double?
    private var fetchingDataTimer: Timer?
    private var wasConnectedBeforeBackground = false
    private var wasInSuccessStateBeforeBackground = false
    
    init(priceService: BitcoinPriceServiceProtocol,
         webSocketService: WebSocketServiceProtocol) {
        self.priceService = priceService
        self.webSocketService = webSocketService
        setupWebSocketCallbacks()
    }
    
    private func setupWebSocketCallbacks() {
        webSocketService.onConnectionStatusChanged = { [weak self] status in
            DispatchQueue.main.async {
                self?.connectionStatus = status
                switch status {
                case .connected:
                    self?.viewState = .fetchingData
                    self?.startFetchingDataTimer()
                case .disconnected:
                    self?.viewState = .disconnected
                case .connecting:
                    self?.viewState = .connecting
                    break
                }
            }
        }
        
        webSocketService.onTransactionReceived = { [weak self] transactionData in
            self?.processTransaction(transactionData)
        }
        
        webSocketService.onError = { [weak self] error in
            DispatchQueue.main.async {
                self?.stopFetchingDataTimer()
                self?.viewState = .error(error)
            }
        }
    }
    
    func connect() async {
        DispatchQueue.main.async {
            self.viewState = .connecting
        }
        
        do {
            try await fetchInitialBTCPrice()
            await webSocketService.connect()
        } catch let error as AppError {
            DispatchQueue.main.async {
                self.viewState = .error(error)
            }
        } catch {
            DispatchQueue.main.async {
                self.viewState = .error(.unknownError(error))
            }
        }
    }
    
    func disconnect() {
        stopAllServices()
        DispatchQueue.main.async {
            self.transactions.removeAll()
            self.viewState = .disconnected
        }
    }
    
    func clearTransactions() {
        DispatchQueue.main.async {
            self.transactions.removeAll()
            self.viewState = .fetchingData
            self.startFetchingDataTimer()
        }
    }
    
    func retryFetching() {
        DispatchQueue.main.async {
            self.transactions.removeAll()
            self.viewState = .fetchingData
            self.startFetchingDataTimer()
        }
    }
    
    private func startFetchingDataTimer() {
        // Cancel any existing timer
        fetchingDataTimer?.invalidate()
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            
            // Start a 10-second timer to show empty state if no transactions are received
            self.fetchingDataTimer = Timer.scheduledTimer(withTimeInterval: 10.0, repeats: false) { [weak self] _ in
                if self?.viewState == .fetchingData && self?.transactions.isEmpty == true {
                    self?.viewState = .empty
                }
                self?.fetchingDataTimer = nil
            }
        }
    }
    
    private func stopFetchingDataTimer() {
        fetchingDataTimer?.invalidate()
        fetchingDataTimer = nil
    }
    
    private func fetchInitialBTCPrice() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            var cancellable: AnyCancellable?
            
            cancellable = priceService.fetchBitcoinPrice()
                .sink(
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            continuation.resume(throwing: error)
                        }
                        cancellable?.cancel()
                    },
                    receiveValue: { [weak self] price in
                        self?.currentBTCPrice = price
                        continuation.resume(returning: ())
                        cancellable?.cancel()
                    }
                )
        }
    }

    private func processTransaction(_ transactionData: TransactionData) {
        guard let currentBTCPrice = currentBTCPrice else { return }
        let totalValue = transactionData.out.reduce(0) { $0 + $1.value }
        let valueInBTC = Double(totalValue) / 100_000_000.0
        let valueInUSD = valueInBTC * currentBTCPrice
        if valueInUSD > minimumValueUSD {
            let transaction = Transaction(
                hash: transactionData.hash,
                valueInSatoshis: totalValue,
                timestamp: Date(timeIntervalSince1970: TimeInterval(transactionData.time)),
                valueInUSD: valueInUSD
            )
            addTransaction(transaction)
        }
    }
    
    private func addTransaction(_ transaction: Transaction) {
        DispatchQueue.main.async {
            if self.transactions.isEmpty && self.viewState == .fetchingData {
                self.stopFetchingDataTimer()
                self.viewState = .success
            }
            self.transactions.insert(transaction, at: 0)
            if self.transactions.count > self.maxTransactions {
                self.transactions = Array(self.transactions.prefix(self.maxTransactions))
            }
        }
    }
    
    private func stopAllServices() {
        webSocketService.disconnect()
        stopFetchingDataTimer()
        cancellables.removeAll()
    }
}
