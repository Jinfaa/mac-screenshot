import Cocoa
import ScreenCaptureKit

class SelectionView: NSView {
    var startPoint: NSPoint?
    var endPoint: NSPoint?
    var cursorView: CursorView?
    static var screenshotWindow: NSWindow?
    var selectionRect: NSRect?
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        setupCursorView()
        setupTrackingArea()
        setupKeyEventHandler()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCursorView()
        setupTrackingArea()
        setupKeyEventHandler()
    }
    
    func setupCursorView() {
        cursorView = CursorView(frame: NSRect(x: 0, y: 0, width: 25, height: 25))
        if let cursorView = cursorView {
            addSubview(cursorView)
            cursorView.isHidden = true
        }
    }
    
    func startGradientAnimation() {
        needsDisplay = true
    }
    
    func setupTrackingArea() {
        let options: NSTrackingArea.Options = [.activeAlways, .mouseMoved, .mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
        addTrackingArea(trackingArea)
    }
    
    override func mouseMoved(with event: NSEvent) {
        let location = convert(event.locationInWindow, from: nil)
        cursorView?.frame.origin = CGPoint(x: location.x - 12.5, y: location.y - 12.5)
    }
    
    override func mouseEntered(with event: NSEvent) {
        NSCursor.hide()
        cursorView?.isHidden = false
    }
    
    override func mouseExited(with event: NSEvent) {
        NSCursor.unhide()
        cursorView?.isHidden = true
    }
    
    override func mouseDown(with event: NSEvent) {
        print("Нажатие мыши обнаружено")
        startPoint = event.locationInWindow
        endPoint = startPoint
        
        // Обновляем положение курсора
        let location = convert(event.locationInWindow, from: nil)
        cursorView?.frame.origin = CGPoint(x: location.x - 12.5, y: location.y - 12.5)
        cursorView?.isHidden = false
        
        startGradientAnimation()
        needsDisplay = true
    }
    
    override func mouseDragged(with event: NSEvent) {
        endPoint = event.locationInWindow
        needsDisplay = true
        
        // Обновляем положение курсора
        let location = convert(event.locationInWindow, from: nil)
        cursorView?.frame.origin = CGPoint(x: location.x - 12.5, y: location.y - 12.5)
    }
    
    override func mouseUp(with event: NSEvent) {
        print("Отпускание кнопки мыши обнаружено")
        endPoint = event.locationInWindow
        
        guard let start = startPoint, let end = endPoint else { return }
        
        let selectionRect = NSRect(x: min(start.x, end.x),
                                   y: min(start.y, end.y),
                                   width: abs(end.x - start.x),
                                   height: abs(end.y - start.y))
        
        // Проверка на минимальный размер выделенной области
        let minSize: CGFloat = 10.0
        if selectionRect.width < minSize || selectionRect.height < minSize {
            print("Выделенная область слишком мала")
            cancelSelection()
            return
        }
        
        // Делаем скриншот без элементов интерфейса
        takeScreenshot(of: selectionRect)
        
        // Сразу отменяем выделение
        cancelSelection()
    }
    @objc func cancelScreenshot() {
        hideCancelButtonAndLoadingIndicator()
        cancelSelection()
    }
    func cancelSelection() {
        startPoint = nil
        endPoint = nil
        cursorView?.isHidden = true
        NSCursor.unhide()
        needsDisplay = true
        cancelSelectionOnAllScreens()
    }
    
    func hideCancelButtonAndLoadingIndicator() {
        subviews.forEach { subview in
            if subview is NSButton || subview is NSProgressIndicator {
                subview.removeFromSuperview()
            }
        }
    }
    
    func showCancelButtonAndLoadingIndicator(in rect: NSRect) {
        let centerX = rect.midX
        let centerY = rect.midY
        
        // Создаем и добавляем кнопку отмены
        let cancelButton = NSButton(frame: NSRect(x: centerX - 40, y: centerY - 15, width: 80, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .rounded
        cancelButton.target = self
        cancelButton.action = #selector(cancelScreenshot)
        addSubview(cancelButton)
        
        // Создаем и добавляем индикатор загрузки
        let loadingIndicator = NSProgressIndicator(frame: NSRect(x: centerX - 10, y: centerY + 20, width: 20, height: 20))
        loadingIndicator.style = .spinning
        loadingIndicator.startAnimation(nil)
        addSubview(loadingIndicator)
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        guard let start = startPoint, let end = endPoint else { return }
        
        let selectionRect = NSRect(x: min(start.x, end.x),
                                   y: min(start.y, end.y),
                                   width: abs(end.x - start.x),
                                   height: abs(end.y - start.y))
        
        // Создаем градиент
        let gradient = NSGradient(colors: [
            NSColor(red: 1.0, green: 0.5, blue: 0.0, alpha: 0.3),
            NSColor(red: 1.0, green: 0.0, blue: 0.5, alpha: 0.3),
            NSColor(red: 0.5, green: 0.0, blue: 1.0, alpha: 0.3),
            NSColor(red: 0.0, green: 0.5, blue: 1.0, alpha: 0.3)
        ])
        
        // Рисуем градиент
        gradient?.draw(in: selectionRect, angle: CGFloat(Date().timeIntervalSince1970 * 50).truncatingRemainder(dividingBy: 360))
        
        // Рисуем белую рамку
        NSColor.white.setStroke()
        let selectionPath = NSBezierPath(rect: selectionRect)
        selectionPath.lineWidth = 2
        selectionPath.stroke()
        
        drawCornerMarkers(in: selectionRect)
        drawSelectionSize(for: selectionRect)
        
        // Запрашиваем перерисовку для анимации
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.03) {
            self.needsDisplay = true
        }
    }
    
    func drawCornerMarkers(in rect: NSRect) {
        let markerSize: CGFloat = 10
        let markerPath = NSBezierPath()
        
        // Верхний левый угол
        markerPath.move(to: NSPoint(x: rect.minX, y: rect.minY + markerSize))
        markerPath.line(to: NSPoint(x: rect.minX, y: rect.minY))
        markerPath.line(to: NSPoint(x: rect.minX + markerSize, y: rect.minY))
        
        // Верхний правый угол
        markerPath.move(to: NSPoint(x: rect.maxX - markerSize, y: rect.minY))
        markerPath.line(to: NSPoint(x: rect.maxX, y: rect.minY))
        markerPath.line(to: NSPoint(x: rect.maxX, y: rect.minY + markerSize))
        
        // Нижний левый угол
        markerPath.move(to: NSPoint(x: rect.minX, y: rect.maxY - markerSize))
        markerPath.line(to: NSPoint(x: rect.minX, y: rect.maxY))
        markerPath.line(to: NSPoint(x: rect.minX + markerSize, y: rect.maxY))
        
        // Нижний правый угол
        markerPath.move(to: NSPoint(x: rect.maxX - markerSize, y: rect.maxY))
        markerPath.line(to: NSPoint(x: rect.maxX, y: rect.maxY))
        markerPath.line(to: NSPoint(x: rect.maxX, y: rect.maxY - markerSize))
        
        NSColor.white.setStroke()
        markerPath.lineWidth = 2
        markerPath.stroke()
    }
    
    func drawSelectionSize(for rect: NSRect) {
        let sizeString = String(format: "%.0f x %.0f", rect.width, rect.height)
        let attributes: [NSAttributedString.Key: Any] = [
            .font: NSFont.systemFont(ofSize: 12),
            .foregroundColor: NSColor.white,
            .strokeColor: NSColor.black,
            .strokeWidth: -1.0
        ]
        let size = sizeString.size(withAttributes: attributes)
        let point = NSPoint(x: rect.midX - size.width / 2, y: rect.maxY + 5)
        sizeString.draw(at: point, withAttributes: attributes)
    }
    
    func takeScreenshot(of rect: NSRect) {
        print("Начало создания скриншота \(rect)")
        
        // Временно скрываем все элементы интерфейса
        let originalNeedsDisplay = needsDisplay
        needsDisplay = false
        cursorView?.isHidden = true
        
        // Скрываем выделение и другие элементы интерфейса
        self.isHidden = true
        
        Task {
            do {
                let content = try await SCShareableContent.excludingDesktopWindows(false, onScreenWindowsOnly: true)
                guard let activeDisplay = getActiveDisplay(from: content.displays) else {
                    print("Не удалось определить активный экран")
                    return
                }
                
                let screenWidth = activeDisplay.width
                let screenHeight = activeDisplay.height
                let screenRect = NSRect(x: 0, y: 0, width: screenWidth, height: screenHeight)
                let filter = SCContentFilter(display: activeDisplay, excludingWindows: [])
                let pixelPointScale = Int(filter.pointPixelScale)
                print("Масштаб пикселей: \(pixelPointScale)")
                
                let configuration = SCStreamConfiguration()
                configuration.queueDepth = 1
                configuration.showsCursor = false
                configuration.capturesAudio = false
                configuration.backgroundColor = .clear
                
                configuration.width = Int(screenRect.width) * pixelPointScale
                configuration.height = Int(screenRect.height) * pixelPointScale
                configuration.pixelFormat = kCVPixelFormatType_32BGRA
                
                let stream = SCStream(filter: filter, configuration: configuration, delegate: nil)
                
                let scaledRect = rect.scaled(by: CGFloat(pixelPointScale))
                let captureRect = NSRect(x: scaledRect.origin.x, y: screenRect.height * CGFloat(pixelPointScale) - scaledRect.origin.y - scaledRect.height, width: scaledRect.width, height: scaledRect.height)
                
                let output = MyStreamOutput(captureRect: captureRect)
                try stream.addStreamOutput(output, type: .screen, sampleHandlerQueue: DispatchQueue.main)
                
                try await stream.startCapture()
                
                try await Task.sleep(nanoseconds: 100_000_000) // 100ms
                
                try await stream.stopCapture()
                print("Захват успешно остановлен")
                
                let capturedImage = try await output.captureImage()
                let bitmapRep = NSBitmapImageRep(cgImage: capturedImage)
                guard let pngData = bitmapRep.representation(using: .png, properties: [.compressionFactor: 1.0]) else {
                    print("Не удалось создать PNG данные")
                    return
                }
                print("PNG данные созданы")
                
                // Сохранение и отображение скриншота
                saveAndDisplayScreenshot(pngData: pngData)
            } catch {
                print("Не удалось создать изображение: \(error)")
            }
            
            // Восстанавливаем видимость элементов интерфейса
            DispatchQueue.main.async { [weak self] in
                self?.isHidden = false
                self?.needsDisplay = originalNeedsDisplay
                self?.cursorView?.isHidden = false
                
                // Показываем кнопку отмены и индикатор загрузки после создания скриншота
                if let selectionRect = self?.selectionRect {
                    self?.showCancelButtonAndLoadingIndicator(in: selectionRect)
                }
            }
        }
    }
    
    func saveAndDisplayScreenshot(pngData: Data) {
        let tempDir = FileManager.default.temporaryDirectory
        let timestamp = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
        let dateString = dateFormatter.string(from: timestamp)
        let fileURL = tempDir.appendingPathComponent("CodenameScreenshot_\(dateString).png")
        
        do {
            try pngData.write(to: fileURL)
            print("Скриншот успешно сохранен: \(fileURL.path)")
            
            CoreDataManager.shared.saveImagePath(fileURL.path, description: dateString, timestamp: timestamp)
            
            if let image = NSImage(data: pngData) {
                DispatchQueue.main.async { [weak self] in
                    self?.displayScreenshot(image)
                }
            }
        } catch {
            print("Ошибка при сохранении скриншота: \(error.localizedDescription)")
        }
    }
    
    func getActiveDisplay(from displays: [SCDisplay]) -> SCDisplay? {
        // Логика для определения активного экрана
        // Например, можно использовать текущую позицию курсора для определения активного экрана
        let mouseLocation = NSEvent.mouseLocation
        for display in displays {
            let screenFrame = display.frame
            if screenFrame.contains(mouseLocation) {
                return display
            }
        }
        return nil
    }
    
    func cancelSelectionOnAllScreens() {
        print("Отмена выделения на всех экранах")
        guard let appDelegate = NSApp.delegate as? AppDelegate else { return }
        appDelegate.stopSelection()
    }
    
    func displayScreenshot(_ image: NSImage) {
        // Скрываем предыдущее окно скриншота, если оно существует
        SelectionView.screenshotWindow?.orderOut(nil)
        
        let window = NSWindow(contentRect: .zero, styleMask: [.borderless], backing: .buffered, defer: false)
        window.level = .floating
        window.isOpaque = false
        window.backgroundColor = .clear
        window.collectionBehavior = [.canJoinAllSpaces, .fullScreenAuxiliary]
        window.animationBehavior = .none // Отключаем анимацию
        
        let contentView = NSView()
        contentView.wantsLayer = true
        contentView.layer?.backgroundColor = NSColor.clear.cgColor
        window.contentView = contentView
        
        let imageView = NSImageView()
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyUpOrDown
        contentView.addSubview(imageView)
        
        let gradientView = NSView()
        gradientView.wantsLayer = true
        gradientView.layer?.borderWidth = 4.0
        gradientView.layer?.cornerRadius = 8.0
        contentView.addSubview(gradientView)
        
        SelectionView.screenshotWindow = window
        
        updateScreenshotWindowPosition()
        
        // Анимация градиента
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = gradientView.bounds
        gradientLayer.colors = [NSColor.red.cgColor, NSColor.blue.cgColor, NSColor.green.cgColor, NSColor.yellow.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientView.layer?.addSublayer(gradientLayer)
        
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = [NSColor.yellow.cgColor, NSColor.green.cgColor, NSColor.blue.cgColor, NSColor.red.cgColor]
        animation.duration = 3.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")
        
        window.makeKeyAndOrderFront(nil)
        
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(activeSpaceDidChange),
            name: NSWorkspace.activeSpaceDidChangeNotification,
            object: nil
        )
        
        // Заменяем скриншот на текст через 5 секунд
        DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
            imageView.removeFromSuperview()
        }
    }
    
    @objc func activeSpaceDidChange() {
        updateScreenshotWindowPosition()
    }
    
 func updateScreenshotWindowPosition() {
    guard let window = SelectionView.screenshotWindow,
          let image = (window.contentView?.subviews.first as? NSImageView)?.image else { return }
    
    let mouseLocation = NSEvent.mouseLocation
    guard let screen = NSScreen.screens.first(where: { NSMouseInRect(mouseLocation, $0.frame, false) }) else { return }
    
    let padding: CGFloat = 4.0
    let maxContainerWidth: CGFloat = 400.0
    let maxContainerHeight: CGFloat = 200.0

    let aspectRatio = image.size.height / image.size.width
    let containerWidth = maxContainerWidth
    var containerHeight = (containerWidth - 2 * padding) * aspectRatio + 2 * padding
    
    // Ограничиваем высоту контейнера
    if containerHeight > maxContainerHeight {
        containerHeight = maxContainerHeight
    }
    
    let windowRect = NSRect(x: screen.frame.minX + padding,
                            y: screen.frame.maxY - containerHeight - padding,
                            width: containerWidth,
                            height: containerHeight)
    
    window.setFrame(windowRect, display: true, animate: true)
    
    if let contentView = window.contentView {
        contentView.subviews.forEach { $0.removeFromSuperview() }
        
        // Создаем контейнер
        let containerView = NSView(frame: contentView.bounds)
        containerView.wantsLayer = true
        containerView.layer?.cornerRadius = 8.0
        containerView.layer?.masksToBounds = true
        contentView.addSubview(containerView)
        
        // Добавляем градиентный слой
        let gradientLayer = CAGradientLayer()
        gradientLayer.frame = containerView.bounds
        gradientLayer.colors = [NSColor.red.cgColor, NSColor.blue.cgColor, NSColor.green.cgColor, NSColor.yellow.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.opacity = 0.8
        containerView.layer?.addSublayer(gradientLayer)
        
        // Анимация градиента
        let animation = CABasicAnimation(keyPath: "colors")
        animation.fromValue = gradientLayer.colors
        animation.toValue = [NSColor.yellow.cgColor, NSColor.green.cgColor, NSColor.blue.cgColor, NSColor.red.cgColor]
        animation.duration = 3.0
        animation.autoreverses = true
        animation.repeatCount = .infinity
        gradientLayer.add(animation, forKey: "gradientAnimation")
        
        // Добавляем белый фон
        let whiteBackgroundView = NSView(frame: NSRect(x: padding, y: padding, width: containerWidth - 2 * padding, height: containerHeight - 2 * padding))
        whiteBackgroundView.wantsLayer = true
        whiteBackgroundView.layer?.backgroundColor = NSColor.white.cgColor
        whiteBackgroundView.layer?.cornerRadius = 8.0
        containerView.addSubview(whiteBackgroundView)
        
        // Добавляем изображение
        let imageView = NSImageView(frame: whiteBackgroundView.bounds)
        imageView.image = image
        imageView.imageScaling = .scaleProportionallyDown
        imageView.imageAlignment = .alignCenter
        whiteBackgroundView.addSubview(imageView)
        
        // Добавляем контейнер для кнопки и индикатора
        let controlsContainer = NSView(frame: NSRect(x: containerWidth - 120, y: 10, width: 110, height: 30))
        controlsContainer.wantsLayer = true
        controlsContainer.layer?.backgroundColor = NSColor.darkGray.withAlphaComponent(0.7).cgColor
        controlsContainer.layer?.cornerRadius = 15
        containerView.addSubview(controlsContainer)
        
        // Добавляем индикатор загрузки
        let loadingIndicator = NSProgressIndicator(frame: NSRect(x: 16, y: 5, width: 20, height: 20))
        loadingIndicator.style = .spinning
        loadingIndicator.appearance = NSAppearance(named: .vibrantLight)
        loadingIndicator.startAnimation(nil)
        controlsContainer.addSubview(loadingIndicator)
        
        // Добавляем кнопку Cancel
        let cancelButton = NSButton(frame: NSRect(x: 30, y: 0, width: 80, height: 30))
        cancelButton.title = "Cancel"
        cancelButton.bezelStyle = .inline
        cancelButton.isBordered = false
        cancelButton.font = NSFont.systemFont(ofSize: 14, weight: .medium)
        cancelButton.set(textColor: .white)
        cancelButton.target = self
        cancelButton.action = #selector(closeScreenshotWindow(_:))
        controlsContainer.addSubview(cancelButton)
    }
}
    
    @objc func closeScreenshotWindow(_ sender: NSButton?) {
        SelectionView.screenshotWindow?.orderOut(nil)
        SelectionView.screenshotWindow = nil
    }
    
    func setupKeyEventHandler() {
        NSEvent.addLocalMonitorForEvents(matching: .keyDown) { [weak self] event in
            self?.keyDown(with: event)
            return event
        }
    }
    
    override func keyDown(with event: NSEvent) {
        if event.keyCode == 53 { // 53 - это код клавиши Esc
            print("Нажата клавиша Esc")
            cancelSelection()
        } else {
            super.keyDown(with: event)
        }
    }
}


extension NSButton {
    
    func set(textColor color: NSColor) {
        let newAttributedTitle = NSMutableAttributedString(attributedString: attributedTitle)
        let range = NSRange(location: 0, length: attributedTitle.length)
        
        newAttributedTitle.addAttributes([
            .foregroundColor: color,
        ], range: range)
        
        attributedTitle = newAttributedTitle
    }
}
