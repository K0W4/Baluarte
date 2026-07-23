import Foundation
import SwiftUI

@Observable
@MainActor
public final class EventDetailViewModel {
    public var title: String
    public var eventType: String
    public var scheduledDate: Date
    public var notes: String
    
    public var isLoading: Bool = false
    public var errorMessage: String? = nil
    
    public let eventTypes = ["Reunião Ritualística", "Reunião Administrativa", "Congresso", "Filantropia", "Monetário", "Outro"]
    
    private let eventService: EventServiceProtocol
    private var event: Event
    private let currentUserId: UUID
    
    public var isValid: Bool {
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public var hasChanges: Bool {
        event.title != title ||
        event.eventType != eventType ||
        event.scheduledDate != scheduledDate ||
        (event.notes ?? "") != notes
    }
    
    public var isUserConfirmed: Bool {
        event.confirmedAttendees?.contains(currentUserId) ?? false
    }
    
    public init(event: Event, eventService: EventServiceProtocol = MockEventService(), currentUserId: UUID = UUID()) {
        self.event = event
        self.eventService = eventService
        self.currentUserId = currentUserId
        
        self.title = event.title
        self.eventType = event.eventType
        self.scheduledDate = event.scheduledDate
        self.notes = event.notes ?? ""
    }
    
    public func saveChanges() async -> Bool {
        guard isValid && hasChanges else { return false }
        
        isLoading = true
        errorMessage = nil
        
        var updatedEvent = event
        updatedEvent.title = title.trimmingCharacters(in: .whitespacesAndNewlines)
        updatedEvent.eventType = eventType
        updatedEvent.scheduledDate = scheduledDate
        updatedEvent.notes = notes.isEmpty ? nil : notes
        
        do {
            try await eventService.updateEvent(updatedEvent)
            self.event = updatedEvent
            isLoading = false
            return true
        } catch {
            errorMessage = "Erro ao atualizar o evento."
            isLoading = false
            return false
        }
    }
    
    public func toggleAttendance() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isUserConfirmed {
                try await eventService.removeAttendance(eventId: event.id, userId: currentUserId)
                event.confirmedAttendees?.removeAll(where: { $0 == currentUserId })
            } else {
                try await eventService.confirmAttendance(eventId: event.id, userId: currentUserId)
                if event.confirmedAttendees == nil {
                    event.confirmedAttendees = []
                }
                event.confirmedAttendees?.append(currentUserId)
            }
            isLoading = false
        } catch {
            errorMessage = "Erro ao atualizar presença."
            isLoading = false
        }
    }
    
    public func deleteEvent() async -> Bool {
        isLoading = true
        errorMessage = nil
        
        do {
            try await eventService.deleteEvent(eventId: event.id)
            isLoading = false
            return true
        } catch {
            errorMessage = "Erro ao excluir o evento."
            isLoading = false
            return false
        }
    }
}
