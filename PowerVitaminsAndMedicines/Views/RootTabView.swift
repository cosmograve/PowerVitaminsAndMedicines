import SwiftUI
import UserNotifications

struct RootTabView: View {
    
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    @StateObject private var store = AppStore()
    
    @State private var selectedTab: Int = 0
    
    @State private var mainPath: [AppRoute] = []
    @State private var calendarPath: [AppRoute] = []
    @State private var notificationsPath: [AppRoute] = []
    @State private var statsPath: [AppRoute] = []
    
    init() {
        configureTabBarAppearance()
    }
    var body: some View {
        TabView(selection: $selectedTab) {
            
            NavigationStack(path: $mainPath) {
                MainView(path: $mainPath)
                    .environmentObject(store)
                    .navigationDestination(for: AppRoute.self) { route in
                        switch route {
                        case .medicationDetail(let id):
                            AddEditMedicationView(mode: .edit(id: id))
                                .environmentObject(store)
//                                .toolbar(.hidden, for: .tabBar)
                            
                        case .medicationEditor(let mode):
                            AddEditMedicationView(mode: mode)
                                .environmentObject(store)
//                                .toolbar(.hidden, for: .tabBar)
                        }
                    }
            }
            .tabItem { Image(.tabMain); Text("") }
            .tag(0)
            
            NavigationStack(path: $calendarPath) {
                CalendarView()
                    .environmentObject(store)
            }
            .tabItem { Image(.tabCalendar); Text("") }
            .tag(1)
            
            NavigationStack(path: $notificationsPath) {
                NotificationsView()
                    .environmentObject(store)
            }
            .tabItem { Image(.tabNotifications); Text("") }
            .tag(2)
            
            NavigationStack(path: $statsPath) {
                StatsView()
                    .environmentObject(store)
            }
            .tabItem { Image(.tabStats); Text("") }
            .tag(3)
        }
        .tint(AppColors.red)
        .task {
            // Register categories
            NotificationManager.shared.configureCategories()
            
            // Ask permission (one-time)
            let granted = await NotificationManager.shared.requestAuthorizationIfNeeded()
            
            // MVP decision:
            // If granted, refresh schedules for existing meds (rolling 30 days).
            if granted {
                store.rescheduleAllNotifications()
            }
        }
    }
    
    private func configureTabBarAppearance() {
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppColors.tabBarBackground)
        
        appearance.shadowColor = .clear
        
        appearance.stackedLayoutAppearance.normal.iconColor = UIColor(AppColors.gray)
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: UIColor.clear
        ]
        
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppColors.red)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor.clear
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}
