//
//  AppDelegate.swift
//  WeTrain
//
//  Created by Bobby Ren on 7/31/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit
import CoreData
import Parse
import Bolts
import Fabric
import Crashlytics
import GoogleMaps
import ParseFacebookUtilsV4
import Stripe
import MBProgressHUD
import SystemConfiguration

@UIApplicationMain

class AppDelegate: UIResponder, UIApplicationDelegate, TutorialDelegate, UITabBarControllerDelegate {

    var window: UIWindow?
    
    var OptionType                  : NSString?
    var ScheduleTime                : NSDate?
    var scheduleConfirmationCon     : ScheduleConfirmationViewController?
    var scheduleRemiderInfo         : NSDictionary?
    var maintabBarController        : UITabBarController?
    var videoShareTo                : Int?
    var motivateMevideoPath         : NSString!
    var pushNotificationUserInfo    : NSDictionary?
    var isRatingVisible             : Bool!
    var randomWorkOutIndex          : NSMutableArray!
    var availtrainers               : AvailableTrainers!
    var apsUserInfo                 : NSDictionary!
    var isAppJustOpen : Bool! = false

    var Locationcompletion: ((result: String) -> Void)!
    
    func application(application: UIApplication, didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {
        
    
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)

        //for app open from scheduled workout reminder
        if let options = launchOptions {
            if let notification = options[UIApplicationLaunchOptionsLocalNotificationKey] as? UILocalNotification {
                if let userInfo = notification.userInfo {
                    self.scheduleRemiderInfo = userInfo
                }
            }
            
            
            if let notification = options[UIApplicationLaunchOptionsRemoteNotificationKey] as? NSDictionary {
                
                    print(notification)
                
                    apsUserInfo  = notification["aps"] as! NSDictionary

                    if let apnsType = notification["apnsType"] as! String? {
                        
                        if apnsType.characters.count > 0 {
                            
                            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
                            dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                                self.showAppUpdateAlert(self.apsUserInfo["alert"] as! String)
                            }
                            
                        }
                    }
                    else
                    {
                        self.pushNotificationUserInfo = notification
                    }
            }
        }
        
        // Override point for customization after application launch.
        if TESTING == 0 {
            Parse.setApplicationId(PARSE_APP_ID_PROD, clientKey: PARSE_CLIENT_KEY_PROD)
            Stripe.setDefaultPublishableKey(STRIPE_PUBLISHABLE_KEY_PROD)
        }
        else {
            Parse.setApplicationId(PARSE_APP_ID_DEV, clientKey: PARSE_CLIENT_KEY_DEV)
            Stripe.setDefaultPublishableKey(STRIPE_PUBLISHABLE_KEY_DEV)
        }
        
        PFFacebookUtils.initializeFacebookWithApplicationLaunchOptions(launchOptions)
        
        // [Optional] Track statistics around application opens.
        PFAnalytics.trackAppOpenedWithLaunchOptions(launchOptions)
        
        Fabric.with([Crashlytics.self])
        
