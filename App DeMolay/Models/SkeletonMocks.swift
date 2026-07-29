import Foundation

private enum SkeletonIds {
    static let event1 = UUID(uuidString: "00000000-0000-0000-0000-000000000001") ?? UUID()
    static let event2 = UUID(uuidString: "00000000-0000-0000-0000-000000000002") ?? UUID()
    static let goal1 = UUID(uuidString: "00000000-0000-0000-0000-000000000011") ?? UUID()
    static let goal2 = UUID(uuidString: "00000000-0000-0000-0000-000000000012") ?? UUID()
    static let goal3 = UUID(uuidString: "00000000-0000-0000-0000-000000000013") ?? UUID()
    static let committee1 = UUID(uuidString: "00000000-0000-0000-0000-000000000021") ?? UUID()
    static let committee2 = UUID(uuidString: "00000000-0000-0000-0000-000000000022") ?? UUID()
    static let task1 = UUID(uuidString: "00000000-0000-0000-0000-000000000031") ?? UUID()
    static let task2 = UUID(uuidString: "00000000-0000-0000-0000-000000000032") ?? UUID()
    static let task3 = UUID(uuidString: "00000000-0000-0000-0000-000000000033") ?? UUID()
    static let task4 = UUID(uuidString: "00000000-0000-0000-0000-000000000034") ?? UUID()
    static let member1 = UUID(uuidString: "00000000-0000-0000-0000-000000000041") ?? UUID()
    static let member2 = UUID(uuidString: "00000000-0000-0000-0000-000000000042") ?? UUID()
    static let member3 = UUID(uuidString: "00000000-0000-0000-0000-000000000043") ?? UUID()
    static let member4 = UUID(uuidString: "00000000-0000-0000-0000-000000000044") ?? UUID()
    static let member5 = UUID(uuidString: "00000000-0000-0000-0000-000000000045") ?? UUID()
    static let chapter = UUID(uuidString: "00000000-0000-0000-0000-000000000099") ?? UUID()
    static let creator = UUID(uuidString: "00000000-0000-0000-0000-000000000098") ?? UUID()
}

public extension Event {
    static var skeletonList: [Event] {
        [
            Event(id: SkeletonIds.event1, chapterId: SkeletonIds.chapter, title: "Evento Carregando Longo", scheduledDate: Date(), eventType: "Reunião", notes: "Carregando notas do evento", confirmedAttendees: [], createdAt: Date()),
            Event(id: SkeletonIds.event2, chapterId: SkeletonIds.chapter, title: "Segundo Evento Exemplo", scheduledDate: Date(), eventType: "Filantropia", notes: "Mais detalhes aqui", confirmedAttendees: [], createdAt: Date())
        ]
    }
}

public extension Goal {
    static var skeletonList: [Goal] {
        [
            Goal(id: SkeletonIds.goal1, chapterId: SkeletonIds.chapter, title: "Meta Exemplo Longa", description: "Carregando...", currentValue: 50, targetValue: 100, targetDate: Date(), createdAt: Date()),
            Goal(id: SkeletonIds.goal2, chapterId: SkeletonIds.chapter, title: "Segunda Meta", description: "Carregando...", currentValue: 30, targetValue: 100, targetDate: Date(), createdAt: Date()),
            Goal(id: SkeletonIds.goal3, chapterId: SkeletonIds.chapter, title: "Terceira Meta", description: "Carregando...", currentValue: 70, targetValue: 100, targetDate: Date(), createdAt: Date())
        ]
    }
}

public extension Committee {
    static var skeletonList: [Committee] {
        [
            Committee(id: SkeletonIds.committee1, chapterId: SkeletonIds.chapter, name: "Comissão Exemplo Carregando", chairmanId: nil, createdAt: Date()),
            Committee(id: SkeletonIds.committee2, chapterId: SkeletonIds.chapter, name: "Segunda Comissão Carregando", chairmanId: nil, createdAt: Date())
        ]
    }
}

public extension ChapterTask {
    static var skeletonList: [ChapterTask] {
        [
            ChapterTask(id: SkeletonIds.task1, chapterId: SkeletonIds.chapter, creatorId: SkeletonIds.creator, title: "Tarefa muito longa carregando", description: "Descrição que quebra linha com detalhes", isCompleted: false, dueDate: Date(), createdAt: Date()),
            ChapterTask(id: SkeletonIds.task2, chapterId: SkeletonIds.chapter, creatorId: SkeletonIds.creator, title: "Segunda tarefa exemplo", description: "Mais uma descrição", isCompleted: false, dueDate: Date(), createdAt: Date()),
            ChapterTask(id: SkeletonIds.task3, chapterId: SkeletonIds.chapter, creatorId: SkeletonIds.creator, title: "Terceira tarefa pendente", description: "", isCompleted: false, dueDate: nil, createdAt: Date()),
            ChapterTask(id: SkeletonIds.task4, chapterId: SkeletonIds.chapter, creatorId: SkeletonIds.creator, title: "Quarta tarefa do capítulo", description: "Descrição curta", isCompleted: false, dueDate: Date(), createdAt: Date())
        ]
    }
}

