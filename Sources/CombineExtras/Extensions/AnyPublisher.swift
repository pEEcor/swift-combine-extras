//
//  AnyPublisher.swift
//
//
//  Created by Paavo Becker on 03.03.24.
//

import Foundation
import Combine

extension AnyPublisher where Failure == Error {
    /// Creates a publisher from an async task.
    ///
    /// The task will start to run after a subscription to the publisher was made.
    /// - Parameter operation: The async operation that should be executed.
    /// - Returns: A publisher that publishes the result of the operation.
    public static func `async`(
        operation: @Sendable @escaping () async throws -> Output
    ) -> AnyPublisher<Output, Failure> where Output: Sendable {
         Deferred {
            AsyncFuture {
                try await operation()
            }
        }
        .eraseToAnyPublisher()       
    }
    
    /// Creates a publisher that immediately publishes the given value.
    ///
    /// - Parameter value: The value that should be published.
    /// - Returns: A publisher.
    public static func just(_ value: Output) -> AnyPublisher<Output, Failure> {
        Just(value)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }
    
    /// Creates a publisher that immedeately publishes the given failure.
    ///
    /// - Parameter error: The failure that should be published.
    /// - Returns: A publisher.
    public static func fail(_ error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error)
            .eraseToAnyPublisher()
    }
}
