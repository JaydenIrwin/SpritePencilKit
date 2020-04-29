//
//  DocumentController.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2018-10-15.
//  Copyright © 2018 Jayden Irwin. All rights reserved.
//

import UIKit
import CoreImage.CIFilterBuiltins

public protocol ToolDelegate: class {
    func selectTool(atIndex index: Int, animated: Bool)
}
public protocol EditorDelegate: class {
    func hover(at point: PixelPoint?)
    func eyedropColor(colorComponents components: ColorComponents, at point: PixelPoint)
    func refreshUndo()
}
public protocol RecentColorDelegate: class {
    func usedColor(components: ColorComponents)
}
public protocol PaintParticlesDelegate: class {
    func painted(context: CGContext, color: UIColor?, at point: PixelPoint)
}

public class DocumentController {
    
    public enum RotateDirection {
        case left, right
    }
    
    public var context: CGContext! {
        didSet {
            let widthMultiple = ContextDataManager.contextWidthMultiple
            let rowOffset = ((context.width + widthMultiple - 1) / widthMultiple) * widthMultiple // Round up to multiple of 8
            let dataPointer: UnsafeMutablePointer<UInt8> = {
                let capacity = self.context.width * context.height
                let pointer = self.context.data!.bindMemory(to: UInt8.self, capacity: capacity)
                return pointer
            }()
            contextDataManager = ContextDataManager(rowOffset: rowOffset, dataPointer: dataPointer)
        }
    }
    public var palette: Palette?
    public var toolColor = UIColor.black
    public var currentOperationPixelPoints = [PixelPoint]()
    public var fillFromColor: UIColor?
    public var fillFromColorComponents: ColorComponents?
    public var contextDataManager: ContextDataManager!
    public var horizontalSymmetry = false
    
    // Tools
    public var pencilTool = PencilTool(width: 1)
    public var eraserTool = EraserTool(width: 1)
    public var eyedroperTool = EyedroperTool()
    public var fillTool = FillTool()
    public var moveTool = MoveTool()
    public var highlightTool = HighlightTool(width: 1)
    public var shadowTool = ShadowTool(width: 1)
    public var previousTool: Tool = EraserTool(width: 1)
    public var tool: Tool = PencilTool(width: 1) {
        didSet {
            if type(of: tool) != type(of: oldValue) {
                UISelectionFeedbackGenerator().selectionChanged()
                previousTool = oldValue
            }
            let index: Int
            switch tool {
            case let pencil as PencilTool:
                index = 0
                canvasView.toolSizeChanged(size: pencil.size)
            case let eraser as EraserTool:
                index = 1
                canvasView.toolSizeChanged(size: eraser.size)
            case is EyedroperTool:
                index = 2
                canvasView.toolSizeChanged(size: CGSize(width: 1, height: 1))
            case is FillTool:
                index = 3
                canvasView.toolSizeChanged(size: CGSize(width: 1, height: 1))
            case is MoveTool:
                index = 4
                canvasView.toolSizeChanged(size: CGSize(width: 1, height: 1))
            case let highlight as HighlightTool:
                index = 5
                canvasView.toolSizeChanged(size: highlight.size)
            case let shadow as ShadowTool:
                index = 6
                canvasView.toolSizeChanged(size: shadow.size)
            default:
                index = 0
                canvasView.toolSizeChanged(size: CGSize(width: 1, height: 1))
            }
            let animated = type(of: tool) != type(of: oldValue)
            toolDelegate?.selectTool(atIndex: index, animated: animated)
        }
    }
    
    // Delegates
    weak public var undoManager: UndoManager?
    weak public var recentColorDelegate: RecentColorDelegate?
    weak public var toolDelegate: ToolDelegate?
    weak public var editorDelegate: EditorDelegate?
    weak public var paintParticlesDelegate: PaintParticlesDelegate?
    weak public var canvasView: CanvasView!
    
    public init(undoManager: UndoManager?, canvasView: CanvasView) {
        self.undoManager = undoManager
        self.canvasView = canvasView
    }
    
    public func refresh() {
        canvasView.canvasDelegate?.canvasViewDrawingDidChange(canvasView)
        let image = UIImage(cgImage: context.makeImage()!)
        canvasView.spriteView.image = image
        canvasView.canvasDelegate?.canvasViewDidFinishRendering(canvasView)
        editorDelegate?.refreshUndo()
    }
    
