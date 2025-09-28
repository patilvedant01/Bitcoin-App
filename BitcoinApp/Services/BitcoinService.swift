//
//  BitcoinService.swift
//  BitcoinApp
//
//  Created by Vedant Patil on 27/09/25.
//

import Foundation
import Combine

protocol BitcoinPriceServiceProtocol {
    func fetchBitcoinPrice() -> AnyPublisher<Double, AppError>
}

class BitcoinPriceService: BitcoinPriceServiceProtocol {
    private static let defaultPriceURLString = "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=usd"
      
    private func getValidURL() throws -> URL {
        guard let url = URL(string: Self.defaultPriceURLString) else {
            throw AppError.urlConfigurationError("Bitcoin Price Service is unavailable.")
        }
        return url
    }
    
    func fetchBitcoinPrice() -> AnyPublisher<Double, AppError> {
        return Future<URL, AppError> { promise in
            do {
                let validURL = try self.getValidURL()
                promise(.success(validURL))
            } catch {
                if let appError = error as? AppError {
                    promise(.failure(appError))
                } else {
                    promise(.failure(AppError.unknownError(error)))
                }
            }
        }
        .flatMap { validURL in
            URLSession.shared.dataTaskPublisher(for: validURL)
                .map(\.data)
                .decode(type: BitcoinPriceResponse.self, decoder: JSONDecoder())
                .map(\.bitcoin.usd)
                .mapError { error in
                    return AppError.unknownError(error)
                }
        }
        .eraseToAnyPublisher()
    }
}
