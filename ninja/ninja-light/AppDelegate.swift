//
//  AppDelegate.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit
import UserNotifications
import ChatLib


enum Identifiers {
  static let viewAction = "VIEW_IDENTIFIER"
  static let newsCategory = "NEWS_CATEGORY"
}

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
        public let DevTypeIOS = 1
        public let Debug = false
        
        var window: UIWindow?
        
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
                
                let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                print("token \(token)")
                ServiceDelegate.InitPushParam(deviceToken: token)
                
                if Wallet.shared.Addr == nil {
                        let url = URL(string: "https://baidu.com")
                        let task = URLSession.shared.dataTask(with: url!) {(data: Data?, response: URLResponse?, error: Error?) in
                                guard let data = data else { return }
                                print(String(data: data, encoding: .utf8)!)
                        }
                        task.resume()
                }
        }
        
        func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
                print("failed to register remote noti\(error.localizedDescription)")
                ServiceDelegate.InitPushParam(deviceToken: "")
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
                completionHandler([.badge, .sound, .list, .banner])
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
                defer {
                        completionHandler()
                }
                
                guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
                        return
                }
                
                let content = response.notification.request.content
                print("------>>>title: \(content.title)")
                print("------>>>body: \(content.body)")
                
                guard let userInfo = content.userInfo as? [String: Any] else{
                        return
                }
                if let aps = userInfo["aps"] as? [String: Any]{
                        print("------>>>aps: \(aps)")
                }
                if let newSystemMessage = userInfo["newSystemMessage"] as? String{
                        print("------>>>newSystemMessage: \(newSystemMessage)")
                }
        }
        
        func getPushNotifications() {
                let center = UNUserNotificationCenter.current()
                center.removeAllPendingNotificationRequests()
                center.delegate = self
                center.requestAuthorization(options: [.alert, .badge, .sound], completionHandler: {(granted, error) in
                        if let err = error{
                                print("------>>> request notification err:[\(err.localizedDescription)]")
                        }
                        print("------>>>granted resut:[\(granted)]")
                        guard granted else{
                                return
                        }
                        
                        let viewAction = UNNotificationAction(
                                identifier: Identifiers.viewAction,
                                title: "View",
                                options: [.foreground])
                        let newsCategory = UNNotificationCategory(
                                identifier: Identifiers.newsCategory,
                                actions: [viewAction],
                                intentIdentifiers: [],
                                options: []
                        )
                        UNUserNotificationCenter.current().setNotificationCategories([newsCategory])
                        
                        DispatchQueue.main.sync {
                                UIApplication.shared.registerForRemoteNotifications()
                        }
                })
        }
        
        func getNotificationSettings() {
                UNUserNotificationCenter.current().getNotificationSettings { settings in
                        print("Notification settings: \(settings)")
                        guard settings.authorizationStatus == .authorized else { return }
                        DispatchQueue.main.async {
                                UIApplication.shared.registerForRemoteNotifications()
                        }
                }
        }
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
                ServiceDelegate.InitAPP()
                self.getPushNotifications()
                return true
        }
        
        // MARK: UISceneSession Lifecycle
        func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
                // Called when a new scene session is being created.
                // Use this method to select a configuration to create the new scene with.
                return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }
        
        func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
                // Called when the user discards a scene session.
                // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
                // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        }
        
        func applicationDidBecomeActive(_ application: UIApplication) {
                if Wallet.shared.IsActive(){
                        WebsocketSrv.shared.Online()
                }
        }
        
        func applicationWillTerminate(_ application: UIApplication) {
                CDManager.shared.saveContext()
        }
        
        func applicationWillEnterForeground(_ application: UIApplication) {
                UserDefaults(suiteName: "group.com.hop.ninja.light")?.set(1, forKey: "count")
                UIApplication.shared.applicationIconBadgeNumber = 0
        }
        
        func applicationDidEnterBackground(_ application: UIApplication) {
                CDManager.shared.saveContext()
                WebsocketSrv.shared.Offline()
        }
}

