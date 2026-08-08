import Foundation
import Supabase

public enum AppError: Error, LocalizedError, Equatable {
    case networkUnavailable
    case serverError
    case authenticationRequired
    case permissionDenied
    case notFound
    case validationFailed(String)
    case timeout
    case unknown
    
    public var userMessage: String {
        switch self {
        case .networkUnavailable:
            return String(localized: "Sem conexão com a internet. Verifique sua rede e tente novamente.")
        case .serverError:
            return String(localized: "O servidor está temporariamente indisponível. Tente novamente em alguns instantes.")
        case .authenticationRequired:
            return String(localized: "Sua sessão expirou. Faça login novamente.")
        case .permissionDenied:
            return String(localized: "Você não tem permissão para realizar esta ação.")
        case .notFound:
            return String(localized: "O recurso solicitado não foi encontrado.")
        case .validationFailed(let message):
            return message
        case .timeout:
            return String(localized: "A operação demorou mais do que o esperado. Tente novamente.")
        case .unknown:
            return String(localized: "Ocorreu um erro inesperado. Tente novamente.")
        }
    }
    
    public var errorDescription: String? { userMessage }
    
    public static func from(_ error: Error) -> AppError {
        if let appError = error as? AppError {
            return appError
        }

        let description = String(describing: error)

        // Business rules live in Postgres. Each raise that can reach a person carries a
        // stable `baluarte.` hint, which is what gets translated — the message itself is
        // always Portuguese, because the server does not know the caller's language.
        //
        // The hint is consulted before the code on purpose: an authorization failure that
        // names a real reason ("chapters cannot be moved") is more useful than the generic
        // refusal, and none of those reasons discloses anyone's data. A bare
        // `insufficient_privilege` carries no hint and still reads as a plain refusal.
        if let postgrestError = error as? PostgrestError {
            if let message = ServerMessage.localized(hint: postgrestError.hint) {
                return .validationFailed(message)
            }
            switch postgrestError.code {
            case "42501":
                return .permissionDenied
            case "PGRST116", "P0002":
                return .notFound
            case "23514":
                // Fallback for any raise the hints migration did not reach: the Portuguese
                // message is worse than a translation but better than nothing.
                let message = postgrestError.message
                return message.isEmpty ? .unknown : .validationFailed(message)
            default:
                // Everything else is a constraint name, a PostgREST diagnostic or a
                // Postgres internal — text written for a developer, never for a member.
                return .serverError
            }
        }

        // PostgrestBuilder throws HTTPError when the body is not a PostgREST envelope.
        // Without this the code below matches "403" against a stringified Data blob.
        if let httpError = error as? HTTPError {
            return from(statusCode: httpError.response.statusCode)
        }

        if let urlError = error as? URLError {
            switch urlError.code {
            case .notConnectedToInternet, .networkConnectionLost:
                return .networkUnavailable
            case .timedOut:
                return .timeout
            default:
                return .serverError
            }
        }
        
        if description.contains("401") || description.contains("unauthorized") {
            return .authenticationRequired
        }
        
        if description.contains("403") || description.contains("forbidden") {
            return .permissionDenied
        }
        
        if description.contains("404") || description.contains("PGRST116") {
            return .notFound
        }
        
        if description.contains("500") || description.contains("502") || description.contains("503") {
            return .serverError
        }
        
        return .unknown
    }

    private static func from(statusCode: Int) -> AppError {
        switch statusCode {
        case 401: return .authenticationRequired
        case 403: return .permissionDenied
        case 404, 406: return .notFound
        case 408: return .timeout
        case 500...599: return .serverError
        default: return .unknown
        }
    }
}
