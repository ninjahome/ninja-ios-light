//
//  AppDelegate.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit
import UserNotifications
import ChatLib

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    public let DevTypeIOS = 1
    public let Debug = true
    
        var window: UIWindow?
    
        func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

            
            let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
            print("token \(token)")
            print("deviceToken \(deviceToken)")
            ServiceDelegate.deviceToken = token
            ServiceDelegate.InitAPP()
            
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
        }
    
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
            completionHandler([.alert, .sound])
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
            defer {
                completionHandler()
            }
            
            guard response.actionIdentifier == UNNotificationDefaultActionIdentifier else {
                return
            }
            
            let content = response.notification.request.content
            print("title: \(content.title)")
            print("body: \(content.body)")
            
            if let userInfo = content.userInfo as? [String: Any],
               let aps = userInfo["aps"] as? [String: Any] {
                print("aps: \(aps)")
            }
            
        }
    
        func getNotificationSettings() {
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                guard settings.authorizationStatus == .authorized else { return }
                
                DispatchQueue.main.sync {
                    UIApplication.shared.registerForRemoteNotifications()
                }
                print("Notification settings: \(settings)")
            }
        }
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
            
                //TODO:: to be test
//                ServiceDelegate.InitAPP()
                // Override point for customization after application launch.
                if Wallet.shared.loaded{
                        ServiceDelegate.InitService()
                        window?.rootViewController = instantiateViewController(vcID: "NinjaHomeTabVC")
//                        window?.rootViewController = instantiateViewController(vcID: "NinjaGuideVC")
                        
                }else{
                        window?.rootViewController = instantiateViewController(vcID: "NinjaNewWalletVC")
                }
                window?.makeKeyAndVisible()
            
                UNUserNotificationCenter.current().delegate = self
            
                UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound, .carPlay]) { (granted, error) in
                    print("granted \(granted)")
                    guard granted else { return }
                    
                }
                self.getNotificationSettings()
                return true
        }

        // MARK: UISceneSession Lifecycle
        @available(iOS 13.0, *)
        func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
                // Called when a new scene session is being created.
                // Use this method to select a configuration to create the new scene with.
                return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
        }

        @available(iOS 13.0, *)
        func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
                // Called when the user discards a scene session.
                // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
                // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
        }
        
        func applicationWillResignActive(_ application: UIApplication) {
                CDManager.shared.saveContext()
                WebsocketSrv.shared.Offline()
        }
        
        func applicationDidBecomeActive(_ application: UIApplication) {
                if Wallet.shared.IsActive(){
                        WebsocketSrv.shared.Online()
                }
        }
    
        func applicationWillTerminate(_ application: UIApplication) {
//                MessageItem.removeAllRead()
                AudioFilesManager.deleteAllRecordingFiles()
        }
    
        
}

