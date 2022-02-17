//
// Created by gaozhiqiang03 on 2022/2/12.
// Copyright (c) 2022 Anton Palgunov. All rights reserved.
//

import Foundation

class ShellScriptHelper {

    static func register(identifier: NSTouchBarItem.Identifier, interval: TimeInterval, source: SourceProtocol, callback: @escaping (NSMutableAttributedString, NSImage?, String) -> ()) {
        if ((source.string ?? "").isEmpty) {
            return;
        }
        let source = source.string ?? "echo No \"source\""
        DispatchQueueHelper.register(taskId: identifier.rawValue, interval: interval, callback: {
            refreshAndSchedule(interval: interval, source: source, callback: callback);
        })
    }

    struct ScriptResult: Decodable {
        var title: String?
        var image: Source?
    }

    static func refreshAndSchedule(interval: TimeInterval, source: String, callback: @escaping (NSMutableAttributedString, NSImage?, String) -> ()) {
        // Execute script and get result
        let scriptResult = execute(source, interval: interval)
        var rawTitle: String = scriptResult, image: NSImage?

        do {
            let result = try JSONDecoder().decode(ScriptResult.self, from: scriptResult.data(using: .utf8)!)
            rawTitle = result.title ?? ""
            image = result.image?.image
        } catch {
        }

        // Apply returned text attributes (if they were returned) to our result string
        let helper = AMR_ANSIEscapeHelper.init()
        helper.defaultStringColor = NSColor.white
        helper.font = "1".defaultTouchbarAttributedString.attribute(.font, at: 0, effectiveRange: nil) as? NSFont
        let title = NSMutableAttributedString.init(attributedString: helper.attributedString(withANSIEscapedString: rawTitle) ?? NSAttributedString(string: ""))
        title.addAttributes([.baselineOffset: 1], range: NSRange(location: 0, length: title.length))

        // Update UI
        DispatchQueue.main.async { () in
            callback(title, image, scriptResult)
        }
    }

    static func asyncAfter(interval: TimeInterval, callback: (() -> Void)?) {
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { () in
            callback?()
        }
    }

    static func execute(_ command: String, interval: TimeInterval) -> String {
        let task = Process()
        task.launchPath = "/bin/bash"
        task.arguments = ["-c", command]

        let pipe = Pipe()
        task.standardOutput = pipe

        // kill process if it is over update interval
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) { [weak task] in
            task?.terminate()
        }

        task.launch()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        var output: String = NSString(data: data, encoding: String.Encoding.utf8.rawValue) as String? ?? ""

        //always wait until task end or you can catch "task still running" error while accessing task.terminationStatus variable
        task.waitUntilExit()
        if (output == "" && task.terminationStatus != 0) {
            output = "error"
        }

        return output.replacingOccurrences(of: "\\n+$", with: "", options: .regularExpression)
    }
}
