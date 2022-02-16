//
//  EventActions.swift
//  MTMR
//
//  Created by Fedor Zaitsev on 4/27/20.
//  Copyright © 2020 Anton Palgunov. All rights reserved.
//

import Foundation

public class ItemAction {
    typealias TriggerClosure = (() -> Void)?

    var trigger: Action.Trigger
    var closure: TriggerClosure

    init(_ trigger: Action.Trigger, _ closure: TriggerClosure) {
        self.trigger = trigger
        self.closure = closure
    }

    init(_ trigger: Action.Trigger) {
        self.trigger = trigger
        closure = { () in
        }
    }

    func setHidKeyClosure(keycode: Int32) -> ItemAction {
        closure = { () in
            HIDPostAuxKey(keycode)
        }
        return self
    }

    func setKeyPressClosure(keycode: Int) -> ItemAction {
        closure = { () in
            GenericKeyPress(keyCode: CGKeyCode(keycode)).send()
        }
        return self
    }

    func setAppleScriptClosure(appleScript: NSAppleScript) -> ItemAction {
        closure = { () in
            DispatchQueue.appleScriptQueue.async {
                var error: NSDictionary?
                appleScript.executeAndReturnError(&error)
                if let error = error {
                    print("error \(error) when handling apple script ")
                }
            }
        }
        return self
    }

    func setShellScriptClosure(executable: String, parameters: [String]) -> ItemAction {
        closure = { () in
            let task = Process()
            task.launchPath = executable
            task.arguments = parameters
            task.launch()
        }
        return self
    }

    func setOpenUrlClosure(url: String) -> ItemAction {
        closure = { () in
            if let url = URL(string: url), NSWorkspace.shared.open(url) {
                #if DEBUG
                print("URL was successfully opened")
                #endif
            } else {
                print("error", url)
            }
        }
        return self
    }
}

class LongTapEventAction: ItemAction, Decodable {
    private enum CodingKeys: String, CodingKey {
        case longAction
        case longKeycode
        case longActionAppleScript
        case longExecutablePath
        case longShellArguments
        case longUrl
    }

    private enum LongActionTypeRaw: String, Decodable {
        case hidKey
        case keyPress
        case appleScript
        case shellScript
        case openUrl
    }

    required init(closure: TriggerClosure) {
        super.init(Action.Trigger.singleTap, closure)
    }

    required init(from decoder: Decoder) throws {
        super.init(Action.Trigger.longTap)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(LongActionTypeRaw.self, forKey: .longAction)

        switch type {
        case .some(.hidKey):
            let keycode = try container.decode(Int32.self, forKey: .longKeycode)

            _ = setHidKeyClosure(keycode: keycode)
        case .some(.keyPress):
            let keycode = try container.decode(Int.self, forKey: .longKeycode)

            _ = setKeyPressClosure(keycode: keycode)
        case .some(.appleScript):
            let source = try container.decode(Source.self, forKey: .longActionAppleScript)

            guard let appleScript = source.appleScript else {
                print("cannot create apple script")
                return
            }

            _ = setAppleScriptClosure(appleScript: appleScript)
        case .some(.shellScript):
            let executable = try container.decode(String.self, forKey: .longExecutablePath)
            let parameters = try container.decodeIfPresent([String].self, forKey: .longShellArguments) ?? []

            _ = setShellScriptClosure(executable: executable, parameters: parameters)
        case .some(.openUrl):
            let url = try container.decode(String.self, forKey: .longUrl)

            _ = setOpenUrlClosure(url: url)
        case .none:
            break
        }
    }
}

class SingleTapEventAction: ItemAction, Decodable {
    private enum CodingKeys: String, CodingKey {
        case action
        case keycode
        case actionAppleScript
        case executablePath
        case shellArguments
        case url
    }

    private enum ActionTypeRaw: String, Decodable {
        case hidKey
        case keyPress
        case appleScript
        case shellScript
        case openUrl
    }

    required init() {
        super.init(Action.Trigger.singleTap)
    }

    required init(closure: TriggerClosure) {
        super.init(Action.Trigger.singleTap, closure)
    }

    required init(from decoder: Decoder) throws {
        super.init(Action.Trigger.singleTap)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decodeIfPresent(ActionTypeRaw.self, forKey: .action)
        trigger = Action.Trigger.singleTap
        switch type {
        case .some(.hidKey):
            let keycode = try container.decode(Int32.self, forKey: .keycode)

            _ = setHidKeyClosure(keycode: keycode)
        case .some(.keyPress):
            let keycode = try container.decode(Int.self, forKey: .keycode)

            _ = setKeyPressClosure(keycode: keycode)
        case .some(.appleScript):
            let source = try container.decode(Source.self, forKey: .actionAppleScript)

            guard let appleScript = source.appleScript else {
                print("cannot create apple script")
                return
            }

            _ = setAppleScriptClosure(appleScript: appleScript)
        case .some(.shellScript):
            let executable = try container.decode(String.self, forKey: .executablePath)
            let parameters = try container.decodeIfPresent([String].self, forKey: .shellArguments) ?? []

            _ = setShellScriptClosure(executable: executable, parameters: parameters)
        case .some(.openUrl):
            let url = try container.decode(String.self, forKey: .url)

            _ = setOpenUrlClosure(url: url)
        case .none:
            break
        }
    }
}

public struct Action: Decodable {
    enum Trigger: String, Decodable {
        case singleTap
        case doubleTap
        case tripleTap
        case longTap
    }

    enum Value {
        case none
        case hidKey(keycode: Int32)
        case keyPress(keycode: Int)
        case appleScript(source: SourceProtocol)
        case shellScript(executable: String, parameters: [String])
        case custom(closure: () -> Void)
        case openUrl(url: String)
    }

    private enum ActionTypeRaw: String, Decodable {
        case hidKey
        case keyPress
        case appleScript
        case shellScript
        case openUrl
    }

    enum CodingKeys: String, CodingKey {
        case trigger
        case action
        case keycode
        case actionAppleScript
        case executablePath
        case shellArguments
        case url
    }

    let trigger: Trigger
    let value: Value

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)

        trigger = try container.decode(Trigger.self, forKey: .trigger)
        let type = try container.decodeIfPresent(ActionTypeRaw.self, forKey: .action)

        switch type {
        case .some(.hidKey):
            let keycode = try container.decode(Int32.self, forKey: .keycode)
            value = .hidKey(keycode: keycode)

        case .some(.keyPress):
            let keycode = try container.decode(Int.self, forKey: .keycode)
            value = .keyPress(keycode: keycode)

        case .some(.appleScript):
            let source = try container.decode(Source.self, forKey: .actionAppleScript)
            value = .appleScript(source: source)

        case .some(.shellScript):
            let executable = try container.decode(String.self, forKey: .executablePath)
            let parameters = try container.decodeIfPresent([String].self, forKey: .shellArguments) ?? []
            value = .shellScript(executable: executable, parameters: parameters)

        case .some(.openUrl):
            let url = try container.decode(String.self, forKey: .url)
            value = .openUrl(url: url)
        case .none:
            value = .none
        }
    }

    init(trigger: Trigger, value: Value) {
        self.trigger = trigger
        self.value = value
    }
}