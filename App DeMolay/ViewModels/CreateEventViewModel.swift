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
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init(eventService: EventServiceProtocol = Services.event, chapterId: UUID = Constants.testChapterId, initialDate: Date = Date()) {
        self.eventService = eventService
        self.chapterId = chapterId
        self.scheduledDate = initialDate
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
