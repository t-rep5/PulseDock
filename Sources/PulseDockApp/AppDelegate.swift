import AppKit
import SwiftUI

@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate, NSWindowDelegate {
    let appModel = AppModel()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var dashboardWindow: NSWindow?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.accessory)
        ProcessInfo.processInfo.disableAutomaticTermination("PulseDock runs as a menu bar utility.")
        configureMainMenu()
        configureStatusItem()
        appModel.start()
        showDashboardWindow(nil)
    }

    func applicationWillTerminate(_ notification: Notification) {
        appModel.stop()
        ProcessInfo.processInfo.enableAutomaticTermination("PulseDock runs as a menu bar utility.")
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            showDashboardWindow(nil)
        }
        return true
    }

    private func configureMainMenu() {
        let mainMenu = NSMenu()

        let appMenuItem = NSMenuItem()
        let appMenu = NSMenu()
        appMenu.addItem(NSMenuItem(title: localized("关于 PulseDock", "About PulseDock", language: appModel.settings.language), action: nil, keyEquivalent: ""))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: localized("设置...", "Settings...", language: appModel.settings.language), action: #selector(showSettingsWindow), keyEquivalent: ","))
        appMenu.addItem(.separator())
        appMenu.addItem(NSMenuItem(title: localized("退出 PulseDock", "Quit PulseDock", language: appModel.settings.language), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        appMenuItem.submenu = appMenu
        mainMenu.addItem(appMenuItem)

        let windowMenuItem = NSMenuItem()
        let windowMenu = NSMenu(title: localized("窗口", "Window", language: appModel.settings.language))
        windowMenu.addItem(NSMenuItem(title: localized("显示仪表盘", "Show Dashboard", language: appModel.settings.language), action: #selector(showDashboardWindow), keyEquivalent: "0"))
        windowMenuItem.submenu = windowMenu
        mainMenu.addItem(windowMenuItem)

        NSApp.mainMenu = mainMenu
    }

    private func configureStatusItem() {
        let statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.target = self
        statusItem.button?.action = #selector(handleStatusItemClick)
        statusItem.button?.sendAction(on: [.leftMouseUp, .rightMouseUp])
        self.statusItem = statusItem

        let popover = NSPopover()
        popover.behavior = .transient
        popover.contentSize = NSSize(width: 460, height: 600)
        popover.contentViewController = NSHostingController(
            rootView: DashboardView()
                .environmentObject(appModel)
                .environment(\.appLanguage, appModel.settings.language)
        )
        self.popover = popover

        updateMenuBarTitle()
        appModel.onMenuBarUpdate = { [weak self] in
            self?.updateMenuBarTitle()
        }
        appModel.onSettingsUpdate = { [weak self] in
            self?.updateMenuBarTitle()
            self?.configureMainMenu()
        }
    }

    private func updateMenuBarTitle() {
        let snapshot = appModel.snapshot
        let title: String
        let image: NSImage?

        switch appModel.settings.menuBarMode {
        case .iconOnly:
            title = ""
            image = menuBarAppIcon()
        case .compactMetrics:
            title = "CPU \(snapshot.cpuUsage.percentText)  MEM \(snapshot.memory.usedRatio.percentText)"
            image = nil
        case .network:
            title = "↓\(snapshot.network.downloadBytesPerSecond.byteCount) ↑\(snapshot.network.uploadBytesPerSecond.byteCount)"
            image = nil
        case .pressure:
            title = appModel.diagnosis.status == .good ? "OK" : appModel.diagnosis.status.label(language: appModel.settings.language)
            image = nil
        }

        statusItem?.button?.title = title
        statusItem?.button?.image = image
        statusItem?.button?.font = .monospacedSystemFont(ofSize: NSFont.systemFontSize, weight: .regular)
    }

    private func menuBarAppIcon() -> NSImage? {
        let image = NSImage(size: NSSize(width: 20, height: 18), flipped: false) { rect in
            let path = NSBezierPath()
            let midY = rect.midY
            let width = rect.width
            let height = rect.height

            path.move(to: NSPoint(x: rect.minX + width * 0.05, y: midY))
            path.line(to: NSPoint(x: rect.minX + width * 0.22, y: midY))
            path.line(to: NSPoint(x: rect.minX + width * 0.33, y: midY + height * 0.28))
            path.line(to: NSPoint(x: rect.minX + width * 0.46, y: midY - height * 0.32))
            path.line(to: NSPoint(x: rect.minX + width * 0.58, y: midY + height * 0.43))
            path.line(to: NSPoint(x: rect.minX + width * 0.72, y: midY))
            path.line(to: NSPoint(x: rect.maxX - width * 0.05, y: midY))

            path.lineWidth = 2.4
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            NSColor.white.setStroke()
            path.stroke()
            return true
        }
        image.isTemplate = true
        return image
    }

    @objc private func handleStatusItemClick() {
        if NSApp.currentEvent?.type == .rightMouseUp {
            showStatusItemMenu()
        } else {
            togglePopover()
        }
    }

    private func showStatusItemMenu() {
        guard let button = statusItem?.button else {
            return
        }

        popover?.performClose(nil)

        guard let event = NSApp.currentEvent else {
            return
        }

        let menu = NSMenu()
        let overviewItem = NSMenuItem(title: localized("前往主界面", "Open Overview", language: appModel.settings.language), action: #selector(showOverviewWindow), keyEquivalent: "")
        overviewItem.target = self
        menu.addItem(overviewItem)
        menu.addItem(.separator())
        let quitItem = NSMenuItem(title: localized("退出 App", "Quit App", language: appModel.settings.language), action: #selector(NSApplication.terminate(_:)), keyEquivalent: "")
        quitItem.target = NSApp
        menu.addItem(quitItem)

        NSMenu.popUpContextMenu(menu, with: event, for: button)
    }

    private func togglePopover() {
        guard let button = statusItem?.button, let popover else {
            return
        }

        if popover.isShown {
            popover.performClose(nil)
        } else {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
        }
    }

    @objc func showDashboardWindow(_ sender: Any?) {
        NSApp.setActivationPolicy(.regular)

        if dashboardWindow == nil {
            let controller = NSHostingController(
                rootView: DesktopDashboardView()
                    .environmentObject(appModel)
                    .environment(\.appLanguage, appModel.settings.language)
            )

            let window = NSWindow(contentViewController: controller)
            window.title = "PulseDock"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.minSize = NSSize(width: 1280, height: 780)
            window.setContentSize(NSSize(width: 1440, height: 900))
            window.isReleasedWhenClosed = false
            window.delegate = self
            window.center()
            dashboardWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        dashboardWindow?.makeKeyAndOrderFront(sender)
    }

    func windowWillClose(_ notification: Notification) {
        if notification.object as? NSWindow === dashboardWindow {
            popover?.performClose(nil)
            NSApp.setActivationPolicy(.accessory)
        }
    }

    @objc func showOverviewWindow(_ sender: Any?) {
        appModel.showDesktopSection(.overview)
        showDashboardWindow(sender)
    }

    @objc func showSettingsWindow(_ sender: Any?) {
        appModel.showDesktopSection(.settings)
        showDashboardWindow(sender)
    }
}
