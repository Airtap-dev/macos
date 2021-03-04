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

@main
class AppDelegate: NSObject, NSApplicationDelegate {

    var welcomeWindow: NSWindow?
    var mainWindow: NSWindow?
    var statusBarItem: NSStatusItem!
    
    private lazy var resolver = Resolver()
    private var cancellables = Set<AnyCancellable>()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        setupStatusBarItem()
        
        resolver.authProvider.eventSubject
            .sink { [weak self] event in
                switch event {
                case let .signedIn(accountId, token):
                    self?.start(accountId: accountId, token: token)
                case .signedOut:
                    break
                }
            }
            .store(in: &cancellables)
    
        if let (accountId, token) = resolver.authProvider.currentAccount() {
            resolver.authProvider.signIn(accountId: accountId, token: token)
        }
    }

    private func start(accountId: Int, token: String) {
        resolver.start(accountId: accountId, token: token)
        
        resolver.apiService.getServers()
            .receive(on: DispatchQueue.main)
            .sink(receiveCompletion: { [weak self] completion in
                if case let .failure(error) = completion, case let .error(code) = error {
                    if APIError(rawValue: code) == .invalidCredentials {
                        self?.resolver.authProvider.signOut()
                        self?.resolver.persistenceProvider.wipeAll()
                        self?.resolver.wsService.stop()
                        self?.resolver.apiService.dropIdentity()
                    }
                }
            }, receiveValue: { [weak self] response in
                self?.resolver.webRTCService.updateServers(response.servers.map {
                    Server(id: $0.serverId, url: $0.url, username: $0.username, password: $0.password)
                })
            }).store(in: &cancellables)
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
        statusBarItem.button?.title = "🎙"
    }
    
    @objc
    private func didClickStatusBarItem() {
        if resolver.isAuthorised() {
            if mainWindow?.isVisible == true {
                mainWindow?.close()
            } else {
                buildMainWindow()
            }
        } else {
            if welcomeWindow?.isVisible == true {
                welcomeWindow?.close()
            } else {
                buildWelcomeWindow()
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
    
    private func buildMainWindow() {
        mainWindow = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: 480, height: 300),
            styleMask: [.borderless],
            backing: .buffered,
            defer: false
        )
        mainWindow!.isReleasedWhenClosed = false
        mainWindow!.contentView = NSHostingView(rootView: resolver.main())
        mainWindow!.contentView?.layer?.cornerRadius = 5
        mainWindow!.contentView?.layer?.masksToBounds = true
        mainWindow!.isOpaque = false
        mainWindow!.backgroundColor = .clear

        if let button = statusBarItem.button, let buttonWindow = button.window {
            var position = buttonWindow.frame.origin
            position.x -= (mainWindow!.frame.width / 2) - (buttonWindow.frame.width / 2)
            position.y -= mainWindow!.frame.height
            mainWindow!.setFrameOrigin(position)
        }
        mainWindow!.makeKeyAndOrderFront(nil)
    }
}

