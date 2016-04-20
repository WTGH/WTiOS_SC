//
//  HomeViewController.swift
//  WeTrain
//
//  Created by Sempercon on 24/12/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse


class HomeViewController: UIViewController {

    @IBOutlet var bgTrainNow    : UIView!
    @IBOutlet var bgTrainLater  : UIView!
    @IBOutlet var bgMotivateMe  : UIView!

    var availtrainers           :AvailableTrainers!
    
    // MARK: - VIEW DELEGATES
    
    override func viewDidLoad() {
        
        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        self.navigationController?.navigationBar.clipsToBounds = true
        
        // if there's a current request and we return to the app, go to that
//        if PFUser.currentUser() != nil {
//            self.loadExistingRequest()
//        }
        
        
        availtrainers = AvailableTrainers.getView() as! AvailableTrainers
        availtrainers.getAvailableTrainer()
        self.appDelegate().availtrainers = availtrainers

        
    }
    
    override func viewWillAppear(animated: Bool) {
        
        self.navigationItem.title = ""
        
        availtrainers.frame = CGRectMake((self.appDelegate().window?.frame.origin.x)!,(self.navigationController!.navigationBar.frame.origin.y), (self.appDelegate().window?.frame.size.width)!, (self.navigationController!.navigationBar.frame.size.height))
        self.appDelegate().window?.addSubview(availtrainers)

    }
    
    override func viewWillDisappear(animated: Bool) {
        
        availtrainers.removeFromSuperview()
    }

    

    
    // MARK: - BUTTON ACTIONS
    
    @IBAction func didClickTrainNow(){
       
        let controller: ScheduleConfirmationViewController = self.appDelegate().scheduleConfirmationCon!
        controller.confirmationType = confimationScreentype.None
        controller.CurrentScheduleInfo = nil
        self.appDelegate().ScheduleTime = nil
        
        self.appDelegate().OptionType = "Train Now"
        self.changeButtonBGColor()
    }
    
    @IBAction func didClickTrainLater(){

        let controller: ScheduleConfirmationViewController = self.appDelegate().scheduleConfirmationCon!
        controller.confirmationType = confimationScreentype.None
        controller.CurrentScheduleInfo = nil
        
        self.appDelegate().ScheduleTime = nil
        self.appDelegate().OptionType = "Train Later"
        self.changeButtonBGColor()

    }
    
    @IBAction func didClickMotivateMe(){
        
        self.appDelegate().OptionType = "Motivate Me"
        self.changeButtonBGColor()
        
    }
  
    
      // MARK: - CUSTOM METHODS
    
    func changeButtonBGColor(){
        
    }
    
    
    func loadExistingRequest() {
        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
            client.fetchInBackgroundWithBlock({ (object, error) -> Void in
                if let request: PFObject = client.objectForKey("workout") as? PFObject {
                    request.fetchInBackgroundWithBlock({ (requestObject, error) -> Void in
                        if let state = request.objectForKey("status") as? String {
                            print("state \(state) object \(requestObject)")
                            
                            ////check for Rating
                            if state == RequestState.Complete.rawValue {
                                if request.objectId != nil {
                                    
                                    ///rating view not shown for client yet
                                    if request.objectForKey("clientRating") == nil{
                                        self.showRatingView()
                                    }
                                    
                                }
                            }
                            
                            if state == RequestState.Matched.rawValue {
                                self.performSegueWithIdentifier("GoToRequestState", sender: nil)
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
                                        self.performSegueWithIdentifier("GoToRequestState", sender: nil)
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
                                        self.performSegueWithIdentifier("GoToRequestState", sender: nil)
                                    }
                                }
                            }
                        }
                    })
                }
            })
        }
    }
    
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
       
        if segue.identifier == "GoToRequestState" {
            let controller = segue.destinationViewController as! RequestStatusViewController
            let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
            let request: PFObject = client.objectForKey("workout") as! PFObject
            controller.currentRequest = request
        }
    }
    
   
    

}
