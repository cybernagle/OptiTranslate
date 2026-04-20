import Cocoa
import SwiftUI

final class StatusBarController {
    private let store: TranslationStore
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: Any?

    init(store: TranslationStore) {
        self.store = store

        popover = NSPopover()
        popover.behavior = .transient
        let contentView = ContentView().environmentObject(store)
        let vc = NSHostingController(rootView: contentView)
        popover.contentViewController = vc

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "character.book.closed",
                                   accessibilityDescription: "OptiTranslate")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Global monitor: Opt+Space when another app is frontmost
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            guard let self else { return }
            if ev.keyCode == 49, ev.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option {
                DispatchQueue.main.async { self.togglePopover(nil) }
            }
        }
        // Local monitor: Opt+Space when this app is frontmost
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            if ev.keyCode == 49, ev.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option {
                DispatchQueue.main.async { self?.togglePopover(nil) }
                return nil  // consume the event so no beep/space inserted
            }
            return ev
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            guard let button = statusItem.button else { return }
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    deinit {
        if let m = eventMonitor { NSEvent.removeMonitor(m) }
    }
}
