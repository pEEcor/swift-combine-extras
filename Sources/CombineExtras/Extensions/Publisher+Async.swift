//
//  Publisher+Async.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import Foundation

extension Publisher {
    /// Awaits a single value from a publisher
    ///
    /// - Note: Only use this property if you expect the publisher to publish exactly one value. If
    /// you need to handle multiple values, consider converting the publisher into an async stream.
    ///
    /// - Returns: The next value that is published by the upstream publisher
    /// - throws: An error if the publisher fails of finishes without publishing value
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public var value: Output {
        get async throws {
            var cancellable: AnyCancellable?
            var didReceiveValue = false

            return try await withCheckedThrowingContinuation { continuation in
                cancellable = sink(
                    receiveCompletion: { completion in
                        switch completion {
                        case let .failure(error):
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
                        guard !didReceiveValue else {
                            return
                        }

                        didReceiveValue = true
                        cancellable?.cancel()
                        continuation.resume(returning: value)
                    }
                )
            }
        }
    }
}

// MARK: - AsyncPublisherError

public enum AsyncPublisherError: Error, Equatable {
    case missingOutput
}
