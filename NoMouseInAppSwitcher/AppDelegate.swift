//
//  AppDelegate.swift
//  NoMouseInAppSwitcher
//
//  Created by Michael Madsen on 11/06/2026.
//

import Cocoa
import ApplicationServices

// Settings
let moveMouseBackToOriginalPosition = false
let debugOverlayEnabled = true

var savedMousePosition: NSPoint? = nil
var debugOverlay: DebugOverlayWindow?

// MARK: - Debug overlay
class DebugOverlayWindow: NSWindow {
    init(frame: NSRect) {
        super.init(
            contentRect: frame,
            styleMask: .borderless,
            backing: .buffered,
            defer: false
        )
        isOpaque = false
        backgroundColor = NSColor.systemRed.withAlphaComponent(0.3)
        level = .screenSaver
        ignoresMouseEvents = true
        collectionBehavior = [.canJoinAllSpaces, .stationary]
    }
}

func showDebugOverlay(frame: NSRect) {
    if debugOverlay == nil {
        debugOverlay = DebugOverlayWindow(frame: frame)
    } else {
        debugOverlay?.setFrame(frame, display: true)
    }
    debugOverlay?.orderFrontRegardless()

    DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
        debugOverlay?.orderOut(nil)
    }
}

@discardableResult
func requireAXTrust() -> Bool {
    let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
    return AXIsProcessTrustedWithOptions(options)
}

// MARK: - AppDelegate
class AppDelegate: NSObject, NSApplicationDelegate {

    var eventTap: CFMachPort?
    var runLoopSource: CFRunLoopSource?

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        requireAXTrust()

        let eventMask = (1 << CGEventType.keyDown.rawValue) | (1 << CGEventType.flagsChanged.rawValue)

        guard let eventTap = CGEvent.tapCreate(
            tap: .cgSessionEventTap,
            place: .tailAppendEventTap,
            options: .listenOnly,
            eventsOfInterest: CGEventMask(eventMask),
            callback: { (proxy, type, cgEvent, refcon) -> Unmanaged<CGEvent>? in

                
                if type == .flagsChanged {
                    let flags = cgEvent.flags
                    let commandStillHeld = flags.contains(.maskCommand)

                    if !commandStillHeld, let saved = savedMousePosition {
                        let screenHeight = NSScreen.screens.reduce(0) { max($0, $1.frame.maxY) }
                        let targetCG = CGPoint(x: saved.x, y: screenHeight - saved.y)
                        if moveMouseBackToOriginalPosition {
                            moveMouse(to: targetCG)
                            print("Mouse restored to \(saved)")
                        }
                        savedMousePosition = nil
                    }
                    return Unmanaged.passRetained(cgEvent)
                }

                guard type == .keyDown else {
                    return Unmanaged.passRetained(cgEvent)
                }

                let keyCode = cgEvent.getIntegerValueField(.keyboardEventKeycode)
                let flags   = cgEvent.flags

                let commandPressed = flags.contains(.maskCommand)
                let isTabKey       = (keyCode == 48) // kVK_Tab

                if commandPressed && isTabKey {
                    let mouseNow = NSEvent.mouseLocation
                    if savedMousePosition == nil {
                        savedMousePosition = mouseNow
                    }
                    print("Mouse: \(mouseNow.x), \(mouseNow.y)")

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.08) {
                        handleCmdTab(mouseAtKeypress: mouseNow)
                    }
                }

                return Unmanaged.passUnretained(cgEvent)
            },
            userInfo: nil
        ) else {
            DispatchQueue.main.async {
                let alert = NSAlert()
                alert.messageText = "Accessibility Permission Required"
                alert.informativeText = "NoMouseInAppSwitcher needs Accessibility access to monitor keyboard shortcuts.\n\nPlease enable it in System Settings → Privacy & Security → Accessibility."
                alert.alertStyle = .critical
                alert.addButton(withTitle: "Open System Settings")
                alert.addButton(withTitle: "Quit")
                
                let response = alert.runModal()
                if response == .alertFirstButtonReturn {
                    NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!)
                }
                NSApp.terminate(nil)
            }
            return
        }

        self.eventTap = eventTap
        let runLoopSource = CFMachPortCreateRunLoopSource(kCFAllocatorDefault, eventTap, 0)
        self.runLoopSource = runLoopSource
        CFRunLoopAddSource(CFRunLoopGetCurrent(), runLoopSource, .commonModes)
        CGEvent.tapEnable(tap: eventTap, enable: true)
        print("Event tap active")
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        if let eventTap = eventTap {
            CGEvent.tapEnable(tap: eventTap, enable: false)
        }
    }
}

