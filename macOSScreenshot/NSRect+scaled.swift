import Cocoa

extension NSRect {
    func scaled(by scale: CGFloat) -> NSRect {
        return NSRect(x: self.origin.x * scale, y: self.origin.y * scale, width: self.width * scale, height: self.height * scale)
    }
}