    public func undo() {
        undoManager?.undo()
        currentOperationPixelPoints.removeAll()
        refresh()
    }
    public func redo() {
        undoManager?.redo()
        currentOperationPixelPoints.removeAll()
        refresh()
    }
    
    public func hover(at point: PixelPoint?) {
        editorDelegate?.hover(at: point)
    }
    
    public func paint(color: UIColor?, at point: PixelPoint, size: CGSize, byUser: Bool) {
        
        func registerUndo(at brushPoint: PixelPoint) {
            let undoColorComponents = getColorComponents(at: brushPoint)
            let isClear = (undoColorComponents.alpha == 0)
            let undoColor = isClear ? nil : UIColor(components: undoColorComponents)
            undoManager?.registerUndo(withTarget: self, handler: { (target) in
                target.paint(color: undoColor, at: brushPoint, size: CGSize(width: 1, height: 1), byUser: false)
            })
            currentOperationPixelPoints.append(brushPoint)
        }
        
        let pointInBounds: PixelPoint
        let sizeInBounds: CGSize
        if byUser {
            if size == CGSize(width: 1, height: 1) {
                guard point.x < context.width, point.y < context.height, 0 <= point.x, 0 <= point.y else { return }
                pointInBounds = point
                sizeInBounds = size
            } else {
                guard point.x < context.width, point.y < context.height, 0 <= point.x + Int(size.width)-1, 0 <= point.y + Int(size.height)-1 else { return }
                pointInBounds = PixelPoint(x: max(0, point.x), y: max(0, point.y))
                let newWidth = min(size.width - CGFloat(pointInBounds.x - point.x), CGFloat(context.width - pointInBounds.x))
                let newHeight = min(size.height - CGFloat(pointInBounds.y - point.y), CGFloat(context.height - pointInBounds.y))
                sizeInBounds = CGSize(width: newWidth, height: newHeight)
            }
        } else {
            pointInBounds = point
            sizeInBounds = size
        }
        let symmetricPointInBounds = PixelPoint(x: context.width - pointInBounds.x - Int(sizeInBounds.width), y: pointInBounds.y)
        
        for xOffset in 0..<Int(sizeInBounds.width) {
            for yOffset in 0..<Int(sizeInBounds.height) {
                let brushPoint = PixelPoint(x: pointInBounds.x + xOffset, y: pointInBounds.y + yOffset)
                if byUser {
                    registerUndo(at: brushPoint)
                    if horizontalSymmetry {
                        let brushPoint = PixelPoint(x: symmetricPointInBounds.x + xOffset, y: symmetricPointInBounds.y + yOffset)
                        registerUndo(at: brushPoint)
                    }
                }
            }
        }
        
        let fillRect = CGRect(origin: CGPoint(x: pointInBounds.x, y: pointInBounds.y), size: sizeInBounds)
        if let color = color {
            color.setFill()
            context.fill(fillRect)
            if byUser {
                var red: CGFloat = 0.0
                var green: CGFloat = 0.0
                var blue: CGFloat = 0.0
                var alpha: CGFloat = 0.0
                color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
                let components = ColorComponents(red: UInt8(red*255), green: UInt8(green*255), blue: UInt8(blue*255), alpha: 255)
                recentColorDelegate?.usedColor(components: components)
                
                if horizontalSymmetry {
                    let symmetricRect = CGRect(origin: CGPoint(x: symmetricPointInBounds.x, y: symmetricPointInBounds.y), size: sizeInBounds)
                    context.fill(symmetricRect)
                }
            }
        } else {
            context.clear(fillRect)
            if byUser, horizontalSymmetry {
                let symmetricRect = CGRect(origin: CGPoint(x: symmetricPointInBounds.x, y: symmetricPointInBounds.y), size: sizeInBounds)
                context.clear(symmetricRect)
            }
        }
        paintParticlesDelegate?.painted(context: context, color: color, at: point)
    }
    
