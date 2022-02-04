//
//  SceneDelegate.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit
import UserNotifications

class SceneDelegate: UIResponder, UIWindowSceneDelegate, UNUserNotificationCenterDelegate {
        
        var window: UIWindow?
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
                completionHandler()
        }
        
        func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
                completionHandler([.alert, .sound])
        }
        
        
        func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
                guard let winScene = (scene as? UIWindowScene) else { return }
                window = UIWindow(windowScene: winScene)
                if Wallet.shared.loaded {
                        window?.rootViewController = instantiateViewController(vcID: "NinjaHomeTabVC")
                } else {
                        if isFirstUser() {
                                window?.rootViewController = instantiateViewController(vcID: "NinjaGuideVC")
                        } else {
                                window?.rootViewController = instantiateViewController(vcID: "NinjaNewWalletVC")
                        }
                        
                }
                window?.makeKeyAndVisible()
        }
        
        func sceneDidDisconnect(_ scene: UIScene) {
                CDManager.shared.saveContext()

                // Called as the scene is being released by the system.
                // This occurs shortly after the scene enters the background, or when its session is discarded.
                // Release any resources associated with this scene that can be re-created the next time the scene connects.
                // The scene may re-connect later, as its session was not necessarily discarded (see `application:didDiscardSceneSessions` instead).
                //            MessageItem.removeAllRead()
        }
        
        func sceneDidBecomeActive(_ scene: UIScene) {
                // Called when the scene has moved from an inactive state to an active state.
                // Use this method to restart any tasks that were paused (or not yet started) when the scene was inactive.
                
        }
        
        func sceneWillResignActive(_ scene: UIScene) {
                // Called when the scene will move from an active state to an inactive state.
                // This may occur due to temporary interruptions (ex. an incoming phone call).
        }
        
        func sceneWillEnterForeground(_ scene: UIScene) {
                // Called as the scene transitions from the background to the foreground.
                // Use this method to undo the changes made on entering the background.
                if Wallet.shared.IsActive() {
                        WebsocketSrv.shared.Online()
                }
        }
        
        func sceneDidEnterBackground(_ scene: UIScene) {
                // Called as the scene transitions from the foreground to the background.
                // Use this method to save data, release shared resources, and store enough scene-specific state information
                // to restore the scene back to its current state.
                
                // Save changes in the application's managed object context when the application transitions to the background.
                UserDefaults(suiteName: "group.com.hop.ninja.light")?.set(1, forKey: "count")
                UIApplication.shared.applicationIconBadgeNumber = 0
                CDManager.shared.saveContext()
                WebsocketSrv.shared.Offline()
        }
}

