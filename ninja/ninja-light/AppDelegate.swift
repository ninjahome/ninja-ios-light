//
//  AppDelegate.swift
//  ninja
//
//  Created by wesley on 2021/3/30.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
        var window: UIWindow?
        
        func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
                
                // Override point for customization after application launch.
                if Wallet.shared.loaded{
                        ServiceDelegate.InitService()
                        window?.rootViewController = instantiateViewController(vcID: "NinjaHomeTabVC")
                }else{
                        window?.rootViewController = instantiateViewController(vcID: "NinjaNewWalletVC")
                }
                    window?.makeKeyAndVisible()
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
                _ = WebsocketSrv.shared.Online()
        }
    
        func applicationWillTerminate(_ application: UIApplication) {
            MessageItem.removeAllRead()
        }
}

