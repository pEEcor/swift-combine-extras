//
//  FutureTests.swift
//  
//
//  Created by Becker, Paavo on 10.03.24.
//

import XCTest
import Combine
import CombineExtras

final class FutureTests: XCTestCase {

    override func setUpWithError() throws {
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testFutureValueBuffer() async throws {
        let future: Future<Int, Never> = Future { promise in
            print("Running")
            sleep(1)
            print("Done")
            promise(.success(42))
        }
        
        try await Task.sleep(for: .seconds(2))
        
        let _ = future.sink { output in
            print(output)
            XCTAssertEqual(42, output)
        }
        
        let _ = future.sink { output in
            print(output)
            XCTAssertEqual(42, output)
        }
    }
}
