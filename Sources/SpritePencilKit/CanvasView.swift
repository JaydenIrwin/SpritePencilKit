import UIKit

public protocol CanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: CanvasView)
    func canvasViewDidFinishRendering(_ canvasView: CanvasView)
    func canvasViewDidBeginUsingTool(_ canvasView: CanvasView)
    func canvasViewDidEndUsingTool(_ canvasView: CanvasView)
}

public class CanvasView: UIScrollView, UIGestureRecognizerDelegate, UIScrollViewDelegate {
    
    public enum FingerAction: String {
        case ignore, move, eyedrop
    }

    // Delegates & Views
    public var documentController: DocumentController!
    public var canvasDelegate: CanvasViewDelegate?
    public var checkerboardView: UIImageView!
    public var spriteView: UIImageView!
    public var hoverView: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 2.05, height: 2.05)))
        view.layer.borderWidth = 0.1
        view.layer.borderColor = UIColor.black.cgColor
        view.isHidden = true
        return view
    }()
    public var toolSizeCopy = CGSize(width: 1, height: 1)
    
    // Grids
    public var pixelGridEnabled = false
    public var tileGridEnabled = false
    public var tileGridLayer: CAShapeLayer?
    public var pixelGridLayer: CAShapeLayer?
    
    // General
    public var tool: Tool {
        get {
            return documentController.tool
        }
        set {
            documentController.tool = newValue
        }
    }
    public var zoomEnabled = true {
        didSet {
            if zoomEnabled {
                minimumZoomScale = 4.0
                maximumZoomScale = 32.0
            } else {
                minimumZoomScale = zoomScale
                maximumZoomScale = zoomScale
            }
        }
    }
    public var zoomEnabledOverride = false
    public var fingerAction = FingerAction.ignore
    public var applePencilUsed = false
    public var applePencilCanEyedrop = true
    public var shouldFillPaths = false
    public var userZoomingCausedAccidentalDrawing = false
    public var spriteZoomScale: CGFloat = 2.0 // Sprite view is 2x scale of checkerboard view
    public var dragStartPoint: CGPoint?
    public var spriteCopy: UIImage! {
        didSet {
            contentSize = spriteCopy.size
        }
    }
    public var shouldStartZooming: Bool {
        let toolSize: CGSize
        switch tool {
        case let pencil as PencilTool:
            toolSize = pencil.size
        case let eraser as EraserTool:
            toolSize = eraser.size
        case let highlight as HighlightTool:
            toolSize = highlight.size
        case let shadow as ShadowTool:
            toolSize = shadow.size
        default:
            toolSize = CGSize(width: 1, height: 1)
        }
        let maximumCancelableDrawnPoints = 8 * Int(toolSize.width * toolSize.height)
        let drawnPointsAreCancelable = (documentController.currentOperationPixelPoints.count <= maximumCancelableDrawnPoints)
        return (zoomEnabled && drawnPointsAreCancelable) || zoomEnabledOverride
    }

    public func setupView() {
        delegate = self
        panGestureRecognizer.minimumNumberOfTouches = 2
        delaysContentTouches = false
        minimumZoomScale = 4.0
        maximumZoomScale = 32.0
        zoomScale = 4.0
        scrollsToTop = false
        
        checkerboardView = UIImageView(frame: bounds)
        checkerboardView.layer.magnificationFilter = .nearest
        checkerboardView.translatesAutoresizingMaskIntoConstraints = false
        
        spriteView = UIImageView(frame: bounds)
        spriteView.layer.magnificationFilter = .nearest
        spriteView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(checkerboardView)
        checkerboardView.addSubview(spriteView)
        spriteView.addSubview(hoverView)
        
        addConstraints([
            NSLayoutConstraint(item: spriteView!, attribute: .top, relatedBy: .equal, toItem: checkerboardView, attribute: .top, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: spriteView!, attribute: .bottom, relatedBy: .equal, toItem: checkerboardView, attribute: .bottom, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: spriteView!, attribute: .leading, relatedBy: .equal, toItem: checkerboardView, attribute: .leading, multiplier: 1.0, constant: 0.0),
            NSLayoutConstraint(item: spriteView!, attribute: .trailing, relatedBy: .equal, toItem: checkerboardView, attribute: .trailing, multiplier: 1.0, constant: 0.0)
        ])
        
        let undo = UISwipeGestureRecognizer(target: self, action: #selector(doUndo))
        undo.direction = .left
        undo.numberOfTouchesRequired = 3
        let redo = UISwipeGestureRecognizer(target: self, action: #selector(doRedo))
        redo.direction = .right
        redo.numberOfTouchesRequired = 3
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(mouseDidMove(with:)))
        addGestureRecognizer(undo)
        addGestureRecognizer(redo)
        addGestureRecognizer(hover)
        
        documentController.refresh()
        makeCheckerboard()
		isUserInteractionEnabled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.zoomToFit()
        }
	}
    
    public func makeCheckerboard() {
        checkerboardView.image = {
            guard let checkers = CIFilter(name: "CICheckerboardGenerator") else { return nil }
            let color0 = CIColor(color: UIColor.systemGray5)
            let color1 = CIColor(color: UIColor.systemGray6)
            checkers.setValue(color0, forKey: "inputColor0")
            checkers.setValue(color1, forKey: "inputColor1")
            checkers.setValue(1.0, forKey: kCIInputWidthKey)
            guard let image = checkers.outputImage, let documentContext = documentController.context else { return nil }
            
            let minimumCheckerboardPixelSize: CGFloat = 4.0
            let checkerboardPixelSize = bounds.width / (CGFloat(documentContext.width) * spriteZoomScale)
            if checkerboardPixelSize < minimumCheckerboardPixelSize {
                spriteZoomScale = 1.0
            }
            
            let width = CGFloat(documentContext.width) * spriteZoomScale
            let height = CGFloat(documentContext.height) * spriteZoomScale
            let rect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
            let ciContext = CIContext(options: nil)
            return UIImage(cgImage: ciContext.createCGImage(image, from: rect)!)
        }()
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            makeCheckerboard()
        }
    }
    
    public func toolSizeChanged(size: CGSize) {
        toolSizeCopy = size
        hoverView.bounds.size = CGSize(width: size.width * 2 + 0.05, height: size.height * 2 + 0.05)
    }
    
    public func zoomToFit() {
        let viewRatio = bounds.width / bounds.height
        let spriteSize = CGSize(width: documentController.context.width, height: documentController.context.height)
        let spriteRatio = spriteSize.width / spriteSize.height
        
        var scale: CGFloat = 1/spriteZoomScale
        if viewRatio <= spriteRatio {
            scale *= bounds.width / spriteSize.width
        } else {
            scale *= bounds.height / spriteSize.height
        }
        zoomEnabledOverride = true
        if scale < self.minimumZoomScale || self.maximumZoomScale < scale {
            self.minimumZoomScale = scale
            self.maximumZoomScale = scale
        }
        self.setZoomScale(scale, animated: false)
        self.checkerboardView.frame.origin = .zero
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.zoomEnabledOverride = false
        }
    }
    
    public func refreshGrid() {
        let documentWidth = documentController.context.width
        let documentHeight = documentController.context.height
        
        if tileGridEnabled {
            if tileGridLayer == nil {
                let tileSize = 16
                let tileScaleFactor = spriteZoomScale * CGFloat(tileSize)
                let path = UIBezierPath()
                for row in 0...(documentHeight / tileSize) {
                    let y = CGFloat(row) * tileScaleFactor
                    let start = CGPoint(x: 0, y: y)
                    let end = CGPoint(x: CGFloat(documentWidth) * spriteZoomScale, y: y)
                    path.move(to: start)
                    path.addLine(to: end)
                }
                for column in 0...(documentWidth / tileSize) {
                    let x = CGFloat(column) * tileScaleFactor
                    let start = CGPoint(x: x, y: 0)
                    let end = CGPoint(x: x, y: CGFloat(documentHeight) * spriteZoomScale)
                    path.move(to: start)
                    path.addLine(to: end)
                }
                path.close()
                tileGridLayer = CAShapeLayer()
                tileGridLayer?.lineWidth = 0.2
                tileGridLayer?.path = path.cgPath
                tileGridLayer?.strokeColor = UIColor.systemGray4.cgColor
                spriteView.layer.addSublayer(tileGridLayer!)
            }
        } else {
            tileGridLayer?.removeFromSuperlayer()
            tileGridLayer = nil
        }
        if pixelGridEnabled {
            if pixelGridLayer == nil {
                let pixelScaleFactor = spriteZoomScale
                let path = UIBezierPath()
                for row in 0...documentHeight {
                    let y = CGFloat(row) * pixelScaleFactor
                    let start = CGPoint(x: 0, y: y)
                    let end = CGPoint(x: CGFloat(documentWidth) * spriteZoomScale, y: y)
                    path.move(to: start)
                    path.addLine(to: end)
                }
                for column in 0...documentWidth {
                    let x = CGFloat(column) * pixelScaleFactor
                    let start = CGPoint(x: x, y: 0)
                    let end = CGPoint(x: x, y: CGFloat(documentHeight) * spriteZoomScale)
                    path.move(to: start)
                    path.addLine(to: end)
                }
                path.close()
                pixelGridLayer = CAShapeLayer()
                pixelGridLayer?.lineWidth = (0.1 / UIScreen.main.scale)
                pixelGridLayer?.path = path.cgPath
                pixelGridLayer?.strokeColor = UIColor.systemGray4.cgColor
                spriteView.layer.addSublayer(pixelGridLayer!)
            }
        } else {
            pixelGridLayer?.removeFromSuperlayer()
            pixelGridLayer = nil
        }
    }
    
    public func makePixelPoint(touchLocation: CGPoint, toolSize: CGSize) -> PixelPoint {
        let xOffset: CGFloat = (toolSize.width-1) / 2
        let yOffset: CGFloat = (toolSize.height-1) / 2
        // Returns the top left pixel of the rect of pixels.
        return PixelPoint(x: Int((touchLocation.x - xOffset) / spriteZoomScale), y: Int((touchLocation.y - yOffset) / spriteZoomScale))
    }
    
    @objc public func doUndo() {
        documentController.undo()
    }
    @objc public func doRedo() {
        documentController.redo()
    }
    
    // MARK: - Touches & Hover
    
    @objc public func mouseDidMove(with recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            let touchLocation = recognizer.location(in: spriteView)
            let point = makePixelPoint(touchLocation: touchLocation, toolSize: toolSizeCopy)
            hoverView.frame.origin = CGPoint(x: CGFloat(point.x * 2) - 0.05, y: CGFloat(point.y * 2) - 0.05)
            hoverView.isHidden = false
        case .ended:
            hoverView.isHidden = true
        default:
            break
        }
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        switch touches.first!.type {
        case .pencil:
            applePencilUsed = true
            if !applePencilCanEyedrop, tool is EyedroperTool {
                tool = documentController.pencilTool
            }
        default:
            if applePencilUsed {
                switch fingerAction {
                case .move:
                    tool = MoveTool()
                case .eyedrop:
                    tool = EyedroperTool()
                default:
                    break
                }
            }
        }
        guard validateTouchesForCurrentTool(touches) else { return }
        
        switch tool {
        case is EyedroperTool:
            break
        case is MoveTool:
            spriteCopy = UIImage(cgImage: documentController.context.makeImage()!)
            dragStartPoint = touches.first!.location(in: spriteView)
        default:
            documentController.undoManager?.beginUndoGrouping()
        }
        canvasDelegate?.canvasViewDidBeginUsingTool(self)
        if let coalesced = event?.coalescedTouches(for: touches.first!) {
            addSamples(for: coalesced)
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard validateTouchesForCurrentTool(touches) else { return }
        if let coalesced = event?.coalescedTouches(for: touches.first!) {
            addSamples(for: coalesced)
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard validateTouchesForCurrentTool(touches) else { return }
        
        switch tool {
        case is EyedroperTool:
            let point = makePixelPoint(touchLocation: touches.first!.location(in: spriteView), toolSize: CGSize(width: 1, height: 1))
            documentController.eyedrop(at: point)
            canvasDelegate?.canvasViewDidEndUsingTool(self)
        default:
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
            touchesStoped(touches)
        }
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard validateTouchesForCurrentTool(touches) else { return }
        
        if userZoomingCausedAccidentalDrawing {
            documentController.currentOperationPixelPoints.removeAll()
            canvasDelegate?.canvasViewDidEndUsingTool(self)
            if documentController.undoManager?.groupingLevel == 1 {
                documentController.undoManager?.endUndoGrouping()
                documentController.undoManager?.undo()
                documentController.refresh()
            }
        } else {
            touchesStoped(touches)
        }
    }
    
    public func validateTouchesForCurrentTool(_ touches: Set<UITouch>) -> Bool {
        switch touches.first!.type {
        case .pencil:
            return true
        default:
            if applePencilUsed {
                switch tool {
                case is EyedroperTool:
                    return fingerAction == .eyedrop
                case is MoveTool:
                    return fingerAction == .move
                default:
                    return false
                }
            } else {
                return true
            }
        }
    }

    public func touchesStoped(_ touches: Set<UITouch>) {
        switch tool {
        case is PencilTool:
            if shouldFillPaths {
                documentController.fillPath()
            }
            documentController.currentOperationPixelPoints.removeAll()
            documentController.undoManager?.endUndoGrouping()
        case is EyedroperTool, is MoveTool:
            break
        case is FillTool:
            let point = makePixelPoint(touchLocation: touches.first!.location(in: spriteView), toolSize: CGSize(width: 1, height: 1))
            documentController.fill(at: point)
            documentController.currentOperationPixelPoints.removeAll()
            documentController.undoManager?.endUndoGrouping()
        default:
            documentController.currentOperationPixelPoints.removeAll()
            documentController.undoManager?.endUndoGrouping()
        }
        canvasDelegate?.canvasViewDidEndUsingTool(self)
        
        switch touches.first!.type {
        case .pencil:
            break
        default:
            if applePencilUsed, fingerAction == .move {
                tool = documentController.previousTool
            }
        }
	}
    
    public func addSamples(for touches: [UITouch]) {
        switch tool {
        case is PencilTool, is EraserTool, is MoveTool, is HighlightTool, is ShadowTool:
            for touch in touches {
                let touchLocation = touch.location(in: spriteView)
                switch tool {
                case let pencil as PencilTool:
                    let point = makePixelPoint(touchLocation: touchLocation, toolSize: pencil.size)
                    documentController.paint(color: documentController.toolColor, at: point, size: pencil.size, byUser: true)
                case let eraser as EraserTool:
                    let point = makePixelPoint(touchLocation: touchLocation, toolSize: eraser.size)
                    documentController.paint(color: nil, at: point, size: eraser.size, byUser: true)
                case is MoveTool:
                    let dx = CGFloat((touchLocation.x - dragStartPoint!.x) / spriteZoomScale).rounded()
                    let dy = CGFloat((touchLocation.y - dragStartPoint!.y) / spriteZoomScale).rounded()
                    documentController.move(dx: dx, dy: dy)
                case let highlight as HighlightTool:
                    let point = makePixelPoint(touchLocation: touchLocation, toolSize: highlight.size)
                    documentController.highlight(at: point, size: highlight.size)
                case let shadow as ShadowTool:
                    let point = makePixelPoint(touchLocation: touchLocation, toolSize: shadow.size)
                    documentController.shadow(at: point, size: shadow.size)
                default:
                    break
                }
            }
            documentController.refresh()
            
            #if targetEnvironment(macCatalyst)
            let touchLocation = touches.first!.location(in: spriteView)
            let point = makePixelPoint(touchLocation: touchLocation, toolSize: toolSizeCopy)
            hoverView.frame.origin = CGPoint(x: CGFloat(point.x * 2) - 0.05, y: CGFloat(point.y * 2) - 0.05)
            hoverView.isHidden = false
            #endif
        default:
            break
        }
    }
    
    // MARK: - Zooming
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return checkerboardView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        userZoomingCausedAccidentalDrawing = shouldStartZooming && !zoomEnabledOverride
    }
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) {
        
        func centerContent() {
            if (contentSize.width < bounds.size.width) {
                contentOffset.x = (contentSize.width - bounds.size.width) / 2
            }
            if (contentSize.height < bounds.size.height) {
                contentOffset.y = (contentSize.height - bounds.size.height) / 2
            }
            
            var x: CGFloat = 0.0
            var y: CGFloat = 0.0
            if (contentSize.width < bounds.size.width) {
                x = (bounds.size.width - contentSize.width) / 2.0
            }
            if (contentSize.height < bounds.size.height) {
                y = (bounds.size.height - contentSize.height) / 2.0
            }
            contentInset = UIEdgeInsets(top: y, left: x, bottom: y, right: x)
        }
        
        centerContent()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let view = view else { return }
        // Snap to 100%
        let thresholdToSnap: CGFloat = 0.12
        let zoomScaleDistanceRange = 1.0-thresholdToSnap...1.0+thresholdToSnap
        
        let contentWidthFraction = bounds.width / (view.bounds.width * zoomScale)
        if zoomScaleDistanceRange.contains(contentWidthFraction) {
            let zoom = (bounds.width / view.bounds.width)
            setZoomScale(zoom, animated: true)
            return
        }
        
        let contentHeightFraction = bounds.height / (view.bounds.height * zoomScale)
        if zoomScaleDistanceRange.contains(contentHeightFraction) {
            let zoom = (bounds.height / view.bounds.height)
            setZoomScale(zoom, animated: true)
            return
        }
    }
    
}
