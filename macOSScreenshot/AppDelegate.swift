import Cocoa
import Carbon
import ScreenCaptureKit

@main
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem!
    
    var selectionWindows: [SelectionWindow] = {
        return NSScreen.screens.map { screen in
            let screenFrame = screen.frame
            let selectionWindow = SelectionWindow(contentRect: screenFrame, styleMask: .borderless, backing: .buffered, defer: false)
            selectionWindow.backgroundColor = .clear
            selectionWindow.isOpaque = false
            selectionWindow.level = .floating
            selectionWindow.ignoresMouseEvents = false
            selectionWindow.contentView = SelectionView(frame: screenFrame)
            return selectionWindow
        }
    }()
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
        
        let menu = NSMenu()
        
        let historyMenuItem = NSMenuItem(title: "History", action: #selector(openHistory), keyEquivalent: "H")
        menu.addItem(historyMenuItem)
        
        let quitMenuItem = NSMenuItem(title: "Quit", action: #selector(quitApplication), keyEquivalent: "Q")
        menu.addItem(quitMenuItem)
        
        statusItem.menu = menu
        
        statusItem.button?.image = NSImage.init(named: "TrayIcon")
        statusItem.button?.image?.size = NSSize(width: 16, height: 16)
        
        registerGlobalHotkey()
        
        NSApp.setActivationPolicy(.accessory)
    }
    
    func startSelection() {
        guard !selectionWindows.isEmpty else {
            return
        }
        
        for selectionWindow in selectionWindows {
            updateSelectionWindowContent(selectionWindow)
            selectionWindow.makeKeyAndOrderFront(self)
        }
        
        NSApplication.shared.activate(ignoringOtherApps: true)
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        
        selectionWindows.first?.makeKeyAndOrderFront(self)
    }
    
    
    
    func updateSelectionWindowContent(_ window: SelectionWindow) {
        guard let screen = window.screen else {
            return
        }
        
        let screenFrame = screen.frame
        window.setFrame(screenFrame, display: true)
        
        let newSelectionView = SelectionView(frame: screenFrame)
        window.contentView = newSelectionView
        window.makeFirstResponder(newSelectionView)
    }
    
    func stopSelection() {
        
        for selectionWindow in selectionWindows {
            selectionWindow.orderOut(nil)
        }
    }
    
    func registerGlobalHotkey() {
        var eventHotKeyRef: EventHotKeyRef?
        var eventHotKeyID = EventHotKeyID(signature: OSType(0x5343524E), id: UInt32(1))
        let hotKeyCode = UInt32(kVK_ANSI_Grave) // Код клавиши для тильды (~)
        let hotKeyModifiers = UInt32(shiftKey | cmdKey) // Модификаторы для shift+cmd
        
        let _ = RegisterEventHotKey(hotKeyCode, hotKeyModifiers, eventHotKeyID, GetApplicationEventTarget(), 0, &eventHotKeyRef)
        
        let eventHandler: EventHandlerUPP = { (nextHandler, theEvent, userData) -> OSStatus in
            let appDelegate = NSApp.delegate as! AppDelegate
            appDelegate.startSelection()
            return noErr
        }
        
        var eventType = EventTypeSpec(eventClass: OSType(kEventClassKeyboard), eventKind: UInt32(kEventHotKeyPressed))
        let _ = InstallEventHandler(GetApplicationEventTarget(), eventHandler, 1, &eventType, nil, nil)
    }
    
    @objc func openHistory() {
        let historyViewController = HistoryViewController()
        let window = NSWindow(contentViewController: historyViewController)
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    @objc func quitApplication() {
        NSApp.terminate(nil)
    }
    
    func getActiveDisplay(from displays: [SCDisplay]) -> SCDisplay? {
        let mouseLocation = NSEvent.mouseLocation
        for display in displays {
            let screenFrame = display.frame
            if screenFrame.contains(mouseLocation) {
                return display
            }
        }
        return nil
    }
}
