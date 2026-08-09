import Foundation

/// O que o widget precisa saber sobre um Capítulo para deixar alguém escolher entre
/// eles. Vive num modelo próprio, e não no `ChapterMembership`, porque atravessa o app
/// group: é escrito pelo app e lido por outro processo, que não fala com o Supabase
/// para descobrir um nome.
///
/// Chaveado pelo vínculo, e não pelo Capítulo, porque é o vínculo que o widget usa
/// para filtrar tarefas e marcar presença — quem tem dupla filiação tem dois vínculos
/// e dois nomes, e trocar um pelo outro mostraria as tarefas do Capítulo errado.
public struct WidgetChapter: Codable, Identifiable, Hashable, Sendable {
    public let membershipId: UUID
    public let chapterId: UUID
    public let name: String

    public var id: UUID { membershipId }

    public init(membershipId: UUID, chapterId: UUID, name: String) {
        self.membershipId = membershipId
        self.chapterId = chapterId
        self.name = name
    }
}
