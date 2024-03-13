# swift-combine-extras

Useful bridges between combine and Swift concurrency.

## Overview

This library comes with a couple of tools to seamlessly transition combine into the Swift
concurrency world and vice versa. The main goal is to make the briding as smooth as possible. This
especially includes cancellation to be propagated into the other world correctly.

## Installation via SPM

Add the following to you `Package.swift` description.

```Swift
.package(url: "git@github.com:pEEcor/swift-combine-extras.git", from: "0.2.0")
```

The exposed library is named `CombineExtras`.

## Complete Concurrency Checking

This library is compiled with complete-concurrency-checking enabled to pave the way towards
optional concurrency checking in Swift 6. All types are designed to be concurrency safe. This
however also means that the values that are returned from async operations or published by publisher
need to be `Sendable` too.

## Documentation

The latest documentation for this library is available [here](docs).

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[docs]: https://peecor.github.io/swift-combine-extras/main/documentation/combineextras/