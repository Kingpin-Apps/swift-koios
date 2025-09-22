import Foundation
import OpenAPIRuntime
import OpenAPIURLSession
import HTTPTypes

/// The network to use.
public enum Network {
    case mainnet
    case preprod
    case preview
    case guild
    case sancho
    
    public func url() throws -> URL {
        switch self {
            case .mainnet:
                return try Servers.Server1.url()
            case .guild:
                return try Servers.Server2.url()
            case .preview:
                return try Servers.Server3.url()
            case .preprod:
                return try Servers.Server4.url()
            case .sancho:
                return try Servers.Server5.url()
        }
    }
}

extension HTTPField.Name {
    public static var authorization: Self { .init("authorization")! }
}

/// A client middleware that injects a value into the `Authorization` header field of the request.
package struct AuthenticationMiddleware {
    
    /// The value for the `Authorization` header field.
    private let authorization: String
    
    /// Creates a new middleware.
    /// - Parameter value: The value for the `Authorization` header field.
    package init(authorizationHeaderFieldValue authorization: String) { self.authorization = "Bearer \(authorization)" }
}

extension AuthenticationMiddleware: ClientMiddleware {
    package func intercept(
        _ request: HTTPRequest,
        body: HTTPBody?,
        baseURL: URL,
        operationID: String,
        next: (HTTPRequest, HTTPBody?, URL) async throws -> (HTTPResponse, HTTPBody?)
    ) async throws -> (HTTPResponse, HTTPBody?) {
        var request = request
        // Adds the `Authorization` header field with the provided value.
        request.headerFields[.authorization] = authorization
        return try await next(request, body, baseURL)
    }
}

public struct Koios {
    public let client: Client
    public let network: Network
    public let apiKey: String?
    
    public init(
        network: Network,
        apiKey: String? = nil,
        basePath: String? = nil,
        environmentVariable: String? = nil,
        client: Client? = nil,
    ) throws {
        self.network = network
        
        if let apiKey = apiKey {
            self.apiKey = apiKey
        } else if let environmentVariable = environmentVariable {
            guard let apiKey = ProcessInfo.processInfo.environment[environmentVariable],
                  !apiKey.isEmpty else {
                throw KoiosError.missingAPIKey("Environment variable \(environmentVariable) is not set or empty.")
            }
            self.apiKey = apiKey
        } else {
            self.apiKey = apiKey
        }
        
        let serverURL: URL
        if let basePath = basePath {
            guard let url = URL(string: basePath) else {
                throw KoiosError.invalidBasePath("Invalid base path: \(basePath)")
            }
            serverURL = url
        } else {
            guard let url = try? network.url() else {
                throw KoiosError.invalidBasePath("Could not determine server URL for network \(network).")
            }
            serverURL = url
        }
        
        self.client = client ?? Client(
            serverURL: serverURL,
            transport: URLSessionTransport(),
            middlewares: (self.apiKey != nil) ? [AuthenticationMiddleware(authorizationHeaderFieldValue: self.apiKey!)] : []
        )
    }
    
}
