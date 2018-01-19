//
//  AppDelegate.swift
//  PennMobile
//
//  Created by Josh Doman on 5/3/17.
//  Copyright © 2017 PennLabs. All rights reserved.
//

import UIKit
import UserNotifications
import FirebaseCore
import FirebaseInstanceID
import FirebaseMessaging

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    
    let gcmMessageIDKey = "gcm.message_id"

    var window: UIWindow?
    var swRevealViewController: SWRevealViewController!
    var navController: UINavigationController!
    var masterTableViewController = MasterTableViewController()
    var homeController = ControllerSettings.shared.firstController
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        DatabaseManager.shared.dryRun = true
        GoogleAnalyticsManager.shared.dryRun = true
        //DatabaseManager.shared.startSession() //adds new session log to queue
        
        GoogleAnalyticsManager.prepare()
        LaundryAPIService.instance.prepare()
        LaundryNotificationCenter.shared.prepare()
        
        // Firebase
        FirebaseApp.configure();
//        if #available(iOS 10.0, *) {
//            UNUserNotificationCenter.current().delegate = self
//            let authOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
//            UNUserNotificationCenter.current().requestAuthorization(
//                options: authOptions,
//                completionHandler: {_, _ in })
//        } else {
//            let settings: UIUserNotificationSettings =
//                UIUserNotificationSettings(types: [.alert, .badge, .sound], categories: nil)
//            application.registerUserNotificationSettings(settings)
//        }
//
//        application.registerForRemoteNotifications()

        
        if !UserDefaults.standard.isOnboarded() {
            handleOnboarding(animated: true)
            UserDefaults.standard.setIsOnboarded(value: true) // uncomment in order to prevent multiple onboardings
            return true
        }
        
        navController = UINavigationController(rootViewController: homeController)
        navController.isNavigationBarHidden = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        presentSWController()
        //registerForPushNotifications() //uncomment when ready to start registering tokens for push notifications

        return true
    }
    
    func handleOnboarding(animated: Bool) {
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        navController = UINavigationController(rootViewController: vc)
        navController.isNavigationBarHidden = true
        
        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = navController
        window?.makeKeyAndVisible()
        
        let tempVC = UIViewController()
        tempVC.view.backgroundColor = UIColor.red
        navController.modalTransitionStyle = .crossDissolve
        let oc = OnboardingController()
        oc.delegate = self
        self.navController.present(oc, animated: animated, completion: nil)
    }
    
    func presentSWController() {
        
        let masterNavController = UINavigationController(rootViewController: masterTableViewController)
        let homeNavController = UINavigationController(rootViewController: homeController)
        
        swRevealViewController = SWRevealViewController(rearViewController: masterNavController, frontViewController: homeNavController)
        
        self.navController.pushViewController(swRevealViewController, animated: false)
        
        masterTableViewController.prepare() //need to call because viewDidLoad not called until menu button is pressed (bug with SWRevealViewController?)
    }
    
    //Special thanks to Ray Wenderlich
    func registerForPushNotifications() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) {
            (granted, error) in
            guard granted else {
                self.registerOrUpdateUser()
                return
            }
            self.getNotificationSettings()
        }
    }
    
    func getNotificationSettings() {
        UNUserNotificationCenter.current().getNotificationSettings { (settings) in
            if settings.authorizationStatus != .authorized {
                self.registerOrUpdateUser()
                return
            }
            DispatchQueue.main.async {
                UIApplication.shared.registerForRemoteNotifications()
            }
        }
    }
    
    func application(_ application: UIApplication,
                     didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        let tokenParts = deviceToken.map { data -> String in
            return String(format: "%02.2hhx", data)
        }
        
        let token = tokenParts.joined()
        registerOrUpdateUser(with: token)
    }
    
    func application(_ application: UIApplication,
                     didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register: \(error)")
        registerOrUpdateUser()
    }
    
    private func registerOrUpdateUser(with token: String? = nil) {
        do {
            if try DatabaseManager.shared.createUser(with: token) { //returns true if first visit
                DatabaseManager.shared.startSession()
            } else if let token = token {
                try DatabaseManager.shared.updateDeviceToken(with: token)
            }
        } catch {
            print("Caught: \(error)")
        }
    }
    
    var backgroundTask: UIBackgroundTaskIdentifier?
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        if DatabaseManager.shared.dryRun { return }
        
        DatabaseManager.shared.endSession()
        backgroundTask = application.beginBackgroundTask {
            if let bgTask = self.backgroundTask {
                DispatchQueue.main.async {
                    application.endBackgroundTask(bgTask)
                    self.backgroundTask = UIBackgroundTaskInvalid
                }
            }
        }
        
        DispatchQueue.main.async {
            if application.backgroundTimeRemaining > 1.0 {
                DatabaseManager.shared.endSession()
            }
            
            if let bgTask = self.backgroundTask {
                application.endBackgroundTask(bgTask)
                self.backgroundTask = UIBackgroundTaskInvalid
            }
        }
    }
    
    func applicationWillEnterForeground(_ application: UIApplication) {
        DatabaseManager.shared.startSession()
        ControllerSettings.shared.visibleVC().viewWillAppear(true)
    }

    func applicationWillTerminate(_ application: UIApplication) {
        DatabaseManager.shared.endSession()
    }

}

extension AppDelegate: OnboardingDelegate {
    func handleFinishedOnboarding() {
        navController.viewControllers = [homeController]
        presentSWController()
        //registerForPushNotifications()
    }
}

extension AppDelegate: MessagingDelegate {
    func application(received remoteMessage: MessagingRemoteMessage) {
        print("Received data message: \(remoteMessage.appData)")
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Receive displayed notifications for iOS 10 devices.
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        let userInfo = notification.request.content.userInfo
        
        // With swizzling disabled you must let Messaging know about the message, for Analytics
        // Messaging.messaging().appDidReceiveMessage(userInfo)
        
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        // Change this to your preferred presentation option
        completionHandler([])
    }
    
    func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Print message ID.
        if let messageID = userInfo[gcmMessageIDKey] {
            print("Message ID: \(messageID)")
        }
        
        // Print full message.
        print(userInfo)
        
        completionHandler()
    }
}

