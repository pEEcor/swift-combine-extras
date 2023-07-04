//
//  Publisher+Async.swift
//  CombineExtension
//
//  Created by Paavo Becker on 04.07.23
//

import Foundation
import Combine

public extension Publisher {
    /// Awaits a single result from a publisher
    ///
    /// - Returns: The next value that is publisher by the upstream publisher
    func singleResult() async throws -> Output {
        var cancellable: AnyCancellable?
        var didReceiveValue = false

        return try await withCheckedThrowingContinuation { continuation in
            cancellable = sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .failure(let error):
                        continuation.resume(throwing: error)
                    case .finished:
                        if !didReceiveValue {
                            continuation.resume(
                                throwing: AsyncPublisherError.missingOutput
                            )
                        }
                    }
                },
                receiveValue: { value in
                    guard !didReceiveValue else { return }

                    didReceiveValue = true
                    cancellable?.cancel()
                    continuation.resume(returning: value)
                }
            )
        }
    }
}

enum AsyncPublisherError: Error {
    case missingOutput
}
