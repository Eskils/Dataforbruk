//
//  Datastructures.swift
//  TMDataView
//
//  Created by Eskil Sviggum on 10/01/2022.
//

import Foundation

enum UsageCategoryType: Int, Decodable {
    case administrativeTenester = 0
    case bankID = 1
    case unknown1 = 2
    case mobildata = 3
    case ringetid = 4
    case unknown = -1
}

extension UsageCategoryType {
    public init(from decoder: Decoder) throws {
        self = try UsageCategoryType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .unknown
    }
}

struct Usage: Decodable {
    let usageCategories: [UsageCategory]
    
    struct UsageCategory: Decodable {
        let usageCategoryType: UsageCategoryType
        let thisMonthAmountUsed: Double
        let amountUsed: Double
        let amountGiven: Double
        let monthPeriode: MonthPeriode
        
        enum CodingKeys: String, CodingKey {
            case usageCategoryType = "UsageCategoryType"
            case thisMonthAmountUsed = "ThisMonthAmountUsed"
            case amountUsed = "AmountUsed"
            case amountGiven = "AmountGiven"
            case monthPeriode = "MonthPeriode"
        }
    }
    
    enum CodingKeys: String, CodingKey {
        case usageCategories = "UsageCategories"
    }
    
    func getUsage(ofType type: UsageCategoryType) -> UsageCategory? {
        for category in usageCategories {
            if category.usageCategoryType == type { return category }
        }
        return nil
    }
}

struct MonthPeriode: Decodable {
    let startDate: String
    let endDate: String
    let year: Int
    let month: Int
    let isThisMonth: Bool
    
    enum CodingKeys: String, CodingKey {
        case startDate = "StartDate"
        case endDate = "EndDate"
        case year = "Year"
        case month = "Month"
        case isThisMonth = "IsThisMonth"
    }
}

struct DetailedUsage: Decodable {
    let amountUsed: Double
    let quantity: Int
    let monthPeriode: MonthPeriode
    
    enum CodingKeys: String, CodingKey {
        case amountUsed = "BundleAmountUsed"
        case quantity = "Quantity"
        case monthPeriode = "MonthPeriode"
    }
}
