import WidgetKit
import SwiftUI
import AppIntents

// MARK: - Tasks Provider
struct TasksProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> TasksEntry {
        TasksEntry(date: Date(), tasks: ChapterTask.mockList, totalPendingCount: 3, errorMessage: nil, configuration: ConfigurationAppIntent())
    }

    func snapshot(for configuration: ConfigurationAppIntent, in context: Context) async -> TasksEntry {
        TasksEntry(date: Date(), tasks: ChapterTask.mockList, totalPendingCount: 3, errorMessage: nil, configuration: configuration)
    }
    
    func timeline(for configuration: ConfigurationAppIntent, in context: Context) async -> Timeline<TasksEntry> {
        let membershipId = configuration.chapter?.id.uuidString
        var fetchedTasks: [ChapterTask] = []
        var fetchError: String? = nil

        do {
            fetchedTasks = try await WidgetDataManager.shared.fetchPendingTasks(membershipId: membershipId)
        } catch {
            fetchError = error.localizedDescription
            fetchedTasks = WidgetDataManager.shared.cachedTasks(membershipId: membershipId) ?? []
        }

        let entry = TasksEntry(
            date: Date(),
            tasks: Array(fetchedTasks.prefix(3)),
            totalPendingCount: fetchedTasks.count,
            errorMessage: fetchError,
            configuration: configuration
        )
        return Timeline(entries: [entry], policy: .after(EventProvider.nextRefresh))
    }
}

// MARK: - Tasks Entry
struct TasksEntry: TimelineEntry {
    let date: Date
    let tasks: [ChapterTask]
    let totalPendingCount: Int
    let errorMessage: String?
    let configuration: ConfigurationAppIntent
}

// MARK: - Tasks Widget View
struct TasksWidgetEntryView : View {
    var entry: TasksProvider.Entry
    @Environment(\.widgetFamily) var family
    
    var body: some View {
        VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 16) {
            HStack(alignment: .center) {
                Text(entry.configuration.chapter?.name ?? String(localized: "Tarefas"))
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                    .lineLimit(1)

                Spacer()

                if entry.errorMessage != nil && !entry.tasks.isEmpty {
                    StaleDataBadge()
                } else {
                    Text("\(entry.totalPendingCount)")
                        .font(.subheadline)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                }
            }

            if entry.tasks.isEmpty {
                // Dizer "todas as tarefas concluídas" quando a leitura falhou é elogiar
                // alguém por trabalho que talvez esteja todo pendente.
                WidgetPlaceholder(
                    icon: entry.errorMessage == nil ? "checklist.checked" : "exclamationmark.triangle",
                    message: entry.errorMessage ?? String(localized: "Todas as tarefas concluídas"),
                    showsIcon: family == .systemMedium
                )
            } else {
                VStack(alignment: .leading, spacing: family == .systemSmall ? 8 : 16) {
                    ForEach(entry.tasks) { task in
                        HStack(alignment: .center, spacing: 4) {
                            Button(intent: ToggleTaskIntent(taskId: task.id.uuidString)) {
                                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(task.isCompleted ? .green : .secondary)
                                    .font(.subheadline)
                            }
                            .buttonStyle(.plain)
                            
                            Text(task.title)
                                .font(family == .systemSmall ? .caption : .subheadline)
                                .foregroundColor(.primary)
                                .lineLimit(2)
                        }
                    }
                }
                Spacer(minLength: 0)
            }
        }
        .padding(2)
        .containerBackground(Color(UIColor.systemBackground), for: .widget)
    }
}

// MARK: - Widget Configuration
struct TasksWidget: Widget {
    let kind: String = "TasksWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: kind, intent: ConfigurationAppIntent.self, provider: TasksProvider()) { entry in
            TasksWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Minhas Tarefas")
        .description("Gerencie e conclua suas tarefas diretamente da tela inicial.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

// MARK: - Mock for Previews
extension ChapterTask {
    static var mockList: [ChapterTask] {
        [
            ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Ler Ritual", description: "", isCompleted: false, createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Comprar salgados", description: "", isCompleted: false, createdAt: Date()),
            ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), title: "Avisar os sêniors", description: "", isCompleted: false, createdAt: Date())
        ]
    }
}

#Preview("Small", as: .systemSmall) {
    TasksWidget()
} timeline: {
    TasksEntry(date: .now, tasks: ChapterTask.mockList, totalPendingCount: 5, errorMessage: nil, configuration: ConfigurationAppIntent())
}

#Preview("Medium", as: .systemMedium) {
    TasksWidget()
} timeline: {
    TasksEntry(date: .now, tasks: ChapterTask.mockList, totalPendingCount: 5, errorMessage: nil, configuration: ConfigurationAppIntent())
}

