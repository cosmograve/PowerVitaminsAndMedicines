import SwiftUI

struct RootTabView: View {

    @StateObject private var store = AppStore()
    
    @State private var selectedTab: Int = 0
    
    @State private var mainPath: [AppRoute] = []
    @State private var calendarPath: [AppRoute] = []
    @State private var notificationsPath: [AppRoute] = []
    @State private var statsPath: [AppRoute] = []
    @State private var showImportantIntro: Bool = true
    
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

                        case .pillCard(let id):
                            PillCardView(path: $mainPath, medicationId: id)
                                .environmentObject(store)

                        case .medicationEditor(let mode):
                            AddEditMedicationView(mode: mode)
                                .environmentObject(store)
                        }
                    }
            }
            .tabItem { Image(.tabMain); Text("") }
            .tag(0)
            
            NavigationStack(path: $notificationsPath) {
                NotificationsView()
                    .environmentObject(store)
            }
            .tabItem { Image(.tabNotifications); Text("") }
            .tag(1)
            
            NavigationStack(path: $calendarPath) {
                CalendarView()
                    .environmentObject(store)
            }
            .tabItem { Image(.tabCalendar); Text("") }
            .tag(2)
            
            NavigationStack(path: $statsPath) {
                StatsView()
                    .environmentObject(store)
            }
            .tabItem { Image(.tabStats); Text("") }
            .tag(3)
        }
        .tint(AppColors.red)
        .overlay {
            if showImportantIntro {
                ImportantIntroView()
                    .transition(.opacity)
                    .zIndex(2)
            }
        }
        .task {
            NotificationManager.shared.configureCategories()
            
            let granted = await NotificationManager.shared.requestAuthorizationIfNeeded()
            
            if granted {
                store.rescheduleAllNotifications()
            }

            try? await Task.sleep(nanoseconds: 2_300_000_000)
            await MainActor.run {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showImportantIntro = false
                }
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

private struct ImportantIntroView: View {
    var body: some View {
        ZStack {
            AppColors.background.ignoresSafeArea()

            VStack(spacing: 16) {
                Text("!")
                    .font(.system(size: 120, weight: .bold, design: .rounded))
                    .foregroundColor(AppColors.yellow)

                Text("Important!")
                    .font(AppFont.poppins(size: 48 / 2, weight: .semibold))
                    .foregroundColor(AppColors.yellow)

                Text("This app is a personal medication and supplement tracker for reminder and logging purposes only. It is not a medical device, does not provide health advice, and should not replace consultation with a qualified healthcare professional.")
                    .font(AppFont.poppins(size: 18, weight: .regular))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 28)
                    .padding(.top, 6)
            }
            .padding(.top, 30)
        }
    }
}
