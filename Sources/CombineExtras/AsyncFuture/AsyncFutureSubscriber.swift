//
//  AsyncFutureSubscriber.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras
import Foundation

// MARK: - AsyncFutureSubscriber

final class AsyncFutureSubscriber<Input, Failure>: Subscriber, Sendable
    where Failure: Error
{
    /// The underlying Subscriber.
    private let subscriber: LockIsolated<UncheckedSendable<AnySubscriber<Input, Failure>>>

    init<S>(subscriber: S) where S: Subscriber, S.Input == Input, S.Failure == Failure {
        let sendableSubscriber = UncheckedSendable(AnySubscriber(subscriber))
        self.subscriber = LockIsolated(sendableSubscriber)
    }

    func receive(subscription: any Subscription) {
        self.subscriber.value.value.receive(subscription: subscription)
    }

    func receive(_ input: Input) -> Subscribers.Demand {
        self.subscriber.value.value.receive(input)
    }

    func receive(completion: Subscribers.Completion<Failure>) {
        self.subscriber.value.value.receive(completion: completion)
    }
}

// MARK: Hashable

extension AsyncFutureSubscriber: Hashable {
    static func == (
        lhs: AsyncFutureSubscriber<Input, Failure>,
        rhs: AsyncFutureSubscriber<Input, Failure>
    ) -> Bool {
        ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }
}