// MARK: - Main handler
func handleCmdTab(mouseAtKeypress: NSPoint) {
    guard let activeScreen = NSScreen.screens.first(where: { $0.frame.contains(mouseAtKeypress) })
               ?? NSScreen.main else { return }

    let appSwitcherFrame = estimatedSwitcherFrame(on: activeScreen)
    print("Estimated app switcher frame: \(appSwitcherFrame)")
    if debugOverlayEnabled {
        DispatchQueue.main.async {
            showDebugOverlay(frame: appSwitcherFrame)
        }
    }


    let currentMouse = NSEvent.mouseLocation
    guard appSwitcherFrame.contains(currentMouse) else {
        print("Mouse is outside app switcher - nothing to do...")
        return
    }
    print("Mouse is inside app switcher — moving out")

    let screenHeight = NSScreen.screens.reduce(0) { max($0, $1.frame.maxY) }
    let targetNS = NSPoint(x: currentMouse.x, y: appSwitcherFrame.minY - 30)
    let targetCG = CGPoint(x: targetNS.x, y: screenHeight - targetNS.y)
    moveMouse(to: targetCG)
}

// MARK: - Estimated switcher frame
func estimatedSwitcherFrame(on screen: NSScreen) -> NSRect {
    // These are approximate values that work for macOS 26.5
    let iconSize:    CGFloat = 104
    let iconGap:     CGFloat = 30
    let sidePadding: CGFloat = 36
    let topPadding:  CGFloat = 36
    let screenMargin: CGFloat = 33

    let appCount = CGFloat(NSWorkspace.shared.runningApplications.filter {
        $0.activationPolicy == .regular
    }.count)

    print("appCount: \(appCount)")

    // maxSwitcherWidth is the max size that macOS will allocate to the app switcher window
    let maxSwitcherWidth = screen.frame.width - (screenMargin * 2)  // screenMargin on both sides of the appSwitcher
    let naturalWidth = (appCount * iconSize) + (appCount - 1) * iconGap + sidePadding * 2

    if naturalWidth <= maxSwitcherWidth {
        let height = iconSize + topPadding * 2
        let x = screen.frame.minX + (screen.frame.width - naturalWidth) / 2
        let y = (screen.frame.minY + (screen.frame.height - height) / 2).rounded(.down)
        return NSRect(x: x, y: y, width: naturalWidth, height: height)
    } else {
        let availableForIcons = maxSwitcherWidth - sidePadding * 2
        let gapRatio = iconGap / iconSize
        let scaledIcon = (availableForIcons / (appCount + gapRatio * (appCount - 1))).rounded(.down)
        let height = (scaledIcon + topPadding * 2).rounded(.down)
        let x = screen.frame.minX + (screen.frame.width - maxSwitcherWidth) / 2
        let y = (screen.frame.minY + (screen.frame.height - height) / 2).rounded(.down)
        print("Scaled icon size: \(scaledIcon)pt")
        return NSRect(x: x, y: y, width: maxSwitcherWidth, height: height)
    }
}

// MARK: - Mouse movement
func moveMouse(to cgPoint: CGPoint) {
    let event = CGEvent(
        mouseEventSource: nil,
        mouseType: .mouseMoved,
        mouseCursorPosition: cgPoint,
        mouseButton: .left
    )
    event?.post(tap: .cghidEventTap)
}
