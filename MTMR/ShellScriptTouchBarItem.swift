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

    struct ScriptResult: Decodable {
        var title: String?
        var image: Source?
    }

    init?(identifier: NSTouchBarItem.Identifier, source: SourceProtocol, interval: TimeInterval) {
        super.init(identifier: identifier, title: "⏳")

        forceHideConstraint = view.widthAnchor.constraint(equalToConstant: 0)

        ShellScriptHelper.register(identifier: identifier, interval: interval, source: source, callback: updateTitle);
    }

    func updateTitle(title: NSAttributedString, image: NSImage?, scriptResult: String) {
        let newBackgroundColor: NSColor? = title.length != 0 ? title.attribute(.backgroundColor, at: 0, effectiveRange: nil) as? NSColor : nil

        if (newBackgroundColor != self.backgroundColor) { // performance optimization because of reinstallButton
            backgroundColor = newBackgroundColor
        }
        attributedTitle = title
        if image != nil {
            self.image = image
        }
        self.forceHideConstraint.isActive = scriptResult == ""
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
