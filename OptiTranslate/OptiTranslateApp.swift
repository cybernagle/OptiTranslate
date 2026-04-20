import SwiftUI

@main
struct OptiTranslateApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        Settings { EmptyView() }
    }
}

class AppDelegate: NSObject, NSApplicationDelegate {
    private var statusController: StatusBarController?
    private var store: TranslationStore?

    func applicationDidFinishLaunching(_ notification: Notification) {
        let s = TranslationStore()
        store = s
        statusController = StatusBarController(store: s)
    }
}
