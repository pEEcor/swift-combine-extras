<p align="center">
    <a href="https://github.com/pEEcor/swift-combine-extras/actions/workflows/ci.yml">
        <img src="https://github.com/pEEcor/swift-combine-extras/actions/workflows/ci.yml/badge.svg?branch=main"
    </a>
    <a href="https://codecov.io/gh/pEEcor/swift-combine-extras" > 
    <img src="https://codecov.io/gh/pEEcor/swift-combine-extras/graph/badge.svg?token=3MBI7HAVN5"/> 
    </a>
    <a href="https://github.com/pEEcor/swift-combine-extras/tags">
        <img alt="GitHub tag (latest SemVer)"
             src="https://img.shields.io/github/v/tag/pEEcor/swift-combine-extras?label=version">
    </a>
    <img src="https://img.shields.io/badge/Swift-5.10-red"
         alt="Swift: 5.10">
    <img src="https://img.shields.io/badge/Platforms-iOS%20%7C%20macOS-red"
        alt="Platforms: iOS, macOS">
    <a href="https://github.com/pEEcor/swiftui-pager/blob/main/LICENSE">
        <img alt="GitHub" 
             src="https://img.shields.io/github/license/pEEcor/swiftui-pager">
    </a>
</p>

# swift-combine-extras

Useful bridges between combine and Swift concurrency.

## Overview

This library comes with a couple of tools to seamlessly transition combine into the Swift
concurrency world and vice versa. The main goal is to make the briding as smooth as possible. This
especially includes cancellation to be propagated into the other world correctly.

## Installation via SPM

Add the following to you `Package.swift` description.

```Swift
.package(url: "git@github.com:pEEcor/swift-combine-extras.git", from: "0.2.2")
```

The exposed library is named `CombineExtras`.

## Complete Concurrency Checking

This library is compiled with complete-concurrency-checking enabled to pave the way towards
optional concurrency checking in Swift 6. All types are designed to be concurrency safe. This
however also means that the values that are returned from async operations or published by publisher
need to be `Sendable` too.

## Documentation

The latest documentation for this library is available [here][documentation].

## License

This library is released under the MIT license. See [LICENSE](LICENSE) for details.

[documentation]: https://peecor.github.io/swift-combine-extras/main/documentation/combineextras/