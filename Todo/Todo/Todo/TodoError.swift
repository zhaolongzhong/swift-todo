//
//  TodoError.swift
//

enum NetworkError: Error, Equatable {
    case invalidURL
    case invalidResponse
    case serverError(Int)
    case decodingError
    case noData
}

enum TodoError: Error, Equatable {
    case network(NetworkError)
    case notFound
    case invalidData
    case unauthorized
    case fetchFailed(_ message: String? = nil)
    case updateFailed(_ message: String? = nil)
    case addFailed(_ message: String? = nil)
    case deleteFailed(_ message: String? = nil)
    case genericError(_ message: String? = nil)

    var errorMessage: String {
        switch self {
        case .network(let error):
            return "Network error: \(error)"
        case .notFound:
            return "Todo not found"
        case .invalidData:
            return "Invalid data received"
        case .unauthorized:
            return "Unauthorized access"
        case .fetchFailed(let message):
            return message ?? "Unable to fetch your todos.\nPlease try again later."
        case .updateFailed(let message):
            return message ?? "Failed to update the todo.\nPlease try again."
        case .addFailed(let message):
            return message ?? "Unable to add new todo.\nPlease try again."
        case .deleteFailed(let message):
            return message ?? "Failed to delete the todo.\nPlease try again."
        case .genericError(let message):
            return message ?? "Something went wrong.\nPlease try again later."
        }
    }
}
