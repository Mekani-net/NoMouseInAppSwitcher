//
//  NoMouseInAppSwitcherApp.swift
//  NoMouseInAppSwitcher
//
//  Created by Michael Madsen on 11/06/2026.
//

import SwiftUI

@main
struct NoMouseInAppSwitcher: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        // We don't need any windows since this app is background-only
        Settings {
            EmptyView()
        }
    }
}
