import SwiftUI

struct ContentView: View {
    enum Tab {
        case home
        case calendar
        case roster
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
            
            RosterView()
                .tabItem {
                    Label("Nominata", systemImage: "person.3.fill")
                }
                .tag(Tab.roster)
            
            TasksView()
                .tabItem {
                    Label("Tarefas", systemImage: "checklist")
                }
                .tag(Tab.tasks)
        }
        .tint(.accent)
    }
}

#Preview {
    ContentView()
}
