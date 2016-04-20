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
import AssetsLibrary
import Photos


var file : NSFileHandle!

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
        alert.view.tintColor = UIColor.blackColor()
        alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            print("cancel")
            if completion != nil {
                completion!()
            }
        }))
        self.presentViewController(alert, animated: true, completion: nil)
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
        self.navigationController?.navigationBar.shadowImage = UIImage()
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

    
    func showRatingView(){
        
        if self.appDelegate().isRatingVisible == false {
            
            self.appDelegate().isRatingVisible = true
            let ratingView : RatingView = RatingView.getView() as! RatingView
            ratingView.appdelegate = self.appDelegate()
            ratingView.frame = CGRectMake((self.appDelegate().window?.frame.origin.x)!, (self.appDelegate().window?.frame.size.height)!, (self.appDelegate().window?.frame.size.width)!, (self.appDelegate().window?.frame.size.height)!)
            
            let navCon : UINavigationController = self.appDelegate().window?.rootViewController! as! UINavigationController

            navCon.view.addSubview(ratingView)
            
            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                
                ratingView.frame = CGRectMake((self.appDelegate().window?.frame.origin.x)!, (self.appDelegate().window?.frame.origin.y)!, (self.appDelegate().window?.frame.size.width)!, (self.appDelegate().window?.frame.size.height)!)
                
                self.view.layoutIfNeeded()
                }, completion: nil)

        }
        
    }
    

   
    
  
}