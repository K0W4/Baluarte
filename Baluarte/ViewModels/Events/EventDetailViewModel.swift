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
    
    public var activeMembers: [Member] = []
    public var seniorMembers: [Member] = []
    public var advisoryCouncil: [Member] = []
    
    private let eventService: EventServiceProtocol
    private let memberService: MemberServiceProtocol
    private var event: Event
    private let currentMembershipId: UUID
    
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
        event.confirmedAttendees?.contains(currentMembershipId) ?? false
    }
    
    public init(event: Event, currentMembershipId: UUID, eventService: EventServiceProtocol = Services.event, memberService: MemberServiceProtocol = Services.member) {
        self.event = event
        self.eventService = eventService
        self.memberService = memberService
        self.currentMembershipId = currentMembershipId
        
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
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = String(localized: "Erro ao atualizar o evento.")
            isLoading = false
            return false
        }
    }
    
    public func toggleAttendance() async {
        isLoading = true
        errorMessage = nil
        
        do {
            if isUserConfirmed {
                try await eventService.removeAttendance(eventId: event.id, userId: currentMembershipId)
                event.confirmedAttendees?.removeAll(where: { $0 == currentMembershipId })
                NotificationService.shared.cancelEventReminder(eventId: event.id.uuidString)
            } else {
                try await eventService.confirmAttendance(eventId: event.id, userId: currentMembershipId)
                if event.confirmedAttendees == nil {
                    event.confirmedAttendees = []
                }
                event.confirmedAttendees?.append(currentMembershipId)
                NotificationService.shared.scheduleEventReminder(for: event.title, date: event.scheduledDate, eventId: event.id.uuidString)
            }
            await loadMembers()
            isLoading = false
        } catch {
            if error is CancellationError { return }
            print("❌ Supabase Error: \(error)")
            errorMessage = String(localized: "Erro ao atualizar presença.")
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
            if error is CancellationError { return false }
            print("❌ Supabase Error: \(error)")
            errorMessage = String(localized: "Erro ao excluir o evento.")
            isLoading = false
            return false
        }
    }
    
    public func loadMembers() async {
        do {
            let allMembers = try await memberService.fetchMembers(for: event.chapterId)
            let attendees = allMembers.filter { event.confirmedAttendees?.contains($0.id) ?? false }
            
            self.activeMembers = attendees.filter { $0.isActive && !$0.isSenior && !$0.isMason && $0.role != "Consultor" }.sorted(by: { $0.fullName < $1.fullName })
            self.seniorMembers = attendees.filter { $0.isSenior }.sorted(by: { $0.fullName < $1.fullName })
            self.advisoryCouncil = attendees.filter { $0.isMason || $0.role == "Consultor" }.sorted(by: { $0.fullName < $1.fullName })
        } catch {
            print("❌ Supabase Error (Event Members): \(error)")
        }
    }
}
