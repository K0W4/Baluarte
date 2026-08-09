import Foundation
import Testing
import Supabase
@testable import Baluarte

struct AppErrorTests {

    // MARK: - Hint conhecido

    @Test func knownHintProducesTheLocalizedMessage() {
        let error = PostgrestError(
            hint: "baluarte.already_member",
            code: "23514",
            message: "Você já participa deste Capítulo."
        )

        #expect(AppError.from(error).userMessage == String(localized: "Você já participa deste Capítulo."))
    }

    // A decisão explícita do projeto: um 42501 que nomeie um motivo real mostra o motivo,
    // em vez da negativa genérica que descartava a mensagem do servidor.
    @Test func knownHintOn42501BeatsTheGenericRefusal() {
        let error = PostgrestError(
            hint: "baluarte.chapter_immutable",
            code: "42501",
            message: "O Capítulo de um registro não pode ser alterado."
        )

        let message = AppError.from(error).userMessage
        #expect(message == String(localized: "O Capítulo de um registro não pode ser alterado."))
        #expect(message != AppError.permissionDenied.userMessage)
    }

    @Test func knownHintOnP0002BeatsTheGenericNotFound() {
        let error = PostgrestError(
            hint: "baluarte.membership_not_found",
            code: "P0002",
            message: "Vínculo não encontrado."
        )

        #expect(AppError.from(error).userMessage == String(localized: "Vínculo não encontrado."))
    }

    // MARK: - Hint parametrizado

    @Test func parameterisedHintInterpolatesItsArgument() {
        let error = PostgrestError(
            hint: "baluarte.last_owner_with_members:3",
            code: "23514",
            message: "Você é o único Fundador e ainda há 3 pessoa(s) no Capítulo. Promova outro Fundador antes de sair."
        )

        let message = AppError.from(error).userMessage
        #expect(message.contains("3"))
        #expect(!message.contains("%lld"))
    }

    @Test func parameterisedHintWithoutAnArgumentStillReads() {
        let error = PostgrestError(
            hint: "baluarte.last_owner_with_members",
            code: "23514",
            message: "Você é o único Fundador."
        )

        let message = AppError.from(error).userMessage
        #expect(!message.isEmpty)
        #expect(!message.contains("%lld"))
    }

    @Test func unparseableArgumentFallsBackInsteadOfShowingTheFormat() {
        let error = PostgrestError(
            hint: "baluarte.last_owner_with_members:abc",
            code: "23514",
            message: "Você é o único Fundador."
        )

        #expect(!AppError.from(error).userMessage.contains("%lld"))
    }

    // MARK: - Fallbacks

    @Test func unknownHintOn23514FallsBackToTheServerMessage() {
        let error = PostgrestError(
            hint: "baluarte.regra_que_ainda_nao_existe",
            code: "23514",
            message: "Uma regra nova que o cliente ainda não conhece."
        )

        #expect(AppError.from(error).userMessage == "Uma regra nova que o cliente ainda não conhece.")
    }

    // Um hint do próprio Postgres não é nosso e não deve ser interpretado como chave.
    @Test func foreignHintIsIgnored() {
        let error = PostgrestError(
            hint: "Perhaps you meant to reference the column \"chapter.number\".",
            code: "23514",
            message: "Mensagem de regra de negócio."
        )

        #expect(AppError.from(error).userMessage == "Mensagem de regra de negócio.")
    }

    @Test func bareInsufficientPrivilegeStaysGeneric() {
        let error = PostgrestError(code: "42501", message: "insufficient_privilege")

        #expect(AppError.from(error) == .permissionDenied)
    }

    @Test func notFoundWithoutHintStaysGeneric() {
        let error = PostgrestError(code: "P0002", message: "Solicitação não encontrada.")

        #expect(AppError.from(error) == .notFound)
    }

    // MARK: - O texto do banco não vaza para a tela

    @Test func constraintViolationDoesNotLeakDatabaseText() {
        let error = PostgrestError(
            code: "23505",
            message: "duplicate key value violates unique constraint \"chapter_invite_code_key\""
        )

        let message = AppError.from(error).userMessage
        #expect(message == AppError.serverError.userMessage)
        #expect(!message.contains("constraint"))
    }

    @Test func postgrestDiagnosticDoesNotLeakEither() {
        let error = PostgrestError(
            code: "PGRST301",
            message: "JWT expired"
        )

        #expect(AppError.from(error) == .serverError)
    }

    // MARK: - HTTPError

    // Sem este ramo o código caía no String(describing:), que estampa o Data cru --
    // e aí "403" casava contra bytes e UUIDs por acidente.
    @Test func httpErrorIsMappedByItsStatusCode() throws {
        let url = try #require(URL(string: "https://example.supabase.co/rest/v1/chapter"))

        func httpError(_ status: Int) throws -> HTTPError {
            let response = try #require(
                HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)
            )
            return HTTPError(data: Data(), response: response)
        }

        #expect(AppError.from(try httpError(401)) == .authenticationRequired)
        #expect(AppError.from(try httpError(403)) == .permissionDenied)
        #expect(AppError.from(try httpError(404)) == .notFound)
        #expect(AppError.from(try httpError(503)) == .serverError)
    }

    // MARK: - Erros de rede e passagem adiante

    @Test func urlErrorsKeepTheirMapping() {
        #expect(AppError.from(URLError(.notConnectedToInternet)) == .networkUnavailable)
        #expect(AppError.from(URLError(.timedOut)) == .timeout)
    }

    @Test func anExistingAppErrorPassesThroughUntouched() {
        #expect(AppError.from(AppError.validationFailed("já convertido")).userMessage == "já convertido")
    }

    // MARK: - ServerMessage

    @Test func serverMessageIgnoresNilAndForeignHints() {
        #expect(ServerMessage.localized(hint: nil) == nil)
        #expect(ServerMessage.localized(hint: "outra_coisa") == nil)
        #expect(ServerMessage.localized(hint: "baluarte.") == nil)
        #expect(ServerMessage.localized(hint: "baluarte.chave_inexistente") == nil)
    }

    // Cada chave que a migration 20260808190000 emite precisa ter tradução aqui. Sem este
    // teste, uma chave nova no Postgres cai silenciosamente no texto em português.
    @Test func everyHintKeyEmittedByTheMigrationIsTranslated() {
        let keys = [
            "two_chapters_max", "chapter_immutable", "event_not_found",
            "request_not_found", "request_already_reviewed", "chapter_already_has_owner",
            "owner_needs_transfer", "roster_entry_unavailable", "not_in_chapter",
            "last_owner_with_members", "invite_code_generation_failed", "invite_code_required",
            "invite_rate_limited", "invite_invalid", "already_member", "roster_entry_taken",
            "membership_not_found", "membership_unclaimed", "cannot_change_own_access",
            "owner_target_invalid", "already_owner",
        ]

        for key in keys {
            let message = ServerMessage.localized(hint: "baluarte.\(key)")
            #expect(message != nil, "chave sem tradução: \(key)")
            #expect(message?.isEmpty == false, "tradução vazia: \(key)")
        }
    }
}
