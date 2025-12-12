//
//  CropMaskProtocol.swift
//  Mantis
//
//  Created by Echo on 10/22/18.
//  Copyright © 2018 Echo. All rights reserved.
//

import UIKit

private let minOverLayerUnit: CGFloat = 4
private let initialFrameLength: CGFloat = 1000

protocol CropMaskProtocol: UIView {
    var cropShapeType: CropShapeType { get set }
    var maskLayer: CALayer? { get set }
    var overLayerFillColor: CGColor { get set }
    
    func initialize(cropRatio: CGFloat)
    func setMask(cropRatio: CGFloat)
    func adaptMaskTo(match cropRect: CGRect, cropRatio: CGFloat)
}

extension CropMaskProtocol {
    func initialize(cropRatio: CGFloat = 1.0) {
        setInitialFrame()
        setMask(cropRatio: cropRatio)
    }
    
    private func setInitialFrame() {
        let width = initialFrameLength
        let height = initialFrameLength
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        
        let originX = (screenWidth - width) / 2
        let originY = (screenHeight - height) / 2
        
        self.frame = CGRect(x: originX, y: originY, width: width, height: height)
    }
    
    func adaptMaskTo(match cropRect: CGRect, cropRatio: CGFloat) {
        var scaleX: CGFloat
        
        switch cropShapeType {
        case .roundedRect:
            maskLayer?.removeFromSuperlayer()
            setMask(cropRatio: cropRatio)
            scaleX = cropRect.width / (minOverLayerUnit * cropRatio)
        default:
            scaleX = cropRect.width / minOverLayerUnit
        }
                
        var scaleY = cropRect.height / minOverLayerUnit
        
        scaleX = max(scaleX, 0.0001)
        scaleY = max(scaleY, 0.0001)

        transform = CGAffineTransform(scaleX: scaleX, y: scaleY)

        self.frame.origin.x = cropRect.midX - self.frame.width / 2
        self.frame.origin.y = cropRect.midY - self.frame.height / 2
    }
    
    func createMaskLayer(opacity: Float, cropRatio: CGFloat = 1.0) -> CAShapeLayer {
        let coff: CGFloat
        switch cropShapeType {
        case .roundedRect:
            coff = cropRatio
        default:
            coff = 1
        }
        
        let originX = bounds.midX - minOverLayerUnit * coff / 2
        let originY = bounds.midY - minOverLayerUnit / 2
        let initialRect = CGRect(x: originX, y: originY, width: minOverLayerUnit * coff, height: minOverLayerUnit)
        
        let path = UIBezierPath(rect: self.bounds)
        
        let innerPath: UIBezierPath
        
        func getInnerPath(by points: [CGPoint]) -> UIBezierPath {
            let innerPath = UIBezierPath()
            guard points.count >= 3 else {
                return innerPath
            }
            let points0 = CGPoint(x: initialRect.width * points[0].x + initialRect.origin.x,
                                  y: initialRect.height * points[0].y + initialRect.origin.y)
            innerPath.move(to: points0)
        
            for index in 1..<points.count {
                let point = CGPoint(x: initialRect.width * points[index].x + initialRect.origin.x,
                                    y: initialRect.height * points[index].y + initialRect.origin.y)
                innerPath.addLine(to: point)
            }
            
            innerPath.close()
            return innerPath
        }
                
        switch cropShapeType {
        case .rect, .square:
            innerPath = UIBezierPath(rect: initialRect)
        case .ellipse, .circle:
            innerPath = UIBezierPath(ovalIn: initialRect)
        case .roundedRect(let radiusToShortSide, _):
            let radius = min(initialRect.width, initialRect.height) * radiusToShortSide
            innerPath = UIBezierPath(roundedRect: initialRect, cornerRadius: radius)
        case .diamond:
            let points = [CGPoint(x: 0.5, y: 0), CGPoint(x: 1, y: 0.5), CGPoint(x: 0.5, y: 1), CGPoint(x: 0, y: 0.5)]
            innerPath = getInnerPath(by: points)
        case .path(let points, _):
            innerPath = getInnerPath(by: points)
        case .heart:
            innerPath = UIBezierPath(heartIn: initialRect)
        case .star:
            innerPath = UIBezierPath(starIn: initialRect)
        case .polygon(let sides, let offset, _):
            let points = polygonPointArray(sides: sides, originX: 0.5, originY: 0.5, radius: 0.5, offset: 90 + offset)
            innerPath = getInnerPath(by: points)
        }
                
        path.append(innerPath)
        path.usesEvenOddFillRule = true
        
        let fillLayer = CAShapeLayer()
        fillLayer.path = path.cgPath
        fillLayer.fillRule = .evenOdd
        fillLayer.fillColor = overLayerFillColor
        fillLayer.opacity = opacity
        return fillLayer
    }
}

extension UIBezierPath {
    convenience init(heartIn rect: CGRect) {
        self.init()
        
        let minX: CGFloat = 0.0
        let maxX: CGFloat = 24.7266
        let minY: CGFloat = 0.693359
        let maxY: CGFloat = 23.4668
        
        let origWidth  = maxX - minX
        let origHeight = maxY - minY
        
        let scale = rect.width / origWidth
        let scaledHeight = origHeight * scale
        
        let yOffset = rect.minY + (rect.height - scaledHeight) / 2.0
        
        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            return CGPoint(
                x: rect.minX + (x - minX) * scale,
                y: yOffset     + (y - minY) * scale
            )
        }
        
        self.move(to: P(12.3633, 23.4668))
        
