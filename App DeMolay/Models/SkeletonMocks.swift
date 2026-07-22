import Foundation

public extension Event {
    static var skeletonMock: Event {
        Event(id: UUID(), chapterId: UUID(), title: "Evento Carregando Longo", scheduledDate: Date(), eventType: "Reunião", notes: "Carregando notas do evento", confirmedAttendees: [], createdAt: Date())
    }
    
    static var skeletonList: [Event] {
        return (0..<2).map { _ in skeletonMock }
    }
}

public extension Goal {
    static var skeletonMock: Goal {
        Goal(id: UUID(), chapterId: UUID(), type: "memberCount", title: "Meta Exemplo Longa", description: "Carregando...", currentValue: 50, targetValue: 100, targetDate: Date(), createdAt: Date())
    }
    
    static var skeletonList: [Goal] {
        return (0..<3).map { _ in skeletonMock }
    }
}

public extension Committee {
    static var skeletonMock: Committee {
        Committee(id: UUID(), chapterId: UUID(), name: "Comissão Exemplo Carregando", chairmanId: UUID(), createdAt: Date())
    }
    
    static var skeletonList: [Committee] {
        return (0..<2).map { _ in skeletonMock }
    }
}

public extension ChapterTask {
    static var skeletonMock: ChapterTask {
        ChapterTask(id: UUID(), chapterId: UUID(), creatorId: UUID(), assigneeId: UUID(), committeeId: nil, title: "Tarefa muito longa carregando", description: "Descrição que quebra linha com detalhes", isCompleted: false, dueDate: Date(), createdAt: Date())
    }
    
    static var skeletonList: [ChapterTask] {
        return (0..<4).map { _ in skeletonMock }
    }
}

public extension Member {
    static var skeletonMock: Member {
        Member(id: UUID(), chapterId: UUID(), fullName: "Nome Sobrenome Extenso", role: "Mestre Conselheiro", isActive: true, isSenior: false, isMason: false, accessLevel: "member", birthdate: Date(), cid: "12345", createdAt: Date())
    }
    
    static var skeletonList: [Member] {
        return (0..<5).map { _ in skeletonMock }
    }
}
