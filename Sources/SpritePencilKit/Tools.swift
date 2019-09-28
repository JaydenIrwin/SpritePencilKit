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
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
public struct EraserTool: Tool {
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
public struct EyedroperTool: Tool {
    
}
public struct FillTool: Tool {
    
}
public struct MoveTool: Tool {
    
}
public struct HighlightTool: Tool {
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
public struct ShadowTool: Tool {
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
