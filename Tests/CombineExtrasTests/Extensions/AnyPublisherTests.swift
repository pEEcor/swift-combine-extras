//
//  AnyPublisherTests.swift
//
//  Copyright © 2024 Paavo Becker.
//

import Combine
import ConcurrencyExtras
import XCTest

final class AnyPublisherTests: XCTestCase {
    func testAsync_shouldStartRunningOperation_afterSubscriptionWasMade() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation = expectation(description: "published")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut: AnyPublisher<Int, Never> = AnyPublisher.async {
                return 42
            }

            // Yielding does not run the publishers task since it has not been scheduled on the
            // serial executor.
            await Task.yield()

            // WHEN
            // Create subscription. At this state, the operation did not run yet, since no
            // subscription was made. Subscribing will start the task.
            let cancellable = sut.sink { _ in
                expectation.fulfill()
            }

            // THEN
            await fulfillment(of: [expectation], timeout: 3)

            // Cleanup
            cancellable.cancel()
        }
    }

    func testAsyncThrowing_shouldStartRunningOperation_afterSubscriptionWasMade() async throws {
        await withMainSerialExecutor {
            // Make an expectation that can be fulfilled when the sut publishes.
            let expectation = expectation(description: "published")

            // GIVEN
            // The async future starts its operation immediately on creation. However it cannot run
            // until the test task yields execution.
            let sut: AnyPublisher<Int, any Error> = AnyPublisher.async {
                return 42
            }

            // Yielding does not run the publishers task since it has not been scheduled on the
            // serial executor.
            await Task.yield()

            // WHEN
            // Create subscription. At this state, the operation did not run yet, since no
            // subscription was made. Subscribing will start the task.
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

            // THEN
            await fulfillment(of: [expectation], timeout: 3)

            // Cleanup
            cancellable.cancel()
        }
    }
    
    func testJustWithoutErrorType_ShouldCreatePublisherThatPublishesImmediately() async throws {
        // Make an expectation that can be fulfilled when the sut publishes.
        let expectation = expectation(description: "published")
        
        // GIVEN
        let sut: AnyPublisher<Int, Never> = .just(42)
        
        // WHEN
        // Create subscription. At this state, the operation did not run yet, since no
        // subscription was made. Subscribing will start the task.
        let cancellable = sut.sink { _ in
            expectation.fulfill()
        }
        
        // THEN
        await fulfillment(of: [expectation], timeout: 3)
        
        // Cleanup
        cancellable.cancel()
    }
    
    func testJustWithErrorType_ShouldCreatePublisherThatPublishesImmediately() async throws {
        // Make an expectation that can be fulfilled when the sut publishes.
        let expectation = expectation(description: "published")
        
        struct Failure: Error {}
        
        // GIVEN
        let sut: AnyPublisher<Int, Failure> = .just(42)
        
        // WHEN
        // Create subscription. At this state, the operation did not run yet, since no
        // subscription was made. Subscribing will start the task.
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
        
        // THEN
        await fulfillment(of: [expectation], timeout: 3)
        
        // Cleanup
        cancellable.cancel()
    }
    
    func testFailWithErrorType_ShouldCreatePublisherThatPublishesImmediately() async throws {
        // Make an expectation that can be fulfilled when the sut publishes.
        let expectation = expectation(description: "published")
        
        struct Failure: Error, Equatable {}
        
        // GIVEN
        let sut: AnyPublisher<Int, Failure> = .fail(Failure())
        
        // WHEN
        // Create subscription. At this state, the operation did not run yet, since no
        // subscription was made. Subscribing will start the task.
        let cancellable = sut.sink(
            receiveCompletion: { completion in
                guard case .failure(let error) = completion else {
                    XCTFail("Expected failure")
                    return
                }
                
                XCTAssertEqual(error, Failure())
                
                expectation.fulfill()
            },
            receiveValue: { _ in }
        )
        
        // THEN
        await fulfillment(of: [expectation], timeout: 3)
        
        // Cleanup
        cancellable.cancel()
    }
}
