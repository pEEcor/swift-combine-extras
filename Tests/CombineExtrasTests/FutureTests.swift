//
//  FutureTests.swift
//  
//
//  Created by Becker, Paavo on 10.03.24.
//

import XCTest
import Combine
import ConcurrencyExtras

@testable import CombineExtras

final class FutureTests: XCTestCase {
    func test_complete_whenCancelled() async throws {
        let sut: Future<Int, Never> = Future { promise in
            DispatchQueue.main.async {
                print("Running")
                sleep(1)
                print("Done")
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
}
