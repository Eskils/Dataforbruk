//
//  Helpers.swift
//  TMDataView
//
//  Created by Eskil Sviggum on 10/01/2022.
//

import Foundation
import SwiftUI

//TODO: Refactor this file — poss separate into methods and structures

func readConfigValues() -> (nummer: String, token: String) {
    var format =  PropertyListSerialization.PropertyListFormat.xml
    let configDictUrl = Bundle.main.path(forResource: "Config", ofType: "plist")!
    let configDict = FileManager.default.contents(atPath: configDictUrl)!
    let config = try! PropertyListSerialization.propertyList(from: configDict, options: [], format: &format) as! [String: String]
    return (config["Nummer"]!, config["Token"]!)
}

func checkIfTokenIsValid(token: String) -> Bool {
    let payload = getPayloadOfToken(token: token)
    let exp = Double(payload["exp"] as! Int)
    return exp > Date().timeIntervalSince1970
}

func getPayloadOfToken(token: String) -> [String: Any] {
    let split = token.split(separator: ".")
    var str = String(split[1])
    switch str.count % 4 {
    case 0: break
    case 2: str += "=="
    case 3: str += "="
    default: return [:] // The token is invalid
    }
    let payload = Data(base64Encoded: str)!
    let payloadDict = try! JSONSerialization.jsonObject(with: payload) as! [String: Any]
    return payloadDict
}

func convertBytesToGIB(_ bytes: Double) -> Double {
    let const = 9.31322575
    let power: Double = pow(10, 10)
    let gib = const * bytes / power
    return (gib * 10).rounded() / 10
}

func formatDecim(_ dec: Double, sigfigs: Int=1) -> String {
    return String(format: "%.\(sigfigs)f", dec)
}

func getNameOfMonth() -> String {
    let date = Date()
    let cal = Calendar.current
    
    let monthIdx = cal.component(.month, from: date) - 1
    return cal.monthSymbols[monthIdx]
}

func getNameOfDate() -> String {
    let date = Date()
    let cal = Calendar.current
    
    let monthIdx = cal.component(.month, from: date) - 1
    let monthStr = cal.monthSymbols[monthIdx]
    
    let day = cal.component(.day, from: date)
    let dayStr = day < 10 ? "0\(day)" : "\(day)"
    
    return "\(dayStr). \(monthStr)"
}

func getNumDaysInMonth() -> Double {
    let date = Date()
    let cal = Calendar.current
    
    let month = cal.component(.month, from: date)
    let year = cal.component(.year, from: date)
    var dateComponents = DateComponents()
            dateComponents.year = year
            dateComponents.month = month
            if let d = Calendar.current.date(from: dateComponents),
               let interval = Calendar.current.dateInterval(of: .month, for: d),
               let days = Calendar.current.dateComponents([.day], from: interval.start, to: interval.end).day
    { return Double(days) }
            else { return 30 }
}

func tidFråDato(dato: Date) -> String {
    let cal = Calendar.current
    let hour = cal.component(.hour, from: dato)
    let minute = cal.component(.minute, from: dato)
    let hourStr = (hour < 10) ? "0\(hour)" : "\(hour)"
    let minStr = (minute < 10) ? "0\(minute)" : "\(minute)"
    return "\(hourStr):\(minStr)"
}

func calcPercentage(used: Double?, given: Double?) -> Double {
    return (used ?? 0) / (given ?? 0.01)
}

func getUsageData(fromUsage usage: Usage.UsageCategory?) -> (used: Double, given: Double) {
    let amountGiven = usage?.amountGiven ?? 0
    let amountUsed = usage?.amountUsed ?? 100
    
    let dataGiven = convertBytesToGIB(amountGiven)
    let dataUsed = convertBytesToGIB(amountUsed)
    
    return (dataUsed, dataGiven)
}

class CalcResult: ObservableObject {
    @Published var prosent: Double
    @Published var verdi: String
    
    init(prosent: Double, verdi: String) {
        self.prosent = prosent
        self.verdi = verdi
    }
    
    func set(_ new: CalcResult) {
        self.prosent = new.prosent
        self.verdi = new.verdi
    }
    
    static func empty() -> CalcResult {
        return .init(prosent: 0, verdi: "--")
    }
    
    fileprivate func toCodable() -> CodableUsageCalc.CodableCalcResult {
        return .init(prosent: self.prosent, verdi: self.verdi)
    }
}

func getMaksAvgData(fromDataGiven dataGiven: Double, numDaysInMonth: Double?=nil) -> Double {
    let numDaysInMonth = numDaysInMonth ?? getNumDaysInMonth()
    let maksAvgData = dataGiven / numDaysInMonth
    return maksAvgData
}

func getDailyPeriode() -> (startDate: String, endDate: String) {
    let date = Date()
    let formater = DateFormatter()
    formater.dateFormat = "ddMMyyyy"
    let startDate = formater.string(from: date)
    let endDate = formater.string(from: date.addingTimeInterval(24*60*60))
    
    return (startDate, endDate)
}

