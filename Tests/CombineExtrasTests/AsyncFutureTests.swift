import XCTest
import Combine
@testable import CombineExtras

func loop() async throws {
    var seconds = 0
    while true {
        print("loop: \(seconds)")
        
        try await Task.sleep(for: .seconds(1))
        seconds += 1
        
        try Task.checkCancellation()
    }
}

final class AsyncFutureTests: XCTestCase {
    
    func foo() {
        Task {
            try await loop()
        }
    }
    
    func testFoo() async throws {
        let task = Task { try await loop() }
        try await Task.sleep(for: .seconds(5))
        task.cancel()
        
        try await Task.sleep(for: .seconds(5))
    }
    
    func testFutureTaskCancellation() async throws {
        let future = AsyncFuture {
            try await loop()
        }
        
        let cancellable = future.sink { completion in
            switch completion {
            case .finished:
                print("finished")
            case .failure(let error):
                print(String(describing: error))
            }
        } receiveValue: { value in
            print(value)
        }
        
        try await Task.sleep(for: .seconds(5))
        
        cancellable.cancel()
        print("subscription cancelled")
        
        try await Task.sleep(for: .seconds(5))
    }
    
    
    func testAsyncFutureBuffer() async throws {
        let future = AsyncFuture {
            try! await Task.sleep(for: .seconds(1))
            return 42
        }
        
        try await Task.sleep(for: .seconds(2))
        
        let _ = future.sink { output in
            XCTAssertEqual(42, output)
        }
    }
}
