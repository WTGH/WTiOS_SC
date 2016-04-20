//
//  VideoRequsestStatusViewController.swift
//  WeTrain
//
//  Created by Sempercon on 28/12/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import AVFoundation
import AVKit

class VideoRequsestStatusViewController: UIViewController,AVPlayerViewControllerDelegate {
    
    @IBOutlet weak var labelTitle: UILabel!
    @IBOutlet weak var labelMessage: UILabel!
    @IBOutlet weak var labelFunfactTitle: UILabel!

    @IBOutlet weak var buttonTop: UIButton!
    @IBOutlet weak var buttonBottom: UIButton!
    
    @IBOutlet weak var imageViewBG: UIImageView!
    
    @IBOutlet weak var constraintDetailsHeight: NSLayoutConstraint!
    
    @IBOutlet weak var progressView: ProgressView!
    
    var state: VideoRequestState = .NoRequest
    var currentRequest: PFObject?
    var currentTrainer: PFObject?
    
    var timer: NSTimer?
    
    var topButtonHandler: RequestStatusButtonHandler? = nil
    var bottomButtonHandler: RequestStatusButtonHandler? = nil
    
    var trainerController: TrainerProfileViewController? = nil
    var goingToTrainer: Bool = false

    // MARK: - View Delegate
    var videoFile : PFFile!
    
    let playerViewController = AVPlayerViewController()
    
    
    var alreadyShownFunfactArr : NSMutableArray!
    var funFacttimer: NSTimer?


