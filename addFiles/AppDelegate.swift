//
//  AppDelegate.swift
//  LivetexMessaging
//
//  Created by Livetex on 19.05.2020.
//  Copyright © 2022 Livetex. All rights reserved.
//

import UIKit
import LivetexUICore
import KeychainSwift

@UIApplicationMain
    class AppDelegate: UIResponder, UIApplicationDelegate {

    private let options: UNAuthorizationOptions = [.alert, .badge, .sound]

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        UNUserNotificationCenter.current().requestAuthorization(options: options) {
            granted, error in
            guard granted else {
                NotificationCenter.default.post(name: UIApplication.didRegisterForRemoteNotifications, object: nil)
                return
            }

            DispatchQueue.main.async {
                application.registerForRemoteNotifications()
            }
        }

        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        application.applicationIconBadgeNumber = 0
    }

    // MARK: - Remote Notifications
    let keychain = KeychainSwift()
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {

        keychain.set(deviceToken.hexString, forKey: "deviceToken")

        NotificationCenter.default.post(name: UIApplication.didRegisterForRemoteNotifications,
                                        object: deviceToken.hexString)
    }

    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for notifications: \(error.localizedDescription)")
        NotificationCenter.default.post(name: UIApplication.didRegisterForRemoteNotifications, object: nil)
    }

}

 public extension UIApplication {

    static let didRegisterForRemoteNotifications = NSNotification.Name(rawValue: "didRegisterForRemoteNotifications")
}

