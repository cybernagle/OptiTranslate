import Cocoa
import SwiftUI

final class StatusBarController {
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var eventMonitor: Any?

    init() {
        popover = NSPopover()
        popover.contentSize = NSSize(width: 420, height: 260)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: ContentView())

        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "globe", accessibilityDescription: "OptiTranslate")
            button.action = #selector(togglePopover(_:))
            button.target = self
        }

        // Local and global key listeners
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            self?.handleKeyEvent(ev)
            return ev
        }
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: .keyDown) { [weak self] ev in
            self?.handleKeyEvent(ev)
        }
    }

    @objc func togglePopover(_ sender: Any?) {
        if popover.isShown {
            popover.performClose(sender)
        } else {
            if let button = statusItem.button {
                popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
    }

    private func handleKeyEvent(_ ev: NSEvent) {
        // Option + Space (keyCode 49 is space)
        if ev.keyCode == 49 && ev.modifierFlags.contains(.option) {
            DispatchQueue.main.async {
                self.openTranslateFromSelection()
            }
        }
    }

    private func openTranslateFromSelection() {
        // Copy selection (simulate Cmd+C), then show popover and kick translation
        let src = CGEventSource(stateID: .combinedSessionState)
        let cmdDown = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: true)
        let cmdUp = CGEvent(keyboardEventSource: src, virtualKey: 0x37, keyDown: false)
        // 0x37 is Command; c key virtual key 0x08
        let cKeyDown = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: true)
        let cKeyUp = CGEvent(keyboardEventSource: src, virtualKey: 0x08, keyDown: false)
        cmdDown?.flags = .maskCommand
        cmdUp?.flags = .maskCommand
        cKeyDown?.flags = .maskCommand
        cKeyUp?.flags = .maskCommand
        cmdDown?.post(tap: .cghidEventTap)
        cKeyDown?.post(tap: .cghidEventTap)
        cKeyUp?.post(tap: .cghidEventTap)
        cmdUp?.post(tap: .cghidEventTap)

        // Small delay to allow clipboard to update
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
            let pb = NSPasteboard.general
            if let str = pb.string(forType: .string), !str.isEmpty {
                // show popover
                if let button = self.statusItem.button {
                    self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                    if let vc = self.popover.contentViewController as? NSHostingController<ContentView> {
                        vc.rootView.startTranslation(text: str)
                    }
                }
            } else {
                // no selection
                NSSound.beep()
            }
        }
    }

    deinit {
        if let ev = eventMonitor { NSEvent.removeMonitor(ev) }
    }
}
