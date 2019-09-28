//
//  Tools.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-06-06.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import CoreGraphics

public protocol Tool {
    
}

public struct PencilTool: Tool {
    public var width: CGFloat
    public var size: CGSize {
        return CGSize(width: width, height: width)
    }
    
    public init(width: CGFloat) {
        self.width = width
    }
}
public struct EraserTool: Tool {
    public var width: CGFloat
    public var size: CGSize {
        return CGSize(width: width, height: width)
    }
    
    public init(width: CGFloat) {
        self.width = width
    }
}
public struct EyedroperTool: Tool {
    public init() { }
}
public struct FillTool: Tool {
    public init() { }
}
public struct MoveTool: Tool {
    public init() { }
}
public struct HighlightTool: Tool {
    public var width: CGFloat
    public var size: CGSize {
        return CGSize(width: width, height: width)
    }
    
    public init(width: CGFloat) {
        self.width = width
    }
}
public struct ShadowTool: Tool {
    public var width: CGFloat
    public var size: CGSize {
        return CGSize(width: width, height: width)
    }
    
    public init(width: CGFloat) {
        self.width = width
    }
}
