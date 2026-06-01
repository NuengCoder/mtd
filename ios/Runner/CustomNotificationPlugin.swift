import Flutter
import UIKit
import UserNotifications

public class CustomNotificationPlugin: NSObject, FlutterPlugin {

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.nueng.mtd/notification",
                                           binaryMessenger: registrar.messenger())
        let instance = CustomNotificationPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "scheduleNotification":
            scheduleNotification(call, result)
        case "cancelNotification":
            cancelNotification(call, result)
        case "cancelAllNotifications":
            cancelAllNotifications(result)
        case "registerSound":
            registerSound(call, result)
        default:
            result(FlutterMethodNotImplemented)
        }
    }

    private func scheduleNotification(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int,
              let title = args["title"] as? String,
              let body = args["body"] as? String,
              let scheduledTimeMs = args["scheduledTime"] as? Int64 else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing required arguments", details: nil))
            return
        }

        let soundUri = args["soundUri"] as? String

        let triggerDate = Date(timeIntervalSince1970: TimeInterval(scheduledTimeMs) / 1000.0)
        let triggerComponents = Calendar.current.dateComponents(
            [.year, .month, .day, .hour, .minute, .second],
            from: triggerDate
        )
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComponents, repeats: false)

        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = notificationSound(for: soundUri)

        let request = UNNotificationRequest(
            identifier: "\(id)",
            content: content,
            trigger: trigger
        )

        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                result(FlutterError(code: "SCHEDULE_FAILED", message: error.localizedDescription, details: nil))
            } else {
                debugPrint("[CustomNotif] Scheduled id=\(id) sound=\(soundUri ?? "default")")
                result(true)
            }
        }
    }

    private func cancelNotification(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let id = args["id"] as? Int else {
            result(FlutterError(code: "INVALID_ARGS", message: "Missing id", details: nil))
            return
        }
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["\(id)"])
        result(true)
    }

    private func cancelAllNotifications(_ result: @escaping FlutterResult) {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        result(true)
    }

    private func registerSound(_ call: FlutterMethodCall, _ result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let path = args["path"] as? String else {
            result(nil)
            return
        }

        let fileURL = URL(fileURLWithPath: path)
        let fileName = fileURL.lastPathComponent

        guard let soundsDir = FileManager.default.urls(for: .libraryDirectory, in: .userDomainMask).first?
            .appendingPathComponent("Sounds") else {
            result(nil)
            return
        }

        do {
            try FileManager.default.createDirectory(at: soundsDir, withIntermediateDirectories: true)
            let destURL = soundsDir.appendingPathComponent(fileName)

            if FileManager.default.fileExists(atPath: destURL.path) {
                try FileManager.default.removeItem(at: destURL)
            }
            try FileManager.default.copyItem(at: fileURL, to: destURL)

            // Return the filename (without extension) for UNNotificationSound
            let soundName = fileURL.deletingPathExtension().lastPathComponent
            debugPrint("[CustomNotif] Sound registered: \(soundName)")
            result(soundName)
        } catch {
            debugPrint("[CustomNotif] registerSound error: \(error)")
            result(nil)
        }
    }

    private func notificationSound(for uri: String?) -> UNNotificationSound {
        guard let uri = uri, !uri.isEmpty else {
            return .default
        }

        // content:// URIs are Android-only; fall back to default
        if uri.hasPrefix("content://") {
            return .default
        }

        return UNNotificationSound(named: UNNotificationSoundName(rawValue: uri))
    }
}
