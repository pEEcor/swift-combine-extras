//
//  AsyncFutureSubscriber.swift
//  
//
//  Created by Becker, Paavo on 11.03.24.
//

import Foundation
import Combine
import ConcurrencyExtras

final class AsyncFutureSubscriber<Input, Failure>: Subscriber, Sendable
    where Failure: Error
{
    /// The underlying Subscriber.
    private let subscriber: LockIsolated<UncheckedSendable<AnySubscriber<Input, Failure>>>
    
    init<S>(subscriber: S) where S : Subscriber, S.Input == Input, S.Failure == Failure {
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
