import Foundation
import SwiftUI

@Observable
@MainActor
public final class CreateEventViewModel {
    public var title: String = ""
    public var eventType: String = "Reunião Ritualística"
    public var scheduledDate: Date
    public var notes: String = ""
    
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    private let eventService: EventServiceProtocol
    private let chapterId: UUID
    
    public let eventTypes = ["Reunião Ritualística", "Reunião Administrativa", "Congresso", "Filantropia", "Monetário", "Outro"]
    
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !notes.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init(chapterId: UUID, eventService: EventServiceProtocol = Services.event, initialDate: Date? = nil) {
        self.eventService = eventService
        self.chapterId = chapterId
        self.scheduledDate = initialDate ?? Self.nextSaturdayAt13()
    }
    
    public static func nextSaturdayAt13() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        var daysToAdd = 7 - weekday
        if daysToAdd <= 0 { daysToAdd += 7 }
        
        let nextSaturday = calendar.date(byAdding: .day, value: daysToAdd, to: now)!
        return calendar.date(bySettingHour: 13, minute: 0, second: 0, of: nextSaturday)!
    }
    
    public func saveEvent() async -> Bool {
        guard isValid else { return false }
        
        isLoading = true
        errorMessage = nil
        
        let newEvent = Event(
            id: UUID(),
            chapterId: chapterId,
            title: title.trimmingCharacters(in: .whitespacesAndNewlines),
            scheduledDate: scheduledDate,
            eventType: eventType,
            notes: notes.isEmpty ? nil : notes,
            confirmedAttendees: [],
            createdAt: Date()
        )
        
        do {
            try await eventService.createEvent(newEvent)
            isLoading = false
            return true
        } catch {
            if error is CancellationError { return false }
            print("❌ Erro no Supabase (Create Event): \(error)")
            errorMessage = "Erro ao criar o evento: \(error.localizedDescription)"
            isLoading = false
            return false
        }
    }
}
