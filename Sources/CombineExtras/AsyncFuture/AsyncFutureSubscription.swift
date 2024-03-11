//
//  AsyncFutureSubscription.swift
//
//
//  Created by Becker, Paavo on 11.03.24.
//

import Foundation
import Combine
import ConcurrencyExtras

final class AsyncFutureSubscription: Subscription, Sendable {
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
