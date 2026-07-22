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
                    Label("Membros", systemImage: selectedTab == .members ? "person.3.fill" : "person.3")
                }
                .tag(Tab.members)
            
            TasksView()
                .tabItem {
                    Label("Tarefas", systemImage: selectedTab == .tasks ? "list.clipboard.fill" : "list.clipboard")
                }
                .tag(Tab.tasks)
        }
        .tint(Theme.accent)
    }
}

#Preview {
    ContentView()
}
