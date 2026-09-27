import SwiftUI

public struct BottomRoundedRectangle: Shape {
    public var cornerRadius: CGFloat
    public var topBleed: CGFloat

    public init(cornerRadius: CGFloat = 16, topBleed: CGFloat = 4) {
        self.cornerRadius = cornerRadius
        self.topBleed = topBleed
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        let topY = rect.minY - topBleed
        path.move(to: CGPoint(x: rect.minX, y: topY))

        path.addLine(to: CGPoint(x: rect.maxX, y: topY))

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY - cornerRadius))
        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(0),
            endAngle: .degrees(90),
            clockwise: false
        )

        path.addLine(to: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY))
        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(180),
            clockwise: false
        )

        path.closeSubpath()

        return path
    }
}

public struct BottomRoundedBorder: Shape {
    public var cornerRadius: CGFloat

    public init(cornerRadius: CGFloat = 16) {
        self.cornerRadius = cornerRadius
    }

    public func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - cornerRadius))

        path.addArc(
            center: CGPoint(x: rect.minX + cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(180),
            endAngle: .degrees(90),
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY))

        path.addArc(
            center: CGPoint(x: rect.maxX - cornerRadius, y: rect.maxY - cornerRadius),
            radius: cornerRadius,
            startAngle: .degrees(90),
            endAngle: .degrees(0),
            clockwise: true
        )

        path.addLine(to: CGPoint(x: rect.maxX, y: rect.minY))

        return path
    }
}
