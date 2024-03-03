//
//  Future.swift
//
//
//  Created by Paavo Becker on 03.03.24.
//

import Foundation
import Combine

extension Future where Failure == Error {
    /// Creates a Future that runs asynchronous work.
    ///
    /// - Parameter operation: The operation that should be executed.
    public convenience init(
        operation: @Sendable @escaping () async throws -> Output
    ) {
        self.init { promise in
            Task {
                do {
                    let output = try await operation()
                    promise(.success(output))
                } catch {
                    promise(.failure(error))
                }
            }
        }
    }
}
