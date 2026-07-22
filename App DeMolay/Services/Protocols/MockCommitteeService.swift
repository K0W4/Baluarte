import Foundation

public struct MockCommitteeService: CommitteeServiceProtocol {
    nonisolated public init() {}

    public func fetchCommittees(for chapterId: UUID) async throws -> [Committee] {
        try await Task.sleep(nanoseconds: 300_000_000)
        return [
            Committee(id: UUID(), chapterId: chapterId, name: "Sindicância", chairmanId: nil, createdAt: Date()),
            Committee(id: UUID(), chapterId: chapterId, name: "Hospitalaria", chairmanId: nil, createdAt: Date()),
            Committee(id: UUID(), chapterId: chapterId, name: "Finanças", chairmanId: nil, createdAt: Date()),
            Committee(id: UUID(), chapterId: chapterId, name: "Eventos", chairmanId: nil, createdAt: Date())
        ]
    }
}