        // google maps
        GMSServices.provideAPIKey(GOOGLE_API_APP_KEY)

        
        // reregister for relevant channels
        if UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
            
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()
        }

        UITabBar.appearance().tintColor = UIColor.orangeColor()
        UITabBar.appearance().selectedImageTintColor = UIColor.orangeColor()
        UITabBar.appearance().shadowImage = nil
        UITabBar.appearance().barTintColor = UIColor.blackColor()
        
        
        
        self.scheduleConfirmationCon = (UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ScheduleConfirmationController") as! ScheduleConfirmationViewController)
        self.scheduleConfirmationCon?.view

        
        // delay for 0.5 seconds
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1.5 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
            if NSUserDefaults.standardUserDefaults().boolForKey("tutorial:seen") {
                self.goToMain()
            }
            else {
                self.goToMain()
            }
        }
        
        
        
        self.motivateMevideoPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        self.motivateMevideoPath = self.motivateMevideoPath.stringByAppendingString("/motivateMe.mov")
        isRatingVisible = false
        
        self.randomWorkOutIndex = NSMutableArray()
        
        if (NSFoundationVersionNumber > NSFoundationVersionNumber_iOS_6_1) {
            self.window!.tintAdjustmentMode = UIViewTintAdjustmentMode.Normal;
        }
        return true
    }

    func applicationWillResignActive(application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(application: UIApplication) {
      
        self.isAppJustOpen = true
        
        ////to shuffle wo in workout selection screen
        let currentViewController = self.getVisibleViewController(nil)
        
        if currentViewController != nil {
            
            currentViewController!.generaterandomWorkOut()
            
            if (currentViewController!.isKindOfClass(TrainingRequestViewController)) {
                
                let tController : TrainingRequestViewController = currentViewController as! TrainingRequestViewController
                tController.CollectionView.reloadData()
            }
        }
        
        if self.availtrainers != nil {
            self.availtrainers.getAvailableTrainer()
        }

    }

    func applicationWillEnterForeground(application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
    }

    func applicationDidBecomeActive(application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        FBSDKAppEvents.activateApp()
        
        
        if self.isAppJustOpen == true {
            self.checkForUserCurrentWorkoutStatus()
        }
        
        self.isAppJustOpen = false

    }

    func applicationWillTerminate(application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        // Saves changes in the application's managed object context before the application terminates.
        self.saveContext()
    }
    
    func application(application: UIApplication, openURL url: NSURL, sourceApplication: String?, annotation: AnyObject) -> Bool {
        
        return FBSDKApplicationDelegate.sharedInstance().application(application, openURL: url, sourceApplication: sourceApplication, annotation: annotation)

    }
    
    func application(application: UIApplication, didRegisterUserNotificationSettings notificationSettings: UIUserNotificationSettings) {
        
        let currentViewController = self.getVisibleViewController(nil)
        
        if (currentViewController != nil ){
            
            if (currentViewController!.isKindOfClass(MapViewController)) {
                let mController = currentViewController as! MapViewController
                mController.didClickRequest(UIButton())
            }
        }
        
     
        
    }
    
    
    func tabBar(tabBar: UITabBar, didSelectItem item: UITabBarItem) {
        print("Selected item")
    }
    
    // UITabBarControllerDelegate
    func tabBarController(tabBarController: UITabBarController, didSelectViewController viewController: UIViewController) {
        
        if tabBarController.selectedIndex == 1{
            
            UIApplication.sharedApplication().statusBarStyle = .Default
            let navCon : UINavigationController = viewController as! UINavigationController
            navCon.popToRootViewControllerAnimated(false)
            
        }
        else
        {
            
            let navCon : UINavigationController = viewController as! UINavigationController
            
            if (navCon.visibleViewController!.isKindOfClass(SettingsViewController) ||  navCon.visibleViewController!.isKindOfClass(TutorialViewController) ||  navCon.visibleViewController!.isKindOfClass(UserInfoViewController)){
                UIApplication.sharedApplication().statusBarStyle = .Default
                
            } else {
                UIApplication.sharedApplication().statusBarStyle = .LightContent
            }
            
        }
        
        
        
        
    }
    
    func tabBarController(tabBarController: UITabBarController, shouldSelectViewController viewController: UIViewController) -> Bool {
        
        let navCon : UINavigationController = viewController as! UINavigationController
        
        if navCon.topViewController!.isKindOfClass(RequestStatusViewController) || navCon.topViewController!.isKindOfClass(TrainerProfileViewController){
            return (viewController != tabBarController.selectedViewController)
        }
        
        return true
    }

    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "tech.bobbyren.TestCoreData" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls[urls.count-1]
        }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("Model", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
        }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("WeTrain.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: nil)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as! NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        return coordinator
        }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
    func refreshUser() {
        PFUser.currentUser()?.fetchInBackgroundWithBlock({ (user: PFObject?, error) -> Void in
            if error != nil {
                if let userInfo: [NSObject: AnyObject] = error!.userInfo {
                    let code = userInfo["code"] as! Int
                    print("code: \(code)")
                    
                    // if code == 209, invalid token; just display login
                    self.invalidLogin()
                }
            }
            else {
                if let client: PFObject = user!.objectForKey("client") as? PFObject {
                    client.fetchInBackground()
                }
            }
        })
    }

    func goToMain() {
        
        let controller: UIViewController?  = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("MainTabController") as UIViewController?
        
        let tabBarController : UITabBarController = controller as! UITabBarController
        tabBarController.delegate = self
        
        self.window?.rootViewController!.dismissViewControllerAnimated(true, completion: nil)
        self.window?.rootViewController!.presentViewController(controller!, animated: false, completion: nil)

       // self.window?.rootViewController = controller
       // self.window?.makeKeyAndVisible()
        
        ////move to map when app open from schedule reminder
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
            
            if self.scheduleRemiderInfo != nil
            {
                self.showConfirmFor_WorkoutReminder(self.scheduleRemiderInfo!)
                self.scheduleRemiderInfo == nil
            }
            
            else if self.pushNotificationUserInfo != nil
            {
                self.getDetailsfor_matchWorkOut(self.pushNotificationUserInfo!)
                self.pushNotificationUserInfo == nil
            }
        }
        
        self.checkForUserCurrentWorkoutStatus()
        Generals.showUIinconsistenciesAlert()

    }
    
    func goToTutorial() {
        let nav: UINavigationController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TutorialNavigationController") as! UINavigationController
        let controller: TutorialViewController = nav.viewControllers[0] as! TutorialViewController
        controller.delegate = self
        Generals.appRootController().presentViewController(nav, animated: true, completion: nil)
    }
    
    func showConfirmFor_WorkoutReminder(userinfo : NSDictionary) {
        
        if(PFUser.currentUser() == nil) {
            return
        }
        
        
        self.OptionType = "Train Later"
        let controller = self.scheduleConfirmationCon
        controller!.confirmationType    = confimationScreentype.FromWorkOutReminder;
        controller!.workOutReminderInfo = userinfo
        controller!.isRefresh = true
        
        Generals.ShowLoadingView()
        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        let mController: MapViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("MapViewController") as! MapViewController
        tabNabcontroller.pushViewController(mController, animated: true)
        controller!.parentController = mController
        
        var isCompletionCalledOnce = false

        Locationcompletion  = { (response) in
            
            if isCompletionCalledOnce == true {
                return
            }
            
            isCompletionCalledOnce = true
            
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(0 * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                
                controller?.fetchScheduleInfo({
                    (result: String) in
                    
                    print("Schedule fetched status: \(result)")
                    
                    /// to handle self confirmed request
                    if result == "differntUser"{
                        
                        var message :String!
                        
                        if controller!.requestedTrainingType != nil {
                            message = TRAINING_TITLES[controller!.requestedTrainingType!]
                        } else {
                            message = "Scheduled "
                        }
                        
                        message = message + " by differnt user."
                        ///If Schedule previously cancelled
                        let alert: UIAlertController = UIAlertController(title: "Message", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                        }))
                        Generals.appRootController().presentViewController(alert, animated: true, completion: nil)
                        alert.view.tintColor = UIColor.blackColor()

                        
                    }
                    else if result == ScheduleState.SelfConfirmed.rawValue || result == ScheduleState.Searching.rawValue{
                        
                        if PFUser.currentUser() != nil {
                            self.loadExistingRequest(true)
                        }
                        self.removeScheduleInfo_from_UserDefault(userinfo as! NSMutableDictionary)
                        
                    }
                    else if (result == ScheduleState.Canceled.rawValue)
                    {
                        
                        var message :String!
                        
                        if controller!.requestedTrainingType != nil {
                            message = TRAINING_TITLES[controller!.requestedTrainingType!]
                        } else {
                            message = "Schedule "
                        }
                        
                        message = message + " was cancelled previously."
                        ///If Schedule previously cancelled
                        let alert: UIAlertController = UIAlertController(title: "Message", message: message, preferredStyle: UIAlertControllerStyle.Alert)
                        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                        }))
                        Generals.appRootController().presentViewController(alert, animated: true, completion: nil)
                        alert.view.tintColor = UIColor.blackColor()
                    }
                    else
                    {
                        mController.showConfirmScreen(controller!)
                        self.removeScheduleInfo_from_UserDefault(userinfo as! NSMutableDictionary)
                        
                    }
                    
                    Generals.hideLoadingView()
                })
                
            }
            
        }
        

        
    }
    
    // MARK: - TutorialDelegate
    func didCloseTutorial() {
        self.refreshUser()
        self.goToMain()
    }
    
    func createClient() {
        let client: PFObject = PFObject(className: "Client")
        client.setObject(false, forKey: "checkedTOS")
        client.saveInBackgroundWithBlock({ (success, error) -> Void in
            PFUser.currentUser()!.setObject(client, forKey: "client")
            PFUser.currentUser()!.saveInBackgroundWithBlock({ (success, error) -> Void in
                if success {
                    self.goToMain()
                }
                else {
                    self.invalidLogin()
                }
            })
        })
    }
    
    func promptToCompleteSignup() {
        let alert: UIAlertController = UIAlertController(title: "Complete signup", message: "You have not finished creating your account. Would you like to do that now?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Setup account", style: .Default, handler: { (action) -> Void in
            self.goToUserProfile()
        }))
        alert.addAction(UIAlertAction(title: "Logout", style: .Default, handler: { (action) -> Void in
            self.logout()
        }))
        if self.window?.rootViewController?.presentedViewController != nil {
            self.window?.rootViewController?.presentedViewController?.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            Generals.appRootController().presentViewController(alert, animated: true, completion: nil)
        }
        alert.view.tintColor = UIColor.blackColor()

    }
    
    func goToLogin() {
        let controller: LoginViewController  = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        //Generals.appRootController().dismissViewControllerAnimated(true, completion: nil)
        Generals.appRootController().presentViewController(controller, animated: true, completion: nil)
    }
    
    func goToUserProfile() {
        let controller: UserInfoViewController = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("UserInfoViewController") as! UserInfoViewController
        controller.isSignup = true
        let nav: UINavigationController = UINavigationController(rootViewController: controller)
        Generals.appRootController().dismissViewControllerAnimated(true, completion: nil)
        Generals.appRootController().presentViewController(nav, animated: true, completion: nil)
        controller.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Logout", style: UIBarButtonItemStyle.Plain, target: self, action: "logout")
    }
    
    func logout() {
        PFUser.logOutInBackgroundWithBlock { (error) -> Void in
            self.goToLogin()
        }
    }
    
    func invalidLogin() {
        let alert = UIViewController.simpleAlert("Invalid user", message: "We could not log you in.", completion: { () -> Void in
            self.logout()
        })
        Generals.appRootController().presentViewController(alert, animated: true, completion: nil)
    }

    /// MARK: - Push
    func application(application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: NSData) {
        // Store the deviceToken in the current Installation and save it to Parse
        NSNotificationCenter.defaultCenter().postNotificationName("push:enabled", object: nil)
        let installation = PFInstallation.currentInstallation()
        installation.setDeviceTokenFromData(deviceToken)
        installation.addUniqueObject("Clients", forKey: "channels") // subscribe to trainers channel
        installation.saveInBackground()
        
        if PFUser.currentUser() != nil {
            installation.setObject(PFUser.currentUser()!.objectId!, forKey: "userId")
        }
        
        let channels = installation.objectForKey("channels")
        print("installation registered for remote notifications: token \(deviceToken) channel \(channels)")
    }
    
    func application(application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: NSError) {
        print("failed: error \(error)")
        NSNotificationCenter.defaultCenter().postNotificationName("push:enable:failed", object: nil)
    }
    
    
    /// MARK: - LocalNotification Delegate
    func application(application: UIApplication, didReceiveLocalNotification notification: UILocalNotification) {
        
        let appState = application.applicationState
        if appState == UIApplicationState.Active {
            
            if let userInfo = notification.userInfo {
                ///show default alert if user is in app for schedule reminder
                let alert: UIAlertController = UIAlertController(title: "Message", message: "Hey! It’s almost time to workout!", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Start", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                    self.showConfirmFor_WorkoutReminder(userInfo)
                }))
                
                Generals.appRootController()!.presentViewController(alert, animated: true, completion: nil)
                alert.view.tintColor = UIColor.blackColor()

                
            }
        } else {
            
            if let userInfo = notification.userInfo {
                self.showConfirmFor_WorkoutReminder(userInfo)
            }
        }
       
    }
    
    
    func getVideoPath () ->NSString {
        
        print(self.motivateMevideoPath)
        return self.motivateMevideoPath
    }
    
    func getAppThemeColor () ->UIColor {
        
        return UIColor(red: 83.0/255.0, green: 221.0/255.0, blue: 159.0/255.0, alpha:1)
    }
    
    func application(application: UIApplication, didReceiveRemoteNotification userInfo: [NSObject : AnyObject]) {
        print("notification received: \(userInfo)")
        
        let apsUserInfo : NSDictionary = userInfo["aps"] as! NSDictionary
        
        if let apnsType = userInfo["apnsType"] as! String?{
            
            if apnsType.characters.count > 0 {
                
                showAppUpdateAlert(apsUserInfo["alert"] as! String)
            }
            else
            {
                let time = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
                dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                    self.getDetailsfor_matchWorkOut(userInfo)
                }
            }
        }
        else
        {
            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(2 * Double(NSEC_PER_SEC)))
            dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                self.getDetailsfor_matchWorkOut(userInfo)
            }
        }
        
      
       
    }
    
    func getDetailsfor_matchWorkOut(userInfo: NSDictionary!){
        
        //get current workout and trainer for the client and then move to trainer profile
        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
            client.fetchInBackgroundWithBlock({ (object, error) -> Void in
                
                if let request: PFObject = client.objectForKey("workout") as? PFObject {
                    request.fetchInBackgroundWithBlock({ (requestObject, error) -> Void in
                        
                        if let state = request.objectForKey("status") as? String {
                            print("state \(state) object \(requestObject)")
                            
                            if state == RequestState.Matched.rawValue {
                                
                                if let trainer: PFObject = request.objectForKey("trainer") as? PFObject {
                                    trainer.fetchInBackgroundWithBlock({ (requestObject, error) -> Void in
                                        
                                        
                                        dispatch_async(dispatch_get_main_queue()) { () -> Void in
                                            
                                            let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
                                            tcon.selectedIndex = 0
                                            let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
                                            
                                            if (tabNabcontroller.visibleViewController?.isKindOfClass(TrainerProfileViewController)) == false{
                                                
                                                let tController: TrainerProfileViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TrainerProfileViewController") as! TrainerProfileViewController
                                                
                                                tController.request = request
                                                tController.trainer = trainer
                                                tabNabcontroller.visibleViewController?.navigationController!.pushViewController(tController, animated: true)
                                            }
                                        }
                                })}
                            }
                        }
                    })
                }
            })
        }
        
    }
    
    func getScheduleInfo_from_UserDefault() -> NSMutableArray {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if  let arrayOfSchedules = userDefaults.objectForKey("ScheduleInfo") {
            return arrayOfSchedules as! NSMutableArray
        }
        
        return NSMutableArray()
    }
    
    func removeScheduleInfo_from_UserDefault(dictionary : NSMutableDictionary!) {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if (userDefaults.objectForKey("ScheduleInfo") != nil) {
            
            if let arrayOfSchedules : NSMutableArray = (userDefaults.objectForKey("ScheduleInfo") as! NSMutableArray).mutableCopy() as? NSMutableArray {
                
                let array = arrayOfSchedules.valueForKey("scheduleInfoId")
                if array.containsObject(dictionary.objectForKey("scheduleInfoId")!) == true
                {
                    arrayOfSchedules.removeObjectAtIndex((array.indexOfObject(dictionary.objectForKey("scheduleInfoId")!)))
                }
                
                userDefaults.setObject(arrayOfSchedules, forKey:"ScheduleInfo")
                userDefaults.synchronize()
            }
            
        }
        

    }
    
    func loadExistingRequest(isShowLoading : Bool) {
        
        
        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
            
            if isShowLoading == true {
                Generals.ShowLoadingView()
            }

            
            client.fetchInBackgroundWithBlock({ (object, error) -> Void in
                if let request: PFObject = client.objectForKey("workout") as? PFObject {
                    request.fetchInBackgroundWithBlock({ (requestObject, error) -> Void in
                        
                        if isShowLoading == true {
                            Generals.hideLoadingView()
                        }
                        
                        if let state = request.objectForKey("status") as? String {
                            print("state \(state) object \(requestObject)")
                            
                            ////check for Rating
                            if state == RequestState.Complete.rawValue {
                                if request.objectId != nil {
                                    
                                    ///rating view not shown for client yet
                                    if request.objectForKey("clientRating") == nil{
                                        
                                        self.moveToTrainerProfile(request)

//                                        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
//                                        tcon.selectedIndex = 0
//                                        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
//                                        
//                                        tabNabcontroller.visibleViewController!.showRatingView()
                                    }
                                    
                                }
                            }
                            
                            if state == RequestState.Matched.rawValue {
                                //self.performSegueWithIdentifier("GoToRequestState", sender: nil)
                                self.moveToRequestState(request)

                            }
                            else if state == RequestState.Searching.rawValue {
                                if let time = request.objectForKey("time") as? NSDate {
                                    let minElapsed = NSDate().timeIntervalSinceDate(time) / 60
                                    if Int(minElapsed) > 60 { // cancel after 60 minutes of searching
                                        print("request cancelled")
                                        request.setObject(RequestState.Cancelled.rawValue, forKey: "status")
                                        request.saveInBackground()
                                    }
                                    else {
                                        //self.performSegueWithIdentifier("GoToRequestState", sender: nil)
                                        self.moveToRequestState(request)
                                    }
                                }
                            }
                            else if state == RequestState.Training.rawValue {
                                if let start = request.objectForKey("start") as? NSDate {
                                    let minElapsed = NSDate().timeIntervalSinceDate(start) / 60
                                    let length = request.objectForKey("length") as! Int
                                    print("started at \(start) time passed \(minElapsed) workout length \(length)")
                                    if Int(minElapsed) > length * 2 { // cancel after 2x the workout time
                                        print("completing training")
                                        request.setObject(RequestState.Complete.rawValue, forKey: "status")
                                        request.saveInBackground()
                                    }
                                    else {
                                        //self.performSegueWithIdentifier("GoToRequestState", sender: nil)
                                        self.moveToRequestState(request)

                                    }
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    
    func moveToRequestState(currentWorkoutRequest : PFObject){
        
        if Generals.appRootController() == nil{
            return;
        }
        
        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        
        
        if (tabNabcontroller.topViewController?.isKindOfClass(TrainerProfileViewController)) == false &&
            (tabNabcontroller.topViewController?.isKindOfClass(RequestStatusViewController)) == false {
                
                var requestStateCon : RequestStatusViewController!
                
                if let viewControllers : NSArray = tabNabcontroller.viewControllers {
                    for viewController in viewControllers {
                        // some process
                        if viewController.isKindOfClass(RequestStatusViewController) {
                            requestStateCon = viewController as! RequestStatusViewController
                        }
                    }
                }
                
                if requestStateCon != nil {
                    requestStateCon.currentRequest = currentWorkoutRequest
                    tabNabcontroller.popToViewController(requestStateCon, animated: true)
                } else {
                    
                    let rController: RequestStatusViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("RequestStatusViewController") as! RequestStatusViewController
                    rController.currentRequest = currentWorkoutRequest
                    tabNabcontroller.pushViewController(rController, animated: false)
                }
        }
    }
    
    
    func moveToTrainerProfile(currentWorkoutRequest : PFObject){
        
        if Generals.appRootController() == nil{
            return;
        }
        
        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        
        
        if (tabNabcontroller.topViewController?.isKindOfClass(TrainerProfileViewController)) == false &&
            (tabNabcontroller.topViewController?.isKindOfClass(RequestStatusViewController)) == false {
                
                var trainerProfile : TrainerProfileViewController!
                
                if let viewControllers : NSArray = tabNabcontroller.viewControllers {
                    for viewController in viewControllers {
                        // some process
                        if viewController.isKindOfClass(TrainerProfileViewController) {
                            trainerProfile = viewController as! TrainerProfileViewController
                        }
                    }
                }
                
                if trainerProfile != nil {
                    trainerProfile.request = currentWorkoutRequest
                    
                    if let trainer = currentWorkoutRequest.objectForKey("trainer") as? PFObject {
                        trainerProfile.trainer = trainer
                    }
                    
                    tabNabcontroller.popToViewController(trainerProfile, animated: true)
                } else {
                    
                    let rController: TrainerProfileViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TrainerProfileViewController") as! TrainerProfileViewController
                    rController.request = currentWorkoutRequest
                    
                    if let trainer = currentWorkoutRequest.objectForKey("trainer") as? PFObject {
                        rController.trainer = trainer
                    }
                    
                    tabNabcontroller.pushViewController(rController, animated: false)
                }
        }
    }
    
    
    func getVisibleViewController(let rootViewController: UIViewController?) -> UIViewController? {
        
        if(Generals.appRootController() != nil) {
            
            let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
            
            if let tabNabcontroller : UINavigationController = tcon.selectedViewController! as? UINavigationController {
                return tabNabcontroller.visibleViewController!
            }

        }
        
        
        return nil
    }
    
    func showAppUpdateAlert(var message : String!){
        
        if message.characters.count == 0 {
            message = "Your WeTrain app needs to be updated!"
        }
        
        let alert: UIAlertController = UIAlertController(title: "Message", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
        }))
        alert.addAction(UIAlertAction(title: "Update", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            
            let appStoreLink : NSURL = NSURL(string: "https://itunes.apple.com/us/app/wetrain/id1049915108?mt=8")!
            UIApplication.sharedApplication().openURL( appStoreLink )
            
        }))
        Generals.appRootController().presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()
        
    }
    
    func checkForUserCurrentWorkoutStatus() {
        
        
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(3 * Double(NSEC_PER_SEC)))
        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
            
            if (self.scheduleRemiderInfo == nil && self.pushNotificationUserInfo == nil && PFUser.currentUser() != nil){
                
                let SchedulesInfoArray = self.getScheduleInfo_from_UserDefault()
                let currentTimeStamp   = NSDate().timeIntervalSinceReferenceDate
                
                if SchedulesInfoArray.count > 0 {
                    
                    for schedule in SchedulesInfoArray {
                        
                        /// show confirm (if user enter between reminder time and selconfirm time)
                        //// 90 minutes for reminder notitication'
                        //// 60 minutes for self confirm
                        
                        var reminderTime : NSDate = schedule.objectForKey("scheduledTime") as! NSDate
                        reminderTime = reminderTime.dateByAddingTimeInterval( -(90 * 60))
                        let reminderTimeStamp : NSTimeInterval = reminderTime.timeIntervalSinceReferenceDate
                        
                        var selfConfirmTime : NSDate = schedule.objectForKey("scheduledTime") as! NSDate
                        selfConfirmTime = selfConfirmTime.dateByAddingTimeInterval( -(60 * 60))
                        let selfConfirmTimeTimeStamp : NSTimeInterval = selfConfirmTime.timeIntervalSinceReferenceDate
                        
                        if (currentTimeStamp > reminderTimeStamp  && currentTimeStamp < selfConfirmTimeTimeStamp){
                            
                            self.showConfirmFor_WorkoutReminder(schedule as! NSMutableDictionary)
                            break
                        }
                        
                        ///to remove the schedule info from userdefault
                        if (currentTimeStamp > reminderTimeStamp && currentTimeStamp > selfConfirmTimeTimeStamp){
                            self.removeScheduleInfo_from_UserDefault(schedule as! NSMutableDictionary)
                        }
                    }
                }
                else {
                }
            }
        }
        
        // load if any previous requset pending or process
        if (PFUser.currentUser() != nil && self.scheduleRemiderInfo == nil && self.pushNotificationUserInfo == nil){
            self.loadExistingRequest(false)
        }
    }
    
    static func isConnectedToNetwork() -> Bool {
        
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(sizeofValue(zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        let defaultRouteReachability = withUnsafePointer(&zeroAddress) {
            SCNetworkReachabilityCreateWithAddress(nil, UnsafePointer($0))
        }
        var flags = SCNetworkReachabilityFlags()
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability!, &flags) {
            return false
        }
        let isReachable = (flags.rawValue & UInt32(kSCNetworkFlagsReachable)) != 0
        let needsConnection = (flags.rawValue & UInt32(kSCNetworkFlagsConnectionRequired)) != 0
        return (isReachable && !needsConnection)
        
    }
    
    
}