//
//  QRGenerator.swift
//  air
//
//  Created by Dylan Karunanayake on 11/9/2026.
//

import SwiftUI
import CoreImage.CIFilterBuiltins

enum QRDotStyle: String, CaseIterable, Identifiable {
    case square, rounded, dots
    var id: String { rawValue }
}

enum QREyeBorderStyle: String, CaseIterable, Identifiable {
    case square, rounded, circle
    var id: String { rawValue }
}

enum QREyeCenterStyle: String, CaseIterable, Identifiable {
    case square, rounded, circle
    var id: String { rawValue }
}

struct QRGenerator {
    static func generate(
        from string: String,
        scale: CGFloat = 10,
        foregroundColor: NSColor = .black,
        backgroundColor: NSColor = .white,
        dotStyle: QRDotStyle = .square,
        eyeBorderStyle: QREyeBorderStyle = .square,
        eyeCenterStyle: QREyeCenterStyle = .square
    ) -> NSImage? {
        guard !string.isEmpty else { return nil }
        guard let matrix = moduleMatrix(for: string) else { return nil }
        let n = matrix.count

        return render(
            matrix: matrix, n: n, scale: scale,
            foregroundColor: foregroundColor, backgroundColor: backgroundColor,
            dotStyle: dotStyle, eyeBorderStyle: eyeBorderStyle, eyeCenterStyle: eyeCenterStyle
        )
    }

    private static func render(
        matrix: [[Bool]],
        n: Int,
        scale: CGFloat,
        foregroundColor: NSColor,
        backgroundColor: NSColor,
        dotStyle: QRDotStyle,
        eyeBorderStyle: QREyeBorderStyle,
        eyeCenterStyle: QREyeCenterStyle
    ) -> NSImage? {
        let quietZone = 1
        let total = n + quietZone * 2
        let pixelSize = CGFloat(total) * scale

        let image = NSImage(size: NSSize(width: pixelSize, height: pixelSize))
        image.lockFocus()
        guard let ctx = NSGraphicsContext.current?.cgContext else {
            image.unlockFocus()
            return nil
        }

        ctx.setFillColor(backgroundColor.cgColor)
        ctx.fill(CGRect(x: 0, y: 0, width: pixelSize, height: pixelSize))
        ctx.setFillColor(foregroundColor.cgColor)

        let eyeRegions: [(row: Int, col: Int)] = [
            (0, 0),
            (0, n - 7),
            (n - 7, 0)
        ]

        func isInEye(_ row: Int, _ col: Int) -> Bool {
            eyeRegions.contains { row >= $0.row && row < $0.row + 7 && col >= $0.col && col < $0.col + 7 }
        }

        func flippedRect(row: Int, col: Int, size: CGFloat = 1) -> CGRect {
            let x = CGFloat(col + quietZone) * scale
            let y = CGFloat(total - 1 - (row + quietZone)) * scale
            return CGRect(x: x, y: y, width: scale * size, height: scale * size)
        }

        for row in 0..<n {
            for col in 0..<n {
                guard matrix[row][col], !isInEye(row, col) else { continue }
                let rect = flippedRect(row: row, col: col)
                drawDot(rect, style: dotStyle, in: ctx)
            }
        }

        for eye in eyeRegions {
            drawEye(
                topRow: eye.row,
                topCol: eye.col,
                quietZone: quietZone,
                total: total,
                scale: scale,
                borderStyle: eyeBorderStyle,
                centerStyle: eyeCenterStyle,
                in: ctx
            )
        }

        image.unlockFocus()
        return image
    }

    static func verifyScannable(_ image: NSImage, expected: String) -> Bool {
        guard let cgImage = image.cgImageRepresentation() else { return false }
        let ciImage = CIImage(cgImage: cgImage)
        let detector = CIDetector(
            ofType: CIDetectorTypeQRCode,
            context: nil,
            options: [CIDetectorAccuracy: CIDetectorAccuracyHigh]
        )
        guard let features = detector?.features(in: ciImage) as? [CIQRCodeFeature] else { return false }
        return features.contains { $0.messageString == expected }
    }