    override func viewDidLoad() {
        
        // Do any additional setup after loading the view.
        let index = arc4random_uniform(3)+1
        self.imageViewBG.image = UIImage(named: "bg_workout\(index)")!
        
        
        if self.timer == nil {
            self.timer = NSTimer.scheduledTimerWithTimeInterval(10, target: self, selector: "updateVideoRequestState", userInfo: nil, repeats: true)
        }
        
        
        
        alreadyShownFunfactArr = NSMutableArray()
        if self.funFacttimer == nil {
            self.funFacttimer = NSTimer.scheduledTimerWithTimeInterval(7, target: self, selector: "getRandomFunFact", userInfo: nil, repeats: true)
        }
        
        //Intiate motivateMe search
        initiateMotivateMeRequestRequest()
        
        self.labelTitle.hidden = true
        self.labelMessage.hidden = true
        self.labelFunfactTitle.hidden = true
        
        
        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "", style: UIBarButtonItemStyle.Done, target: self, action: "nothing")

    }
    
    
    // MARK: - Custom methods

    func initiateMotivateMeRequestRequest() {
        
        let request: PFObject = PFObject(className: "MotivateMe")
        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        let id = client.objectId
        print("client: \(client) \(id)")
        request.setObject(client, forKey: "client")
        request.setObject(VideoRequestState.Searching.rawValue, forKey: "status")

        if TESTING == 1 {
            request.setObject(true, forKey: "testing")
        }
        print("request: \(request)")
        
        request.saveInBackgroundWithBlock { (success, error) -> Void in
            print("saved: \(success)")
            
            client.setObject(request, forKey: "motivateMe")
            
            
            client.saveInBackgroundWithBlock( { (success, error) -> Void in
                
                if success {
                    // subscribe to channel
                    self.timer?.fire()
                    //self.upLoadVideo()
                }
            })
            
            if success {
                // subscribe to channel
                
                if request.objectId != nil {
                    let currentInstallation = PFInstallation.currentInstallation()
                    let requestId: String = request.objectId!
                    let channelName = "motivateMe_\(requestId)"
                    currentInstallation.addUniqueObject(channelName, forKey: "channels")
                    currentInstallation.setObject(PFUser.currentUser()!.objectId!, forKey: "userId")
                    currentInstallation.saveInBackgroundWithBlock({ (success, error) -> Void in
                        if success {
                            let channels = currentInstallation.objectForKey("channels")
                            print("MotivateMe installation registering while initiating: channel \(channels)")
                        }
                        else {
                            print("MotivateMe installation registering error:\(error)")
                        }
                    })
                }
                
                
            }
            else {
                let message = "There was an issue requesting a training session. Please try again."
                print("error: \(error)")
                self.simpleAlert("Could not request workout", defaultMessage: message, error: error)
            }
        }
    }
    
    func updateVideoRequestState() {
        
        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        if let request: PFObject = client.objectForKey("motivateMe") as? PFObject {
            request.fetchInBackgroundWithBlock({ (object, error) -> Void in
                self.currentRequest = object
                if self.currentRequest == nil {
                    // if request is still nil, then it got cancelled/deleted somehow.
                    self.toggleRequestState(.NoRequest)
                    return
                }
                
                if let previousState: String = self.currentRequest!.objectForKey("status") as? String{
                    let newState: VideoRequestState = VideoRequestState(rawValue: previousState)!
                    
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
    
    
    func toggleRequestState(newState: VideoRequestState) {
        self.state = newState
        print("going to state \(newState.rawValue)")
        
        switch self.state {
        case .NoRequest:
            let title = "No current MotivateMe"
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
            var message: String? = self.currentRequest!.objectForKey("cancelReason") as? String
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
            
            let title = "We're preparing your motivation!"
            let message = "Please be patient; this may take a few minutes. If you close the app, we will notify you once a trainer has been matched!"
            
//            if let addressString: String = self.currentRequest?.objectForKey("address") as? String {
//                title = "Searching for an available trainer near:"
//                message = "\(addressString)\n\n\(message)"
//            }
            
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
               // self.promptForCancel()
            })
            self.progressView.startActivity()
        case .Matched:
            let title = "Trainer found"
            let message = "You have been matched with a trainer!"
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
            })
          
        case .VideoRecordStarted:
            let title = "VideoRecordStarted"
            let message = ""
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
            })
         
        case .VideoRecordProcessing:
            let title = "VideoRecordProcessing"
            let message = ""
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
            })
            
        case .VideoUploadedStart:
            let title = "videoUploadStart"
            let message = ""
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
            })
         
            
        case .VideoUploaded:
            let title = "VideoUploaded"
            let message = ""
            self.updateTitle(title, message: message, top: nil, bottom: "Cancel Request", topHandler: nil, bottomHandler: { () -> Void in
            })
            // self.goToTrainerInfo()
            if self.timer != nil {
                self.timer!.invalidate()
                self.timer = nil
            }
            self.progressView.stopActivity()
            
            self.playMotivateMeVideo(true)
            
        default:
            break
        }
    }
    
    
    func updateTitle(title: String, message: String, top: String?, bottom: String, topHandler: RequestStatusButtonHandler?, bottomHandler: RequestStatusButtonHandler) {
        self.labelTitle.text = title
        self.labelTitle.hidden = false
        self.labelMessage.hidden = false
        self.labelFunfactTitle.hidden = false

     
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
    
    func promptForCancel() {
        let alert = UIAlertController(title: "Cancel request?", message: "Are you sure you want to cancel your training request?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel training", style: .Cancel, handler: { (action) -> Void in
            if self.currentRequest != nil {
                self.currentRequest!.setObject(VideoRequestState.Cancelled.rawValue, forKey: "status")
                self.currentRequest!.saveInBackgroundWithBlock({ (success, error) -> Void in
                    self.toggleRequestState(VideoRequestState.Cancelled)
                })
            }
        }))
        alert.addAction(UIAlertAction(title: "Keep waiting", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }
    
    func unsubscribeToCurrentRequestChannel() {
        if self.currentRequest != nil && self.currentRequest!.objectId != nil {
            let currentInstallation = PFInstallation.currentInstallation()
            let requestId: String = self.currentRequest!.objectId!
            let channelName = "motivateMe_\(requestId)"
            currentInstallation.removeObject(channelName, forKey: "channels")
            currentInstallation.setObject(PFUser.currentUser()!.objectId!, forKey: "userId")
            currentInstallation.saveInBackground()
        }
    }
    
    
    
    func getRandomFunFact() {
        
        if FUN_FACTS.count == self.alreadyShownFunfactArr.count {
            self.alreadyShownFunfactArr.removeAllObjects()
        }
        
        
        var randomFunfact :String!
        
        for (var i = 0 ; i < FUN_FACTS.count ; i++) {
            
            let index  = arc4random_uniform( UInt32(FUN_FACTS.count))
            randomFunfact = FUN_FACTS[Int(index)] as String
            
            if(!self.alreadyShownFunfactArr.containsObject(randomFunfact)) {
                break;
            }
        }
        
        self.labelMessage.text = randomFunfact
        
        let string:NSString = self.labelMessage.text! as NSString
        let bounds = CGSizeMake(self.labelMessage.frame.size.width, 500)
        let rect = string.boundingRectWithSize(bounds, options: NSStringDrawingOptions.UsesLineFragmentOrigin, attributes: [NSFontAttributeName:self.labelMessage.font], context:nil)
        self.constraintDetailsHeight.constant = rect.size.height + 20;
        
        self.labelMessage.superview!.layoutSubviews()
        
    }
    
    
    // MARK: - AvPlayer Delegate
    
    func playMotivateMeVideo(isShowDetail : Bool) {
        
        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        if let request: PFObject = client.objectForKey("motivateMe") as? PFObject {
            
            self.videoFile  = request.objectForKey("video") as! PFFile

            print(self.videoFile.url)
            
            let avAsset : AVAsset = AVAsset(URL: NSURL(string: self.videoFile.url!)!)
            let avPlayeritem = AVPlayerItem(asset: avAsset)
            let player = AVPlayer(playerItem: avPlayeritem)
            
            self.playerViewController.player = player
            if #available(iOS 9.0, *) {
                self.playerViewController.delegate = self
            } else {
                // Fallback on earlier versions
            }
            
            
            NSNotificationCenter.defaultCenter().addObserver(self, selector:"avPlayerItemReachEndTime:",name: AVPlayerItemDidPlayToEndTimeNotification, object: avPlayeritem)

            self.navigationController!.presentViewController(playerViewController, animated: true) {
                
                self.playerViewController.player!.play()
                
                if isShowDetail {
                    self.performSegueWithIdentifier("GoToVideoDetail", sender: nil)
                }
                
            }
        }
        
        
        
    }
    
    func avPlayerItemReachEndTime(notification: NSNotification){
        self.playerViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func playerViewControllerDidStartPictureInPicture(playerViewController: AVPlayerViewController) {
        
    }
    
    func playerViewControllerWillStopPictureInPicture(playerViewController: AVPlayerViewController) {
        
        playerViewController.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "GoToVideoDetail" {
            
            let controller: VideoDetailViewController = segue.destinationViewController as! VideoDetailViewController
            controller.parentController = self
        }
      
    }


}
