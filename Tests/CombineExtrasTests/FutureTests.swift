//
//  FutureTests.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras
import XCTest

@testable import CombineExtras

final class FutureTests: XCTestCase {
    func test_complete_whenCancelled() async throws {
        let sut: Future<Int, Never> = Future { promise in
            DispatchQueue.main.async {
                sleep(1)
                promise(.success(42))
            }
        }

        let cancellable = sut.sink(
            receiveCompletion: { completion in
                switch completion {
                case .failure:
                    print("failed")
                case .finished:
                    print("finished")
                }
            },
            receiveValue: { output in
                print(output)
            }
        )

        cancellable.cancel()
    }

    func testInit_shouldRunAsyncOperation() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation = expectation(description: "published")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut: Future<Int, Never> = Future {
                return 42
            }

            // Create subscription. At this state, the operation did not run yet, since the test
            // task did not yield. Therefore the subsription is established before the publisher
            // could run and publish anything.
            let cancellable = sut.sink { _ in
                expectation.fulfill()
            }

            await fulfillment(of: [expectation], timeout: 3)

            // Cleanup
            cancellable.cancel()
        }
    }

    func testInit_shouldEmitOutput_whenOperationSucceeds() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation = expectation(description: "published")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut: Future<Int, any Error> = Future {
                return 42
            }

            // Create subscription. At this state, the operation did not run yet, since the test
            // task did not yield. Therefore the subsription is established before the publisher
            // could run and publish anything.
            let cancellable = sut.sink(
                receiveCompletion: { completion in
                    guard case .finished = completion else {
                        XCTFail("Expected finished")
                        return
                    }

                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )

            await fulfillment(of: [expectation], timeout: 3)

            // Cleanup
            cancellable.cancel()
        }
    }

    func testInit_shouldEmitError_whenOperationFails() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation = expectation(description: "published")

            struct Failure: Error, Equatable {}

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut: Future<Int, any Error> = Future {
                throw Failure()
            }

            // Create subscription. At this state, the operation did not run yet, since the test
            // task did not yield. Therefore the subsription is established before the publisher
            // could run and publish anything.
            let cancellable = sut.sink(
                receiveCompletion: { completion in
                    guard case let .failure(failure) = completion else {
                        XCTFail("Expected finished")
                        return
                    }
                    XCTAssertEqual(failure as? Failure, Failure())
                    expectation.fulfill()
                },
                receiveValue: { _ in }
            )

            await fulfillment(of: [expectation], timeout: 3)

            // Cleanup
            cancellable.cancel()
        }
    }
}
