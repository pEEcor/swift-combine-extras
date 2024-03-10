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
final public class AsyncFuture<Output, Failure> : Publisher where Failure: Error {
    /// The current subscriber
    private var subscriber: LockIsolated<UncheckedSendable<AnySubscriber<Output, Failure>>?>
    
    /// Reference to task
    private var task: Task<Void, Never>!

    /// Creates a publisher that emits a single value after the given async operation finishes.
    ///
    /// - Parameter attemptToFulfill: The operation that should be run asyncronously.
    private init(
        attemptToFulfill: @Sendable @escaping () async -> Result<Output, Failure>
    ) where Output: Sendable {
        self.subscriber = LockIsolated(nil)
        self.task = Task<Void, Never> { [subscriber] in
            // Run the operation
            switch await attemptToFulfill() {
            case .success(let output):
                // The demand of the subscriber is ignored since only one value is published.
                let _ = subscriber.withValue { $0?.value.receive(output) }
                
                // Comple the publisher by sending the finished value downstream
                subscriber.withValue { $0?.value.receive(completion: .finished) }
            case .failure(let error):
                subscriber.withValue { $0?.value.receive(completion: .failure(error)) }
            }
        }
    }
    
    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, S.Input == Output, S.Failure == Failure {
        /// Create a sendable version of the subscriber. This is required in order to pass it into
        /// the transforming closure of the lock.
        let sendableSubscriber = UncheckedSendable(AnySubscriber(subscriber))
        
        /// Store the subscriber.
        self.subscriber.withValue { $0 = sendableSubscriber }
        
        /// Create the subscription that is passed to the downstream subscriber.
        let subscription = AsyncFutureSubscription(
            onCancel: { [task] in
                task?.cancel()
            }
        )
        
        /// Send the subscription to the downstream subscriber.
        self.subscriber.withValue { $0?.value.receive(subscription:subscription) }
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

private final class AsyncFutureSubscription: Subscription, Sendable {
    /// The action that should be invoked when the subscription gets cancelled.
    let onCancel: LockIsolated<() -> Void>
    
    init(onCancel: @Sendable @escaping () -> Void) {
        self.onCancel = LockIsolated(onCancel)
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        self.onCancel.withValue { $0() }
    }
}
