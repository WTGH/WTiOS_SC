//
//  RequestStatusViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 8/17/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD

typealias RequestStatusButtonHandler = () -> Void

class RequestStatusViewController: UIViewController {

    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var buttonTop: UIButton!
    @IBOutlet weak var buttonBottom: UIButton!
    
    @IBOutlet weak var imageViewBG: UIImageView!
    
    @IBOutlet weak var constraintDetailsHeight: NSLayoutConstraint!
    
    @IBOutlet weak var progressView: ProgressView!
    
    var state: RequestState = .NoRequest
    var currentRequest: PFObject?
    var currentTrainer: PFObject?
    
    var timer: NSTimer?

    var topButtonHandler: RequestStatusButtonHandler? = nil
    var bottomButtonHandler: RequestStatusButtonHandler? = nil
    
    var trainerController: TrainerProfileViewController? = nil
    var goingToTrainer: Bool = false
    var bgImageIndex = 1
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        //let index = arc4random_uniform(3)+1
        self.imageViewBG.image = UIImage(named: "bg_workout\(bgImageIndex)")!
        
        self.title = "Searching for a Trainer"

        if let previousState: String = self.currentRequest?.objectForKey("status") as? String{
            let newState: RequestState = RequestState(rawValue: previousState)!
            if newState == RequestState.Matched || newState == RequestState.Training {
                self.goToTrainerInfo()
                return
            }
            else {
                self.updateRequestState()
                
                
                ////check for Rating
                if newState == RequestState.Complete {
                    if self.currentRequest!.objectId != nil {
                        
                        ///rating view not shown for client yet
                        if self.currentRequest?.objectForKey("clientRating") == nil{
                            self.showRatingView()
                        }

                    }
                }
                
                
                    if newState == RequestState.Searching {
                        if self.currentRequest!.objectId != nil {
                            let currentInstallation = PFInstallation.currentInstallation()
                            let requestId: String = self.currentRequest!.objectId!
                            let channelName = "workout_\(requestId)"
                            currentInstallation.addUniqueObject(channelName, forKey: "channels")
                            currentInstallation.setObject(PFUser.currentUser()!.objectId!, forKey: "userId")
                            currentInstallation.saveInBackgroundWithBlock({ (success, error) -> Void in
                                if success {
                                    let channels = currentInstallation.objectForKey("channels")
                                    print("installation registering while searching: channel \(channels)")
                                }
                                else {
                                    print("installation registering error:\(error)")
                                }
                            })
                        }
                    }
            }
        }
        
//        if !self.hasPushEnabled() {
//            self.registerForRemoteNotifications()
//        }

        
        if self.timer == nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "updateRequestState", userInfo: nil, repeats: true)
            self.timer?.fire()
        }
        
        //self.labelTitle.hidden = true
        self.labelMessage.hidden = true

        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Done, target: self, action: "nothing")
    }
    
    override func viewWillAppear(animated: Bool) {
        Generals.hideLoadingView()
    }
    
    func nothing() {
        // do nothing
    }
    
    @IBAction func didClickButton(sender: UIButton) {
        if sender == buttonTop {
            print("top button")
            if self.topButtonHandler != nil {
                self.topButtonHandler!()
            }
        }
        else if sender == buttonBottom {
            print("bottom button")
            if self.bottomButtonHandler != nil {
                self.bottomButtonHandler!()
            }
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func updateRequestState() {
        
        bgImageIndex = bgImageIndex + 1
        
        if bgImageIndex == 4 { bgImageIndex = 1 }
        
        self.imageViewBG.image = UIImage(named: "bg_workout\(bgImageIndex)")!
        
        if PFUser.currentUser() == nil{
            
            if self.timer != nil {
                self.timer!.invalidate()
                self.timer = nil
            }

            self.navigationController?.popToRootViewControllerAnimated(true)
            return
        }

        
        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
            if let request: PFObject = client.objectForKey("workout") as? PFObject {
                request.fetchInBackgroundWithBlock({ (object, error) -> Void in
                    self.currentRequest = object
                    if self.currentRequest == nil {
                        // if request is still nil, then it got cancelled/deleted somehow.
                        self.toggleRequestState(.NoRequest)
                        return
                    }
                    
                    if let previousState: String = self.currentRequest!.objectForKey("status") as? String{
                        let newState: RequestState = RequestState(rawValue: previousState)!
                        
                        ////check for Rating
                        if newState == RequestState.Complete {
                            if self.currentRequest!.objectId != nil {
                                
                                ///rating view not shown for client yet
                                if self.currentRequest?.objectForKey("clientRating") == nil{
                                    self.showRatingView()
                                }
                                
                            }
                        }
                        
                        if let trainer: PFObject = request.objectForKey("trainer") as? PFObject {
                            trainer.fetchInBackgroundWithBlock({ (object, error) -> Void in
                                print("trainer: \(object) newState: \(newState.rawValue)")
                                self.currentTrainer = trainer
                                self.toggleRequestState(newState)
                            })
                        }
                        else {
                            self.toggleRequestState(newState)
                        }
                    }
                })
            }
        }
    }

    func updateTitle(title: String, message: String, top: String?, bottom: String, topHandler: RequestStatusButtonHandler?, bottomHandler: RequestStatusButtonHandler) {
        
        self.title = title
        self.labelMessage.text = message

        //self.labelTitle.hidden = false
        self.labelMessage.hidden = false

        let string:NSString = self.labelMessage.text! as NSString
        let bounds = CGSizeMake(self.labelMessage.frame.size.width, 500)
        let rect = string.boundingRectWithSize(bounds, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:self.labelMessage.font], context:nil)
        self.constraintDetailsHeight.constant = rect.size.height + 50;

        self.labelMessage.superview!.layoutSubviews()
        
        if top == nil {
            self.buttonTop.hidden = true
        }
        else {
            self.buttonTop.hidden = false
            self.buttonTop.setTitle(top!, forState: .Normal)
        }
        
        self.buttonBottom.setTitle(bottom, forState: .Normal)
        
        self.topButtonHandler = topHandler
        self.bottomButtonHandler = bottomHandler
    }
    
    
    func toggleRequestState(newState: RequestState) {
        self.state = newState
        print("going to state \(newState.rawValue)")
        
        switch self.state {
        case .NoRequest:
            let title = "No current workout"
            let message = "You're not currently in a workout or waiting for a trainer. Please click OK to go back to the training menu."
            self.updateTitle(title, message: message, top: nil, bottom: "Close", topHandler: nil, bottomHandler: { () -> Void in
                // dismiss the current stack and go back
                self.navigationController!.popToRootViewControllerAnimated(true)
            })
            
            if self.timer != nil {
                self.timer!.invalidate()
                self.timer = nil
            }
            self.progressView.stopActivity()
        case .Cancelled:
            // request state is set to .NoRequest if cancelled from an app action.
            // "cancelled" state is set on the web in order to trigger this state
            let title = "Search was cancelled"
            
             var message: String?
            
            if self.currentRequest != nil {
                
                if self.currentRequest!.allKeys.contains("cancelReason") {
                    message = self.currentRequest!.objectForKey("cancelReason") as? String
                }
            }
            
           
            
            if message == nil {
                message = "You have cancelled the training session. You have not been charged for this training session since no trainer was matched. Please click OK to go back to the training menu."
            }
            
            self.unsubscribeToCurrentRequestChannel()

            self.currentRequest = nil
            self.updateTitle(title, message: message!, top: nil, bottom: "OK", topHandler: nil, bottomHandler: { () -> Void in
                // dismiss the current stack and go back
                self.navigationController!.popToRootViewControllerAnimated(true)
            })
            
            if self.timer != nil {
                self.timer!.invalidate()
                self.timer = nil
            }
            self.progressView.stopActivity()
        case .Searching:
            
            var title = "Searching for a Trainer"
            var message = "Please be patient; this should only take a few minutes. In the meantime feel free to close the app. We will let you know once a trainer has been matched!"
            
//            if let addressString: String = self.currentRequest?.objectForKey("address") as? String {
//                title = "Searching for a Trainer near"
//                message = "\(addressString)\n\n\(message)"
//            }
            
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
                self.promptForCancel()
            })
            self.progressView.startActivity()
        case .Matched:
            let title = "Trainer found"
            let message = "You have been matched with a trainer!"
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
            })
            self.goToTrainerInfo()
            if self.timer != nil {
                self.timer!.invalidate()
                self.timer = nil
            }
            self.progressView.stopActivity()
            
            self.unsubscribeToCurrentRequestChannel()

        case .Training:
            let title = "Training in session"
            let message = ""
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
            })
            self.goToTrainerInfo()
            if self.timer != nil {
                self.timer!.invalidate()
                self.timer = nil
            }
            self.progressView.stopActivity()

            self.unsubscribeToCurrentRequestChannel()

        default:
            break
        }
    }

    func goToTrainerInfo() {
        if self.trainerController != nil || self.goingToTrainer {
            return
        }
        self.goingToTrainer = true
        print("display info")
        if let trainer: PFObject = self.currentRequest!.objectForKey("trainer") as? PFObject {
            trainer.fetchInBackgroundWithBlock({ (object, error) -> Void in
                print("trainer: \(object)")
                self.currentTrainer = trainer
                
                let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
                tcon.selectedIndex = 0
                let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
                
                if (tabNabcontroller.visibleViewController?.isKindOfClass(TrainerProfileViewController)) == false{
                    self.performSegueWithIdentifier("GoToViewTrainer", sender: nil)
                }
            })
        }
    }
    
    func promptForCancel() {
        let alert = UIAlertController(title: "Cancel request?", message: "Are you sure you want to cancel your training request?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel training", style: .Cancel, handler: { (action) -> Void in
            if self.currentRequest != nil {
                self.currentRequest!.setObject(RequestState.Cancelled.rawValue, forKey: "status")
                self.currentRequest!.saveInBackgroundWithBlock({ (success, error) -> Void in
                    self.toggleRequestState(RequestState.Cancelled)
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Keep waiting", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "GoToViewTrainer" {
            let controller: TrainerProfileViewController = segue.destinationViewController as! TrainerProfileViewController
            controller.request = self.currentRequest
            controller.trainer = self.currentTrainer
            
            self.trainerController = controller
        }
    }
    
   

    func warnForRemoteNotificationRegistrationFailure() {
        let alert = UIAlertController(title: "Change notification settings?", message: "Push notifications are disabled, so you can't receive notifications from trainers. Would you like to go to the Settings to update them?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            print("go to settings")
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }
    
    func unsubscribeToCurrentRequestChannel() {
        if self.currentRequest != nil && self.currentRequest!.objectId != nil {
            let currentInstallation = PFInstallation.currentInstallation()
            let requestId: String = self.currentRequest!.objectId!
            let channelName = "workout_\(requestId)"
            currentInstallation.removeObject(channelName, forKey: "channels")
            currentInstallation.setObject(PFUser.currentUser()!.objectId!, forKey: "userId")
            currentInstallation.saveInBackground()
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
}
