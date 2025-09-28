import SwiftUI
import Foundation
import Combine

enum ViewState: Equatable {
    case initial
    case connecting
    case fetchingData
    case success
    case empty
    case disconnected
    case error(AppError)
    
    static func == (lhs: ViewState, rhs: ViewState) -> Bool {
        switch (lhs, rhs) {
        case (.initial, .initial), (.connecting, .connecting), (.fetchingData, .fetchingData), (.success, .success), (.empty, .empty), (.disconnected, .disconnected):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

enum AppError: LocalizedError, Equatable {
    case serverError(String)
    case webSocketConnectionFailed
    case urlConfigurationError(String)
    case unknownError(Error)
    
    var errorDescription: String? {
        switch self {
        case .serverError(let message):
            return "Server Error: \(message)"
        case .webSocketConnectionFailed:
            return "Failed to Connect to Bitcoin Network"
        case .urlConfigurationError(let service):
            return service
        case .unknownError(let error):
            return "Something went wrong: \(error.localizedDescription)"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .serverError:
            return "We're experiencing server issues. Please try again later."
        case .webSocketConnectionFailed:
            return "Unable to connect to Bitcoin network. Please try again."
        case .urlConfigurationError:
            return "There's a configuration issue with the app. Please restart the app or contact support."
        case .unknownError:
            return "Please try again or contact support if the problem persists."
        }
    }
    
    var iconName: String {
        switch self {
        case .serverError:
            return "server.rack"
        case .webSocketConnectionFailed:
            return "bolt.horizontal.circle"
        case .urlConfigurationError:
            return "gear.badge.xmark"
        case .unknownError:
            return "exclamationmark.triangle"
        }
    }
    
    static func == (lhs: AppError, rhs: AppError) -> Bool {
        switch (lhs, rhs) {
        case (.webSocketConnectionFailed, .webSocketConnectionFailed):
            return true
        case (.serverError(let lhsMessage), .serverError(let rhsMessage)):
            return lhsMessage == rhsMessage
        case (.urlConfigurationError(let lhsService), .urlConfigurationError(let rhsService)):
            return lhsService == rhsService
        case (.unknownError(let lhsError), .unknownError(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}

struct ContentView: View {
    @StateObject private var viewModel: TransactionViewModel
        
    init(viewModel: TransactionViewModel) {
        self._viewModel = StateObject(wrappedValue: viewModel)
    }
    
    var body: some View {
        VStack(spacing: 20) {
            Text("Bitcoin Monitor")
                .font(.title2)
                .fontWeight(.semibold)
            if viewModel.viewState != .initial {
                connectionStatusHeader
            }
            mainContentArea
        }
        .onDisappear {
            viewModel.disconnect()
        }
    }
    
    private var connectionStatusHeader: some View {
        HStack {
            ConnectionStatusView(status: viewModel.connectionStatus)
            Spacer()
            
            Button(action: toggleConnection) {
                Text(buttonTitle)
                    .foregroundColor(.white)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(buttonColor)
                    .cornerRadius(8)
            }
            .disabled(viewModel.viewState == .connecting)
        }
        .padding(.horizontal)
    }

    private var mainContentArea: some View {
        Group {
            switch viewModel.viewState {
            case .initial:
                GenericStateView(
                    icon: "bitcoinsign.circle.fill",
                    title: "Bitcoin Transaction Monitor",
                    subtitle: "Track high-value Bitcoin transactions in real-time",
                    buttonTitle: "Start Monitoring",
                    buttonAction: {
                        Task {
                            await viewModel.connect()
                        }
                    },
                    iconColor: .orange,
                    buttonColor: .blue
                )
                
            case .connecting:
                GenericStateView(
                    title: "Connecting to Bitcoin Network...",
                    isLoading: true
                )
                
            case .fetchingData:
                GenericStateView(
                    title: "Fetching transactions...",
                    subtitle: "Waiting for high-value transactions",
                    isLoading: true
                )
                
            case .success:
                TransactionListView(
                    transactions: viewModel.transactions,
                    onClearQueue: viewModel.clearTransactions
                )
                
            case .empty:
                GenericStateView(
                    icon: "exclamationmark.triangle",
                    subtitle: "We could not fetch the transactions in the mean time, please come back again.",
                    buttonTitle: "Retry",
                    buttonAction: {
                        viewModel.retryFetching()
                    },
                    iconColor: .yellow,
                    buttonColor: .blue
                )
                
            case .disconnected:
                GenericStateView(
                    icon: "server.rack",
                    subtitle: "Your WebSocket is disconnected, connect it to get latest transactions.",
                    iconColor: .red
                )
                
            case .error(let error):
                GenericStateView(
                    icon: error.iconName,
                    title: error.localizedDescription,
                    subtitle: error.recoverySuggestion,
                    iconColor: .red
                )
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }


    private var buttonTitle: String {
        return viewModel.connectionStatus == .connected ? "Disconnect" : "Connect"
    }

    private var buttonColor: Color {
        switch viewModel.connectionStatus {
        case .connected:
            return Color.red
        case .connecting:
            return Color.gray
        case .disconnected:
            return Color.blue
        }
    }
    
    private func toggleConnection() {
        if viewModel.connectionStatus == .connected {
            viewModel.disconnect()
        } else if viewModel.connectionStatus == .disconnected {
            Task {
                await viewModel.connect()
            }
        }
    }
}

// MARK: - Preview
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView(
            viewModel: TransactionViewModel(
                priceService: BitcoinPriceService(),
                webSocketService: WebSocketService()
            )
        )
    }
}
