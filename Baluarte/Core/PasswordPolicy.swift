import Foundation

/// O piso da senha numa fonte só. Cadastro exigia 6 caracteres e a redefinição exigia 8,
/// então quem criava a conta com 6 descobria a regra nova meses depois, preso numa folha
/// modal aberta por um link de e-mail que só vale uma vez.
public enum PasswordPolicy {
    public static let minLength = 8
}
