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
        // Detalhes é opcional, como já era na edição. Exigi-lo aqui sem dizer em lugar
        // nenhum fazia o visto de salvar ficar cinza sem explicação: a pessoa preenchia
        // título, tipo e data, tocava, e nada acontecia.
        !title.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    public init(chapterId: UUID, eventService: EventServiceProtocol = Services.event, initialDate: Date? = nil) {
        self.eventService = eventService
        self.chapterId = chapterId
        // O dia vem do calendário, a hora não. As datas da grade saem de somas de dias
        // inteiros, então são meia-noite: tocar num dia e depois no "+" abria o formulário
        // marcando a reunião para 00:00, e quem não reparasse criava o evento de madrugada.
        if let initialDate {
            let calendar = Calendar.current
            self.scheduledDate = calendar.date(bySettingHour: 13, minute: 0, second: 0, of: initialDate) ?? initialDate
        } else {
            self.scheduledDate = Self.nextSaturdayAt13()
        }
    }
    
    public static func nextSaturdayAt13() -> Date {
        let calendar = Calendar.current
        let now = Date()
        let weekday = calendar.component(.weekday, from: now)
        var daysToAdd = 7 - weekday
        if daysToAdd <= 0 { daysToAdd += 7 }
        
        // Sem `!`: `date(bySettingHour:)` devolve nil em horários que não existem por
        // transição de fuso, e o projeto proíbe força-desempacotamento em qualquer lugar.
        guard let nextSaturday = calendar.date(byAdding: .day, value: daysToAdd, to: now) else { return now }
        return calendar.date(bySettingHour: 13, minute: 0, second: 0, of: nextSaturday) ?? nextSaturday
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
            errorMessage = AppError.from(error).userMessage
            isLoading = false
            return false
        }
    }
}
