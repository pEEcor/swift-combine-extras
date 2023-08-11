//
//  Publisher+Stream.swift
//
//
//  Created by Paavo Becker on 11.08.23.
//

import Combine

extension Publisher where Failure == Never {
    /// Creates an AsyncStream from a publisher that does not fail
    ///
    /// > Note: The observation of the publisher gets cancelled once the AsyncStream gets cancelled.
    /// - Parameter bufferingPolicy: The buffering policy for the AsyncStream
    /// - Returns: The stream
    public func asyncStream(
        bufferingPolicy: AsyncStream<Output>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncStream<Output> {
        AsyncStream<Output>(bufferingPolicy: bufferingPolicy) { continuation in
            let cancellable = self.sink { continuation.yield($0) }
            
            // Store the cancellable inside the onTermination closure. This will retain the
            // cancellable until the continuation gets cancelled
            continuation.onTermination = { _ in
                _ = cancellable
            }
        }
    }
}

extension Publisher {
    public typealias AsyncThrowingStreamOf<Publisher> = AsyncThrowingStream<
        Publisher.Output, Publisher.Failure
    > where Publisher: Combine.Publisher
    
    /// Creates an AsyncThrowingStream from a publisher that can fail
    ///
    /// > Note: The observation of the publisher gets cancelled once the AsyncThrowingStream gets
    /// cancelled.
    /// - Parameter bufferingPolicy: The buffering policy for the AsyncThrowingStream
    /// - Returns: The stream
    public func asyncThrowingStream(
        bufferingPolicy: AsyncThrowingStreamOf<Self>.Continuation.BufferingPolicy = .unbounded
    ) -> AsyncThrowingStream<Output, Failure> where Failure == Error {
        AsyncThrowingStream { continuation in
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
            
            // Store the cancellable inside the onTermination closure. This will retain the
            // cancellable until the continuation gets cancelled
            continuation.onTermination = { _ in
                _ = cancellable
            }
        }
    }
}
