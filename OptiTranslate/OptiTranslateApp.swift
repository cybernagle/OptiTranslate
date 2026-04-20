import SwiftUI

@main
struct OptiTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusController: StatusBarController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusController = StatusBarController()
    }
}
