import UIKit
import CoreImage.CIFilterBuiltins

public protocol CanvasViewDelegate {
    func canvasViewDrawingDidChange(_ canvasView: CanvasView)
    func canvasViewDidFinishRendering(_ canvasView: CanvasView)
    func canvasViewDidBeginUsingTool(_ canvasView: CanvasView)
    func canvasViewDidEndUsingTool(_ canvasView: CanvasView)
}

public class CanvasView: UIScrollView, UIGestureRecognizerDelegate, UIScrollViewDelegate, UIPencilInteractionDelegate {
    
    public static let defaultMinimumZoomScale: CGFloat = 1.0 // Must be low since if current < minimum, view will not zoom in.
    public static let defaultMaximumZoomScale: CGFloat = 32.0
    static let hoverViewBorderWidth: CGFloat = 0.1
    
    public enum FingerAction: String {
        case ignore, move, eyedrop
    }

    // Delegates & Views
    public var documentController: DocumentController!
    public var canvasDelegate: CanvasViewDelegate?
    public var checkerboardView: UIImageView!
    public var spriteView: UIImageView!
    public var hoverView: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 2 + CanvasView.hoverViewBorderWidth/2, height: 2 + CanvasView.hoverViewBorderWidth/2)))
        view.layer.borderWidth = CanvasView.hoverViewBorderWidth
        view.layer.borderColor = UIColor.label.cgColor
        view.isHidden = true
        return view
    }()
    public var symmetricHoverView: UIView = {
        let view = UIView(frame: CGRect(origin: .zero, size: CGSize(width: 2 + CanvasView.hoverViewBorderWidth/2, height: 2 + CanvasView.hoverViewBorderWidth/2)))
        view.layer.borderWidth = CanvasView.hoverViewBorderWidth
        view.layer.borderColor = UIColor.label.cgColor
        view.isHidden = true
        return view
    }()
    public var toolSizeCopy = PixelSize(width: 1, height: 1)
    override public var bounds: CGRect {
        didSet {
            if documentController != nil, !userWillStartZooming {
                zoomToFit()
            }
        }
    }
    
    // Grids
    public var pixelGridEnabled = false
    public var tileGridEnabled = false
    public var tileGridLayer: CAShapeLayer?
    public var pixelGridLayer: CAShapeLayer?
    public var symmetryLineLayer: CALayer?
    
    // General
    public var tool: Tool {
        get {
            documentController.tool
        }
        set {
            documentController.tool = newValue
        }
    }
    public var zoomEnabled = true {
        didSet {
            if zoomEnabled {
                minimumZoomScale = CanvasView.defaultMinimumZoomScale
                maximumZoomScale = CanvasView.defaultMaximumZoomScale
            } else {
                minimumZoomScale = zoomScale
                maximumZoomScale = zoomScale
            }
        }
    }
    public var zoomEnabledOverride = false
    public var fingerAction = FingerAction.ignore
    public var twoFingerUndoEnabled = true
    public var applePencilUsed = false
    public var applePencilCanEyedrop = true
    public var shouldFillPaths = false
    public var userWillStartZooming = false
    public var spriteZoomScale: CGFloat = 2.0 // Sprite view is 2x scale of checkerboard view
    public var dragStartPoint: CGPoint?
    public var spriteCopy: UIImage! {
        didSet {
            contentSize = spriteCopy.size
        }
    }
    public var shouldStartZooming: Bool {
        (zoomEnabled && drawnPointsAreCancelable()) || zoomEnabledOverride
    }

    public func setupView() {
        delegate = self
        panGestureRecognizer.minimumNumberOfTouches = 2
        delaysContentTouches = false
        minimumZoomScale = CanvasView.defaultMinimumZoomScale
        maximumZoomScale = CanvasView.defaultMaximumZoomScale
        zoomScale = 4.0
        scrollsToTop = false
        
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        addInteraction(pencilInteraction)
        
        checkerboardView = UIImageView(frame: bounds)
        checkerboardView.layer.magnificationFilter = .nearest
        checkerboardView.translatesAutoresizingMaskIntoConstraints = false
        
        spriteView = UIImageView(frame: bounds)
        spriteView.layer.magnificationFilter = .nearest
        spriteView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(checkerboardView)
        checkerboardView.addSubview(spriteView)
        spriteView.addSubview(hoverView)
        spriteView.addSubview(symmetricHoverView)
        
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
        let undoAlternative = UITapGestureRecognizer(target: self, action: #selector(doUndoForAltGesture))
        undoAlternative.numberOfTouchesRequired = 2
        let redoAlternative = UITapGestureRecognizer(target: self, action: #selector(doRedoForAltGesture))
        redoAlternative.numberOfTouchesRequired = 3
        let hover = UIHoverGestureRecognizer(target: self, action: #selector(mouseDidMove(with:)))
        addGestureRecognizer(undo)
        addGestureRecognizer(redo)
        addGestureRecognizer(redoAlternative)
        addGestureRecognizer(undoAlternative)
        addGestureRecognizer(hover)
        
        documentController.refresh()
        makeCheckerboard()
		isUserInteractionEnabled = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.zoomToFit()
        }
	}
    
    public func makeCheckerboard() {
        let checkers = CIFilter.checkerboardGenerator()
        checkers.color0 = CIColor(color: UIColor.systemGray5)
        checkers.color1 = CIColor(color: UIColor.systemGray6)
        checkers.width = 1.0
        guard let image = checkers.outputImage, let documentContext = documentController.context else { return }
        
        let minimumCheckerboardPixelSize: CGFloat = 4.0
        let checkerboardPixelSize = bounds.width / (CGFloat(documentContext.width) * spriteZoomScale)
        if checkerboardPixelSize < minimumCheckerboardPixelSize {
            spriteZoomScale = 1.0
        }
        
        let width = CGFloat(documentContext.width) * spriteZoomScale
        let height = CGFloat(documentContext.height) * spriteZoomScale
        let rect = CGRect(origin: .zero, size: CGSize(width: width, height: height))
        let ciContext = CIContext(options: nil)
        guard let cgImage = ciContext.createCGImage(image, from: rect) else { return }
        checkerboardView.image = UIImage(cgImage: cgImage)
    }
    
    override public func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            makeCheckerboard()
        }
    }
    
    public func toolSizeChanged(size: PixelSize) {
        toolSizeCopy = size
        hoverView.bounds.size = CGSize(width: CGFloat(size.width) * spriteZoomScale + CanvasView.hoverViewBorderWidth/2, height: CGFloat(size.height) * spriteZoomScale + CanvasView.hoverViewBorderWidth/2)
        symmetricHoverView.bounds.size = hoverView.bounds.size
    }
    
    public func drawnPointsAreCancelable() -> Bool {
        guard !documentController.currentOperationPixelPoints.isEmpty else { return false }
        let toolSize: PixelSize
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
            toolSize = PixelSize(width: 1, height: 1)
        }
        let maximumCancelableDrawnPoints = 8 * (toolSize.width * toolSize.height)
        return (documentController.currentOperationPixelPoints.count <= maximumCancelableDrawnPoints)
    }
    
    public func zoomToFit(size: CGSize? = nil) {
        let viewSize = size ?? bounds.size
        
        let viewRatio = viewSize.width / viewSize.height
        let spriteSize = CGSize(width: documentController.context.width, height: documentController.context.height)
        let spriteRatio = spriteSize.width / spriteSize.height
        
        var scale: CGFloat = 1/spriteZoomScale
        if viewRatio <= spriteRatio {
            scale *= viewSize.width / spriteSize.width
        } else {
            scale *= viewSize.height / spriteSize.height
        }
        zoomEnabledOverride = true
        if scale < self.minimumZoomScale || self.maximumZoomScale < scale {
            self.minimumZoomScale = scale
            self.maximumZoomScale = scale
        }
        self.setZoomScale(scale, animated: false)
        self.checkerboardView.frame.origin = .zero
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
            self.zoomEnabledOverride = false
        })
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
        if documentController.horizontalSymmetry {
            if symmetryLineLayer == nil {
                symmetryLineLayer = CALayer()
                symmetryLineLayer?.frame = CGRect(x: (CGFloat(documentWidth) * spriteZoomScale/2.0) - 0.1, y: 0, width: 0.2, height: CGFloat(documentHeight) * spriteZoomScale)
                symmetryLineLayer?.borderWidth = 0.2
                symmetryLineLayer?.borderColor = tintColor.cgColor
                spriteView.layer.addSublayer(symmetryLineLayer!)
            }
        } else {
            symmetryLineLayer?.removeFromSuperlayer()
            symmetryLineLayer = nil
        }
    }
    
    public func makePixelPoint(touchLocation: CGPoint, toolSize: PixelSize) -> PixelPoint {
        let xOffset = CGFloat(toolSize.width-1) / 2
        let yOffset = CGFloat(toolSize.height-1) / 2
        // Returns the top left pixel of the rect of pixels.
        return PixelPoint(x: Int(floor((touchLocation.x - xOffset) / spriteZoomScale)), y: Int(floor((touchLocation.y - yOffset) / spriteZoomScale)))
    }
    
    @objc public func doUndo() {
        if documentController.undoManager?.groupingLevel == 1 {
            documentController.undoManager?.endUndoGrouping()
            documentController.undoManager?.undo()
            documentController.refresh()
        }
        documentController.undo()
    }
    @objc public func doRedo() {
        if documentController.undoManager?.groupingLevel == 1 {
            documentController.undoManager?.endUndoGrouping()
//            documentController.undoManager?.redo()
//            documentController.refresh()
        }
        documentController.redo()
    }
    @objc public func doUndoForAltGesture() {
        if twoFingerUndoEnabled, drawnPointsAreCancelable() {
            doUndo()
        }
    }
    @objc public func doRedoForAltGesture() {
        if twoFingerUndoEnabled, drawnPointsAreCancelable() {
            doRedo()
        }
    }
    
    // MARK: - Touches & Hover
    
    @objc public func mouseDidMove(with recognizer: UIHoverGestureRecognizer) {
        switch recognizer.state {
        case .began, .changed:
            let touchLocation = recognizer.location(in: spriteView)
            let point = makePixelPoint(touchLocation: touchLocation, toolSize: toolSizeCopy)
            updateHoverLocation(at: point)
        case .ended, .cancelled:
            hoverView.isHidden = true
            symmetricHoverView.isHidden = true
        default:
            break
        }
    }
    
    func updateHoverLocation(at point: PixelPoint) {
        guard 0 <= point.x, 0 <= point.y, point.x < documentController.context.width, point.y < documentController.context.height else {
            hoverView.isHidden = true
            symmetricHoverView.isHidden = true
            documentController.hover(at: nil)
            return
        }
        hoverView.frame.origin = CGPoint(x: CGFloat(point.x) * spriteZoomScale - CanvasView.hoverViewBorderWidth/2, y: CGFloat(point.y) * spriteZoomScale - CanvasView.hoverViewBorderWidth/2)
        hoverView.isHidden = false
        if documentController.horizontalSymmetry {
            let symmetricPoint = CGPoint(x: CGFloat(documentController.context.width - point.x - toolSizeCopy.width) * spriteZoomScale - CanvasView.hoverViewBorderWidth/2, y: hoverView.frame.origin.y)
            symmetricHoverView.frame.origin = symmetricPoint
            symmetricHoverView.isHidden = false
        }
        documentController.hover(at: point)
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
            let point = makePixelPoint(touchLocation: touches.first!.location(in: spriteView), toolSize: PixelSize(width: 1, height: 1))
            documentController.eyedrop(at: point)
        default:
            if let coalesced = event?.coalescedTouches(for: touches.first!) {
                addSamples(for: coalesced)
            }
            switch tool {
            case is PencilTool:
                if shouldFillPaths {
                    documentController.fillPath()
                }
                documentController.currentOperationPixelPoints.removeAll()
                documentController.undoManager?.endUndoGrouping()
            case is MoveTool: //or is EyedroperTool
                break
            case is FillTool:
                let point = makePixelPoint(touchLocation: touches.first!.location(in: spriteView), toolSize: PixelSize(width: 1, height: 1))
                documentController.fill(at: point)
                documentController.currentOperationPixelPoints.removeAll()
                documentController.undoManager?.endUndoGrouping()
            default:
                documentController.currentOperationPixelPoints.removeAll()
                documentController.undoManager?.endUndoGrouping()
            }
            
            switch touches.first!.type {
            case .pencil:
                break
            default:
                if applePencilUsed, fingerAction == .move {
                    tool = documentController.previousTool
                }
            }
            hoverView.isHidden = true
            symmetricHoverView.isHidden = true
            documentController.hover(at: nil)
        }
        canvasDelegate?.canvasViewDidEndUsingTool(self)
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard validateTouchesForCurrentTool(touches) else { return }
        let drawnPointsAreCancelableBool = drawnPointsAreCancelable()
        
        documentController.currentOperationPixelPoints.removeAll()
        if documentController.undoManager?.groupingLevel == 1 {
            documentController.undoManager?.endUndoGrouping()
        }
        
        hoverView.isHidden = true
        symmetricHoverView.isHidden = true
        documentController.hover(at: nil)
        
        canvasDelegate?.canvasViewDidEndUsingTool(self)
        
        if drawnPointsAreCancelableBool {
            documentController.undoManager?.undo()
            documentController.refresh()
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
    
    public func addSamples(for touches: [UITouch]) {
        switch tool {
        case is PencilTool, is EraserTool, is MoveTool, is HighlightTool, is ShadowTool:
            for touch in touches {
                let touchLocation = touch.location(in: spriteView)
                switch tool {
                case let pencil as PencilTool:
                    let point = makePixelPoint(touchLocation: touchLocation, toolSize: pencil.size)
                    documentController.paint(colorComponents: documentController.toolColorComponents, at: point, size: pencil.size, doneByUser: true)
                case let eraser as EraserTool:
                    let point = makePixelPoint(touchLocation: touchLocation, toolSize: eraser.size)
                    documentController.paint(colorComponents: .clear, at: point, size: eraser.size, doneByUser: true)
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
            
            let touchLocation = touches.first!.location(in: spriteView)
            let point = makePixelPoint(touchLocation: touchLocation, toolSize: toolSizeCopy)
            updateHoverLocation(at: point)
        default:
            break
        }
    }
    
    public func pencilInteractionDidTap(_ interaction: UIPencilInteraction) {
        switch UIPencilInteraction.preferredTapAction {
        case .switchEraser:
            documentController.tool = documentController.eraserTool
        case .switchPrevious:
            documentController.tool = documentController.previousTool
        default:
            break
        }
    }
    
    // MARK: - Zooming
    
    public func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return checkerboardView
    }
    
    public func scrollViewWillBeginZooming(_ scrollView: UIScrollView, with view: UIView?) {
        userWillStartZooming = shouldStartZooming && !zoomEnabledOverride
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
        
        userWillStartZooming = false
    }
    
}
