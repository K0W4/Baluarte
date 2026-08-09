import AppIntents
import WidgetKit

/// As duas intents abaixo engoliam o erro, davam `print` e devolviam `.result()` como
/// se tivesse dado certo — o toque marcava presença na tela e nada acontecia no
/// servidor. Deixar o erro subir é o que faz o iOS avisar quem tocou.
struct ConfirmAttendanceIntent: AppIntent {
    static var title: LocalizedStringResource = "Confirmar Presença"
    static var description = IntentDescription("Confirma a presença no evento diretamente pelo Widget.")

    @Parameter(title: "ID do Evento")
    var eventId: String

    /// O vínculo em que a presença é marcada. Vem do widget que disparou a intent, para
    /// quem tem dupla filiação não confirmar presença no Capítulo errado.
    @Parameter(title: "ID do Vínculo")
    var membershipId: String?

    init() {}

    init(eventId: String, membershipId: String? = nil) {
        self.eventId = eventId
        self.membershipId = membershipId
    }

    func perform() async throws -> some IntentResult {
        try await WidgetDataManager.shared.confirmAttendance(
            eventId: eventId,
            membershipId: membershipId
        )
        reloadWidgets()
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
        try await WidgetDataManager.shared.toggleTaskCompletion(taskId: taskId)
        reloadWidgets()
        return .result()
    }
}

/// A escrita já foi confirmada pelo servidor quando isto roda, então não há o que
/// esperar. A versão anterior recarregava dentro de uma `Task` solta com meio segundo
/// de `sleep` — trabalho que o sistema pode encerrar junto com o processo da extensão,
/// e que só existia para dar tempo a uma escrita que já tinha terminado.
private func reloadWidgets() {
    WidgetCenter.shared.reloadTimelines(ofKind: "EventWidget")
    WidgetCenter.shared.reloadTimelines(ofKind: "TasksWidget")
}

struct ConfigurationAppIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Configuração"
    static var description = IntentDescription("Escolha qual Capítulo este widget acompanha.")

    /// Opcional de propósito: sem escolha, o widget acompanha o Capítulo aberto no app.
    /// A consulta devolve lista vazia para quem tem uma filiação só, então a escolha só
    /// aparece para quem de fato tem dois Capítulos.
    @Parameter(title: "Capítulo")
    var chapter: ChapterEntity?

    init() {}

    init(chapter: ChapterEntity?) {
        self.chapter = chapter
    }
}
