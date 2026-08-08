import AppIntents

public struct DeMolayShortcutsProvider: AppShortcutsProvider {
    public static var shortcutTileColor: ShortcutTileColor {
        .red
    }
    
    public static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: NextEventIntent(),
            phrases: [
                "Qual o próximo evento no \(.applicationName)?",
                "Próxima reunião do \(.applicationName)",
                "Próximo evento no \(.applicationName)"
            ],
            shortTitle: "Próximo Evento",
            systemImageName: "calendar"
        )
        
        AppShortcut(
            intent: ConfirmAttendanceIntent(),
            phrases: [
                "Confirmar presença no \(.applicationName)",
                "Confirmar presença na próxima reunião do \(.applicationName)"
            ],
            shortTitle: "Confirmar presença",
            systemImageName: "checkmark.circle"
        )
        
        AppShortcut(
            intent: CreateTaskIntent(),
            phrases: [
                "Criar tarefa no \(.applicationName)",
                "Adicionar tarefa no \(.applicationName)",
                "Nova tarefa no \(.applicationName)"
            ],
            shortTitle: "Nova Tarefa",
            systemImageName: "plus.circle"
        )
        
        AppShortcut(
            intent: ChapterBriefingIntent(),
            phrases: [
                "Resumo do Capítulo no \(.applicationName)",
                "Meu resumo no \(.applicationName)",
                "Resumo do \(.applicationName)"
            ],
            shortTitle: "Resumo do Capítulo",
            systemImageName: "list.bullet.clipboard"
        )
    }
}
