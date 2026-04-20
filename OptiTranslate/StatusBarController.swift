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
        vc.view.setFrameSize(NSSize(width: 420, height: 300))
        popover.contentViewController = vc

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "OptiTranslate")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Global monitor: fires when another app is frontmost
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            guard let self else { return }
            if ev.keyCode == 49 && ev.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option {
                DispatchQueue.main.async { self.triggerTranslation() }
            }
        }
        // Local monitor: fires when this app is frontmost
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            if ev.keyCode == 49 && ev.modifierFlags.intersection(.deviceIndependentFlagsMask) == .option {
                DispatchQueue.main.async { self?.triggerTranslation() }
            }
            return ev
        }
    }

    @objc private func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            showPopover()
        }
    }

    private func showPopover() {
        guard let button = statusItem.button else { return }
        popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
    }

    private func triggerTranslation() {
        simulateCopy()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { [weak self] in
            guard let self else { return }
            let pb = NSPasteboard.general
            guard let text = pb.string(forType: .string), !text.isEmpty else {
                NSSound.beep()
                return
            }
            Task { @MainActor in
                self.store.original = text
                self.showPopover()
                await self.store.translate()
            }
        }
    }

    /// Simulate Cmd+C to copy the frontmost app's selection.
    private func simulateCopy() {
        let src = CGEventSource(stateID: .combinedSessionState)
        // C key virtual key = 0x08, with maskCommand flag
        let keyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true)
        let keyUp   = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        keyDown?.flags = .maskCommand
        keyUp?.flags   = .maskCommand
        keyDown?.post(tap: .cghidEventTap)
        keyUp?.post(tap: .cghidEventTap)
    }

    deinit {
        if let monitor = eventMonitor { NSEvent.removeMonitor(monitor) }
    }
}
