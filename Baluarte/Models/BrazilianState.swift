import Foundation

public enum BrazilianState: String, CaseIterable, Identifiable, Sendable {
    case ac = "AC", al = "AL", ap = "AP", am = "AM", ba = "BA", ce = "CE"
    case df = "DF", es = "ES", go = "GO", ma = "MA", mt = "MT", ms = "MS"
    case mg = "MG", pa = "PA", pb = "PB", pr = "PR", pe = "PE", pi = "PI"
    case rj = "RJ", rn = "RN", rs = "RS", ro = "RO", rr = "RR", sc = "SC"
    case sp = "SP", se = "SE", to = "TO"

    public var id: String { rawValue }

    /// `allCases` segue a ordem do IBGE, que é por região e não alfabética — AP antes
    /// de AM, MT antes de MS, PR antes de PE. Na tela a fila de siglas é lida como
    /// índice, e um índice fora de ordem obriga a varrer tudo para achar o próprio
    /// estado. Ordenada pela sigla, que é o que a pessoa vê.
    public static let alphabetical: [BrazilianState] = allCases.sorted { $0.rawValue < $1.rawValue }

    public var name: String {
        switch self {
        case .ac: return "Acre"
        case .al: return "Alagoas"
        case .ap: return "Amapá"
        case .am: return "Amazonas"
        case .ba: return "Bahia"
        case .ce: return "Ceará"
        case .df: return "Distrito Federal"
        case .es: return "Espírito Santo"
        case .go: return "Goiás"
        case .ma: return "Maranhão"
        case .mt: return "Mato Grosso"
        case .ms: return "Mato Grosso do Sul"
        case .mg: return "Minas Gerais"
        case .pa: return "Pará"
        case .pb: return "Paraíba"
        case .pr: return "Paraná"
        case .pe: return "Pernambuco"
        case .pi: return "Piauí"
        case .rj: return "Rio de Janeiro"
        case .rn: return "Rio Grande do Norte"
        case .rs: return "Rio Grande do Sul"
        case .ro: return "Rondônia"
        case .rr: return "Roraima"
        case .sc: return "Santa Catarina"
        case .sp: return "São Paulo"
        case .se: return "Sergipe"
        case .to: return "Tocantins"
        }
    }
}