    private static func drawDot(_ rect: CGRect, style: QRDotStyle, in ctx: CGContext) {
        switch style {
        case .square:
            ctx.fill(rect)
        case .rounded:
            let path = CGPath(roundedRect: rect, cornerWidth: rect.width * 0.3, cornerHeight: rect.height * 0.3, transform: nil)
            ctx.addPath(path)
            ctx.fillPath()
        case .dots:
            let inset = rect.width * 0.12
            ctx.fillEllipse(in: rect.insetBy(dx: inset, dy: inset))
        }
    }

    private static func drawEye(
        topRow: Int,
        topCol: Int,
        quietZone: Int,
        total: Int,
        scale: CGFloat,
        borderStyle: QREyeBorderStyle,
        centerStyle: QREyeCenterStyle,
        in ctx: CGContext
    ) {
        func rect(rowSpan: ClosedRange<Int>, colSpan: ClosedRange<Int>) -> CGRect {
            let startCol = topCol + colSpan.lowerBound
            let endCol = topCol + colSpan.upperBound
            let startRow = topRow + rowSpan.lowerBound
            let endRow = topRow + rowSpan.upperBound

            let x = CGFloat(startCol + quietZone) * scale
            let widthModules = CGFloat(endCol - startCol + 1)
            let height = CGFloat(endRow - startRow + 1) * scale
            let y = CGFloat(total - 1 - (endRow + quietZone)) * scale
            return CGRect(x: x, y: y, width: widthModules * scale, height: height)
        }

        let outer = rect(rowSpan: 0...6, colSpan: 0...6)
        let borderWidth = scale

        switch borderStyle {
        case .square:
            let path = CGMutablePath()
            path.addRect(outer)
            path.addRect(outer.insetBy(dx: borderWidth, dy: borderWidth))
            ctx.addPath(path)
            ctx.fillPath(using: .evenOdd)
        case .rounded:
            let outerPath = CGPath(roundedRect: outer, cornerWidth: outer.width * 0.28, cornerHeight: outer.height * 0.28, transform: nil)
            let innerRect = outer.insetBy(dx: borderWidth, dy: borderWidth)
            let innerPath = CGPath(roundedRect: innerRect, cornerWidth: innerRect.width * 0.28, cornerHeight: innerRect.height * 0.28, transform: nil)
            let combined = CGMutablePath()
            combined.addPath(outerPath)
            combined.addPath(innerPath)
            ctx.addPath(combined)
            ctx.fillPath(using: .evenOdd)
        case .circle:
            let path = CGMutablePath()
            path.addEllipse(in: outer)
            path.addEllipse(in: outer.insetBy(dx: borderWidth, dy: borderWidth))
            ctx.addPath(path)
            ctx.fillPath(using: .evenOdd)
        }

        let center = rect(rowSpan: 2...4, colSpan: 2...4)
        switch centerStyle {
        case .square:
            ctx.fill(center)
        case .rounded:
            let path = CGPath(roundedRect: center, cornerWidth: center.width * 0.28, cornerHeight: center.height * 0.28, transform: nil)
            ctx.addPath(path)
            ctx.fillPath()
        case .circle:
            ctx.fillEllipse(in: center)
        }
    }

    private static func moduleMatrix(for string: String) -> [[Bool]]? {
        let data = Data(string.utf8)
        let filter = CIFilter.qrCodeGenerator()
        filter.message = data
        filter.correctionLevel = "H"

        guard let ciImage = filter.outputImage else { return nil }
        let extent = ciImage.extent
        let size = Int(extent.width)
        guard size > 0 else { return nil }

        let context = CIContext()
        guard let cgImage = context.createCGImage(ciImage, from: extent) else { return nil }

        let colorSpace = CGColorSpaceCreateDeviceGray()
        let bytesPerRow = size
        var pixelData = [UInt8](repeating: 0, count: size * size)

        guard let bitmapContext = CGContext(
            data: &pixelData,
            width: size,
            height: size,
            bitsPerComponent: 8,
            bytesPerRow: bytesPerRow,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else { return nil }

        bitmapContext.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))

        var matrix = [[Bool]](repeating: [Bool](repeating: false, count: size), count: size)
        for row in 0..<size {
            let sourceRow = size - 1 - row
            for col in 0..<size {
                matrix[row][col] = pixelData[sourceRow * bytesPerRow + col] < 128
            }
        }
        return matrix
    }
}
