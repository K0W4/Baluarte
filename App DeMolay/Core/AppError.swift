import Foundation

public enum AppError: Error, LocalizedError {
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
            return "Sem conexão com a internet. Verifique sua rede e tente novamente."
        case .serverError:
            return "O servidor está temporariamente indisponível. Tente novamente em alguns instantes."
        case .authenticationRequired:
            return "Sua sessão expirou. Faça login novamente."
        case .permissionDenied:
            return "Você não tem permissão para realizar esta ação."
        case .notFound:
            return "O recurso solicitado não foi encontrado."
        case .validationFailed(let message):
            return message
        case .timeout:
            return "A operação demorou mais do que o esperado. Tente novamente."
        case .unknown:
            return "Ocorreu um erro inesperado. Tente novamente."
        }
    }
    
    public var errorDescription: String? { userMessage }
    
    public static func from(_ error: Error) -> AppError {
        let description = String(describing: error)
        
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
}
