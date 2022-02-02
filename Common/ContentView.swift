//
//  ContentView.swift
//  TMDataView
//
//  Created by Eskil Sviggum on 10/01/2022.
//

import SwiftUI

struct StatCellDescription: Identifiable {
    let id = UUID().uuidString
    let tittel: String
    let eining: String?
    let calcRes: ObservedObject<CalcResult>.Wrapper
    var shouldShowProsent: Bool = true
}

struct ContentView: View {
    
    @State var dataUsed: Double?
    @State var dataGiven: Double?
    @State var dataUsedToday: Double?
    
    @ObservedObject var totalt = CalcResult.init(prosent: 0, verdi: "-- / --")
    @ObservedObject var avg = CalcResult.empty()
    @ObservedObject var slutt = CalcResult.empty()
    @ObservedObject var nytt = CalcResult.empty()
    @ObservedObject var dagsbruk = CalcResult.empty()
    @ObservedObject var utløpsdag = CalcResult.empty()
    @State var lastUpdate: Date?
    
    var stats: [StatCellDescription]!
    
    init() {
        stats = [
            StatCellDescription(tittel: "Totalt", eining: "GB", calcRes: $totalt),
            StatCellDescription(tittel: "Gjennomsnitt", eining: "GB / dag", calcRes: $avg),
            StatCellDescription(tittel: "Sluttsum", eining: "GB", calcRes: $slutt),
            StatCellDescription(tittel: "Nytt snitt", eining: "GB / dag", calcRes: $nytt),
            StatCellDescription(tittel: "I dag", eining: "GB", calcRes: $dagsbruk),
            StatCellDescription(tittel: "Utløpsdag", eining: getNameOfMonth(), calcRes: $utløpsdag, shouldShowProsent: false),
        ]
    }
    
    var body: some View {
        GeometryReader { geo in
            VStack {
                Text("Dataforbruk · \(getNameOfMonth())")
                    .font(.title)
                    .bold()
                    .frame(width: geo.size.width - 32, alignment: .leading)
                Divider()
                VStack {
                    ForEach(stats) { stat in
                        StatCell(tittel: stat.tittel, eining: stat.eining, verdi: stat.calcRes.verdi, prosent: stat.calcRes.prosent, colors: colors, shouldShowProsent: stat.shouldShowProsent)
                        Divider()
                    }
                }
                HStack {
                    if let lastUpdate = lastUpdate {
                        Text("Sist oppdatert: \(tidFråDato(dato: lastUpdate))")
                            .foregroundColor(Color.tertiaryLabel)
                            .font(.system(size: 12, weight: .regular, design: .default))
                    }
                    #if os(macOS)
                    Button(action: closeApp) {
                        Text("Lukk")
                    }
                    #endif
                }
                .frame(width: geo.size.width - 32, alignment: .leading)
            }
            .padding()
            .frame(width: geo.size.width, height: geo.size.height, alignment: .top)
        }.onAppear(perform: didAppear)
    }
    
    func didAppear() {
        _ = appManager.usageManager         .listenToUpdates(self.didGetUpdates(withUsage:))
        _ = appManager.detailedUsageManager .listenToUpdates(self.didGetUpdates(withDetailedUsage:))
        
        if let result: CodableUsageCalc = appManager.storageManager.retrieveData(withKey: StorageKeys.usageResult) {
            handleResult(result.toResult())
            if let lastUpdate: Date = appManager.storageManager.retrieveData(withKey: StorageKeys.lastUpdate) {
                self.lastUpdate = lastUpdate
            }
        }
    }
    
    func didGetUpdates(withUsage usage: Usage) {
        guard let datausage = usage.getUsage(ofType: .mobildata),
              let result = performCalculations(withUsage: datausage)
        else { return }
        
        appManager.storageManager.store(data: result.toCodable(), withKey: StorageKeys.usageResult)
        self.lastUpdate = appManager.lastUpdate
        handleResult(result)
    }
    
    func handleResult(_ result: UsageCalcResult) {
        self.dataGiven = result.dataGiven
        self.dataUsed = result.dataUsed
        
        self.totalt.set(result.totalt)
        self.avg.set(result.avg)
        self.slutt.set(result.slutt)
        self.nytt.set(result.nytt)
        self.utløpsdag.set(CalcResult(prosent: 0, verdi: result.utløpsdagVerdi))
        
        updateDagsbruk()
    }
    
    func didGetUpdates(withDetailedUsage detailedUsage: [DetailedUsage]) {
        let daily = getSumDailyUsage(fromDetailedUsage: detailedUsage)
        self.dataUsedToday = daily
        updateDagsbruk()
    }
    
    func updateDagsbruk() {
        guard let daily = self.dataUsedToday,
              let given = self.dataGiven
        else { return }
        self.dagsbruk.set(performCalculations(withDailyUsage: daily, dataGiven: given))
    }
    
    #if os(macOS)
    func closeApp() {
        NSApplication.shared.terminate(nil)
    }
    #endif
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView().frame(width: 350, height: 582)
    }
}
