//
//  Future.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras
import Foundation

extension Future where Failure == Never {
    /// Creates a Future that runs asynchronous work.
    ///
    /// The operation is started immediately when creating the future. If this is not desired,
    /// consider wrapping the future into a `Deferred` publisher.
    ///
    /// - Parameter operation: The operation that should be executed.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public convenience init(
        _ operation: @Sendable @escaping () async -> Output
    ) where Output: Sendable {
        self.init { promise in
            // The unchecked sendable promise can be consideres save to send since the promise is
            // only ever called once.
            let sendablePromise = UncheckedSendable(promise)

            // Start the task.
            Task {
                let output = await operation()
                sendablePromise.value(.success(output))
            }
        }
    }
}

extension Future where Failure == Error {
    /// Creates a Future that runs asynchronous work.
    ///
    /// The operation is started immediately when creating the future. If this is not desired,
    /// consider wrapping the future into a `Deferred` publisher.
    ///
    /// - Parameter operation: The operation that should be executed.
    @available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
    public convenience init(
        _ operation: @Sendable @escaping () async throws -> Output
    ) where Output: Sendable {
        self.init { promise in
            // The unchecked sendable promise can be consideres save to send since the promise is
            // only ever called once.
            let sendablePromise = UncheckedSendable(promise)

            // Start the task.
            Task {
                do {
                    let output = try await operation()
                    sendablePromise.value(.success(output))
                } catch {
                    sendablePromise.value(.failure(error))
                }
            }
        }
    }
}
