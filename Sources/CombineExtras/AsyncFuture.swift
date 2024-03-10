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
/// - Important: This Future publishes its output immediately like ``PassthroughSubject`` or
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
final public class AsyncFuture<Output> : Publisher {
    /// The error type of this publisher needs to be this generic, since the error type of the
    /// async operation is not explicitly known.
    public typealias Failure = any Error
    
    /// The current subscriber
    @UncheckedSendable
    private var subscriber: AnySubscriber<Output, any Error>?
    
    /// Reference to task
    private var task: Task<Void, Never>!

    /// Creates a publisher that emits a single value after the given async operation finishes.
    ///
    /// - Parameter attemptToFulfill: The operation that should be run asyncronously.
    public init(
        _ attemptToFulfill: @Sendable @escaping () async throws -> Output
    ) where Output: Sendable {
        self.task = Task<Void, Never> { [$subscriber] in
            do {
                // Run the operation
                let output = try await attemptToFulfill()
                
                // The demand of the subscriber is ignored since only one value is published.
                let _ = $subscriber.value?.receive(output)
                
                // Comple the publisher by sending the finished value downstream
                $subscriber.value?.receive(completion: .finished)
            } catch {
                $subscriber.value?.receive(completion: .failure(error))
            }
        }
    }
    
    public func receive<S>(
        subscriber: S
    ) where S : Subscriber, Output == S.Input, any Error == S.Failure {
        self.subscriber = AnySubscriber(subscriber)
        
        let subscription = AsyncFutureSubscription(
            onCancel: { [weak self] in
                self?.task.cancel()
            }
        )
        
        subscriber.receive(subscription: subscription)
    }
}

private class AsyncFutureSubscription: Subscription, @unchecked Sendable {
    let onCancel: () -> Void
    
    init(onCancel: @escaping () -> Void) {
        self.onCancel = onCancel
    }
    
    func request(_ demand: Subscribers.Demand) {}
    
    func cancel() {
        self.onCancel()
    }
}
