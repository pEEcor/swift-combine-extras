//
//  AsyncFutureSubscriber.swift
//  
//
//  Created by Becker, Paavo on 11.03.24.
//

import Foundation
import Combine

class AsyncFutureSubscriber<Input, Failure>: Subscriber, @unchecked Sendable
    where Failure: Error
{
    /// The underlying Subsriber.
    private var subscriber: AnySubscriber<Input, Failure>
    
    init<S>(subscriber: S) where S : Subscriber, S.Input == Input, S.Failure == Failure {
        self.subscriber = AnySubscriber(subscriber)
    }
    
    func receive(subscription: any Subscription) {
        self.subscriber.receive(subscription: subscription)
    }
    
    func receive(_ input: Input) -> Subscribers.Demand {
        self.subscriber.receive(input)
    }
    
    func receive(completion: Subscribers.Completion<Failure>) {
        self.subscriber.receive(completion: completion)
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
