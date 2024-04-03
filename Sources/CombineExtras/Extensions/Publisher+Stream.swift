//
//  Publisher+Stream.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras

extension Publisher where Failure == Never {
    /// Creates an AsyncStream from a publisher that does not fail.
    ///
    /// - Returns: The stream
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 5.0, *)
    public func asyncStream() -> AsyncStream<Output> {
        self.values.eraseToStream()
    }
}

extension Publisher {
    /// Creates an AsyncThrowingStream from a publisher that can fail.
    ///
    /// - Returns: The stream
    @available(macOS 12.0, iOS 15.0, tvOS 15.0, watchOS 8.0, *)
    public func asyncThrowingStream(
    ) -> AsyncThrowingStream<Output, Error> {
        self.values.eraseToThrowingStream()
    }
}
