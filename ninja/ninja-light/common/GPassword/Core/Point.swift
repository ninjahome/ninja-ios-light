//
//  Point.swift
//  GPassword
//
//  Created by Jie Li on 8/5/18.
//
//  Copyright (c) 2018 Jie Li <codelijie@gmail.com>
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

class Point: CAShapeLayer {

    /// Contain all infos to draw
    fileprivate struct Shape {
        let fillColor: UIColor
        let rect: CGRect
        let stroke: Bool
        let strokeColor: UIColor
    }

    // MARK: - Properties

    /// Point selected
    var selected: Bool = false {
        didSet {
            drawAll()
        }
    }

    /// Angle used to draw triangle when isDrawTriangle is true
    var angle: CGFloat = 9999 {
        didSet {
            drawAll()
        }
    }
    
    /// The identifier for point
    var tag: Int = 0

    /// Contain draw infos of inner circle normal
    fileprivate lazy var innerNormal: Shape = {
        let rectWH = bounds.width * globalOptions.scale
        let rectXY = bounds.width * (1 - globalOptions.scale) * 0.5
        let rect =  CGRect(x: rectXY, y: rectXY, width: rectWH, height: rectWH)
        let inner = Shape(fillColor: globalOptions.innerNormalColor,
                          rect: rect,
                          stroke: globalOptions.isInnerStroke,
                          strokeColor: globalOptions.innerStrokeColor)
        return inner
    }()

    /// Contain draw infos of inner circle selected
    fileprivate lazy var innerSelected: Shape = {
        let rectWH = bounds.width * globalOptions.scale
        let rectXY = bounds.width * (1 - globalOptions.scale) * 0.5
        let rect =  CGRect(x: rectXY, y: rectXY, width: rectWH, height: rectWH)
        let inner = Shape(fillColor: globalOptions.innerSelectedColor,
                          rect: rect,
                          stroke: globalOptions.isInnerStroke,
                          strokeColor: globalOptions.innerStrokeColor)
        return inner
    }()

    /// Contain draw infos of inner circle normal
    fileprivate lazy var innerTriangle: Shape = {
        let rectWH = bounds.width * globalOptions.scale
        let rectXY = bounds.width * (1 - globalOptions.scale) * 0.5
        let rect =  CGRect(x: rectXY, y: rectXY, width: rectWH, height: rectWH)
        let inner = Shape(fillColor: globalOptions.triangleColor,
                          rect: rect,
                          stroke: globalOptions.isInnerStroke,
                          strokeColor: globalOptions.innerStrokeColor)
        return inner
    }()

    /// Contain draw infos of outer circle stroke
    fileprivate lazy var outerStroke: Shape = {
        let sizeWH = bounds.width - 2 * globalOptions.pointLineWidth
        let originXY = globalOptions.pointLineWidth
        let rect = CGRect(x: originXY, y: originXY, width: sizeWH, height: sizeWH)
        let outer = Shape(fillColor: globalOptions.outerNormalColor,
                          rect: rect,
                          stroke: globalOptions.isOuterStroke,
                          strokeColor: globalOptions.outerStrokeColor)
        return outer
    }()

    /// Contain draw infos of outer circle selected
    fileprivate lazy var outerSelected: Shape = {
        let sizeWH = bounds.width - 2 * globalOptions.pointLineWidth
        let originXY = globalOptions.pointLineWidth
        let rect = CGRect(x: originXY, y: originXY, width: sizeWH, height: sizeWH)
        let outer = Shape(fillColor: globalOptions.outerSelectedColor,
                          rect: rect,
                          stroke: globalOptions.isOuterStroke,
                          strokeColor: globalOptions.outerStrokeColor)
        return outer
    }()

    // MARK: - Lifecycle
    init(frame: CGRect) {
        super.init()
        self.frame = frame
        drawAll()
    }

    override init(layer: Any) {
        super.init(layer: layer)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Draw

    /// Draw all layers in point
    func drawAll() {
        sublayers?.removeAll()
        if selected {
            drawShape(outerSelected)
            drawShape(innerSelected)
            if globalOptions.isDrawTriangle {
                drawTriangle(innerTriangle)
            }
        } else {
            if globalOptions.normalstyle == .innerFill {
                drawShape(innerNormal)
            } else {
                drawShape(outerStroke)
            }
        }
    }

    /// Draw single layer in point
    ///
    /// - Parameter shape: Shape
    private func drawShape(_ shape: Shape) {
        let path = UIBezierPath(ovalIn: shape.rect)
        let shapeLayer = CAShapeLayer()
        shapeLayer.fillColor = shape.fillColor.cgColor
        if shape.stroke {
            shapeLayer.strokeColor = shape.strokeColor.cgColor
        }
        shapeLayer.path = path.cgPath
        addSublayer(shapeLayer)
    }

    /// Draw triangle according angle property
    ///
    /// - Parameter shape: Shape
    private func drawTriangle(_ shape: Shape) {
        if angle == 9999 { return }
        let triangleLayer = CAShapeLayer()
        let path = UIBezierPath()
        triangleLayer.fillColor = globalOptions.triangleColor.cgColor

        let width = globalOptions.triangleWidth
        let height = globalOptions.triangleHeight
        let topX = shape.rect.minX + shape.rect.width * 0.5
        let topY = shape.rect.minY + (shape.rect.width * 0.5 - height - globalOptions.offsetInnerCircleAndTriangle - shape.rect.height * 0.5)
        path.move(to: CGPoint(x: topX, y: topY))
        let leftPointX = topX - width * 0.5
        let leftPointY = topY + height
        path.addLine(to: CGPoint(x: leftPointX, y: leftPointY))
        let rightPointX = topX + width * 0.5
        path.addLine(to: CGPoint(x: rightPointX, y: leftPointY))
        triangleLayer.path = path.cgPath

        // rotate
        var transform = CATransform3DIdentity
        transform = CATransform3DTranslate(transform, frame.width/2, frame.height/2, 0)
        transform = CATransform3DRotate(transform, angle, 0.0, 0.0, -1.0);
        transform = CATransform3DTranslate(transform, -frame.width/2, -frame.height/2, 0)
        triangleLayer.transform = transform
        addSublayer(triangleLayer)
    }
}
