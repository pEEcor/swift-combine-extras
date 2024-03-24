//
//  Publisher+AsyncTests.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras
import XCTest

@testable import CombineExtras

// MARK: - Publisher_AsyncTests

final class Publisher_AsyncTests: XCTestCase {
    func testValue_shouldContainValue_whenPublisherSucceeds() async throws {
        // GIVEN
        let publisher: AnyPublisher<Int, Never> = .just(42)

        // WHEN
        let output = try await publisher.value

        // THEN
        XCTAssertEqual(output, 42)
    }

    func testValue_shouldThrowError_whenPublisherFails() async throws {
        struct Failure: Error, Equatable {}

        // GIVEN
        let publisher: AnyPublisher<Int, Failure> = .fail(Failure())

        // WHEN
        await XCTAssertThrowsError(try await publisher.value) { error in
            // THEN
            XCTAssertEqual(error as! Failure, Failure())
        }
    }

    func testValue_shouldThrowOutputError_whenPublisherFinishesWithoutValue() async throws {
        await withMainSerialExecutor {
            // GIVEN
            let publisher: PassthroughSubject<Int, Never> = PassthroughSubject()

            // A new task is created to give
            let task = Task { try await publisher.value }

            // WHEN
            publisher.send(completion: .finished)

            // THEN
            switch await task.result {
            case .success:
                XCTFail("Expected Failure")
            case let .failure(error):
                XCTAssertEqual(error as! AsyncPublisherError, .missingOutput)
            }
        }
    }

    func testValue_shouldContainFirstPublishedValue_whenMultipleValuesArePublished() async throws {
        // GIVEN
        let publisher = [1, 2].publisher

        // WHEN
        // A new task is created to give
        let task = Task { try await publisher.value }

        // WHEN
        let output = try await task.value

        // THEN
        XCTAssertEqual(output, 1)
    }
}

public func XCTAssertThrowsError<T>(
    _ expression: @autoclosure () async throws -> T,
    _ message: @autoclosure () -> String = "",
    file: StaticString = #filePath,
    line: UInt = #line,
    _ errorHandler: (_ error: any Error) -> Void = { _ in }
) async {
    let result = await Result { try await expression() }

    switch result {
    case .success:
        XCTFail(message())
    case let .failure(failure):
        errorHandler(failure)
    }
}
