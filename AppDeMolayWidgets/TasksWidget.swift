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
        var fetchedTasks: [ChapterTask] = []
        var fetchError: String? = nil
        do {
            fetchedTasks = try await WidgetDataManager.shared.fetchPendingTasks()
        } catch {
            fetchError = error.localizedDescription
            print("Widget Error: \(error)")
        }
        
        let totalCount = fetchedTasks.count
        let entry = TasksEntry(date: Date(), tasks: Array(fetchedTasks.prefix(3)), totalPendingCount: totalCount, errorMessage: fetchError, configuration: configuration)
        let nextUpdate = Calendar.current.date(byAdding: .minute, value: 15, to: Date())!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
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
                Text("Tarefas")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.accent)
                
                Spacer()
                
                Text("\(entry.totalPendingCount)")
                    .font(.subheadline)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
            }
            
            if entry.tasks.isEmpty {
                HStack(spacing: 8) {
                    if family == .systemMedium {
                        Image(systemName: "checklist.checked")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    Text("Todas as tarefas concluídas")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        
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

