//
// Created by gaozhiqiang03 on 2022/2/12.
// Copyright (c) 2022 Anton Palgunov. All rights reserved.
//

import Foundation

class ChineseStockHelper {

    private static var codeList: [String] = []
    private static var stockInfoMap: [String: StockInfo] = [:]

    static func register(items: [NSTouchBarItem.Identifier: NSTouchBarItem]) {
        codeList = items.values
                .map({ ($0 as? ChineseStockBarItem)?.code ?? "" })
                .filter({ !($0.isEmpty) })

        DispatchQueueHelper.register(taskId: "stock", interval: 10.0, callback: update);
    }

    static func getStockByCode(code: String) -> StockInfo? {
        stockInfoMap[code]
    }

    static func update() {
        if (codeList.isEmpty) {
            stockInfoMap.removeAll()
            return
        }

        let baseUrl = "https://push2.eastmoney.com/api/qt/ulist.np/get?fields=f2,f3,f12,f13,f14,f15,f16,f18,f232&fltt=2&secids="

        let url = baseUrl + codeList.map({ "0." + $0 + ",1." + $0; }).joined(separator: ",")
        let urlRequest = URLRequest(url: URL(string: url)!)

        let task = URLSession.shared.dataTask(with: urlRequest) { data, _, error in
            if error == nil {
                let decoder = JSONDecoder()
                do {
                    let response = try decoder.decode(Response.self, from: data!)
                    let infoList = response.data?.diff ?? []
                    infoList.map({
                        stockInfoMap[$0.code] = $0
                    })
                } catch {
                    print(error)
                }
            }
        }

        task.resume()
    }
}

struct Response: Codable {
    let data: DataClass?
}

struct DataClass: Codable {
    let diff: [StockInfo]?
}

struct StockInfo: Codable {
    let price, diff, highestPrice, openPrice, basePrice: Double
    let code, name: String
    let type: Int
    let stockCode: String

    enum CodingKeys: String, CodingKey {
        case price = "f2"
        case diff = "f3"
        case code = "f12"
        case type = "f13"
        case name = "f14"
        case highestPrice = "f15"
        case openPrice = "f16"
        case basePrice = "f18"
        case stockCode = "f232"
    }
}