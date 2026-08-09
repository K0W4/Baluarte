import Foundation

// MARK: - Mensagens de negativa vindas do Postgres
//
// O servidor não sabe o idioma de quem chamou, então ele não traduz: cada `raise`
// carrega um `hint` estável no formato `baluarte.<chave>`, opcionalmente seguido de
// `:<argumento>`, e a tradução acontece aqui. A frase em português que viaja como
// mensagem da exceção continua servindo ao log e a quem depura por curl.
//
// Uma chave desconhecida devolve nil de propósito, e não uma frase de erro genérica:
// isso deixa `AppError.from` cair no comportamento anterior em vez de trocar uma
// mensagem útil do servidor por uma inútil do cliente.

enum ServerMessage {
    private static let namespace = "baluarte."

    static func localized(hint: String?) -> String? {
        guard let hint, hint.hasPrefix(namespace) else { return nil }

        let payload = hint.dropFirst(namespace.count)
        let parts = payload.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
        guard let key = parts.first.map(String.init), !key.isEmpty else { return nil }
        let argument = parts.count > 1 ? String(parts[1]) : nil

        return message(for: key, argument: argument)
    }

    private static func message(for key: String, argument: String?) -> String? {
        switch key {
        case "two_chapters_max":
            return String(localized: "Você já participa de dois Capítulos. Saia de um antes de entrar em outro.")
        case "chapter_immutable":
            return String(localized: "O Capítulo de um registro não pode ser alterado.")
        case "event_not_found":
            return String(localized: "Evento não encontrado.")
        case "request_not_found":
            return String(localized: "Solicitação não encontrada.")
        case "request_already_reviewed":
            return String(localized: "Esta solicitação já foi respondida.")
        case "chapter_already_has_owner":
            return String(localized: "Este Capítulo já tem um Fundador. Quem quiser entrar deve solicitar a ele.")
        case "owner_needs_transfer":
            return String(localized: "Para tornar alguém Fundador, use a transferência de propriedade.")
        case "roster_entry_unavailable":
            return String(localized: "O cadastro escolhido não existe mais ou já pertence a alguém.")
        case "not_in_chapter":
            return String(localized: "Você não participa deste Capítulo.")
        case "last_owner_with_members":
            return lastOwnerMessage(argument: argument)
        case "invite_code_generation_failed":
            return String(localized: "Não foi possível gerar um código único.")
        case "invite_code_required":
            return String(localized: "Informe o código do convite.")
        case "invite_rate_limited":
            return String(localized: "Muitas tentativas. Aguarde alguns minutos antes de tentar de novo.")
        case "invite_invalid":
            return String(localized: "Convite inválido ou expirado. Confira o código com quem enviou.")
        case "already_member":
            return String(localized: "Você já participa deste Capítulo.")
        case "roster_entry_taken":
            return String(localized: "O cadastro vinculado a este convite já pertence a alguém.")
        case "membership_not_found":
            return String(localized: "Vínculo não encontrado.")
        case "membership_unclaimed":
            return String(localized: "Este cadastro ainda não pertence a ninguém, então não tem acesso para ajustar.")
        case "cannot_change_own_access":
            return String(localized: "Você não pode alterar o próprio nível de acesso.")
        case "owner_target_invalid":
            return String(localized: "A propriedade só pode ser transferida para alguém ativo e com conta no app.")
        case "already_owner":
            return String(localized: "Você já é o Fundador deste Capítulo.")
        case "cannot_raise_own_access":
            return String(localized: "Você pode reduzir o próprio acesso, mas não aumentá-lo.")
        case "last_platform_admin":
            return String(localized: "Você é o único administrador de plataforma. Conceda a outra pessoa antes de sair.")
        case "member_not_found":
            return String(localized: "Pessoa não encontrada.")
        case "cid_required":
            return String(localized: "Informe o CID de quem vai receber o acesso.")
        case "cid_not_found":
            return String(localized: "Ninguém com este CID tem conta no app.")
        case "cid_ambiguous":
            return String(localized: "Há mais de uma conta com este CID. Resolva a duplicidade antes de conceder.")
        default:
            return nil
        }
    }

    // O único caso parametrizado. Sem a contagem a frase perde o sentido, então um
    // argumento ausente ou ilegível cai numa redação que não promete um número.
    private static func lastOwnerMessage(argument: String?) -> String {
        guard let argument, let count = Int(argument), count > 0 else {
            return String(localized: "Você é o único Fundador e ainda há gente no Capítulo. Promova outro Fundador antes de sair.")
        }
        let format = String(localized: "Você é o único Fundador e ainda há %lld pessoa(s) no Capítulo. Promova outro Fundador antes de sair.")
        return String(format: format, count)
    }
}
