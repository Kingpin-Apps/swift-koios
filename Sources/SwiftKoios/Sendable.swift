import Foundation

// MARK: - Sendable conformances for generated types
//
// The OpenAPI generator emits `Client` as a public struct whose only stored
// property is `private let client: UniversalClient`. `UniversalClient` is
// declared `Sendable` in `swift-openapi-runtime`, so `Client` is structurally
// safe to share across isolation domains. The generator does not emit a
// `Sendable` conformance and Swift requires same-source-file for synthesized
// `Sendable`, so we declare `@unchecked Sendable` here. The unchecked
// annotation is sound: `Client`'s only stored state is a single `let` of a
// genuinely-`Sendable` value.
extension Client: @unchecked Sendable {}
