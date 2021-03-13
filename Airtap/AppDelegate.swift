//
//  AppDelegate.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 27.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Cocoa
import SwiftUI
import Combine
import KeychainSwift
import Sparkle

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBarItem: NSStatusItem!
    var popover: NSPopover!
    var mainView: MainView!
    var welcomeWindow: NSWindow?
    
    private let authProvider = AuthProvider()
    private var resolver: Resolver!
    
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.resolver = Resolver(authProvider: authProvider)
        self.mainView = resolver.main()
        
        setupStatusBarItem()
        
        self.authProvider.load()
        self.authProvider.eventSubject
            .sink { [weak self] event in
                if case .signedIn = event {
                    self?.welcomeWindow?.close()
                    self?.welcomeWindow = nil
                }
            }
            .store(in: &cancellables)
        
        let updater = SUUpdater.shared()
        updater?.feedURL = URL(string: Config.sparkleEndpoint)
        updater?.checkForUpdatesInBackground()
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        self.resolver.callProvider.prepareToQuit()
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        resolver.linkHandler.handleURL(url: url)
    }
    
    private func setupStatusBarItem() {
        let statusBar = NSStatusBar.system
        statusBarItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)
        statusBarItem.button?.action = #selector(didClickStatusBarItem)
        statusBarItem.button?.image = NSImage(named: "statusBarIcon")!
        
        let mainViewController = NSViewController()
        mainViewController.view = NSHostingView(rootView: mainView)
        self.popover = NSPopover()
        self.popover.contentViewController = mainViewController
        self.popover.animates = false
    }
    
    @objc
    private func didClickStatusBarItem() {
        if self.popover.isShown {
            self.popover.performClose(nil)
        } else {
            if let button = self.statusBarItem.button {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
    }
    
    func openWelcomeWindow() {
        if welcomeWindow == nil {
            welcomeWindow = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
                styleMask: [
                    .titled,
                    .closable,
                    .fullSizeContentView
                ],
                backing: .buffered,
                defer: false
            )
            welcomeWindow?.toolbar?.isVisible = false
            welcomeWindow?.isReleasedWhenClosed = false
            welcomeWindow?.titlebarAppearsTransparent = true
            welcomeWindow?.contentView = NSHostingView(rootView: resolver.welcome())
        }
        welcomeWindow?.makeKeyAndOrderFront(nil)
        welcomeWindow?.center()
    }
}

