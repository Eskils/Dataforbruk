//
//  DataforbrukWidget.swift
//  DataforbrukWidget
//
//  Created by Eskil Sviggum on 13/01/2022.
//

import WidgetKit
import SwiftUI
import Intents

struct Provider: IntentTimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        let exampleUsage = Usage.UsageCategory(usageCategoryType: .mobildata, thisMonthAmountUsed: 62167119252, amountUsed: 62167119252, amountGiven: 107374182400, monthPeriode: .init(startDate: "--", endDate: "--", year: 2022, month: 1, isThisMonth: true))
        let result = performCalculations(withUsage: exampleUsage)
        return SimpleEntry(date: Date(), configuration: ConfigurationIntent(), mobildataUsage: exampleUsage, result: result)
    }

    func getSnapshot(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let (startDate, endDate) = getDailyPeriode()
        Task.init {
            let usage = try? await getUsageData(number: nummer, token: token)
            let detailedUsage = try? await getDetailedUsageData(number: nummer, token: token, startDate: startDate, endDate: endDate)
            
            let mobildataUsage = usage?.getUsage(ofType: .mobildata)
            let result = performCalculations(withUsage: mobildataUsage)
            
            let daily = getSumDailyUsage(fromDetailedUsage: detailedUsage ?? [])
            var dagsf: CalcResult?
            if let result = result { dagsf = performCalculations(withDailyUsage: daily, dataGiven: result.dataGiven) }
            
            let entry = SimpleEntry(date: Date(), configuration: configuration, mobildataUsage: mobildataUsage, result: result, dagsforbruk: dagsf)
            completion(entry)
        }
    }

    func getTimeline(for configuration: ConfigurationIntent, in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        getSnapshot(for: configuration, in: context) { entry in
            let timeline = Timeline(entries: [entry], policy: .after(Calendar.current.date(byAdding: .hour, value: 1, to: Date())!))
            completion(timeline)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let configuration: ConfigurationIntent
    let mobildataUsage: Usage.UsageCategory?
    let result: UsageCalcResult?
    var dagsforbruk: CalcResult? = nil
}

struct DataforbrukWidgetEntryView : View {
    var entry: Provider.Entry
    let labelHeight: CGFloat = 70
    var percentage: Double?
    var value: String!
    
    init(entry: Provider.Entry) {
        self.entry = entry
        let calcRes = getPercentageAndValue()
        (percentage, value) = (calcRes.prosent, calcRes.verdi)
        if calcRes.prosent == -1 { percentage = nil }
    }

    var body: some View {
        GeometryReader { geo in
            VStack(spacing: 0) { 
                Text(title())
                    .font(.system(size: 14))
                if let percentage = percentage {
                    UsageStatView(percentage: .constant(percentage), colors: colors)
                        .frame(width: geo.size.height - labelHeight, height: geo.size.height - labelHeight)
                    HStack(spacing: 2) {
                        Text(value)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                        Text(eining())
                            .font(.system(size: 14))
                            .foregroundColor(Color.tertiaryLabel)
                    }
                } else {
                    LinearGradient(colors: colors, startPoint: .top, endPoint: .bottomTrailing)
                        .mask {
                            VStack(spacing: -6) {
                                Text(value)
                                    .font(.system(size: 50, weight: .bold, design: .rounded))
                                Text(eining())
                                    .font(.system(size: 14))
                                    .foregroundColor(Color.secondary)
                            }
                        }
                        .frame(width: 100, height: 50 + 20)
                    
                }
                
            }.frame(width: geo.size.width, height: geo.size.height)
        }
    }
    
    func getPercentageAndValue() -> CalcResult {
        guard let result = entry.result else { return CalcResult.empty() }
        switch entry.configuration.parameter {
        case.unknown:       return CalcResult.empty()
        case.totalt:        return result.totalt
        case .avg:          return result.avg
        case.sluttsum:      return result.slutt
        case.nyttSnitt:     return result.nytt
        case.dagsforbruk:   return entry.dagsforbruk ?? CalcResult.empty()
        case.utlop:         return CalcResult(prosent: -1, verdi: result.utløpsdagVerdi.replacingOccurrences(of: ".", with: ""))
        }
    }
    
    func eining() -> String {
        switch entry.configuration.parameter {
        case.unknown:       return ""
        case.totalt:        return "GB"
        case .avg:          return "GB / dag"
        case.sluttsum:      return "GB"
        case.nyttSnitt:     return "GB / dag"
        case.dagsforbruk:   return "GB"
        case.utlop:         return getNameOfMonth()
        }
    }
    
    func title() -> String {
        switch entry.configuration.parameter {
        case.totalt:        return "Totalt"
        case.avg:           return "Gjennomsnitt"
        case.sluttsum:      return "Sluttsum"
        case.utlop:         return "Utløpsdag"
        case.nyttSnitt:     return "Nytt snitt"
        case.dagsforbruk:   return "I dag"
        case.unknown:       return "Ukjend"
        }
    }
}

@main
struct DataforbrukWidget: Widget {
    let kind: String = "DataforbrukWidget"

    var body: some WidgetConfiguration {
        IntentConfiguration(kind: kind, intent: ConfigurationIntent.self, provider: Provider()) { entry in
            DataforbrukWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Dataforbruk")
        .description("Denne widgeten syner totalt dataforbruk denne månaden")
        .supportedFamilies([.systemSmall])
    }
}

struct DataforbrukWidget_Previews: PreviewProvider {
    static var previews: some View {
        let exampleUsage = Usage.UsageCategory(usageCategoryType: .mobildata, thisMonthAmountUsed: 62167119252, amountUsed: 62167119252, amountGiven: 107374182400, monthPeriode: .init(startDate: "--", endDate: "--", year: 2022, month: 1, isThisMonth: true))
        let result = performCalculations(withUsage: exampleUsage)
        let intent = ConfigurationIntent()
        intent.parameter = .nyttSnitt
        return DataforbrukWidgetEntryView(entry: SimpleEntry(date: Date(), configuration: intent, mobildataUsage: exampleUsage, result: result))
            .previewContext(WidgetPreviewContext(family: .systemSmall))
    }
}
