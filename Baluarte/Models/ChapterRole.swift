import Foundation

// MARK: - Cargos do Capítulo
//
// O cargo é gravado em `chapter_membership.role` como texto, e a nomenclatura oficial
// da Ordem no Brasil é a forma canônica — é o que já está nas linhas existentes e o que
// a análise compara. Traduzir o valor gravado quebraria as duas coisas, então o valor
// viaja sempre em português e só a exibição muda de idioma.

public enum ChapterRole {
    public static let member = "Membro"

    public static let activeRoles = [
        "Membro", "Mestre Conselheiro", "1º Conselheiro", "2º Conselheiro",
        "Escrivão", "Tesoureiro", "Hospitalário",
    ]

    public static let seniorRoles = ["Membro", "Consultor"]

    public static let masonRoles = ["Membro", "Consultor", "Presidente do Conselho"]

    public static func roles(isSenior: Bool, isMason: Bool) -> [String] {
        if isMason { return masonRoles }
        if isSenior { return seniorRoles }
        return activeRoles
    }

    // Cargos que a aprovação sugere como administrador — descritivo, nunca atribuído.
    public static let officerRoles = [
        "Mestre Conselheiro", "1º Conselheiro", "2º Conselheiro", "Escrivão", "Consultor",
    ]

    public static func displayName(for role: String) -> String {
        switch role {
        case "Membro": return String(localized: "Membro")
        case "Mestre Conselheiro": return String(localized: "Mestre Conselheiro")
        case "1º Conselheiro": return String(localized: "1º Conselheiro")
        case "2º Conselheiro": return String(localized: "2º Conselheiro")
        case "Escrivão": return String(localized: "Escrivão")
        case "Tesoureiro": return String(localized: "Tesoureiro")
        case "Hospitalário": return String(localized: "Hospitalário")
        case "Consultor": return String(localized: "Consultor")
        case "Presidente do Conselho": return String(localized: "Presidente do Conselho")
        default: return role
        }
    }

    public static let noRole = String(localized: "Sem cargo")
}
