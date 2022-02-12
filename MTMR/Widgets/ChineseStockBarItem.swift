//
// Created by gaozhiqiang03 on 2022/2/12.
// Copyright (c) 2022 Anton Palgunov. All rights reserved.
//

import Foundation

class ChineseStockBarItem: CustomButtonTouchBarItem {
    public var code: String
    private var info: StockInfo?

    init(identifier: NSTouchBarItem.Identifier, code: String) {
        self.code = code

        super.init(identifier: identifier, title: "⏳" + code)

        if actions.filter({ $0.trigger == .singleTap }).isEmpty {
            actions.append(ItemAction(
                    trigger: .singleTap,
                    openXueqiuUrl
            ))
        }

        DispatchQueueHelper.register(taskId: nil, interval: 1.0, callback: updateStock)
    }

    func openXueqiuUrl() {
        let type = info?.type
        if type == nil {
            return
        }
        let url = "https://xueqiu.com/S/S" + (type! == 0 ? "Z" : "H") + code
        if let url = URL(string: url), NSWorkspace.shared.open(url) {
            #if DEBUG
            print("URL was successfully opened")
            #endif
        } else {
            print("error", url)
        }
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func updateStock() {
        info = ChineseStockHelper.getStockByCode(code: code)
        if (info == nil) {
            title = "⏳" + code
        } else {
            let searchRange = NSMakeRange(0, title.lengthOfBytes(using: .utf8))
            let titleFont = attributedTitle.fontAttributes(in: searchRange)[NSAttributedString.Key.font] ??
                    NSFont.monospacedDigitSystemFont(ofSize: 15, weight: NSFont.Weight.regular)
            let newStr = String(format: "%.2f", info!.price)

            let color = info!.diff > 0 ? NSColor.red : info!.diff == 0 ? NSColor.black : NSColor.green
            let flag = info!.diff > 0 ? "↑" : info!.diff == 0 ? "" : "↓"
            let newTitle: NSMutableAttributedString = NSMutableAttributedString(string: "")
            newTitle.append(NSMutableAttributedString(
                    string: flag,
                    attributes: [
                        NSAttributedString.Key.foregroundColor: color,
                        NSAttributedString.Key.font: titleFont,
                    ]))
            newTitle.append(NSMutableAttributedString(
                    string: newStr,
                    attributes: [
                        NSAttributedString.Key.font: titleFont,
                    ]))

            attributedTitle = newTitle
        }
    }
}

