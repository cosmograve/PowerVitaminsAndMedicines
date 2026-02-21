import SwiftUI

struct MainView: View {

    @EnvironmentObject private var store: AppStore
    @Binding var path: [AppRoute]
    
    var body: some View {
        VStack(spacing: 0) {

            AppNavBar(title: "List of pills", showsBack: false, onBackTap: nil)
            Spacer()
            
        }
        .background(AppColors.background)
        .overlay(alignment: .bottomTrailing) {
            FloatingAddButton {
                path.append(.medicationEditor(mode: .create))
            }
            .padding(.trailing, AppLayout.sidePadding)
            .padding(.bottom, AppLayout.sidePadding)
        }
        .onAppear {
            store.ensureTodayScheduleExists()
        }
    }
}
#Preview {
    MainView(path: .constant([]))
}
