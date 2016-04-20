//
//  RatingView.swift
//  WeTrain
//
//  Created by Sempercon on 19/01/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

////check for Rating
class RatingView : UIView {
    
    @IBOutlet var titlelbl : UILabel!
    @IBOutlet var ratinglbl : UILabel!
    @IBOutlet var ratingStarControl : HCSStarRatingView!
    @IBOutlet var commentsTxt : UITextField!

    var CurrentWORating : PFObject?
    var appdelegate : AppDelegate?

    static func getView() -> UIView {
        return NSBundle.mainBundle().loadNibNamed("RatingView", owner: nil, options: nil)[0] as! UIView
    }
    
    
    // MARK: - VIEW DELEGATES
    
    override func drawRect(rect: CGRect) {
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        
//        //done button for keyboard
//        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
//        doneToolbar.barStyle = UIBarStyle.BlackTranslucent
//        
//        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
//        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("doneButtonAction"))
//        
//        let items = NSMutableArray()
//        items.addObject(flexSpace)
//        items.addObject(done)
//        
//        doneToolbar.items = [flexSpace,done]
//        doneToolbar.sizeToFit()
//        
//        self.commentsTxt!.inputAccessoryView = doneToolbar
    }
    
    
    
    // MARK: - BUTTON ACTIONS
    
    @IBAction func didClickSubmit() {
        
        if (self.ratingStarControl.value == 0) {
            
            let alert: UIAlertController = UIAlertController(title: "Message", message: "Please enter a rating", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            }))
            Generals.appRootController().presentViewController(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.blackColor()

            
        } else {
            self.updateRating(true)
        }
        
    }
    
    @IBAction func didClickLater() {
        self.updateRating(false)
    }
    
    @IBAction func didChangeRating() {
        
        if self.ratingStarControl.value < 0 {
            self.ratinglbl.text = ""
        } else if self.ratingStarControl.value > 1 {
            self.ratinglbl.text = "\(self.ratingStarControl.value)" + " Stars!!"
        } else {
            
            self.ratinglbl.text = "\(self.ratingStarControl.value)" + " Star!!"
        }
        
        self.ratinglbl.text = self.ratinglbl.text?.stringByReplacingOccurrencesOfString(".0", withString: "")
    }
    
    
    // MARK: - CUSTOM METHODS

    func updateRating(isRated : Bool){
        
        self.dismissRatingView()
        
        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        
        if let woRequest: PFObject = client.objectForKey("workout") as? PFObject {
            
         woRequest.fetchInBackgroundWithBlock({ (woRequest, error) -> Void in
            
            ///get trainer's user object
            if let trainer: PFObject = woRequest!.objectForKey("trainer") as? PFObject {
                trainer.fetchInBackgroundWithBlock({ (object, error) -> Void in
                    
                    if let User: PFObject = object!.objectForKey("user") as? PFObject {
                        User.fetchInBackgroundWithBlock({ (Userobject, error) -> Void in
                            
                            if error == nil{
                                
                                let dict: [String: AnyObject] = [String: AnyObject]()
                                
                                let request: PFObject
                                
                                if self.CurrentWORating != nil
                                {
                                    request = self.CurrentWORating!
                                }
                                else
                                {
                                    request = PFObject(className: "Ratings", dictionary: dict)
                                }
                                
                                if isRated == true
                                {
                                    request.setObject(self.ratingStarControl.value, forKey: "rating")
                                    request.setObject(self.commentsTxt.text!, forKey: "comments")
                                    request.setObject(RatingState.Rated.rawValue, forKey: "status")
                                }
                                else
                                {
                                    request.setObject(NSNumber(int: 0), forKey: "rating")
                                    request.setObject(RatingState.MayBeLater.rawValue, forKey: "status")
                                }
                                
                                request.setObject("trainer", forKey: "ratingForUserRole")
                                request.setObject(woRequest!, forKey: "workout")
                                request.setObject(PFUser.currentUser()!, forKey: "ratedUser")
                                request.setObject(Userobject!, forKey: "ratingFor")
                                
                                if TESTING == 1
                                {
                                    request.setObject(true, forKey: "testing")
                                }
                                
                                print("request: \(request)")
                                request.saveInBackgroundWithBlock { (success, error) -> Void in
                                print("saved: \(success)")
                                    self.appdelegate!.isRatingVisible = false

                                    if success
                                    {
                                        woRequest!.setObject(request, forKey: "clientRating")
                                        woRequest!.saveInBackground()
                                    }
                                    else
                                    {
                                        let message = "There was an issue on saving. Please try again."
                                        let navCon : UINavigationController = self.window?.rootViewController as! UINavigationController
                                        navCon.visibleViewController!.simpleAlert("Could not save workout", defaultMessage: message, error: error)
                                        print("error: \(error)")
                                        
                                    }
                                }
                            }
                        })
                    }
                })
            }
                
      })}

        
    }
    
    
    func dismissRatingView(){
        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        
        if (tabNabcontroller.topViewController!.isKindOfClass(TrainerProfileViewController)) {
            
            let trainerprofile : TrainerProfileViewController = tabNabcontroller.topViewController as! TrainerProfileViewController
            trainerprofile.close()
            
        }
        
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.frame =  CGRectMake(self.frame.origin.x, self.frame.size.height, self.frame.size.width, self.frame.size.height)
            
            self.layoutIfNeeded()
            }, completion: {_ in
                
                self.removeFromSuperview()
                
        })

        
       
    }
    
    // MARK: - UITEXTFEILD DELEGATE
    
    func keyboardWillShow(sender: NSNotification) {
        
        if (UIScreen.mainScreen().bounds.height <= 480) {
            self.frame.origin.y -= 200
        }else{
            
            self.frame.origin.y -= 100
        }
    }
    
    func keyboardWillHide(sender: NSNotification) {
        
        if (UIScreen.mainScreen().bounds.height <= 480) {
            self.frame.origin.y += 200
        }else {
            
            self.frame.origin.y += 100
        }
    }
    
    func textFieldDidBeginEditing(textField: UITextField) {
        
        
    }
    
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()
        return true
    }
    
    func doneButtonAction()
    {
        self.commentsTxt.resignFirstResponder()
    }


}