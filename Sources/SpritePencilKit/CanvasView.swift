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
    public var toolSizeCopy = PixelSize(width: 1, height: 1)
    override public var bounds: CGRect {
        didSet {
            if documentController?.context != nil, !userWillStartZooming {
                zoomToFit()
            }
        }
    }
    
    // Grids
    public var pixelGridEnabled = false
    public var tileGridEnabled = false
    public var tileGridLayer: CAShapeLayer?
    public var pixelGridLayer: CAShapeLayer?
    public var verticalSymmetryLineLayer: CALayer?
    public var horizontalSymmetryLineLayer: CALayer?
    
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
    public var spriteZoomScale: CGFloat = 2.0 { // Sprite view is normally 2x scale of checkerboard view
        didSet {
            toolSizeChanged(size: toolSizeCopy)
        }
    }
    public var dragStartPoint: CGPoint?
    public var spriteCopy: UIImage! {
        didSet {
            contentSize = spriteCopy.size
        }
    }
    public var shouldStartZooming: Bool {
        (zoomEnabled && drawnPointsAreCancelable()) || zoomEnabledOverride
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        documentController = DocumentController(canvasView: self)
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        documentController = DocumentController(canvasView: self)
    }
    
    public func setupView() {
        delegate = self
        panGestureRecognizer.minimumNumberOfTouches = 2
        delaysContentTouches = false
        minimumZoomScale = CanvasView.defaultMinimumZoomScale
        maximumZoomScale = CanvasView.defaultMaximumZoomScale
        zoomScale = 4.0
        scrollsToTop = false
        showsVerticalScrollIndicator = false
        showsHorizontalScrollIndicator = false
        
        let pencilInteraction = UIPencilInteraction()
        pencilInteraction.delegate = self
        addInteraction(pencilInteraction)
        
        checkerboardView = UIImageView()
        checkerboardView.layer.magnificationFilter = .nearest
        checkerboardView.translatesAutoresizingMaskIntoConstraints = false
        
        spriteView = UIImageView()
        spriteView.layer.magnificationFilter = .nearest
        spriteView.translatesAutoresizingMaskIntoConstraints = false
        
        addSubview(checkerboardView)
        checkerboardView.addSubview(spriteView)
        spriteView.addSubview(hoverView)
        
        NSLayoutConstraint.activate([
            spriteView.topAnchor.constraint(equalTo: checkerboardView.topAnchor),
            spriteView.bottomAnchor.constraint(equalTo: checkerboardView.bottomAnchor),
            spriteView.leadingAnchor.constraint(equalTo: checkerboardView.leadingAnchor),
            spriteView.trailingAnchor.constraint(equalTo: checkerboardView.trailingAnchor)
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
        let checkerboardPixelSize = safeAreaLayoutGuide.layoutFrame.width / (CGFloat(documentContext.width) * spriteZoomScale)
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
    }
    
    public func drawnPointsAreCancelable() -> Bool {
//        guard !documentController.currentOperationPixelPoints.isEmpty else { return false }
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
    
    public func zoomToFit() {
        let viewSize = safeAreaLayoutGuide.layoutFrame.size
        
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
        if documentController.verticalSymmetry {
            if verticalSymmetryLineLayer == nil {
                verticalSymmetryLineLayer = CALayer()
                verticalSymmetryLineLayer?.frame = CGRect(x: 0, y: (CGFloat(documentHeight) * spriteZoomScale/2.0) - 0.1, width: CGFloat(documentWidth) * spriteZoomScale, height: 0.2)
                verticalSymmetryLineLayer?.borderWidth = 0.2
                verticalSymmetryLineLayer?.borderColor = tintColor.cgColor
                spriteView.layer.addSublayer(verticalSymmetryLineLayer!)
            }
        } else {
            verticalSymmetryLineLayer?.removeFromSuperlayer()
            verticalSymmetryLineLayer = nil
        }
        if documentController.horizontalSymmetry {
            if horizontalSymmetryLineLayer == nil {
                horizontalSymmetryLineLayer = CALayer()
                horizontalSymmetryLineLayer?.frame = CGRect(x: (CGFloat(documentWidth) * spriteZoomScale/2.0) - 0.1, y: 0, width: 0.2, height: CGFloat(documentHeight) * spriteZoomScale)
                horizontalSymmetryLineLayer?.borderWidth = 0.2
                horizontalSymmetryLineLayer?.borderColor = tintColor.cgColor
                spriteView.layer.addSublayer(horizontalSymmetryLineLayer!)
            }
        } else {
            horizontalSymmetryLineLayer?.removeFromSuperlayer()
            horizontalSymmetryLineLayer = nil
        }
    }
    
    public func makePixelPoint(touchLocation: CGPoint, toolSize: PixelSize) -> PixelPoint {
        let xOffset = CGFloat(toolSize.width-1) / 2
        let yOffset = CGFloat(toolSize.height-1) / 2
        // Returns the top left pixel of the rect of pixels.
        return PixelPoint(x: Int(floor((touchLocation.x / spriteZoomScale) - xOffset)), y: Int(floor((touchLocation.y / spriteZoomScale) - yOffset)))
    }
    
    @objc public func doUndo() {
        if 0 < documentController.undoManager?.groupingLevel ?? 0 {
            documentController.undoManager?.endUndoGrouping()
            documentController.undoManager?.undo()
        }
        documentController.undo()
    }
    @objc public func doRedo() {
        if 0 < documentController.undoManager?.groupingLevel ?? 0 {
            documentController.undoManager?.endUndoGrouping()
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
        default:
            break
        }
    }
    
    func updateHoverLocation(at point: PixelPoint) {
        guard 0 <= point.x, 0 <= point.y, point.x < documentController.context.width, point.y < documentController.context.height else {
            hoverView.isHidden = true
            documentController.hoverPoint = nil
            return
        }
        hoverView.frame.origin = CGPoint(x: CGFloat(point.x) * spriteZoomScale - CanvasView.hoverViewBorderWidth/2, y: CGFloat(point.y) * spriteZoomScale - CanvasView.hoverViewBorderWidth/2)
        hoverView.isHidden = false
        documentController.hoverPoint = point
    }
    
    override public func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        switch touch.type {
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
        case is EyedroperTool, is FillTool:
            break
        case is MoveTool:
            spriteCopy = UIImage(cgImage: documentController.context.makeImage()!)
            dragStartPoint = touch.location(in: spriteView)
        default:
            let touchLocation = touch.location(in: spriteView)
            let point = makePixelPoint(touchLocation: touchLocation, toolSize: PixelSize(width: 1, height: 1))
            documentController.currentOperationFirstPixelPoint = point
            documentController.undoManager?.beginUndoGrouping()
        }
        canvasDelegate?.canvasViewDidBeginUsingTool(self)
        if let coalesced = event?.coalescedTouches(for: touch) {
            addSamples(for: coalesced)
        }
    }
    
    override public func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, validateTouchesForCurrentTool(touches) else { return }
        if let coalesced = event?.coalescedTouches(for: touch) {
            addSamples(for: coalesced)
        }
    }
    
    override public func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, validateTouchesForCurrentTool(touches) else { return }
        
        switch tool {
        case is EyedroperTool:
            let location = touch.location(in: spriteView)
            let point = makePixelPoint(touchLocation: location, toolSize: PixelSize(width: 1, height: 1))
            documentController.eyedrop(at: point)
        default:
            if let coalesced = event?.coalescedTouches(for: touch) {
                addSamples(for: coalesced)
            }
            let touchLocation = touch.location(in: spriteView)
            let point = makePixelPoint(touchLocation: touchLocation, toolSize: PixelSize(width: 1, height: 1))
            documentController.currentOperationLastPixelPoint = point
            
            switch tool {
            case is PencilTool:
                if shouldFillPaths {
                    documentController.fillDrawnPath()
                }
//                let undoColors = documentController.currentDrawUndoColors
//                documentController.undoManager?.registerUndo(withTarget: documentController, handler: { (target) in
//                    for undoColor in undoColors {
//                        target.basicPaint(colorComponents: undoColor.colorComponents, at: undoColor.pixelPoint)
//                    }
//                })
                documentController.currentOperationPixelPoints.removeAll()
                
                if 0 < documentController.undoManager?.groupingLevel ?? 0 {
                    documentController.undoManager?.endUndoGrouping()
                }
            case is MoveTool:
                let location = touch.location(in: spriteView)
                moveViaTouchLocation(location)
                documentController.undoManager?.registerUndo(withTarget: documentController) { (target) in
                    target.move(deltaPoint: .zero)
                }
                documentController.editorDelegate?.refreshUndo()
            case is FillTool:
                let location = touch.location(in: spriteView)
                let point = makePixelPoint(touchLocation: location, toolSize: PixelSize(width: 1, height: 1))
                documentController.undoManager?.beginUndoGrouping()
                documentController.fill(at: point)
                documentController.currentOperationPixelPoints.removeAll()
                if 0 < documentController.undoManager?.groupingLevel ?? 0 {
                    documentController.undoManager?.endUndoGrouping()
                }
                documentController.refresh()
            default:
                documentController.currentOperationPixelPoints.removeAll()
                if 0 < documentController.undoManager?.groupingLevel ?? 0 {
                    documentController.undoManager?.endUndoGrouping()
                }
            }
            
            switch touch.type {
            case .pencil:
                break
            default:
                if applePencilUsed, fingerAction == .move {
                    tool = documentController.previousTool
                }
            }
            hoverView.isHidden = true
            documentController.hoverPoint = nil
            documentController.currentOperationFirstPixelPoint = nil
            documentController.currentOperationLastPixelPoint = nil
        }
        canvasDelegate?.canvasViewDidEndUsingTool(self)
    }
    
    override public func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard validateTouchesForCurrentTool(touches) else { return }
        let shouldRemoveDrawnPoints = drawnPointsAreCancelable() && !documentController.currentOperationPixelPoints.isEmpty
        
        documentController.currentOperationPixelPoints.removeAll()
        if 0 < documentController.undoManager?.groupingLevel ?? 0 {
            documentController.undoManager?.endUndoGrouping()
        }
        
        hoverView.isHidden = true
        documentController.hoverPoint = nil
        
        canvasDelegate?.canvasViewDidEndUsingTool(self)
        
        if shouldRemoveDrawnPoints {
            documentController.undoManager?.undo()
            documentController.refresh()
        }
    }
    
    public func validateTouchesForCurrentTool(_ touches: Set<UITouch>) -> Bool {
        switch touches.first?.type {
        case .pencil?:
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
                    documentController.brushPaint(colorComponents: documentController.toolColorComponents, at: point, size: pencil.size)
                case let eraser as EraserTool:
                    let point = makePixelPoint(touchLocation: touchLocation, toolSize: eraser.size)
                    documentController.brushPaint(colorComponents: .clear, at: point, size: eraser.size)
                case is MoveTool:
                    moveViaTouchLocation(touchLocation)
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
            
            if !(tool is MoveTool), let touch = touches.first {
                let touchLocation = touch.location(in: spriteView)
                let point = makePixelPoint(touchLocation: touchLocation, toolSize: toolSizeCopy)
                updateHoverLocation(at: point)
            }
        default:
            break
        }
    }
    
    func moveViaTouchLocation(_ touchLocation: CGPoint) {
        guard let dragStartPoint = dragStartPoint else { return }
        let dx = CGFloat((touchLocation.x - dragStartPoint.x) / spriteZoomScale).rounded()
        let dy = CGFloat((touchLocation.y - dragStartPoint.y) / spriteZoomScale).rounded()
        documentController.move(deltaPoint: CGPoint(x: dx, y: dy))
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
    
    public func scrollViewDidZoom(_ scrollView: UIScrollView) { // Called many times while zooming
        
        func centerContent() {
            if contentSize.width < safeAreaLayoutGuide.layoutFrame.width {
                contentOffset.x = ((contentSize.width - safeAreaLayoutGuide.layoutFrame.width) / 2) - safeAreaInsets.left + safeAreaInsets.right
            }
            if contentSize.height < safeAreaLayoutGuide.layoutFrame.height {
                contentOffset.y = ((contentSize.height - safeAreaLayoutGuide.layoutFrame.height) / 2) - safeAreaInsets.top + safeAreaInsets.bottom
            }
            
            var h: CGFloat = 0.0
            var v: CGFloat = 0.0
            if contentSize.width < bounds.width {
                h = (safeAreaLayoutGuide.layoutFrame.width - contentSize.width) / 2.0
            }
            if contentSize.height < bounds.height {
                v = (safeAreaLayoutGuide.layoutFrame.height - contentSize.height) / 2.0
            }
            contentInset = UIEdgeInsets(top: v + safeAreaInsets.top, left: h + safeAreaInsets.left, bottom: v + safeAreaInsets.bottom, right: h + safeAreaInsets.right)
        }
        
        centerContent()
    }
    
    public func scrollViewDidEndZooming(_ scrollView: UIScrollView, with view: UIView?, atScale scale: CGFloat) {
        guard let view = view else { return }
        // Snap to 100%
        let thresholdToSnap: CGFloat = 0.12
        let zoomScaleDistanceRange = 1.0-thresholdToSnap...1.0+thresholdToSnap
        
        let contentWidthFraction = safeAreaLayoutGuide.layoutFrame.width / (view.safeAreaLayoutGuide.layoutFrame.width * zoomScale)
        if zoomScaleDistanceRange.contains(contentWidthFraction) {
            let zoom = (safeAreaLayoutGuide.layoutFrame.width / view.safeAreaLayoutGuide.layoutFrame.width)
            setZoomScale(zoom, animated: true)
            return
        }
        
        let contentHeightFraction = safeAreaLayoutGuide.layoutFrame.height / (view.safeAreaLayoutGuide.layoutFrame.height * zoomScale)
        if zoomScaleDistanceRange.contains(contentHeightFraction) {
            let zoom = (safeAreaLayoutGuide.layoutFrame.height / view.safeAreaLayoutGuide.layoutFrame.height)
            setZoomScale(zoom, animated: true)
            return
        }
        
        Timer.scheduledTimer(withTimeInterval: 0.1, repeats: false, block: { _ in
            self.userWillStartZooming = false
        })
    }
    
}
