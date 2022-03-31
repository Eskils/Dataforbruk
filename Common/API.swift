//
//  API.swift
//  TMDataView
//
//  Created by Eskil Sviggum on 10/01/2022.
//

import Foundation

enum FetchError: String, Error {
    case invalidResponseStatusCode
    case invalidAuthorization
}

fileprivate func performGET(request: URLRequest) async throws -> (Data, HTTPURLResponse) {
    let session = URLSession(configuration: .default)
    let (data, resp) = try await session.data(for: request)
    let response = resp as! HTTPURLResponse
    return (data, response)
}

/// Get usage data for last month for specified number
func getUsageData(number: String, token: String) async throws -> Usage {
    let endpoint = "api.talkmore.no/api/v2/Usage/LastMonth"
    let url = URL(string: "https://\(endpoint)/\(number)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, resp) = try await performGET(request: request)
    
    if resp.statusCode == 200 {
        let usage = try JSONDecoder().decode(Usage.self, from: data)
        return usage
    } else {
        if resp.statusCode == 401 || resp.statusCode == 403 {
            throw FetchError.invalidAuthorization
        }
        print(resp.statusCode)
        throw FetchError.invalidResponseStatusCode
    }
}

/// Get detailed usage data for specified number within period. Period is in format: ddMMyyyy
func getDetailedUsageData(number: String, token: String, startDate: String, endDate: String) async throws -> [DetailedUsage] {
    let endpoint = "api.talkmore.no/api/v2-web/UsageDetailsCategory"
    let url = URL(string: "https://\(endpoint)/\(number)/3/\(startDate)/\(endDate)")!
    var request = URLRequest(url: url)
    request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    
    let (data, resp) = try await performGET(request: request)
    
    if resp.statusCode == 200 {
        let usage = try JSONDecoder().decode([DetailedUsage].self, from: data)
        return usage
    } else {
        print(resp.statusCode)
        throw FetchError.invalidResponseStatusCode
    }
}


