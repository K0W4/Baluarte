import Foundation

public final class MockMemberService: MemberServiceProtocol {
    public init() {}
    
    public func fetchMembers(for chapterId: UUID) async throws -> [Member] {
        try await Task.sleep(nanoseconds: 800_000_000)
        
        let calendar = Calendar.current
        let date1 = calendar.date(byAdding: .year, value: -20, to: Date())!
        let date2 = calendar.date(byAdding: .year, value: -22, to: Date())!
        let date3 = calendar.date(byAdding: .year, value: -35, to: Date())!
        let date4 = calendar.date(byAdding: .year, value: -40, to: Date())!
        let date5 = calendar.date(byAdding: .year, value: -18, to: Date())!
        
        return [
            Member(id: UUID(), chapterId: chapterId, fullName: "Gabriel Kowaleski", role: "Mestre Conselheiro", isActive: true, isSenior: false, isMason: false, accessLevel: "admin", birthdate: date1, cid: "123456", createdAt: Date()),
            Member(id: UUID(), chapterId: chapterId, fullName: "João Silva", role: "1º Conselheiro", isActive: true, isSenior: false, isMason: false, accessLevel: "member", birthdate: date2, cid: "123457", createdAt: Date()),
            Member(id: UUID(), chapterId: chapterId, fullName: "Pedro Souza", role: "Presidente do Conselho Consultivo", isActive: false, isSenior: true, isMason: true, accessLevel: "admin", birthdate: date3, cid: "123458", createdAt: Date()),
            Member(id: UUID(), chapterId: chapterId, fullName: "Lucas Almeida", role: nil, isActive: false, isSenior: true, isMason: false, accessLevel: "member", birthdate: date2, cid: "123459", createdAt: Date()),
            Member(id: UUID(), chapterId: chapterId, fullName: "Marcos Oliveira", role: "Consultor", isActive: false, isSenior: false, isMason: true, accessLevel: "member", birthdate: date4, cid: "123460", createdAt: Date()),
            Member(id: UUID(), chapterId: chapterId, fullName: "Thiago Mendes", role: "Escrivão", isActive: true, isSenior: false, isMason: false, accessLevel: "member", birthdate: date5, cid: "123461", createdAt: Date())
        ]
    }
}
