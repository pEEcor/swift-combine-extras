//
//  AsyncFuture.swift
//
//
//  Created by Paavo Becker on 09.03.24.
//

import Foundation
import Combine
import ConcurrencyExtras

/// A publisher that eventually produces a single value and then finishes or fails. It is
/// specifically designed to run async/await operations.
///
/// This Future bridges an async operation into the combine world. It runs the given operation
/// immediately and publishes the output of the operation once it finishes. The Future also
/// propagates cancellation. If a subscriber of the publisher cancels its observation, then the
/// async operation will also be cancelled.
///
/// - Note: This Future publishes its output immediately like ``PassthroughSubject`` or
/// ``CurrentValueSubject`` even if there is no subscriber attached to it. Additionally, the async
/// operation will be executed immediately when the Future gets created. If this is not desired,
/// then the Future can be wrapped into a `Deferred` publisher.
///
/// ## Drawbacks of other solutions
///
/// Consider the following code section. This solution can be found across numerous sources on the
/// internet. However it has a serious drawback. Both, Combine and structured concurrency with
/// async/await have tools to cancel long running operations. The example below starts creates
/// a future that emits once the output of the async operation is available. Cancelling the futures
/// subscription however does not cancel the work that runs asyncronously inside the task.
/// ```swift
///extension Future {
///    public convenience init(
///        operation: @Sendable @escaping () async throws -> Output
///    ) {
///        self.init { promise in
///            Task {
///                do {
///                    let output = try await operation()
///                    promise(.success(output))
///                } catch {
///                    promise(.failure(error))
///                }
///            }
///        }
///    }
///}
///```
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
final public class AsyncFuture<Output, Failure> : Publisher, @unchecked Sendable
    where Failure: Error, Output: Sendable
{
    /// The current subscriber
    private let subscribers: LockIsolated<Set<AsyncFutureSubscriber<Output, Failure>>>
    
    /// Reference to task.
    ///
    /// This is the only property that must be mutable, since we capture self in the initializer
    /// when constructing the tasks operation. Otherwise the compiler would complain that not all
    /// properties are set before accessing self. Therefore the publisher is marked as
    /// `@checked Sendable`.
    private var task: Task<Void, Never>!
    
    /// The result that will eventually produced by the AsyncFuture.
    private let result: LockIsolated<Result<Output, Failure>?> = LockIsolated(nil)

    /// Creates a publisher that emits a single value after the given async operation finishes.
    ///
    /// - Parameter attemptToFulfill: The operation that should be run asyncronously.
    private init(
        attemptToFulfill: @Sendable @escaping () async -> Result<Output, Failure>
    ) {
        // Start with no attached subscriber.
        self.subscribers = LockIsolated([])
        
        // Create task and run operation immediately.
        self.task = Task<Void, Never> {
            // Run the operation
            let result = await attemptToFulfill()

            // Store the result internally.
            self.result.setValue(result)
            
            // Publish the result.
            self.send()
        }
    }
    
    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, S.Input == Output, S.Failure == Failure {
        /// Create a sendable version of the subscriber. This is required in order to pass it into
        /// the transforming closure of the lock.
        let asyncFutureSubscriber = AsyncFutureSubscriber(subscriber: subscriber)
        
        /// Store the subscriber.
        self.subscribers.withValue { _ = $0.insert(asyncFutureSubscriber) }
        
        /// Create the subscription that is passed to the downstream subscriber.
        let subscription = AsyncFutureSubscription(
            onCancel: { [task] in
                // Remove subscriber
                self.subscribers.withValue { _ = $0.remove(asyncFutureSubscriber) }
                
                // Stop task when all subscribers are cancelled.
                if self.subscribers.value.isEmpty {
                    task?.cancel()
                }
            }
        )
        
        /// Send the subscription to the downstream subscriber.
        asyncFutureSubscriber.receive(subscription: subscription)
        
        /// The operation of the AsyncFuture may have finished already. Therefore a send attempt
        /// is performed immediately after acknowledging the subscriber.
        self.send()
    }
    
    private func send() {
        self.result.withValue { [subscribers] result in
            // Make sure that there is result that can be send to a downstream subscriber.
            guard let result = result else {
                return
            }
            
            // Send result to subscriber.
            subscribers.withValue { subscribers in
                switch result {
                case .success(let output):
                    subscribers.forEach { subscriber in
                        // Send the actual value.
                        _ = subscriber.receive(output)
                        
                        // Finish the publisher.
                        subscriber.receive(completion: .finished)
                    }
                case .failure(let error):
                    // Fail the publisher.
                    subscribers.forEach { $0.receive(completion: .failure(error)) }
                }
            }
        }
    }
}

extension AsyncFuture where Failure == Never {
    /// Creates a publisher that emits a single value after the given async operation finishes.
    ///
    /// - Parameter operation: The operation that should be run asyncronously.
    public convenience init(
        _ operation: @Sendable @escaping () async -> Output
    ) where Output: Sendable {
        self.init(attemptToFulfill: { .success(await operation()) })
    }
}

extension AsyncFuture where Failure == Error {
    /// Creates a publisher that emits a single value after the given async operation finishes.
    ///
    /// - Parameter operation: The operation that should be run asyncronously.
    public convenience init(
        _ operation: @Sendable @escaping () async throws -> Output
    ) where Output: Sendable {
        self.init(attemptToFulfill: { await Result { try await operation() } })
    }
}
