//
//  AsyncFutureTests.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras
import XCTest

@testable import CombineExtras

final class AsyncFutureTests: XCTestCase {
    func test_eventuallyPublishOnSubscription_whenItHasNotPublished() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation = expectation(description: "published")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut = AsyncFuture {
                return 42
            }

            // WHEN
            // Create subscription. At this state, the operation did not run yet, since the test
            // task did not yield. Therefore the subsription is established before the publisher
            // could run and publish anything.
            let cancellable = sut.sink { _ in
                expectation.fulfill()
            }

            // THEN
            await fulfillment(of: [expectation], timeout: 3)

            // Cleanup
            cancellable.cancel()
        }
    }

    func test_publishOutputOnSubscription_whenItHasAlreadyPublished() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation = expectation(description: "published")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut = AsyncFuture {
                return 42
            }

            // Yield to give space to the next item which is the task that is enqueued by the async
            // future.
            await Task.yield()

            // Yield again, to run the actual operation of the async future.
            await Task.yield()

            // WHEN
            // Create subsctiption. At this stage the publishers operation as already finished.
            let cancellable = sut.sink { _ in
                expectation.fulfill()
            }

            // THEN
            await fulfillment(of: [expectation], timeout: 3)

            // Cleanup
            cancellable.cancel()
        }
    }

    func test_publishToSubscriber_whenMultipleSubscribersAreListening() async {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation_1 = expectation(description: "published-1")
            let expectation_2 = expectation(description: "published-2")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut = AsyncFuture {
                return 42
            }

            // WHEN
            let cancellable_1 = sut.sink { _ in
                expectation_1.fulfill()
            }

            let cancellable_2 = sut.sink { _ in
                expectation_2.fulfill()
            }

            // THEN
            await fulfillment(of: [expectation_1, expectation_2], timeout: 3)

            // Cleanup
            cancellable_1.cancel()
            cancellable_2.cancel()
        }
    }

    func test_dontPublish_whenSubscriptionIsCancelled() async {
        await withMainSerialExecutor {
            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut = AsyncFuture {
                return 42
            }

            // Yield to give space to the next item which is the task that is enqueued by the async
            // future.
            await Task.yield()

            // WHEN
            // Create subscription. At this stage the task has been started, but the operation is
            // still waiting on the executor.
            let cancellable = sut.sink { _ in
                XCTFail("The operation should have been cancelled")
            }

            // The task gets cancelled right after the subscription was established.
            cancellable.cancel()

            // Yield to give space to the next item which is the operation of the async future.
            // The operation runs to completion, but since no subscriber is present anymore,
            // nothing will be sent downstream.
            await Task.yield()
        }
    }

    func test_dontPublishToCancelledSubscribers_whenMultipleSubscribersArePresent() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation_2 = expectation(description: "published-2")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut = AsyncFuture {
                return 42
            }

            let cancellable_1 = sut.sink { _ in
                XCTFail("The subscription should have been cancelled")
            }

            let cancellable_2 = sut.sink { _ in
                expectation_2.fulfill()
            }

            // WHEN
            cancellable_1.cancel()

            // THEN
            await fulfillment(of: [expectation_2], timeout: 3)

            // Cleanup
            cancellable_2.cancel()
        }
    }

    func test_cancellation_shouldCancelOperation() async throws {
        await withMainSerialExecutor {
            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut = AsyncFuture {
                // Check cancellation, this throws a CancellationError, when the enclosing task has
                // been cancelled.
                try Task.checkCancellation()
                return 42
            }

            // WHEN
            // Create subscription.
            let cancellable = sut.sink(
                receiveCompletion: { _ in
                    XCTFail("The cancellation error should not be send downstream!")
                },
                receiveValue: { _ in
                    XCTFail("No value should be sent when the publisher fails!")
                }
            )
            // The task gets cancelled right after the subscription was established.
            cancellable.cancel()

            // Yield to give space to the next item which is the task that is enqueued by the async
            // future.
            await Task.yield()

            // Yield to give space to the next item which is the operation of the async future.
            // The operation runs to completion, but since no subscriber is present anymore,
            // nothing will be sent downstream.
            await Task.yield()
        }
    }
}
