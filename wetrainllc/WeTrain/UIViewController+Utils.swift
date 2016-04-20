//
//  UIViewController+Utils.swift
//  WeTrainers
//
//  Created by Bobby Ren on 9/24/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import Foundation
import UIKit
import Parse
import ParseFacebookUtilsV4
import FBSDKShareKit
import FBSDKLoginKit
import FBSDKCoreKit
import AssetsLibrary
import Photos
import TwitterKit
import MBProgressHUD
import EventKit


var file : NSFileHandle!
var moviePlayerStarted : Bool!
var callBackPlayerController : AnyObject!

extension NSMutableArray {
    func shuffle() {
        if count < 2 { return }
        for i in 0..<(count - 1) {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            swap(&self[i], &self[j])
        }
    }
}


protocol currentWODelegate:class {
    func currentWorkoutStatus(request: PFObject)
    func userNotHavingWorkout()

}

extension UIViewController {

    
    // for other classes like AppDelegate
    class func simpleAlert(title: String, message: String?, completion: (() -> Void)?) -> UIAlertController {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.view.tintColor = UIColor.blackColor()
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("cancel")
            if completion != nil {
                completion!()
            }
        }))
        return alert
    }

    func simpleAlert(title: String, defaultMessage: String?, error: NSError?) {
        if error != nil {
            if let msg = error!.userInfo["error"] as? String {
                self.simpleAlert(title, message: msg)
                return
            }
        }
        self.simpleAlert(title, message: defaultMessage)
    }
    
    func simpleAlert(title: String, message: String?) {
        self.simpleAlert(title, message: message, completion: nil)
    }
    
    func simpleAlert(title: String, message: String?, completion: (() -> Void)?) {
        let alert: UIAlertController = UIAlertController(title: title, message: message, preferredStyle: UIAlertControllerStyle.Alert)
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("cancel")
            if completion != nil {
                completion!()
            }
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }

    func appDelegate() -> AppDelegate {
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        return appDelegate
    }
    
    func isValidEmail(testStr:String) -> Bool {
        // http://stackoverflow.com/questions/25471114/how-to-validate-an-e-mail-address-in-swift
        let emailRegEx = "^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$"
        
        let emailTest = NSPredicate(format:"SELF MATCHES %@", emailRegEx)
        return emailTest.evaluateWithObject(testStr)
    }
    
    func setTitleBarColor(color: UIColor, tintColor: UIColor) {
        self.navigationController?.navigationBar.tintColor = tintColor
        self.navigationController?.navigationBar.backgroundColor = color
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        
        if color == UIColor.blackColor() {
            
            self.navigationController?.navigationBar.shadowImage = UIImage()

            UIApplication.sharedApplication().statusBarStyle = .LightContent
            let proxyViewForStatusBar : UIView = UIView(frame: CGRectMake(0, 0,self.view.frame.size.width, 20))
            proxyViewForStatusBar.backgroundColor=UIColor.blackColor()
            self.view.addSubview(proxyViewForStatusBar)
        }
        else
        {
            self.navigationController?.navigationBar.shadowImage = Generals.navbarImage()

            UIApplication.sharedApplication().statusBarStyle = .Default
            let proxyViewForStatusBar : UIView = UIView(frame: CGRectMake(0, 0,self.view.frame.size.width, 20))
            proxyViewForStatusBar.backgroundColor=UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
            self.view.addSubview(proxyViewForStatusBar)
        }
        
      
    }
    
    func userInfoSetTitleBarColor(color: UIColor, tintColor: UIColor) {
        self.navigationController?.navigationBar.tintColor = tintColor
        self.navigationController?.navigationBar.backgroundColor = color
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
    }
    
    
    /// to handel facebook signup/login
    
    func loginWithFacebook(callbackController : UIViewController! , isCheckedTos : Bool!){
        
        Generals.ShowLoadingView()

        
        PFFacebookUtils.logInInBackgroundWithReadPermissions(["public_profile","user_friends","email","user_about_me","user_birthday"]) {
            (user: PFUser?, error: NSError?) -> Void in
            if let user = user {
                
                if user.isNew {
                    
                    print("User signed up and logged in through Facebook!")
                    
                    //get user info frm facebook
                    if FBSDKAccessToken.currentAccessToken() != nil {
                        
                        FBSDKGraphRequest(graphPath: "me", parameters: ["fields": "id, name, first_name, last_name, email,age_range,birthday,picture.type(large),gender"]).startWithCompletionHandler({ (connection, result, error) -> Void in
                            
                            print("This logged in user: \(result)")
                            
                            if error == nil{
                                
                                    //create a new client for faceboook user
                                    let client: PFObject = PFObject(className: "Client")
                                
                                    /// calculate age from bithday
                                    let dFormatter = NSDateFormatter()
                                    dFormatter.dateFormat = "MM/dd/yyyy"
                                
                                
                                    if result.valueForKey("birthday") != nil {
                                        
                                        if let birthday = dFormatter.dateFromString(result.valueForKey("birthday") as! NSString as String) {
                                            
                                            let calendar : NSCalendar = NSCalendar.currentCalendar()
                                            let ageComponents = calendar.components(NSCalendarUnit.Year,
                                                fromDate: birthday,
                                                toDate: NSDate(),
                                                options: [])
                                            let age = ageComponents.year
                                            
                                            if age > 0 {
                                                client.setObject(String(format: "%d", age), forKey: "age")
                                            }
                                            
                                            if age > 18 {
                                                client.setObject(true, forKey: "checkedAgeAbove18")
                                            }
                                            
                                        }
                                        
                                    }
                                
                                
                                
                                    if result.valueForKey("first_name") != nil {
                                        client.setObject(result.valueForKey("first_name") as! NSString, forKey: "firstName")
                                    }
                                    if result.valueForKey("last_name") != nil {
                                        client.setObject(result.valueForKey("last_name") as! NSString, forKey: "lastName")
                                    }
                                    if result.valueForKey("gender") != nil {
                                        client.setObject(result.valueForKey("gender") as! NSString, forKey: "gender")
                                    }
                                
                                    if result.valueForKey("email") != nil {
                                        
                                        let email : String = result.valueForKey("email") as! String
                                        
                                        if email.characters.count > 0 {
                                            
                                            PFUser.currentUser()?.setObject(email, forKey: "email")
                                            PFUser.currentUser()?.saveInBackground()
                                        }
                                    }

                                
                                
                              
                                    print("profilePicture")
                                    print(result.valueForKey("picture")!.valueForKey("data")!.valueForKey("url") as! String)

                                    client.saveInBackgroundWithBlock({ (success, error) -> Void in
                                        
                                        PFUser.currentUser()!.setObject(client, forKey: "client")
                                        PFUser.currentUser()!.saveInBackgroundWithBlock({ (success, error) -> Void in
                                            
                                            if success == true {
                                                if let checkedUrl = NSURL(string: result.valueForKey("picture")!.valueForKey("data")!.valueForKey("url") as! String) {
                                                    self.downloadImage(checkedUrl)
                                                }
                                            }
                                            
                                          
                                            
                                            Generals.hideLoadingView()

                                            //// send status to signupcontroller
                                            if (callbackController.isKindOfClass(SignupViewController)){
                                                
                                                let con : SignupViewController = callbackController as! SignupViewController
                                                
                                                if success {
                                                    con.performSegueWithIdentifier("GoToUserInfo", sender: nil)
                                                } else {
                                                    con.signupError(error)
                                                }
                                            }
                                            
                                            
                                            //// send status to LoginViewController
                                            if (callbackController.isKindOfClass(LoginViewController)){
                                                
                                                let con : LoginViewController = callbackController as! LoginViewController
                                                
                                                if success {
                                                    
                                                    if con.navigationController == nil {
                                                        self.appDelegate().goToMain()
                                                    } else {
                                                        con.performSegueWithIdentifier("GoToUserInfo", sender: nil)
                                                    }
                                                    
                                                } else {
                                                    con.signupError(error)
                                                }
                                            }
                                            
                                            


                                        })
                                    })
                            }
                            else {
                                Generals.hideLoadingView()

                            }
                            

                        })
                    }
                    
                    
                } else {
                    
                    
                    //// send status to SignupViewController
                    if (callbackController.isKindOfClass(SignupViewController)){
                        
                        let con : SignupViewController = callbackController as! SignupViewController
                        con.loggedIn()
                    }

                    
                    //// send status to LoginViewController
                    if (callbackController.isKindOfClass(LoginViewController)){
                        
                        let con : LoginViewController = callbackController as! LoginViewController
                        
                        if con.navigationController == nil {
                            self.appDelegate().goToMain()
                        } else {
                            con.loggedIn()
                        }
                    }
                    
                    
                     Generals.hideLoadingView()

                    print("User logged in through Facebook!")
                }
            } else {
                print("Uh oh. The user cancelled the Facebook login.")
                print(error)
                
                 Generals.hideLoadingView()

            }
        }
    }
    
    func getDataFromUrl(url:NSURL, completion: ((data: NSData?, response: NSURLResponse?, error: NSError? ) -> Void)) {
        NSURLSession.sharedSession().dataTaskWithURL(url) { (data, response, error) in
            completion(data: data, response: response, error: error)
            }.resume()
    }
    
    func downloadImage(url: NSURL){
        
        print("Download Started")
        print("lastPathComponent: " + (url.lastPathComponent ?? ""))
        getDataFromUrl(url) { (data, response, error)  in
            dispatch_async(dispatch_get_main_queue()) { () -> Void in
                guard let data = data where error == nil else { return }
                print(response?.suggestedFilename ?? "")
                print("Download Finished")
                
                
                 let clientObject: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
                 let file: PFFile = PFFile(name: "profile.jpg", data: data)!
                 clientObject.setObject(file, forKey: "photo")
                 clientObject.saveInBackgroundWithBlock { (success, error) -> Void in
                   
                    print("Profile image uploaded from facebook")
                    print(error)

                }

            }
        }
    }
    
    func upLoadVideo(request : PFObject) { /// move this function trainer app
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let dataPath = documentsDirectory.stringByAppendingPathComponent("motivateMe.mov")
        
        let filePath = NSURL(fileURLWithPath: dataPath)
        
        let dataToUpload : NSData = NSData(contentsOfURL: filePath)!
        
        let videoFile = PFFile(name: "motivateMe.mov", data: dataToUpload)
        
        let client: PFObject = request.objectForKey("client") as! PFObject
        
        client.fetchIfNeededInBackgroundWithBlock({ (object, error) -> Void in
            
            if let request: PFObject = client.objectForKey("motivateMe") as? PFObject {
                
                request.setObject(VideoRequestState.VideoUploadedStart.rawValue, forKey: "status")
                
                //change status only
                request.saveInBackground()
                
                //upload recorded video and change staus
                videoFile?.saveInBackgroundWithBlock({ (uploadsuccess, error : NSError?) -> Void in
                    
                    if uploadsuccess {
                        request.setObject(videoFile!, forKey: "video")
                        request.setObject(VideoRequestState.VideoUploaded.rawValue, forKey: "status")
                        request.saveInBackground()
                        
                    }else {
                    }
                    print("uploadvideo error : \(error)")
                    
                    }, progressBlock: ({ (percentDone : CInt) -> Void in
                        
                        //self.labelMessage.text = "\(percentDone)" + "%"
                        print("motivate video upload \(percentDone)" + "%")
                        
                    }))
                
            }
            
        })
        
              
    }
    
    func downloadAndSaveMotivateMeVideo (callbackController : AnyObject) {
        
//        callBackPlayerController = callbackController
//        self.downloadVideo()
//        return
        
        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        if let request: PFObject = client.objectForKey("motivateMe") as? PFObject {
            
            let videoFile : PFFile  = request.objectForKey("video") as! PFFile
            
            videoFile.getDataInBackgroundWithBlock(({
                
                (VideoData: NSData?, error: NSError?) -> Void in
                
                if VideoData != nil {
                    
                    var videoPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
                    videoPath = videoPath.stringByAppendingString("/motivateMe.mov")
                    VideoData!.writeToFile(videoPath, atomically: true)
                    
                    ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(NSURL(fileURLWithPath: videoPath), completionBlock: { (assetURL:NSURL!, error:NSError!) -> Void in
                        
                        ALAssetsLibrary().addAssetURL(assetURL, toAlbum: "WeTrain", withCallback: nil)
                        
                        if (callbackController.isKindOfClass(VideoDetailViewController)){
                            
                            let con : VideoDetailViewController = callbackController as! VideoDetailViewController
                            con.videoDownloaded(error,assetURL: assetURL)
                        }
                        
                        if (callbackController.isKindOfClass(ShareViewController)){
                            
                            if (self.appDelegate().videoShareTo == 1) {
                                self.shareVideoOnFacebook()
                            }

                        }
                        
                    })

                }
                
                
            }), progressBlock: ({ (percentDone : CInt) -> Void in
                
            }))
            
            
        }
    }

    
    func downloadVideo(){
        
        let filemanager = NSFileManager.defaultManager()
        
        if filemanager.fileExistsAtPath(self.appDelegate().getVideoPath() as String) {
            
            do {
                try  filemanager.removeItemAtPath(self.appDelegate().getVideoPath() as String)
                
            }catch {
                // Error - handle if required
            }

        }
        
        file = NSFileHandle(forWritingAtPath: self.appDelegate().getVideoPath() as String)

        if file == nil {
            
           filemanager.createFileAtPath(self.appDelegate().getVideoPath() as String, contents: nil, attributes: nil)
           file = NSFileHandle(forWritingAtPath: self.appDelegate().getVideoPath() as String)
        }
        
        moviePlayerStarted = false
        
        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        if let request: PFObject = client.objectForKey("motivateMe") as? PFObject {
            
            let videoFile : PFFile  = request.objectForKey("video") as! PFFile
            
            
            let urlPath: String = videoFile.url!
            let url: NSURL = NSURL(string: urlPath)!
            let request: NSURLRequest = NSURLRequest(URL: url)
            let connection: NSURLConnection = NSURLConnection(request: request, delegate: self, startImmediately: true)!
            connection.start()
        }
    }
    
    func connection(connection: NSURLConnection!, didReceiveData data: NSData!){
        
        file!.seekToEndOfFile()
        file!.writeData(data)
        
        if moviePlayerStarted == false {
            
            if (callBackPlayerController.isKindOfClass(VideoRequsestStatusViewController)){
                
                let con : VideoRequsestStatusViewController = callBackPlayerController as! VideoRequsestStatusViewController
                con.playMotivateMeVideo(true)
            }
            
            
            moviePlayerStarted = true
        }
    }
    
    
    func connectionDidFinishLoading(connection: NSURLConnection!)
    {
        file!.closeFile()
        
        var videoPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        videoPath = videoPath.stringByAppendingString("/motivateMe.mov")
        
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(NSURL(fileURLWithPath: videoPath), completionBlock: { (assetURL:NSURL!, error:NSError!) -> Void in
            
            ALAssetsLibrary().addAssetURL(assetURL, toAlbum: "WeTrain", withCallback: nil)
            
        })
    }
    
    
    func shareVideoOnFacebook () {
        
        var videoPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        videoPath = videoPath.stringByAppendingString("/motivateMe.mov")
        
        let videoData : NSData = NSData(contentsOfFile: videoPath)!
        let paramDict : NSMutableDictionary = NSMutableDictionary()
        paramDict.setObject(videoData, forKey: "video.mov")
        
        let graphRequest : FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/videos", parameters: paramDict as [NSObject : AnyObject], HTTPMethod: "POST")
        
        graphRequest.startWithCompletionHandler { (connection : FBSDKGraphRequestConnection!, result : AnyObject!, error : NSError!) -> Void in
            
            if error == nil {
                
                print("Friends are : \(result)")
                
            } else {
                
                print("Error Getting Friends \(error)");
                
            }
        }
        
    }
    
    func shareVideoOnTwitter (request : PFObject , mediaUrl : NSURL , controller : ShareViewController) {
        
        if Twitter.sharedInstance().session() == nil {
            
            Twitter.sharedInstance().logInWithCompletion {
                (session, error) -> Void in
                if (session != nil) {
                    
                } else {
                    
                    print("error: \(error!.localizedDescription)")
                }
            }
        } else {
           self.postVideo()
        }
    }
    
  
    
    func postVideo() {
        
        var videoPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
        videoPath = videoPath.stringByAppendingString("/motivateMe.mov")
        
        let video : NSData = NSData(contentsOfFile: videoPath)!
        
        let strUploadUrl = "https://upload.twitter.com/1.1/media/upload.json"
        let strStatusUrl = "https://api.twitter.com/1.1/statuses/update.json"
        
        
        var client = Twitter.sharedInstance().APIClient
        let text: String = "Testing Video"
        let videoLength: String = "\(video.length)"
        
        var initError: NSError?
        var message = ["status": text, "command" : "INIT", "media_type" : "video/m4v", "total_bytes" : videoLength]
        let preparedRequest: NSURLRequest = client.URLRequestWithMethod("POST", URL: strUploadUrl, parameters: message, error: &initError)
        client.sendTwitterRequest(preparedRequest, completion: { (urlResponse: NSURLResponse?, responseData: NSData?, error: NSError?) -> Void in
            if error == nil {
                var jsonError: NSError?
                
                 var json: NSDictionary!
                do {
                    json = try NSJSONSerialization.JSONObjectWithData(responseData!, options: []) as! [String:AnyObject]
                    // use anyObj here
                } catch {
                    print("json error: \(error)")
                }
                
                print(json)
                let mediaID = json.objectForKey("media_id_string") as! String
                
                client = Twitter.sharedInstance().APIClient
                var uploadError: NSError?
                let videoString = video.base64EncodedStringWithOptions([])
                message = ["command" : "APPEND", "media_id" : mediaID, "segment_index" : "0", "media" : videoString]
                let preparedRequest = client.URLRequestWithMethod("POST", URL: strUploadUrl, parameters: message, error: &uploadError)
                client.sendTwitterRequest(preparedRequest, completion: { (urlResponse: NSURLResponse?, responseData: NSData?, error: NSError?) -> Void in
                    if error == nil {
                        client = Twitter.sharedInstance().APIClient
                        var finalizeError: NSError?
                        message = ["command":"FINALIZE", "media_id": mediaID]
                        let preparedRequest = client.URLRequestWithMethod("POST", URL: strUploadUrl, parameters: message, error: &finalizeError)
                        client.sendTwitterRequest(preparedRequest, completion: { (urlResponse: NSURLResponse?, responseData: NSData?, error: NSError?) -> Void in
                            if error == nil {
                                client = Twitter.sharedInstance().APIClient
                                var sendError: NSError?
                                let message = ["status": text, "wrap_links": "true", "media_ids": mediaID]
                                var updateMessage = NSMutableDictionary(dictionary: message)
                                let preparedRequest = client.URLRequestWithMethod("POST", URL: strStatusUrl, parameters: message , error: &sendError)
                                client.sendTwitterRequest(preparedRequest, completion: { (urlResponse: NSURLResponse?, responseData: NSData?, error: NSError?) -> Void in
                                    
                                })
                            } else {
                                print("Command FINALIZE failed \n \(error!)")
                            }
                        })
                    } else {
                        print("Command APPEND failed")
                    }
                })
            } else {
                print("Command INIT failed")
            }
        })
        
    }
    
    
    func showRatingView(){
        
        if self.appDelegate().isRatingVisible == false {
            
            self.appDelegate().isRatingVisible = true
            
            let ratingView:RatingView = RatingView.getView() as! RatingView
            ratingView.appdelegate = self.appDelegate()
            
            ratingView.frame = CGRectMake((self.appDelegate().window?.frame.origin.x)!, (self.appDelegate().window?.frame.size.height)!, (self.appDelegate().window?.frame.size.width)!, (self.appDelegate().window?.frame.size.height)!)
            
            self.appDelegate().window?.addSubview(ratingView)
            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                
                ratingView.frame = CGRectMake((self.appDelegate().window?.frame.origin.x)!, (self.appDelegate().window?.frame.origin.y)!, (self.appDelegate().window?.frame.size.width)!, (self.appDelegate().window?.frame.size.height)!)
                
                self.view.layoutIfNeeded()
                }, completion: nil)
        
        }
        
    }
    
    func setScheduleInfo_in_UserDefault(dictionary : NSMutableDictionary!){
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        var arrayOfSchedules : NSMutableArray!
        if userDefaults.objectForKey("ScheduleInfo") == nil
        {
            arrayOfSchedules = NSMutableArray(object: dictionary)
        }
        else {
            
            arrayOfSchedules  = (userDefaults.objectForKey("ScheduleInfo") as! NSMutableArray).mutableCopy() as! NSMutableArray
            let array = arrayOfSchedules.valueForKey("scheduleInfoId")
            if array.containsObject(dictionary.objectForKey("scheduleInfoId")!) == true
            {
                arrayOfSchedules.replaceObjectAtIndex( (array.indexOfObject(dictionary.objectForKey("scheduleInfoId")!)), withObject: dictionary)
            }
            else
            {
                arrayOfSchedules.addObject(dictionary)
            }
        }
        
        userDefaults.setObject(arrayOfSchedules, forKey:"ScheduleInfo")
        userDefaults.synchronize()
    }
    
    
    func getScheduleInfo_from_UserDefault() -> NSMutableArray {
        
        let userDefaults = NSUserDefaults.standardUserDefaults()
        
        if  let arrayOfSchedules = userDefaults.objectForKey("ScheduleInfo") {
            return arrayOfSchedules as! NSMutableArray
        }
        
        return NSMutableArray()
    }
    
    // push
    func hasPushEnabled() -> Bool {
        if !UIApplication.sharedApplication().isRegisteredForRemoteNotifications() {
            return false
        }
        let settings = UIApplication.sharedApplication().currentUserNotificationSettings()
        if (settings?.types.contains(.Alert) == true){
            return true
        }
        else {
            return false
        }
    }
    
    
    
    func generaterandomWorkOut(){
        
        self.appDelegate().randomWorkOutIndex.removeAllObjects()
        self.appDelegate().randomWorkOutIndex = NSMutableArray(objects: NSNumber(int: 0), NSNumber(int: 1), NSNumber(int: 2), NSNumber(int: 3), NSNumber(int: 4), NSNumber(int: 5))
        
        self.appDelegate().randomWorkOutIndex.shuffle()

    }
    
    func moveToScheduleScreen(){
        
        let controller: ScheduleConfirmationViewController = self.appDelegate().scheduleConfirmationCon!
        controller.confirmationType == confimationScreentype.None
        controller.CurrentScheduleInfo = nil
        self.appDelegate().ScheduleTime = nil
        
        self.appDelegate().OptionType = "Train Later"

        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        tabNabcontroller.popToRootViewControllerAnimated(false)

        
        var ScheduleViewCon : UIViewController!
        
        if let viewControllers : NSArray = tabNabcontroller.viewControllers {
            for viewController in viewControllers {
                // some process
                if viewController.isKindOfClass(ScheduleViewController) {
                    ScheduleViewCon = viewController as! UIViewController
                }
            }
        }
        
        if ScheduleViewCon != nil {
            tabNabcontroller.popToViewController(ScheduleViewCon, animated: true)
        } else {
            
            let sController: ScheduleViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ScheduleViewController") as! ScheduleViewController
            
            tabNabcontroller.pushViewController(sController, animated: false)
        }

    }
    
    func warnForLocationPermission() {
        let message: String = "WeTrain needs GPS access to find trainers near you. Please go to your phone settings to enable location access. Go there now?"
        let alert: UIAlertController = UIAlertController(title: "Could not access location", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }
    
    func checkAndAskForCalendarPermission() -> Bool {
        let type = EKEntityType.Event
        let stat = EKEventStore.authorizationStatusForEntityType(type)
        switch stat {
        case .Authorized:
            return true
        case .NotDetermined:
                self.requestPermisssionForCalenadar()
            return false
        case .Restricted:
            return true
        case .Denied:
            return true
        }
    }
    
    func requestPermisssionForCalenadar() {
        
        let eventStore = EKEventStore()
        eventStore.requestAccessToEntityType(EKEntityType.Event, completion: {
            granted, error in
            
            if !granted
            {
//                let message: String = "WeTrain needs Calendar access to save schedules. Please go to your phone settings to enable Calendar access. Go there now?"
//                let alert = UIAlertController(title: "Could not access Calendar", message: message, preferredStyle: .Alert)
//                alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
//                alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: {
//                    _ in
//                    let url = NSURL(string:UIApplicationOpenSettingsURLString)!
//                    UIApplication.sharedApplication().openURL(url)
//                }))
//                self.presentViewController(alert, animated:true, completion:nil)
//                alert.view.tintColor = UIColor.blackColor()
            }
            
        })
    }
    
    
    func getCurrentWorkOutStatus(isShowLoading : Bool,callBackcontroller : currentWODelegate){
        
        if PFUser.currentUser() == nil {
            callBackcontroller.userNotHavingWorkout()
            return

        }
        
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
                        
                        if (requestObject == nil) {
                            
                            callBackcontroller.userNotHavingWorkout()
                            
                        } else {
                            
                            callBackcontroller.currentWorkoutStatus(requestObject!)
                        }
                        
                        
                    })
                }
                else
                {
                    callBackcontroller.userNotHavingWorkout()

                }
            })
        }
        else
        {
            callBackcontroller.userNotHavingWorkout()
        }
        

    }
    
    
    func setRemoteNotificationPermissionShown (){
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "remoteNotificationPermissionShown")
    }
    
    
    func getRemoteNotificationPremissionStatus () -> Bool {
        return  NSUserDefaults.standardUserDefaults().boolForKey("remoteNotificationPermissionShown")
    }
    
    
   
    
    
      
}