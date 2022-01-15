//
//  Common.swift
//  TMDataViewNIB
//
//  Created by Eskil Sviggum on 13/01/2022.
//

import Foundation
import SwiftUI

let (nummer, token) = readConfigValues()

let colors: [Color] = [.indigo, .pink, .red, .yellow]

extension Color {
    static var tertiaryLabel: Color {
        #if os(macOS)
        return Color(NSColor.tertiaryLabelColor)
        #else
        return Color(UIColor.tertiaryLabel)
        #endif
    }
}
