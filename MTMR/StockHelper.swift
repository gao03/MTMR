//
// Created by gaozhiqiang03 on 2022/2/12.
// Copyright (c) 2022 Anton Palgunov. All rights reserved.
//

import Foundation

class StockHelper {

    private static var codeList: [String] = []
    private static var stockInfoMap: [String: StockInfo] = [:]
    // http://quote.eastmoney.com/center/gridlist.html#hs_a_board
    // 通过这个页面，抓包看 api/qt/stock/get 接口的参数，来判断用哪个类型
    private static var STOCK_TYPE_LIST = [0, 1, 105, 106, 116] // 深A、沪A、美股1、美股2、港股

    static func register(items: [CustomTouchBarItem]) {
        codeList = items
                .map({ ($0 as? StockBarItem)?.code ?? "" })
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

        if checkIsClose() && !stockInfoMap.isEmpty {
            return
        }

        let baseUrl = "https://push2.eastmoney.com/api/qt/ulist.np/get?fields=f2,f3,f12,f13,f14,f15,f16,f18,f232&fltt=2&secids="
        let url = baseUrl + codeList.map {
                    let code = $0
                    return STOCK_TYPE_LIST.map({ String(format: "%d.", $0) + code }).joined(separator: ",")
                }
                .joined(separator: ",")
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

    static func checkIsClose() -> Bool {
        let date = Date()

        let calendar = Calendar.current
        let weekday = calendar.component(.weekday, from: date)
        if weekday == 1 || weekday == 7 {
            return true
        }
        let hour = calendar.component(.hour, from: date)
        let minutes = calendar.component(.minute, from: date)
        let totalMinutes = hour * 60 + minutes;

        // 0 ~ 9:15 ||  15:10 ~ 24:00 休息
        if totalMinutes < 9*60+15 || totalMinutes > 15*60+10 {
            return true
        }
        // 11:40 ~ 13:00 休息
        return totalMinutes > 11*60+40 && totalMinutes < 13*60
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