    public func fillPath() {
        guard 7 <= currentOperationPixelPoints.count else { return }
        let firstPixelPoint = currentOperationPixelPoints.removeFirst()
        guard abs(firstPixelPoint.x - currentOperationPixelPoints.last!.x) <= 1, abs(firstPixelPoint.y - currentOperationPixelPoints.last!.y) <= 1 else { return }
        let image = context.makeImage()!
        context.beginPath()
        context.move(to: CGPoint(x: CGFloat(firstPixelPoint.x) + 0.5, y: CGFloat(firstPixelPoint.y) + 0.5))
        for pixelPoint in currentOperationPixelPoints {
            context.addLine(to: CGPoint(x: CGFloat(pixelPoint.x) + 0.5, y: CGFloat(pixelPoint.y) + 0.5))
        }
        context.closePath()
        context.fillPath()
        undoManager?.registerUndo(withTarget: self, handler: { (target) in
            target.context.clear()
            self.context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: self.context.width, height: self.context.height)))
        })
    }
    
    public func eyedrop(at point: PixelPoint) {
        let components = getColorComponents(at: point)
        guard components.alpha == 255 else { return }
        
        editorDelegate?.eyedropColor(colorComponents: components, at: point)
    }
    
    public func getColorComponents(at point: PixelPoint) -> ColorComponents {
        let cdp = contextDataManager.dataPointer
        let offset = contextDataManager.dataOffset(for: point)
        return ColorComponents(red: cdp[offset+2], green: cdp[offset+1], blue: cdp[offset], alpha: cdp[offset+3])
    }
    
    public func move(dx: CGFloat, dy: CGFloat) {
        context.clear()
        let newOrigin = CGPoint(x: dx, y: dy)
        canvasView.spriteCopy.draw(at: newOrigin)
        
        undoManager?.registerUndo(withTarget: self) { (target) in
            target.move(dx: -dx, dy: -dy)
        }
    }
    
    public func highlight(at point: PixelPoint, size: CGSize) {
        for xOffset in 0..<Int(size.width) {
            for yOffset in 0..<Int(size.height) {
                let brushPoint = PixelPoint(x: point.x + xOffset, y: point.y + yOffset)
                guard !currentOperationPixelPoints.contains(brushPoint) else { continue }
                let highlightColor = (palette ?? Palette.defaultPalette).highlight(forColorComponents: getColorComponents(at: brushPoint))
                paint(color: UIColor(components: highlightColor), at: brushPoint, size: CGSize(width: 1, height: 1), byUser: true)
            }
        }
    }
    
    public func shadow(at point: PixelPoint, size: CGSize) {
        for xOffset in 0..<Int(size.width) {
            for yOffset in 0..<Int(size.height) {
                let brushPoint = PixelPoint(x: point.x + xOffset, y: point.y + yOffset)
                guard !currentOperationPixelPoints.contains(brushPoint) else { continue }
                let shadowColor = (palette ?? Palette.defaultPalette).shadow(forColorComponents: getColorComponents(at: brushPoint))
                paint(color: UIColor(components: shadowColor), at: brushPoint, size: CGSize(width: 1, height: 1), byUser: true)
            }
        }
    }
    
    public func fill(at startPoint: PixelPoint) {
        fillFromColorComponents = getColorComponents(at: startPoint)
        let fillFrom = UIColor(components: fillFromColorComponents!)
        fillFromColor = fillFrom
        guard fillFromColor != toolColor else { return }
        
        toolColor.setFill()
        undoManager?.registerUndo(withTarget: self, handler: { (target) in
            target.toolColor.setFill()
            target.refresh()
            target.currentOperationPixelPoints.removeAll()
        })
        
        let toolSize = CGSize(width: 1, height: 1)
        let maxCheckedPixels = 2048
        var stack = [startPoint]
        var checkedPixels = 0
        while 0 < stack.count && checkedPixels < maxCheckedPixels {
            let pixelPoint = stack.popLast()!
            if currentOperationPixelPoints.contains(pixelPoint) || (pixelPoint.y < 0 || pixelPoint.y > context.height - 1 || pixelPoint.x < 0 || pixelPoint.x > context.width - 1) {
                continue
            }
            guard getColorComponents(at: pixelPoint) == fillFromColorComponents else { continue }

            let point = CGPoint(x: pixelPoint.x, y: pixelPoint.y)
            UIRectFill(CGRect(origin: point, size: toolSize))
            undoManager?.registerUndo(withTarget: self, handler: { (target) in
                UIRectFill(CGRect(origin: point, size: toolSize))
            })
            
            currentOperationPixelPoints.append(pixelPoint)
            
            stack.append(PixelPoint(x: pixelPoint.x+1, y: pixelPoint.y))
            stack.append(PixelPoint(x: pixelPoint.x-1, y: pixelPoint.y))
            stack.append(PixelPoint(x: pixelPoint.x, y: pixelPoint.y+1))
            stack.append(PixelPoint(x: pixelPoint.x, y: pixelPoint.y-1))
            
            checkedPixels += 1
        }
        
        undoManager?.registerUndo(withTarget: self, handler: { (target) in
            fillFrom.setFill()
        })
        refresh()
    }
    
    public func flip(vertically: Bool) {
        let image = context.makeImage()!
        context.clear()
        context.saveGState()
        let number: CGFloat = vertically ? 1.0 : -1.0
        // iOS 13 BUG?
        // The bug is that the context will flip vertically every time, even when you dont ask it to.
//        let tx = vertically ? 0.0 : CGFloat(context.width)
//        let ty = vertically ? CGFloat(context.height) : 0.0
//        let flipVertical = CGAffineTransform(a: number, b: 0.0, c: 0.0, d: -number, tx: tx, ty: ty)
//        context.concatenate(flipVertical)
        
        // FIX (1/2)
        if !vertically {
            let tx = vertically ? 0.0 : CGFloat(context.width)
            let ty = vertically ? CGFloat(context.height) : 0.0
            let flipVertical = CGAffineTransform(a: number, b: 0.0, c: 0.0, d: -number, tx: tx, ty: ty)
            context.concatenate(flipVertical)
        }
        //
        
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: context.width, height: context.height)))
        context.restoreGState()
        
        // FIX (2/2)
        if !vertically {
            let image = context.makeImage()!
            context.clear()
            context.saveGState()
            context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: context.width, height: context.height)))
            context.restoreGState()
        }
        //
        
        undoManager?.registerUndo(withTarget: self) { (target) in
            target.flip(vertically: vertically)
            target.refresh()
        }
        refresh()
    }
    
    public func rotate(to direction: RotateDirection) {
        let image = context.makeImage()!
        context.saveGState()
        context.clear()
        // iOS 13 BUG?
        // The bug is that the context will flip vertically every time, even when you dont ask it to.
//        context.translateBy(x: CGFloat(context.width)/2.0, y: CGFloat(context.height)/2.0)
//        context.rotate(by: CGFloat.pi / (direction == .right ? 2.0 : -2.0))
//        context.draw(image, in: CGRect(origin: CGPoint(x: -context.width/2, y: -context.height/2), size: CGSize(width: context.width, height: context.height)))
        
        // FIX
        let number: CGFloat = direction == .left ? 1.0 : -1.0
        let tx = direction == .left ? 0.0 : CGFloat(context.width)
        let ty = direction == .left ? CGFloat(context.height) : 0.0
        context.translateBy(x: tx, y: ty)
        context.scaleBy(x: number, y: -number)
        context.translateBy(x: CGFloat(context.width)/2, y: CGFloat(context.height)/2)
        context.rotate(by: .pi/2)
        context.translateBy(x: CGFloat(-context.width)/2, y: CGFloat(-context.height)/2)
        context.draw(image, in: CGRect(origin: .zero, size: CGSize(width: context.width, height: context.height)))
        //
        
        context.restoreGState()
        
        undoManager?.registerUndo(withTarget: self) { (target) in
            target.rotate(to: direction == .left ? .right : .left)
            target.refresh()
        }
        refresh()
    }
    
    public func outline(color: UIColor? = nil) {
        var outline = [(point: PixelPoint, colorComponents: ColorComponents)]()
        for y in 0..<context.height {
            for x in 0..<context.width {
                let point = PixelPoint(x: x, y: y)
                let alpha = getColorComponents(at: point).alpha
                if alpha == 0 {
                    // Check if a neighbor has a color
                    let componentsAbove = getColorComponents(at: PixelPoint(x: x, y: y+1))
                    if y+1 < context.height, componentsAbove.alpha != 0 {
                        outline.append((point, componentsAbove))
                        continue
                    }
                    let componentsRight = getColorComponents(at: PixelPoint(x: x+1, y: y))
                    if x+1 < context.width, componentsRight.alpha != 0 {
                        outline.append((point, componentsRight))
                        continue
                    }
                    let componentsBelow = getColorComponents(at: PixelPoint(x: x, y: y-1))
                    if 0 <= y-1, componentsBelow.alpha != 0 {
                        outline.append((point, componentsBelow))
                        continue
                    }
                    let componentsLeft = getColorComponents(at: PixelPoint(x: x-1, y: y))
                    if 0 <= x-1, componentsLeft.alpha != 0 {
                        outline.append((point, componentsLeft))
                        continue
                    }
                }
            }
        }
        undoManager?.beginUndoGrouping()
        if let color = color {
            for point in outline {
                paint(color: color, at: point.point, size: CGSize(width: 1, height: 1), byUser: false)
            }
        } else {
            // Automatic color
            for point in outline {
                let shadowColor = (palette ?? Palette.defaultPalette).shadow(forColorComponents: point.colorComponents)
                paint(color: UIColor(components: shadowColor), at: point.point, size: CGSize(width: 1, height: 1), byUser: false)
            }
        }
        undoManager?.endUndoGrouping()
        currentOperationPixelPoints.removeAll()
        refresh()
    }
    
    public func posterize() {
        guard let image = context.makeImage() else { return }
        let filter = CIFilter.colorPosterize()
        filter.inputImage = CIImage(cgImage: image)
        filter.levels = 4
        let newImage = UIImage(ciImage: filter.outputImage!)
        newImage.draw(at: .zero)
        
        undoManager?.registerUndo(withTarget: self, handler: { (target) in
            UIImage(cgImage: image).draw(at: .zero)
            target.refresh()
        })
        refresh()
    }
    
    public func trimCanvas() {
        var top: Int?
        findTop: for y in 0..<Int(context.height) {
            for x in 0..<Int(context.width) {
                let point = PixelPoint(x: x, y: y)
                if getColorComponents(at: point).alpha != 0 {
                    top = y
                    break findTop
                }
            }
        }
        guard top != nil else { return }
        var bottom = 0
        findBottom: for y in stride(from: Int(context.height), to: 0, by: -1) {
            for x in 0..<Int(context.width) {
                let point = PixelPoint(x: x, y: y)
                if getColorComponents(at: point).alpha != 0 {
                    bottom = y
                    break findBottom
                }
            }
        }
        var left = 0
        findLeft: for x in 0..<Int(context.width) {
            for y in top!..<bottom {
                let point = PixelPoint(x: x, y: y)
                if getColorComponents(at: point).alpha != 0 {
                    left = x
                    break findLeft
                }
            }
        }
        var right = 0
        findRight: for x in stride(from: Int(context.width), to: 0, by: -1) {
            for y in top!..<bottom {
                let point = PixelPoint(x: x, y: y)
                if getColorComponents(at: point).alpha != 0 {
                    right = x
                    break findRight
                }
            }
        }
        let trimRect = CGRect(x: left, y: top!, width: right-left+1, height: bottom-top!+1)
        
        guard let image = context.makeImage()?.cropping(to: trimRect), let context = CGContext(data: nil, width: Int(trimRect.width), height: Int(trimRect.height), bitsPerComponent: image.bitsPerComponent, bytesPerRow: image.bytesPerRow, space: context.colorSpace!, bitmapInfo: image.alphaInfo.rawValue) else { return }
        context.draw(image, in: CGRect(origin: .zero, size: trimRect.size))
        self.context = context
        refresh()
        canvasView.makeCheckerboard()
        canvasView.zoomToFit()
        undoManager?.registerUndo(withTarget: self, handler: { (target) in
            //
        })
    }
    
    public func export(scale: CGFloat, backgroundColor: UIColor? = nil) -> UIImage? {
        guard let cgImage = context.makeImage() else { return nil }
        let image = UIImage(cgImage: cgImage)
        if scale == 1.0, backgroundColor == nil { return image }
        
        let scaledImageSize = image.size.applying(CGAffineTransform(scaleX: scale, y: scale))
        let format = UIGraphicsImageRendererFormat()
        format.scale = 1
        let renderer = UIGraphicsImageRenderer(size: scaledImageSize, format: format)
        let scaledImage = renderer.image { (context) in
            let rect = CGRect(origin: .zero, size: scaledImageSize)
            if let color = backgroundColor {
                color.setFill()
                UIRectFill(rect)
            }
            context.cgContext.interpolationQuality = .none
            image.draw(in: rect)
        }
        return scaledImage
    }
    
}
