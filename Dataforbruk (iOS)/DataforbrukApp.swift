//
//  DataforbrukApp.swift
//  Dataforbruk
//
//  Created by Eskil Sviggum on 13/01/2022.
//

import SwiftUI

@main
struct DataforbrukApp: App {
    
    init() {
        appManager = AppManager()
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
