# ``CombineExtras``

Useful bridges between combine and Swift concurrency.

## Overview

This library comes with a couple of tools to seamlessly transition combine into the Swift
concurrency world and vice versa.

## Complete Concurrency Checking

This library is compiled with complete-concurrency-checking enabled to pave the way towards
optional concurrency checking in Swift 6. All types are designed to be concurrency safe. This
however also means that the values that are returned from async operations or published by publisher
need to be `Sendable` too.

## Topics

### Swift concurrency to Combine

Run async operations and transfrom them into the Combine world.

- ``AsyncFuture``
- ``CombineExtras/Combine/AnyPublisher/async(operation:)``

### Combine to Swift concurrency

Subscribe to publishers using Swift concurrency. This library provides multiple extensions to
the ``CombineExtras/Combine/Publisher`` Protocol, to either await a single output of a publisher or
to transform a publisher into an async sequence that can be iterated using Swift's built-in for
await in syntax.

- ``CombineExtras/Combine/Publisher``
