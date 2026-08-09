import Foundation
import UIKit

/// Recebe o token da APNs e o guarda em `device_token`.
///
/// O token é do aparelho, não da pessoa: a chave da tabela é o token, e ele muda de
/// dono no upsert. Sem isso, quem entrasse no app depois de outra pessoa continuaria
/// recebendo as notificações dela.
@MainActor
final class PushRegistrar: NSObject, UIApplicationDelegate {
    static let shared = PushRegistrar()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        NotificationService.shared.configure()
        return true
    }

    /// Chamado depois que a pessoa autoriza. Registrar antes disso pediria o token de
    /// um aparelho que ainda não concordou em ser notificado.
    func registerIfAuthorized() async {
        guard await NotificationService.shared.hasAuthorization() else { return }
        UIApplication.shared.registerForRemoteNotifications()
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        let token = deviceToken.map { String(format: "%02x", $0) }.joined()
        Task { await Services.push.register(token: token) }
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        // Sem token não há push, e não há nada que a pessoa possa fazer a respeito --
        // avisar na tela seria ruído. O log serve para quem estiver depurando.
        print("APNs registration failed: \(error.localizedDescription)")
    }
}
