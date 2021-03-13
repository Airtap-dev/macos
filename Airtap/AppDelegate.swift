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

import HotKey

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var welcomeWindow: NSWindow?
    
    var mainView: MainView!
    let popover = NSPopover()
    var statusBarItem: NSStatusItem!

    private let authProvider = AuthProvider()
    private var resolver: Resolver!
    
    private var cancellables = Set<AnyCancellable>()
    private var hotKey: HotKey!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.resolver = Resolver(authProvider: authProvider)
        self.mainView = resolver.main()
        
        setupStatusBarItem()
        self.authProvider.load()

        hotKey = HotKey(key: .one, modifiers: [.option])
        hotKey.keyDownHandler = {
          print("Pressed at \(Date())")
        }
        
    }
    
    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
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
    
    private func buildWelcomeWindow() {
        welcomeWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.titled, .closable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        welcomeWindow!.isReleasedWhenClosed = false
        welcomeWindow!.center()
        welcomeWindow!.setFrameAutosaveName("Sign In")
        welcomeWindow!.contentView = NSHostingView(rootView: resolver.welcome())
        welcomeWindow!.makeKeyAndOrderFront(nil)
    }
    
//    private func buildMainWindow() {
//        mainWindow = NSWindow(
//            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
//            styleMask: [.borderless],
//            backing: .buffered,
//            defer: false
//        )
//        mainWindow!.isReleasedWhenClosed = false
//        mainWindow!.contentView = NSHostingView(rootView: resolver.main())
//        mainWindow!.contentView?.layer?.cornerRadius = 5
//        mainWindow!.contentView?.layer?.masksToBounds = true
//        mainWindow!.isOpaque = false
//        mainWindow!.backgroundColor = .clear
//
//        if let button = statusBarItem.button, let buttonWindow = button.window {
//            var position = buttonWindow.frame.origin
//            position.x -= (mainWindow!.frame.width / 2) - (buttonWindow.frame.width / 2)
//            position.y -= mainWindow!.frame.height
//            mainWindow!.setFrameOrigin(position)
//        }
//        mainWindow!.makeKeyAndOrderFront(nil)
//    }
}

