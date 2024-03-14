//
//  AnyPublisher.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import Foundation

extension AnyPublisher where Failure == Error {
    /// Creates a publisher from an async task with task cancellation when the publisher's
    /// subscription is cancelled.
    ///
    /// The task will start to run after a subscription to the publisher was made.
    /// - Parameter operation: The async operation that should be executed.
    /// - Returns: A publisher that publishes the result of the operation.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func async(
        operation: @Sendable @escaping () async throws -> Output
    ) -> AnyPublisher<Output, Failure> where Output: Sendable {
        Deferred { AsyncFuture { try await operation() } }
            .eraseToAnyPublisher()
    }

    /// Creates a publisher that immediately publishes the given value.
    ///
    /// - Parameter value: The value that should be published.
    /// - Returns: A publisher.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func just(_ value: Output) -> AnyPublisher<Output, Failure> {
        Just(value)
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()
    }

    /// Creates a publisher that immedeately publishes the given failure.
    ///
    /// - Parameter error: The failure that should be published.
    /// - Returns: A publisher.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public static func fail(_ error: Failure) -> AnyPublisher<Output, Failure> {
        Fail(error: error)
            .eraseToAnyPublisher()
    }
}
