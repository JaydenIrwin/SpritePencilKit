//
//  Tools.swift
//  Sprite Pencil
//
//  Created by Jayden Irwin on 2019-06-06.
//  Copyright © 2019 Jayden Irwin. All rights reserved.
//

import CoreGraphics

protocol Tool {
    
}

struct PencilTool: Tool {
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
struct EraserTool: Tool {
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
struct EyedroperTool: Tool {
    
}
struct FillTool: Tool {
    
}
struct MoveTool: Tool {
    
}
struct HighlightTool: Tool {
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
struct ShadowTool: Tool {
    var width: CGFloat
    var size: CGSize {
        return CGSize(width: width, height: width)
    }
}
