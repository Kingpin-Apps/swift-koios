import Foundation

enum KoiosError: Error, CustomStringConvertible, Equatable {
    case invalidBasePath(String?)
    case missingAPIKey(String?)
    case valueError(String?)
    
    var description: String {
        switch self {
            case .invalidBasePath(let message):
                return message ?? "Invalid base path."
            case .missingAPIKey(let message):
                return message ?? "The API Key is missing."
            case .valueError(let message):
                return message ?? "The value is invalid."
        }
    }
}
