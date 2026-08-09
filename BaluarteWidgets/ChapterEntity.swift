import AppIntents
import Foundation

/// Um Capítulo oferecido na configuração do widget. O id é o do **vínculo**, não o do
/// Capítulo: é o vínculo que filtra tarefas e marca presença, e quem tem dupla
/// filiação tem dois vínculos no mesmo aparelho.
struct ChapterEntity: AppEntity {
    let id: UUID
    let chapterId: UUID
    let name: String

    static var typeDisplayRepresentation: TypeDisplayRepresentation {
        TypeDisplayRepresentation(name: "Capítulo")
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(name)")
    }

    static var defaultQuery = ChapterEntityQuery()

    init(id: UUID, chapterId: UUID, name: String) {
        self.id = id
        self.chapterId = chapterId
        self.name = name
    }

    init(_ chapter: WidgetChapter) {
        self.init(id: chapter.membershipId, chapterId: chapter.chapterId, name: chapter.name)
    }
}

/// A lista vem do app group, escrita pelo app: o widget não fala com o Supabase para
/// descobrir o nome de um Capítulo, e não teria sessão para isso na tela de
/// configuração.
struct ChapterEntityQuery: EntityQuery {
    /// Só há o que escolher com dupla filiação. Com um vínculo só, a escolha seria
    /// entre uma coisa e ela mesma — a lista sai vazia de propósito, para a
    /// configuração não oferecer uma decisão que não existe.
    private var selectable: [WidgetChapter] {
        let chapters = availableChapters()
        return chapters.count > 1 ? chapters : []
    }

    private func availableChapters() -> [WidgetChapter] {
        guard let defaults = UserDefaults(suiteName: "group.com.kowa.baluarte"),
              let data = defaults.data(forKey: "widgetChapters"),
              let chapters = try? JSONDecoder().decode([WidgetChapter].self, from: data)
        else { return [] }
        return chapters
    }

    func entities(for identifiers: [UUID]) async throws -> [ChapterEntity] {
        selectable
            .filter { identifiers.contains($0.membershipId) }
            .map(ChapterEntity.init)
    }

    func suggestedEntities() async throws -> [ChapterEntity] {
        selectable.map(ChapterEntity.init)
    }

    /// Sem escolha explícita o widget acompanha o Capítulo aberto no app, que é o que
    /// ele sempre fez. Devolver nulo aqui é o que mantém esse comportamento para quem
    /// tem uma filiação só.
    func defaultResult() async -> ChapterEntity? { nil }
}