func getSumDailyUsage(fromDetailedUsage detailedUsage: [DetailedUsage]) -> Double {
    var totalUsedBytes: Double = 0
    for usage in detailedUsage {
        totalUsedBytes += usage.amountUsed
    }
    let totalUsedGibToday = convertBytesToGIB(totalUsedBytes)
    return totalUsedGibToday
}

func performCalculations(withDailyUsage dailyUsage: Double, dataGiven: Double) -> CalcResult {
    let maxAvgData = getMaksAvgData(fromDataGiven: dataGiven)
    let totalUsedGibToday = dailyUsage
    let calcRes = CalcResult(prosent: totalUsedGibToday / maxAvgData, verdi: "\(formatDecim(totalUsedGibToday))")
    return calcRes
}

struct UsageCalcResult {
    let dataUsed: Double
    let dataGiven: Double
    let totalt: CalcResult
    let avg: CalcResult
    let slutt: CalcResult
    let nytt: CalcResult
    let utløpsdagVerdi: String
    
    func toCodable() -> CodableUsageCalc {
        return .init(usageCalcResult: self)
    }
}

struct CodableUsageCalc: Codable {
    
    internal init(dataUsed: Double, dataGiven: Double, totalt: CodableUsageCalc.CodableCalcResult, avg: CodableUsageCalc.CodableCalcResult, slutt: CodableUsageCalc.CodableCalcResult, nytt: CodableUsageCalc.CodableCalcResult, utløpsdagVerdi: String) {
        self.dataUsed = dataUsed
        self.dataGiven = dataGiven
        self.totalt = totalt
        self.avg = avg
        self.slutt = slutt
        self.nytt = nytt
        self.utløpsdagVerdi = utløpsdagVerdi
    }
    
    init(usageCalcResult: UsageCalcResult) {
        self.dataUsed = usageCalcResult.dataUsed
        self.dataGiven = usageCalcResult.dataGiven
        self.totalt = usageCalcResult.totalt.toCodable()
        self.avg = usageCalcResult.avg.toCodable()
        self.slutt = usageCalcResult.slutt.toCodable()
        self.nytt = usageCalcResult.nytt.toCodable()
        self.utløpsdagVerdi = usageCalcResult.utløpsdagVerdi
    }
    
    let dataUsed: Double
    let dataGiven: Double
    let totalt: CodableCalcResult
    let avg: CodableCalcResult
    let slutt: CodableCalcResult
    let nytt: CodableCalcResult
    let utløpsdagVerdi: String
    
    struct CodableCalcResult: Codable {
        let prosent: Double
        let verdi: String
        
        func toResult() -> CalcResult {
            return .init(prosent: prosent, verdi: verdi)
        }
    }
    
    func toResult() -> UsageCalcResult {
        return .init(dataUsed: dataUsed, dataGiven: dataGiven, totalt: totalt.toResult(), avg: avg.toResult(), slutt: slutt.toResult(), nytt: nytt.toResult(), utløpsdagVerdi: utløpsdagVerdi)
    }
}

func performCalculations(withUsage usage: Usage.UsageCategory?) -> UsageCalcResult? {
    guard let usage = usage else { return nil }
    var (dataUsed, dataGiven) = getUsageData(fromUsage: usage)
    if dataUsed.isZero { dataUsed = 0.0001 }
    // Totalt
    let totaltVerdi = "\(formatDecim(dataUsed)) / \(formatDecim(dataGiven))"
    let totaltProsent = calcPercentage(used: dataUsed, given: dataGiven)
    
    // Gjennomsnitt
    let currentDayOfMonth = Double(Calendar.current.component(.day, from: Date()))
    let avgData = dataUsed / currentDayOfMonth
    let numDaysInMonth = getNumDaysInMonth()
    let maksAvgData = getMaksAvgData(fromDataGiven: dataGiven, numDaysInMonth: numDaysInMonth)
    
    let avgVerdi = "\(formatDecim(avgData))"
    let avgProsent = avgData / maksAvgData
    
    // Sluttforbruk
    let sluttsum = avgData * numDaysInMonth
    
    let sluttVerdi = "\(formatDecim(sluttsum))"
    let sluttProsent = sluttsum / dataGiven
    
    // Nytt snitt
    let remainingDays = numDaysInMonth - currentDayOfMonth
    let nyttSnitt = (dataGiven - dataUsed) / remainingDays
    
    let nyttVerdi = "\(formatDecim(nyttSnitt))"
    let nyttProsent = min(1, nyttSnitt / avgData)
    
    // Utløpsdag
    let utløpsdagVerdi = "\(Int(min(numDaysInMonth, floor(dataGiven / avgData))))."
    
    return UsageCalcResult(dataUsed: dataUsed,
                           dataGiven: dataGiven,
                           totalt: CalcResult(prosent: totaltProsent, verdi: totaltVerdi),
                           avg: CalcResult(prosent: avgProsent, verdi: avgVerdi),
                           slutt: CalcResult(prosent: sluttProsent, verdi: sluttVerdi),
                           nytt: CalcResult(prosent: nyttProsent, verdi: nyttVerdi),
                           utløpsdagVerdi: utløpsdagVerdi)
}
