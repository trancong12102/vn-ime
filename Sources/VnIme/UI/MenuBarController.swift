import AppKit
import Combine
import SwiftUI

/// Controls the menu bar icon and menu
@MainActor
public final class MenuBarController {
    private var statusItem: NSStatusItem?
    private var cancellables = Set<AnyCancellable>()

    // Menu item references for updating state
    private var vietnameseMenuItem: NSMenuItem?
    private var englishMenuItem: NSMenuItem?

    public var isVietnameseEnabled: Bool = true {
        didSet {
            updateMenuState()
            updateIcon()
        }
    }

    public var onToggleLanguage: ((Bool) -> Void)?
    public var onOpenSettings: (() -> Void)?
    public var onQuit: (() -> Void)?

    public init() {}

    public func setup() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        updateIcon()
        setupMenu()
    }

    public func cleanup() {
        if let item = statusItem {
            NSStatusBar.system.removeStatusItem(item)
        }
        statusItem = nil
    }

    private func updateIcon() {
        guard let button = statusItem?.button else { return }

        // Use different icons for Vietnamese vs English mode
        let iconName = isVietnameseEnabled ? "v.circle.fill" : "e.circle"
        button.image = NSImage(systemSymbolName: iconName, accessibilityDescription: "VnIme")
    }

    private func setupMenu() {
        let menu = NSMenu()

        // Language toggle
        vietnameseMenuItem = NSMenuItem(
            title: "Vietnamese",
            action: #selector(selectVietnamese),
            keyEquivalent: "v"
        )
        vietnameseMenuItem?.target = self
        if let item = vietnameseMenuItem {
            menu.addItem(item)
        }

        englishMenuItem = NSMenuItem(
            title: "English",
            action: #selector(selectEnglish),
            keyEquivalent: "e"
        )
        englishMenuItem?.target = self
        if let item = englishMenuItem {
            menu.addItem(item)
        }

        updateMenuState()

        menu.addItem(NSMenuItem.separator())

        // Settings
        let settingsItem = NSMenuItem(
            title: "Settings...",
            action: #selector(openSettings),
            keyEquivalent: ","
        )
        settingsItem.target = self
        menu.addItem(settingsItem)

        menu.addItem(NSMenuItem.separator())

        // Quit
        let quitItem = NSMenuItem(
            title: "Quit VnIme",
            action: #selector(quit),
            keyEquivalent: "q"
        )
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem?.menu = menu
    }

    private func updateMenuState() {
        vietnameseMenuItem?.state = isVietnameseEnabled ? .on : .off
        englishMenuItem?.state = isVietnameseEnabled ? .off : .on
    }

    @objc private func selectVietnamese() {
        isVietnameseEnabled = true
        onToggleLanguage?(true)
    }

    @objc private func selectEnglish() {
        isVietnameseEnabled = false
        onToggleLanguage?(false)
    }

    @objc private func openSettings() {
        onOpenSettings?()
    }

    @objc private func quit() {
        onQuit?()
    }
}
