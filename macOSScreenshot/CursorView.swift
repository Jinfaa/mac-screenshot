import Cocoa

class CursorView: NSView {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        self.wantsLayer = true
        self.layer?.backgroundColor = NSColor.clear.cgColor
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
   override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        let cursorSize: CGFloat = 25
        let lineWidth: CGFloat = 2.0
        let centerPoint = NSPoint(x: bounds.midX, y: bounds.midY)
        
        // Создаем градиент
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 1.0),
            NSColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 1.0),
            NSColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 1.0),
            NSColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 1.0)
        ])
        
        let horizontalRect = NSRect(x: centerPoint.x - cursorSize/2, y: centerPoint.y - lineWidth/2, width: cursorSize, height: lineWidth)
        gradient?.draw(in: horizontalRect, angle: CGFloat(Date().timeIntervalSince1970 * 50).truncatingRemainder(dividingBy: 360))
        
        let verticalRect = NSRect(x: centerPoint.x - lineWidth/2, y: centerPoint.y - cursorSize/2, width: lineWidth, height: cursorSize)
        gradient?.draw(in: verticalRect, angle: CGFloat(Date().timeIntervalSince1970 * 50).truncatingRemainder(dividingBy: 360))
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            self.needsDisplay = true
        }
    }
}