public extension Member {
    static var skeletonList: [Member] {
        [
            Member(id: SkeletonIds.member1, chapterId: SkeletonIds.chapter, fullName: "Nome Sobrenome Extenso", role: "Mestre Conselheiro", isActive: true, isSenior: false, isMason: false, accessLevel: "member", birthdate: Date(), cid: "12345", createdAt: Date()),
            Member(id: SkeletonIds.member2, chapterId: SkeletonIds.chapter, fullName: "Segundo Nome Completo", role: "Primeiro Conselheiro", isActive: true, isSenior: false, isMason: false, accessLevel: "member", birthdate: Date(), cid: "12346", createdAt: Date()),
            Member(id: SkeletonIds.member3, chapterId: SkeletonIds.chapter, fullName: "Terceiro Membro Aqui", role: "Escrivão", isActive: true, isSenior: false, isMason: false, accessLevel: "member", birthdate: Date(), cid: "12347", createdAt: Date()),
            Member(id: SkeletonIds.member4, chapterId: SkeletonIds.chapter, fullName: "Quarto Participante", role: nil, isActive: false, isSenior: true, isMason: false, accessLevel: "member", birthdate: Date(), cid: "12348", createdAt: Date()),
            Member(id: SkeletonIds.member5, chapterId: SkeletonIds.chapter, fullName: "Quinto Integrante", role: "Consultor", isActive: false, isSenior: false, isMason: true, accessLevel: "member", birthdate: Date(), cid: "12349", createdAt: Date())
        ]
    }
}

extension DisplayedAnalysis {
    static var skeletonList: [DisplayedAnalysis] {
        [
            DisplayedAnalysis(
                rawAnalysis: RawAnalysis(category: .membership, severity: .info, contextData: [:], fallbackTitle: "", fallbackMessage: ""),
                generatedTitle: "Analisando Gestão",
                generatedMessage: "Por favor aguarde, processando os dados e gerando insights inteligentes para o seu Capítulo.",
                actionLabel: "Ver Membros"
            ),
            DisplayedAnalysis(
                rawAnalysis: RawAnalysis(category: .membership, severity: .warning, contextData: [:], fallbackTitle: "", fallbackMessage: ""),
                generatedTitle: "Buscando Padrões",
                generatedMessage: "Aguardando o processamento da Apple Intelligence para exibir esta análise.",
                actionLabel: nil
            ),
            DisplayedAnalysis(
                rawAnalysis: RawAnalysis(category: .membership, severity: .info, contextData: [:], fallbackTitle: "", fallbackMessage: ""),
                generatedTitle: "Calculando Idades",
                generatedMessage: "Analisando a faixa etária do Capítulo para encontrar o perfil ideal de novos iniciáticos.",
                actionLabel: "Ver Membros"
            ),
            DisplayedAnalysis(
                rawAnalysis: RawAnalysis(category: .structure, severity: .actionRequired, contextData: [:], fallbackTitle: "", fallbackMessage: ""),
                generatedTitle: "Avaliando Estrutura",
                generatedMessage: "Verificando se todas as comissões obrigatórias estão funcionando como deveriam.",
                actionLabel: "Criar Comissão"
            ),
            DisplayedAnalysis(
                rawAnalysis: RawAnalysis(category: .structure, severity: .warning, contextData: [:], fallbackTitle: "", fallbackMessage: ""),
                generatedTitle: "Desempenho Geral",
                generatedMessage: "Analisando o fluxo de tarefas entregues pelas comissões este semestre.",
                actionLabel: nil
            ),
            DisplayedAnalysis(
                rawAnalysis: RawAnalysis(category: .structure, severity: .info, contextData: [:], fallbackTitle: "", fallbackMessage: ""),
                generatedTitle: "Recomendação Estratégica",
                generatedMessage: "Procurando áreas onde a criação de uma nova comissão pode otimizar as atividades do Capítulo.",
                actionLabel: "Criar Comissão"
            )
        ]
    }
}
