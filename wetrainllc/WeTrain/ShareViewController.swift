//
//  ShareViewController.swift
//  WeTrain
//
//  Created by Sempercon on 06/01/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import FBSDKShareKit
import FBSDKLoginKit
import FBSDKCoreKit

class ActivityViewCustomActivity: UIActivity {
    
    var customActivityType = ""
    var activityName = "TitterTest"
    var activityImageName = ""
    var customActionWhenTapped:( (Void)-> Void)!
    
    init(title: String, imageName:String, performAction: (() -> ()) ) {
        self.activityName = title
        self.activityImageName = imageName
        self.customActivityType = "Action \(title)"
        self.customActionWhenTapped = performAction
        super.init()
    }
    
    override func activityType() -> String? {
        return customActivityType
    }
    
    override func activityTitle() -> String? {
        return activityName
    }
    
    override func activityImage() -> UIImage? {
        return UIImage(named: activityImageName)
    }
    
    override func canPerformWithActivityItems(activityItems: [AnyObject]) -> Bool {
        return true
    }
    
    override func prepareWithActivityItems(activityItems: [AnyObject]) {
        // nothing to prepare
    }
    
    override func activityViewController() -> UIViewController? {
        return nil
    }
    
    override func performActivity() {
        customActionWhenTapped()
    }
}


class ShareViewController: UIViewController ,FBSDKLoginButtonDelegate, UINavigationControllerDelegate,FBSDKSharingDelegate {
    
    var mediaUrl : NSURL!
    var currentRequest: PFObject!
    
    override func viewDidLoad() {
        
//        let string: String = "WeTrain"
//        
//        let URL: NSURL =  NSURL(string: "http://files.parsetfss.com/2e37ac67-b582-46b2-89a5-dfcbf0c8190b/tfss-2663d232-3323-445b-a493-980a16e014d6-motivateMe.mov")!
//        
//        let myCustomActivity = ActivityViewCustomActivity(title: "Mark Selected", imageName: "removePin") {
//            print("Do something")
//            
//            var videoPath = NSSearchPathForDirectoriesInDomains(.CachesDirectory, .UserDomainMask, true)[0]
//            videoPath = videoPath.stringByAppendingString("/motivateMe.mov")
//            
//            
//            
//            var video:NSData = NSData()
//            ALAssetsLibrary().assetForURL(NSURL(string: "assets-library://asset/asset.mov?id=AC931052-4FEA-48CC-9719-14483A479B8A&ext=mov"), resultBlock: { (asset : ALAsset!) -> Void in
//                if let rep : ALAssetRepresentation = asset.defaultRepresentation(){
//                    
//                    var error: NSError?
//                    let length = Int(rep.size())
//                    let from = Int64(0)
//                    let data = NSMutableData(length: length)!
//                    let numRead = rep.getBytes(UnsafeMutablePointer(data.mutableBytes), fromOffset: from, length: length, error: &error)
//                    
//                    video = data
//                    
//                    SocialVideoHelper.uploadTwitterVideo(data, comment: "test", account: nil, withCompletion: nil)
//                    
//                }
//                }){ (error : NSError!) -> Void in
//            }
//            
//            
//            // Generals.shareOnTwiiterFromView(self, userTitle: "Twitter", shareURL: "http://files.parsetfss.com/2e37ac67-b582-46b2-89a5-dfcbf0c8190b/tfss-2663d232-3323-445b-a493-980a16e014d6-motivateMe.mov")
    }
    
    // MARK: - Button Action
    @IBAction func didClickShare(button: UIButton) {
        
        
        if button.tag == 1{
            
            FBSDKProfile.enableUpdatesOnAccessTokenChange(true)
            if FBSDKAccessToken.currentAccessToken() != nil{
                
                self.downloadAndSaveMotivateMeVideo(self)
                appDelegate().videoShareTo = 1
                
            } else {
                
                let loginView : FBSDKLoginButton = FBSDKLoginButton()
                self.view.addSubview(loginView)
                loginView.center = self.view.center
                loginView.readPermissions = ["public_profile", "email", "user_friends"]
                loginView.delegate = self
                
            }
            
          
            
//            var paramDict : NSMutableDictionary = NSMutableDictionary()
//            
//            paramDict.setObject(videoData, forKey: "video.mov")
//            
//            let graphrequset :FBSDKGraphRequest = FBSDKGraphRequest(graphPath: "me/videos", parameters: paramDict)
//            
//            graphrequset.startWithCompletionHandler(^(connection : FBSDKGraphRequestConnection, result :id , error : NSError ) {
//                
//                print(error)
//                
//                }
//            )
            
            
        } else if button.tag == 2{
            
            appDelegate().videoShareTo = 2

            
        } else if button.tag == 3{
            
            appDelegate().videoShareTo = 3

            
        }
    }
    
    
    
    // Facebook Delegate Methods
    
    func loginButton(loginButton: FBSDKLoginButton!, didCompleteWithResult result: FBSDKLoginManagerLoginResult!, error: NSError!) {
        print("User Logged In")
        
        if ((error) != nil)
        {
            // Process error
        }
        else if result.isCancelled {
            // Handle cancellations
        }
        else {
            // If you ask for multiple permissions at once, you
            // should check if specific permissions missing
            if result.grantedPermissions.contains("email")
            {
                // Do work
            }
        }
        
    }
    
    func loginButtonDidLogOut(loginButton: FBSDKLoginButton!) {
        print("User Logged Out")
    }
    
    
    func sharer(sharer: FBSDKSharing!, didCompleteWithResults results: [NSObject : AnyObject]!) {
        
    }
    
    func sharerDidCancel(sharer: FBSDKSharing!) {
        
    }
    
    func sharer(sharer: FBSDKSharing!, didFailWithError error: NSError!) {
        
    }
    

}
