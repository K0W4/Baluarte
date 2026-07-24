import AppIntents
import WidgetKit

struct ConfirmAttendanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Confirmar Presença"
    static var description = IntentDescription("Confirma a presença no evento diretamente pelo Widget.")
    
    @Parameter(title: "ID do Evento")
    var eventId: String
    
    init() {}
    
    init(eventId: String) {
        self.eventId = eventId
    }
    
    func perform() async throws -> some IntentResult {
        do {
            try await WidgetDataManager.shared.confirmAttendance(eventId: eventId)
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                WidgetCenter.shared.reloadTimelines(ofKind: "EventWidget")
                WidgetCenter.shared.reloadTimelines(ofKind: "TasksWidget")
            }
        } catch {
            print("Erro ao confirmar presença pelo widget: \(error)")
        }
        return .result()
    }
}

struct ToggleTaskIntent: AppIntent {
    static var title: LocalizedStringResource = "Concluir Tarefa"
    static var description = IntentDescription("Marca a tarefa como concluída diretamente pelo Widget.")
    
    @Parameter(title: "ID da Tarefa")
    var taskId: String
    
    init() {}
    
    init(taskId: String) {
        self.taskId = taskId
    }
    
    func perform() async throws -> some IntentResult {
        do {
            try await WidgetDataManager.shared.toggleTaskCompletion(taskId: taskId)
            Task {
                try? await Task.sleep(nanoseconds: 500_000_000)
                WidgetCenter.shared.reloadTimelines(ofKind: "EventWidget")
                WidgetCenter.shared.reloadTimelines(ofKind: "TasksWidget")
            }
        } catch {
            print("Erro ao alternar tarefa pelo widget: \(error)")
        }
        return .result()
    }
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuração"
    static var description = IntentDescription("Configurações do widget.")
}

