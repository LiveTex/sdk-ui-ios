////
////  AppDelegate.swift
////  LivetexMessaging
////
////  Created by Livetex on 19.05.2020.
////  Copyright © 2022 Livetex. All rights reserved.
////
//
//import UIKit
//
////@UIApplicationMain
//public class AppDelegate: UIResponder, UIApplicationDelegate {
//
//    public var window: UIWindow?
//
//    private let options: UNAuthorizationOptions = [.alert, .badge, .sound]
//
//    public func application(_ application: UIApplication,
//                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
//        UNUserNotificationCenter.current().requestAuthorization(options: options) { granted, error in
//            guard granted else {
//                NotificationCenter.default.post(name: UIApplication.didRegisterForRemoteNotifications, object: nil)
//                return
//            }
//
//            DispatchQueue.main.async {
//                application.registerForRemoteNotifications()
//            }
//        }
//
//        return true
//    }
//
//    public func applicationDidBecomeActive(_ application: UIApplication) {
//        application.applicationIconBadgeNumber = 0
//    }
//
//    // MARK: - Remote Notifications
//
//    public func application(_ application: UIApplication,
//                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
//        NotificationCenter.default.post(name: UIApplication.didRegisterForRemoteNotifications,
//                                        object: deviceToken.hexString)
//    }
//
//   public func application(_ application: UIApplication,
//                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
//        print("Failed to register for notifications: \(error.localizedDescription)")
//        NotificationCenter.default.post(name: UIApplication.didRegisterForRemoteNotifications, object: nil)
//    }
//
//}
//
//extension UIApplication {
//
//    static let didRegisterForRemoteNotifications = NSNotification.Name(rawValue: "didRegisterForRemoteNotifications")
//
//}
//
