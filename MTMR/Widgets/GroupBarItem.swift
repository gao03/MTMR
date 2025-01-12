//
//  GroupBarItem.swift
//  MTMR
//
//  Created by Daniel Apatin on 11.05.2018.
//  Copyright © 2018 Anton Palgunov. All rights reserved.
//

import Cocoa

class GroupBarItem: NSPopoverTouchBarItem, NSTouchBarDelegate {
    var jsonItems: [BarItemDefinition]

    var itemDefinitions: [NSTouchBarItem.Identifier: BarItemDefinition] = [:]
    var items: [NSTouchBarItem.Identifier: NSTouchBarItem] = [:]
    var leftIdentifiers: [NSTouchBarItem.Identifier] = []
    var centerIdentifiers: [NSTouchBarItem.Identifier] = []
    var centerItems: [NSTouchBarItem] = []
    var rightIdentifiers: [NSTouchBarItem.Identifier] = []
    var scrollArea: NSCustomTouchBarItem?
    var centerScrollArea = NSTouchBarItem.Identifier("com.toxblh.mtmr.scrollArea.".appending(UUID().uuidString))

    var button: NSButton? {
        get {
            if let button = collapsedRepresentation as? NSButton {
                return button
            }
            return nil
        }
    }

    init(identifier: NSTouchBarItem.Identifier, source: SourceProtocol, interval: TimeInterval, items: [BarItemDefinition]) {
        jsonItems = items
        super.init(identifier: identifier)
        popoverTouchBar.delegate = self

        ShellScriptHelper.register(identifier: identifier, interval: interval, source: source, callback: self.updateTitle);
    }

    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc override func showPopover(_: Any?) {
        itemDefinitions = [:]
        items = [:]
        leftIdentifiers = []
        centerItems = []
        rightIdentifiers = []

        loadItemDefinitions(jsonItems: jsonItems)
        createItems()

        centerItems = centerIdentifiers.compactMap({ (identifier) -> NSTouchBarItem? in
            items[identifier]
        })

        centerScrollArea = NSTouchBarItem.Identifier("com.toxblh.mtmr.scrollArea.".appending(UUID().uuidString))
        scrollArea = ScrollViewItem(identifier: centerScrollArea, items: centerItems)

        TouchBarController.shared.touchBar.delegate = self
        TouchBarController.shared.touchBar.defaultItemIdentifiers = []
        TouchBarController.shared.touchBar.defaultItemIdentifiers = leftIdentifiers + [centerScrollArea] + rightIdentifiers

        if AppSettings.showControlStripState {
            presentSystemModal(TouchBarController.shared.touchBar, systemTrayItemIdentifier: .controlStripItem)
        } else {
            presentSystemModal(TouchBarController.shared.touchBar, placement: 1, systemTrayItemIdentifier: .controlStripItem)
        }
    }

    func touchBar(_: NSTouchBar, makeItemForIdentifier identifier: NSTouchBarItem.Identifier) -> NSTouchBarItem? {
        if identifier == centerScrollArea {
            DispatchQueueHelper.unregisterAllTask()
            StockHelper.register(items: items)
            return scrollArea
        }

        guard let item = self.items[identifier],
              let definition = self.itemDefinitions[identifier],
              definition.align != .center else {
            return nil
        }
        return item
    }

    func updateTitle(title: NSAttributedString, image: NSImage?, scriptResult: String) {
        button?.attributedTitle = title
        button?.imagePosition = title.length > 0 ? .imageLeading : .imageOnly
        if image != nil {
            button?.image = image
        }
    }

    var isBordered: Bool = true {
        didSet {
            button?.isBordered = isBordered
        }
    }


    func loadItemDefinitions(jsonItems: [BarItemDefinition]) {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "HH-mm-ss"
        let time = dateFormatter.string(from: Date())
        for item in jsonItems {
            let identifierString = item.type.identifierBase.appending(time + "--" + UUID().uuidString)
            let identifier = NSTouchBarItem.Identifier(identifierString)
            itemDefinitions[identifier] = item
            if item.align == .left {
                leftIdentifiers.append(identifier)
            }
            if item.align == .right {
                rightIdentifiers.append(identifier)
            }
            if item.align == .center {
                centerIdentifiers.append(identifier)
            }
        }
    }

    func createItems() {
        for (identifier, definition) in itemDefinitions {
            items[identifier] = TouchBarController.shared.createItem(forIdentifier: identifier, definition: definition)
        }
    }
}
