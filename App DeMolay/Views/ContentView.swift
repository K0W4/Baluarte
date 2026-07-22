import SwiftUI

struct ContentView: View {
    enum Tab {
        case home
        case calendar
        case members
        case tasks
    }
    
    @State private var selectedTab: Tab = .home
    
    var body: some View {
        TabView(selection: $selectedTab) {
            HomeView()
                .tabItem {
                    Label("Início", systemImage: "house.fill")
                }
                .tag(Tab.home)
            
            CalendarView()
                .tabItem {
                    Label("Calendário", systemImage: "calendar")
                }
                .tag(Tab.calendar)
            
            MembersView()
                .tabItem {
                    Label("Membros", systemImage: "person.3.fill")
                }
                .tag(Tab.members)
            
            TasksView()
                .tabItem {
                    Label("Tarefas", systemImage: "checklist")
                }
                .tag(Tab.tasks)
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
}
