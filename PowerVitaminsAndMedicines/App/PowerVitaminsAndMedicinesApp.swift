import SwiftUI

@main
struct PowerVitaminsAndMedicinesApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            RootTabView()
                .preferredColorScheme(.dark)
        }
    }
}
