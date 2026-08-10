import SwiftUI

struct ContentView: View {
    enum Tab {
        case home
        case calendar
        case members
        case tasks
        case analysis
    }

    @Environment(AuthViewModel.self) private var authViewModel
    @State private var selectedTab: Tab = .home

    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Início", systemImage: selectedTab == .home ? "house.fill" : "house")
                }
                .tag(Tab.home)
            
            CalendarView()
                .tabItem {
                    Label("Calendário", systemImage: "calendar")
                }
                .tag(Tab.calendar)
            
            MembersView()
                .tabItem {
                    Label("Membros", systemImage: selectedTab == .members ? "person.2.fill" : "person.2")
                }
                .tag(Tab.members)
            
            TasksView()
                .tabItem {
                    Label("Tarefas", systemImage: "checklist")
                }
                .tag(Tab.tasks)
            
            AnalysisView()
                .tabItem {
                    Label("Análise", systemImage: "apple.intelligence")
                }
                .tag(Tab.analysis)
        }
        // O padrão do app é a variante legível, e não a de marca: assim um botão novo
        // nasce passando o contraste, e o vermelho de preenchimento fica sendo a exceção
        // que alguém escreve de propósito.
        .tint(Theme.accentText)
        .environment(\.permissions, authViewModel.permissions)
    }
}

#Preview {
    ContentView()
}
