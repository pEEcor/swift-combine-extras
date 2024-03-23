//
//  Publisher+StreamTests.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras
import XCTest

final class Publisher_StreamTests: XCTestCase {
    func testAsyncStream_shouldEmitValuesInStream() async throws {
        var result: [Int] = []

        // GIVEn
        let publisher = [1, 2, 3].publisher

        // WHEN
        for await value in publisher.asyncStream() {
            result.append(value)
        }

        // THEN
        XCTAssertEqual(result, [1, 2, 3])
    }

    func testAsyncThrowingStream_shouldEmitValuesInStream() async throws {
        struct Failure: Error, Equatable {}
        var result: [Int] = []

        // GIVEn
        let publisher: AnyPublisher<Int, Failure> = [1, 2, 3]
            .publisher
            .setFailureType(to: Failure.self)
            .eraseToAnyPublisher()

        // WHEN
        for try await value in publisher.asyncThrowingStream() {
            result.append(value)
        }

        // THEN
        XCTAssertEqual(result, [1, 2, 3])
    }
}