        self.addCurve(
            to: P(13.1934, 23.1543),
            controlPoint1: P(12.6074, 23.4668),
            controlPoint2: P(12.9492, 23.3105)
        )
        
        self.addCurve(
            to: P(24.7266, 8.1543),
            controlPoint1: P(20.1758, 18.6523),
            controlPoint2: P(24.7266, 13.457)
        )
        
        self.addCurve(
            to: P(17.8125, 0.693359),
            controlPoint1: P(24.7266, 3.79883),
            controlPoint2: P(21.7285, 0.693359)
        )
        
        self.addCurve(
            to: P(12.3633, 4.11133),
            controlPoint1: P(15.4199, 0.693359),
            controlPoint2: P(13.4668, 2.04102)
        )
        
        self.addCurve(
            to: P(6.91406, 0.693359),
            controlPoint1: P(11.2695, 2.05078),
            controlPoint2: P(9.31641, 0.693359)
        )
        
        self.addCurve(
            to: P(0, 8.1543),
            controlPoint1: P(2.99805, 0.693359),
            controlPoint2: P(0, 3.79883)
        )
        
        self.addCurve(
            to: P(11.543, 23.1543),
            controlPoint1: P(0, 13.457),
            controlPoint2: P(4.55078, 18.6523)
        )
        
        self.addCurve(
            to: P(12.3633, 23.4668),
            controlPoint1: P(11.7871, 23.3105),
            controlPoint2: P(12.1289, 23.4668)
        )
        
        self.close()
    }
    
    convenience init(starIn rect: CGRect) {
        self.init()

        // Actual bounds of the SVG path coordinates
        let minX: CGFloat = 0.056583
        let maxX: CGFloat = 27.5956
        let minY: CGFloat = 0.0
        let maxY: CGFloat = 26.5527

        let origWidth  = maxX - minX
        let origHeight = maxY - minY

        // Small inset so it "almost touches" but doesn't clip
        let insetX = rect.width * 0.0025   // tweak: 0.01–0.02 usually feels like the Heart glyph
        let targetWidth = max(0, rect.width - insetX * 2)

        let scale = targetWidth / origWidth
        let scaledHeight = origHeight * scale

        let xOffset = rect.minX + insetX
        let yOffset = rect.minY + (rect.height - scaledHeight) / 2.0

        func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(
                x: xOffset + (x - minX) * scale,
                y: yOffset + (y - minY) * scale
            )
        }

        move(to: P(5.30072, 26.2109))

        addCurve(to: P(7.02924, 25.9375),
                 controlPoint1: P(5.75971, 26.5527),
                 controlPoint2: P(6.33588, 26.4453))

        addLine(to: P(13.8261, 20.957))
        addLine(to: P(20.6132, 25.9375))

        addCurve(to: P(22.3515, 26.2109),
                 controlPoint1: P(21.3163, 26.4453),
                 controlPoint2: P(21.8828, 26.5527))

        addCurve(to: P(22.6249, 24.4824),
                 controlPoint1: P(22.8007, 25.8691),
                 controlPoint2: P(22.9081, 25.3027))

        addLine(to: P(19.9589, 16.4941))
        addLine(to: P(26.8046, 11.5723))

        addCurve(to: P(27.5956, 10.0098),
                 controlPoint1: P(27.5078, 11.0742),
                 controlPoint2: P(27.7714, 10.5566))

        addCurve(to: P(26.0331, 9.20898),
                 controlPoint1: P(27.4199, 9.47266),
                 controlPoint2: P(26.9023, 9.20898))

        addLine(to: P(17.6249, 9.20898))
        addLine(to: P(15.0663, 1.23047))

        addCurve(to: P(13.8261, 0.0),
                 controlPoint1: P(14.7929, 0.410156),
                 controlPoint2: P(14.3925, 0.0))

        addCurve(to: P(12.5859, 1.23047),
                 controlPoint1: P(13.2499, 0.0),
                 controlPoint2: P(12.8496, 0.410156))

        addLine(to: P(10.0175, 9.20898))
        addLine(to: P(1.60932, 9.20898))

        addCurve(to: P(0.056583, 10.0098),
                 controlPoint1: P(0.740177, 9.20898),
                 controlPoint2: P(0.232364, 9.47266))

        addCurve(to: P(0.837833, 11.5723),
                 controlPoint1: P(-0.128964, 10.5566),
                 controlPoint2: P(0.144474, 11.0742))

        addLine(to: P(7.68354, 16.4941))
        addLine(to: P(5.01752, 24.4824))

        addCurve(to: P(5.30072, 26.2109),
                 controlPoint1: P(4.74408, 25.3027),
                 controlPoint2: P(4.8515, 25.8691))

        close()
    }
}

extension CGFloat {
    func radians() -> CGFloat {
        return .pi * (self/180)
    }
}

extension Int {
    var degreesToRadians: CGFloat { return CGFloat(self) * .pi / 180 }
}

func polygonPointArray(sides: Int,
                       originX: CGFloat,
                       originY: CGFloat,
                       radius: CGFloat,
                       offset: CGFloat) -> [CGPoint] {
    let angle = (360/CGFloat(sides)).radians()
    
    var index = 0
    var points = [CGPoint]()
    
    while index <= sides {
        let xpo = originX + radius * cos(angle * CGFloat(index) - offset.radians())
        let ypo = originY + radius * sin(angle * CGFloat(index) - offset.radians())
        points.append(CGPoint(x: xpo, y: ypo))
        index += 1
    }
    return points
}
