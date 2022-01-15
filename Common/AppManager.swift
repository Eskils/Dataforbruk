//
//  AppManager.swift
//  TMDataViewNIB
//
//  Created by Eskil Sviggum on 11/01/2022.
//

import Foundation

typealias UsageHandler = (Usage)->Void

var appManager: AppManager!

//TODO: Look into using Combine for this
class ValueManager<T> {
    typealias ValueHandler = (T)->Void
    
    var value: T? {
        didSet {
            DispatchQueue.main.async { [self] in
                if let value = value { listeners.forEach { $0.value(value) } }
            }
        }
    }
    
    private var listeners = [String: ValueHandler]()
    
    
    func listenToUpdates(_ handler: @escaping ValueHandler) -> String {
        let key = UUID().uuidString
        listeners[key] = handler
        if let value = value { handler(value) }
        return key
    }
    
    func unlistenToUpdates(withKey key: String) {
        if (listeners[key] != nil) { listeners.removeValue(forKey: key) }
    }
    
}

class AppManager {
    
    var lastUpdate: Date?
    let usageManager = ValueManager<Usage>()
    let detailedUsageManager = ValueManager<[DetailedUsage]>()
    private var timer: Timer!
    
    var systemIsSleeping: Bool = false
    let interval: Double = 60*10 // Every tenth minute
    
    init() {
        reinitTimer()
        performUpdate()
    }
    
    @objc func performUpdate() {
        if !systemIsSleeping {
            fetchUsage()
            fetchDetailedUsage()
        }
    }
    
    func fetchUsage() {
        Task.detached(priority: .background) {
            do {
                let usage = try await getUsageData(number: nummer, token: token)
                print("\(Date()) Did fetch usage")
                self.lastUpdate = Date()
                self.usageManager.value = usage
            } catch {
                print(error)
            }
        }
    }
    
    func fetchDetailedUsage() {
        let (startDate, endDate) = getDailyPeriode()
        Task.detached(priority: .background) {
            do {
                let detailedUsage = try await getDetailedUsageData(number: nummer, token: token, startDate: startDate, endDate: endDate)
                self.detailedUsageManager.value = detailedUsage
            } catch {
                print(error)
            }
        }
    }
    
    func reinitTimer() {
        if timer != nil { timer.invalidate() }
        timer = Timer.scheduledTimer(timeInterval: interval, target: self, selector: #selector(performUpdate), userInfo: nil, repeats: true)
    }
    
}
