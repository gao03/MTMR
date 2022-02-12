//
// Created by gaozhiqiang03 on 2022/2/12.
// Copyright (c) 2022 Anton Palgunov. All rights reserved.
//

import Foundation

class DispatchQueueHelper {
    static let asyncQueue = DispatchQueue(label: "mtmr.async")
    static var taskVersionMap: [String: Int] = [:]


    static func async(callback: @escaping () -> ()) {
        asyncQueue.async {
            callback()
        }
    }

    static func register(taskId: String?, interval: TimeInterval, callback: @escaping () -> ()) {
        var version = getVersion(taskId: taskId)
        if (taskId != nil) {
            version += 1
            taskVersionMap[taskId!] = version
        }
        let task = Task(taskId: taskId, version: version, interval: interval, callback: callback)
        asyncQueue.async {
            callbackAndSchedule(task: task)
        }
    }

    static func unregisterAllTask() {
        print("unregisterAllTask")
        taskVersionMap.removeAll()
    }

    private static func getVersion(taskId: String?) -> Int {
        if (taskId == nil) {
            return -1
        }
        return taskVersionMap[taskId!, default: 0]
    }

    private static func callbackAndSchedule(task: Task) {
        let version = getVersion(taskId: task.taskId)
        if version != task.version {
            return
        }
        task.callback()
        asyncQueue.asyncAfter(deadline: .now() + task.interval) { () in
            callbackAndSchedule(task: task)
        }
    }
}

private struct Task {
    let taskId: String?
    let version: Int
    let interval: TimeInterval
    let callback: () -> ()
}
