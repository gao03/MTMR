//
//  ShellScriptTouchBarItem.swift
//  MTMR
//
//  Created by bobr on 08/08/2019.
//  Copyright © 2019 Anton Palgunov. All rights reserved.
//

import Foundation

class ShellScriptTouchBarItem: CustomButtonTouchBarItem {
    private var forceHideConstraint: NSLayoutConstraint!

    private enum CodingKeys: String, CodingKey {
        case source
        case refreshInterval
    }

    override class var typeIdentifier: String {
        return "shellScriptTitledButton"
    }

    init?(identifier: NSTouchBarItem.Identifier, source: SourceProtocol, interval: TimeInterval) {
        super.init(identifier: identifier, title: "⏳")
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let source = try container.decode(Source.self, forKey: .source)
        let interval = try container.decodeIfPresent(Double.self, forKey: .refreshInterval) ?? 1800.0

        try super.init(from: decoder)

        self.title = "⏳"

        forceHideConstraint = view.widthAnchor.constraint(equalToConstant: 0)

        ShellScriptHelper.register(identifier: identifier, interval: interval, source: source, callback: updateTitle);
    }

    func updateTitle(title: NSAttributedString, image: NSImage?, scriptResult: String) {
        let newBackgroundColor: NSColor? = title.length != 0 ? title.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? NSColor : nil

        if (newBackgroundColor != self.backgroundColor) { // performance optimization because of reinstallButton
            backgroundColor = newBackgroundColor
        }
        setAttributedTitle(title)
        if getImage() != nil {
            self.setImage(image!)
        }
        self.forceHideConstraint.isActive = scriptResult == ""
    }

}
