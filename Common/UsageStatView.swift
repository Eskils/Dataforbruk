//
//  UsageStatView.swift
//  TMDataViewNIB
//
//  Created by Eskil Sviggum on 12/01/2022.
//

import SwiftUI

struct UsageStatView: View {
    
    @Binding var percentage: Double
    @State var colors: [Color]
    @State var lineWidth: CGFloat = 10
    
    let backColor = Color.secondary.opacity(0.1)
    
    var body: some View {
        GeometryReader { geo in
            ZStack {
                Circle()
                    .stroke(style: StrokeStyle(lineWidth: lineWidth+2, lineCap: .round, lineJoin: .round, miterLimit: 1))
                    .foregroundColor(backColor)
                    .frame(width: geo.size.height - 2*lineWidth , height: geo.size.height - 2*lineWidth)
                CreateGradient(percentage: percentage, colors: colors)
                    .mask {
                        CreatePath(percentage: percentage, geometry: geo, lineWidth: lineWidth)
                            .stroke(style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round, miterLimit: 1))
                    }
                CreateCap(percentage: percentage, geometry: geo, lineWidth: lineWidth)
                    .fill()
                    .foregroundColor(colors.last)
                Text(String(format: "%.0f", percentage * 100) + "%")
                    .font(.caption).bold()
            }
        }.onAppear(perform: didAppear)
    }
    
    func didAppear() {
        
    }
    
    func angles(percentage: Double) -> (startAngle: CGFloat, endAngle: CGFloat) {
        let startAngle = CGFloat.zero
        let endAngle = CGFloat.pi * 2 * percentage
        let offset = -CGFloat.pi/2
        return (startAngle + offset, endAngle + offset)
    }
    
    func CreateGradient(percentage: Double, colors: [Color]) -> AngularGradient {
        let (startAngle, endAngle) = angles(percentage: percentage)
        //let multiple: CGFloat = .pi*2 - .pi/2
        //let calcStart = max(floor((endAngle - .pi*2) / (multiple)) * multiple, startAngle)
        let gradient = AngularGradient(colors: colors, center: .center, startAngle: .radians(startAngle), endAngle: .radians(endAngle))
        return gradient
    }
    
    func CreatePath(percentage: Double, geometry: GeometryProxy, lineWidth: CGFloat) -> Path {
        let path = CGMutablePath()
        let (startAngle, endAngle) = angles(percentage: percentage)
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radii: CGFloat = min(center.x, center.y) - lineWidth
        
        path.addArc(center: center, radius: radii, startAngle: startAngle, endAngle: endAngle, clockwise: false)
        return Path(path)
    }
    
    func CreateCap(percentage: Double, geometry: GeometryProxy, lineWidth: CGFloat) -> Path {
        var (_, endAngle) = angles(percentage: percentage)
        endAngle -= 0.01
        let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
        let radii: CGFloat = min(center.x, center.y) - lineWidth
        
        let transform = CGAffineTransform(rotationAngle: endAngle)
            .concatenating(CGAffineTransform(translationX: center.x + radii * cos(endAngle), y: center.y + radii * sin(endAngle)))
        let path = CGMutablePath()
        path.addArc(center: .zero, radius: lineWidth / 2, startAngle: 0, endAngle: .pi, clockwise: false, transform: transform)
        path.closeSubpath()
        return Path(path)
    }
}

struct UsageStatView_Previews: PreviewProvider {
    
    static var previews: some View {
        let colors: [Color] = [.indigo, .pink, .red, .yellow, .green]
        UsageStatView(percentage: .constant(0.1), colors: colors)
            .frame(width: 100, height: 100)
            .preferredColorScheme(.light)
        UsageStatView(percentage: .constant(0.6), colors: colors)
            .frame(width: 100, height: 100)
            .preferredColorScheme(.dark)
        UsageStatView(percentage: .constant(1.3), colors: colors)
            .frame(width: 100, height: 100)
    }
}
