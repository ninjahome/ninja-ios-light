//
//  NotificationService.swift
//  NotificationServiceExtension
//
//  Created by 郭晓芙 on 2022/1/27.
//

import UserNotifications

class NotificationService: UNNotificationServiceExtension {

        var contentHandler: ((UNNotificationContent) -> Void)?
        var bestAttemptContent: UNMutableNotificationContent?
        let defaults = UserDefaults(suiteName: "group.com.hop.ninja.light")

        override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
                self.contentHandler = contentHandler
                bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)
                var count: Int = defaults?.value(forKey: "count") as! Int
                if let bestAttemptContent = bestAttemptContent {
                        // Modify the notification content here...
                        bestAttemptContent.title = "\(bestAttemptContent.title)"
                        bestAttemptContent.body = "\(bestAttemptContent.body) "
                        bestAttemptContent.badge = count as NSNumber
                        count = count + 1
//                        print("badge count: \(count)")
                        defaults?.set(count, forKey: "count")
                        contentHandler(bestAttemptContent)
                }
        }
    
        override func serviceExtensionTimeWillExpire() {
                // Called just before the extension will be terminated by the system.
                // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
                if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
                        contentHandler(bestAttemptContent)
                }
        }

}
