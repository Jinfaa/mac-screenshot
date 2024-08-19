import Cocoa

class SelectionWindow: NSWindow {
    
    // MARK: - Properties
    private var selectionView: NSView?
    
    // MARK: - Initialization
    override init(contentRect: NSRect, styleMask style: NSWindow.StyleMask, backing backingStoreType: NSWindow.BackingStoreType, defer flag: Bool) {
        super.init(contentRect: contentRect, styleMask: style, backing: backingStoreType, defer: flag)
        
        setupWindow()
        setupSelectionView()
    }
    
    // MARK: - Setup
    private func setupWindow() {
        self.isOpaque = false
        self.backgroundColor = NSColor.clear
        self.isMovableByWindowBackground = false
        self.level = .floating
        self.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        self.ignoresMouseEvents = false
    }
    
    private func setupSelectionView() {
        selectionView = NSView(frame: self.contentView!.bounds)
        selectionView?.wantsLayer = true
        
        if let selectionView = selectionView {
            self.contentView?.addSubview(selectionView)
        }
    }
    
    // MARK: - Public Methods
    func updateSelectionFrame(_ frame: NSRect) {
        selectionView?.frame = frame
    }
    
    override func becomeKey() {
        super.becomeKey()
        NotificationCenter.default.addObserver(self, selector: #selector(screenChanged), name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    override var canBecomeKey: Bool {
        return false
    }
    
    override func resignKey() {
        super.resignKey()
        NotificationCenter.default.removeObserver(self, name: NSApplication.didChangeScreenParametersNotification, object: nil)
    }
    
    @objc private func screenChanged() {
        guard let screen = self.screen else { return }
        let screenFrame = screen.frame
        self.setFrame(screenFrame, display: true)
    }
}
