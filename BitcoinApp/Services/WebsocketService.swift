//
//  WebsocketService.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import Foundation
import Combine

protocol WebSocketServiceProtocol {
    var connectionStatus: ConnectionStatus { get }
    var onConnectionStatusChanged: ((ConnectionStatus) -> Void)? { get set }
    var onTransactionReceived: ((TransactionData) -> Void)? { get set }
    var onError: ((AppError) -> Void)? { get set }
    
    func connect() async
    func disconnect()
}

class WebSocketService: NSObject, WebSocketServiceProtocol {
    private var webSocketTask: URLSessionWebSocketTask?
    private let session: URLSession
    var onError: ((AppError) -> Void)?
    
    @Published private(set) var connectionStatus: ConnectionStatus = .disconnected
    var onConnectionStatusChanged: ((ConnectionStatus) -> Void)?
    var onTransactionReceived: ((TransactionData) -> Void)?
    
    private var isManualDisconnect = false
    private var cancellables = Set<AnyCancellable>()
    private static let defaultWebSocketURLString = "wss://ws.blockchain.info/inv"
    
    init(session: URLSession = URLSession.shared) {
        self.session = session
        super.init()
        
        // Observe connection status changes and notify via callback
        $connectionStatus
            .sink { [weak self] status in
                self?.onConnectionStatusChanged?(status)
            }
            .store(in: &cancellables)
    }

    private func getValidWebSocketURL() throws -> URL {
        guard let url = URL(string: Self.defaultWebSocketURLString) else {
            let error = AppError.urlConfigurationError("WebSocket Service is unavailable")
            onError?(error)
            throw error
        }
        return url
    }
    
    func connect() async {
        guard connectionStatus != .connected else {
            return 
        }
        
        do {
            let validURL = try getValidWebSocketURL()
            connectionStatus = .connecting
            webSocketTask = session.webSocketTask(with: validURL)
            webSocketTask?.resume()
        } catch {
            connectionStatus = .disconnected
            return
        }
        
        let subscribeMessage = ["op": "unconfirmed_sub"]
        guard let messageData = try? JSONSerialization.data(withJSONObject: subscribeMessage),
              let messageString = String(data: messageData, encoding: .utf8) else {
            connectionStatus = .disconnected
            onError?(.webSocketConnectionFailed)
            return
        }
        
        webSocketTask?.send(.string(messageString)) { [weak self] error in
            if error != nil {
                self?.connectionStatus = .disconnected
                self?.onError?(.webSocketConnectionFailed)
            } else {
                self?.connectionStatus = .connected
                self?.receiveMessages()
            }
        }
    }
    
    func disconnect() {
        isManualDisconnect = true
        webSocketTask?.cancel(with: .normalClosure, reason: nil)
        webSocketTask = nil
        connectionStatus = .disconnected
    }
    
    private func isNetworkAvailable() async -> Bool {
        do {
            guard let url = URL(string: "https://www.apple.com") else {
                return false
            }
            let (_, response) = try await session.data(from: url)
            if let httpResponse = response as? HTTPURLResponse {
                return httpResponse.statusCode == 200
            }
            return false
        } catch {
            return false
        }
    }
    
    private func receiveMessages() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                self?.handleMessage(message)
                self?.receiveMessages()
            case .failure(let error):
                let isManualDisconnect = self?.isManualDisconnect ?? false
                if isManualDisconnect {
                    self?.connectionStatus = .disconnected
                    self?.isManualDisconnect = false
                } else {
                    self?.onError?(.serverError(error.localizedDescription))
                }
            }
        }
    }
    
    private func handleMessage(_ message: URLSessionWebSocketTask.Message) {
        guard case .string(let text) = message,
              let data = text.data(using: .utf8) else {
            return 
        }
        
        do {
            let wsMessage = try JSONDecoder().decode(WebSocketMessage.self, from: data)
            
            if wsMessage.op == "utx", let transactionData = wsMessage.x {
                self.onTransactionReceived?(transactionData)
            }
        } catch {
            onError?(.unknownError(error))
        }
    }
}
