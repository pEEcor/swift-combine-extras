//
//  Publisher+Stream.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras

extension Publisher where Failure == Never {
    /// Creates an AsyncStream from a publisher that does not fail.
    ///
    /// > Note: The observation of the publisher gets cancelled once the AsyncStream gets cancelled.
    ///
    /// - Parameter bufferingPolicy: The buffering policy for the AsyncStream.
    /// - Returns: The stream
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func asyncStream(
        bufferingPolicy: AsyncStream<Output>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<Output> {
        AsyncStream<Output>(bufferingPolicy: bufferingPolicy) { continuation in
            // Access to the cancellable is not required here. Just the reference is needed to
            // keep the subscription alive.
            let cancellable = UncheckedSendable(self.sink { continuation.yield($0) })

            // Store the cancellable inside the onTermination closure. This will retain the
            // cancellable until the continuation gets cancelled
            continuation.onTermination = { _ in
                _ = cancellable
            }
        }
    }
}

extension Publisher {
    /// A typealias to shorten the type definition of an `AsyncThrowingStream`.
    public typealias AsyncThrowingStreamOf<Publisher> = AsyncThrowingStream<
        Publisher.Output, Publisher.Failure
    > where Publisher: Combine.Publisher

    // Creates an AsyncThrowingStream from a publisher that can fail.
    //
    // > Note: The observation of the publisher gets cancelled once the AsyncThrowingStream gets
    // cancelled.
    //
    // - Parameter bufferingPolicy: The buffering policy for the AsyncThrowingStream.
    // - Returns: The stream
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public func asyncThrowingStream(
        bufferingPolicy: AsyncThrowingStreamOf<Self>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncThrowingStream<Output, Failure> where Failure == Error {
        AsyncThrowingStream(bufferingPolicy: bufferingPolicy) { continuation in
            let cancellable = self.sink(
                receiveCompletion: { completion in
                    switch completion {
                    case .finished:
                        continuation.finish()
                    case let .failure(error):
                        continuation.finish(throwing: error)
                    }
                }, receiveValue: { output in
                    continuation.yield(output)
                }
            )

            // Access to the cancellable is not required here. Just the reference is needed to
            // keep the subscription alive.
            let sendableCancellable = UncheckedSendable(cancellable)

            // Store the cancellable inside the onTermination closure. This will retain the
            // cancellable until the continuation gets cancelled
            continuation.onTermination = { _ in
                _ = sendableCancellable
            }
        }
    }
}
