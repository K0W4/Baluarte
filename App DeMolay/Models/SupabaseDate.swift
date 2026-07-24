import Foundation

@propertyWrapper
public struct SupabaseDate: Codable, Hashable {
    public var wrappedValue: Date?
    
    public init(wrappedValue: Date?) {
        self.wrappedValue = wrappedValue
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if container.decodeNil() {
            wrappedValue = nil
            return
        }
        
        let dateString = try container.decode(String.self)
        
        let isoFormatter = ISO8601DateFormatter()
        isoFormatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = isoFormatter.date(from: dateString) {
            wrappedValue = date
            return
        }
        
        isoFormatter.formatOptions = [.withInternetDateTime]
        if let date = isoFormatter.date(from: dateString) {
            wrappedValue = date
            return
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        if let date = dateFormatter.date(from: dateString) {
            wrappedValue = date
            return
        }
        
        let fallback = DateFormatter()
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
        fallback.timeZone = TimeZone(abbreviation: "UTC")
        if let date = fallback.date(from: dateString) {
            wrappedValue = date
            return
        }
        
        fallback.dateFormat = "yyyy-MM-dd'T'HH:mm:ss"
        if let date = fallback.date(from: dateString) {
            wrappedValue = date
            return
        }
        
        throw DecodingError.dataCorruptedError(in: container, debugDescription: "Invalid date format: \(dateString)")
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let date = wrappedValue {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd"
            try container.encode(dateFormatter.string(from: date))
        } else {
            try container.encodeNil()
        }
    }
}

extension KeyedDecodingContainer {
    public func decode(_ type: SupabaseDate.Type, forKey key: Key) throws -> SupabaseDate {
        if let value = try self.decodeIfPresent(type, forKey: key) {
            return value
        }
        return SupabaseDate(wrappedValue: nil)
    }
}
