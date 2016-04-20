//
//  SettingsViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 8/2/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD

class SettingsViewController: UITableViewController, TutorialDelegate, CreditCardDelegate, currentWODelegate{

    var proxyViewForStatusBar: UIView!
    override func viewDidLoad() {
        super.viewDidLoad()
        
        UIApplication.sharedApplication().statusBarStyle = .Default
        
      

    }
    
    override func viewWillAppear(animated: Bool) {
     
        proxyViewForStatusBar  = UIView(frame: CGRectMake(0, 0,self.view.frame.size.width, 20))
        proxyViewForStatusBar.backgroundColor=UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        self.navigationController!.view.addSubview(proxyViewForStatusBar)
        
        self.navigationController?.navigationBar.tintColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        self.navigationController?.navigationBar.backgroundColor = UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), forBarMetrics: UIBarMetrics.Default)
        self.navigationController?.navigationBar.shadowImage = Generals.navbarImage()
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        UIApplication.sharedApplication().statusBarStyle = .Default

    }
    
    override func viewDidDisappear(animated: Bool) {
        proxyViewForStatusBar.removeFromSuperview()
    }
    
    

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    // MARK: - Table view data source

    override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        // Return the number of sections.
        return 1
    }

    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Return the number of rows in the section.
        if PFUser.currentUser() != nil {
            return 9
        }
        else {
            return 7
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        self.appDelegate().refreshUser()
        self.tableView.reloadData()
    }

    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("SettingsCell", forIndexPath: indexPath) 

        // Configure the cell...
        let row = indexPath.row
        if PFUser.currentUser() != nil {
            switch row {
            case 0:
                cell.textLabel!.text = "Edit your profile"
            case 1:
                cell.textLabel!.text = "Update your credit card"
            case 2:
                cell.textLabel!.text = "Workout descriptions"
            case 3:
                cell.textLabel!.text = "Scheduled Sessions"
            case 4:
                cell.textLabel!.text = "View tutorial"
            case 5:
                cell.textLabel!.text = "Feedback"
            case 6:
                cell.textLabel!.text = "Terms of Service & Privacy"
            case 7:
                cell.textLabel!.text = "Credits"
            case 8:
                cell.textLabel!.text = "Logout"
            default:
                break
            }
        }
        else {
            switch row {
            case 0:
                cell.textLabel!.text = "Log in"
            case 1:
                cell.textLabel!.text = "Sign up"
            case 2:
                cell.textLabel!.text = "Workout descriptions"
            case 3:
                cell.textLabel!.text = "View tutorial"
            case 4:
                cell.textLabel!.text = "Feedback"
            case 5:
                cell.textLabel!.text = "Terms of Service & Privacy"
            case 6:
                cell.textLabel!.text = "Credits"
            default:
                break
            }
        }

        return cell
    }

    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        let row = indexPath.row
        switch row {
        case 0:
            if PFUser.currentUser() == nil {
                self.login()
                return
            }
            else {
                let controller: UserInfoViewController = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("UserInfoViewController") as! UserInfoViewController
//                let nav: UINavigationController = UINavigationController(rootViewController: controller)
//                self.presentViewController:nav
                self.navigationController?.pushViewController(controller, animated: true)
            }
            break
        case 1:
            if PFUser.currentUser() == nil {
                self.signup()
                return
            }
            else {
                self.performSegueWithIdentifier("GoToCreditCard", sender: self)
            }
            
            break
        case 2:
            self.goToWorkOrderDesc()
            break

        case 3:
            
            if PFUser.currentUser() == nil {
                self.goToTutorials()
                return
            }
            else { //move to Schedule sessi0n
                
                self.goToScheduleSession()
            }
            
            
            break
        case 4:
            if PFUser.currentUser() == nil {
                let alert: UIAlertController = UIAlertController(title: "Log in first?", message: "You are not logged in. Please log in first so we can respond to you.", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                }))
                alert.addAction(UIAlertAction(title: "Leave Anonymous Feedback", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                    self.performSegueWithIdentifier("GoToFeedback", sender: self)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                
                alert.view.tintColor = UIColor.blackColor()

            }
            else {
                self.goToTutorials()
            }
            break
        case 5:
            
            if PFUser.currentUser() == nil {
                self.tosController()
                return
            } else {
                self.performSegueWithIdentifier("GoToFeedback", sender: self)
            }
            
            break
        case 6:
            
            if PFUser.currentUser() == nil {
                
                let info = NSBundle.mainBundle().infoDictionary as [NSObject: AnyObject]?
                let version: AnyObject = info!["CFBundleShortVersionString"]!
                let message = "Copyright 2015 WeTrain, LLC\nVersion \(version)"
                self.simpleAlert("Credits", message: message)

                
                return
            } else {
                self.tosController()
            }
            
            break
        case 7:
            let info = NSBundle.mainBundle().infoDictionary as [NSObject: AnyObject]?
            let version: AnyObject = info!["CFBundleShortVersionString"]!
            let message = "Copyright 2015 WeTrain, LLC\nVersion \(version)"
            self.simpleAlert("Credits", message: message)
            break
        case 8:
            self.getCurrentWorkOutStatus(true, callBackcontroller: self)
        default:
            break
        }
    }
    
    
    func goToWorkOrderDesc() {
        
        proxyViewForStatusBar.removeFromSuperview()
        let controller: WorkOutDescriptionViewControler = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("WorkOutDescription") as! WorkOutDescriptionViewControler
       
        self.navigationController?.navigationBar.topItem?.leftBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: controller, action: "back")
        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func goToScheduleSession() {
        
        proxyViewForStatusBar.removeFromSuperview()
        let controller: ScheduledSessionsViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ScheduledSessions") as! ScheduledSessionsViewController
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: controller, action: "back")
        self.navigationController?.pushViewController(controller, animated: true)

    }
    
    func goToTutorials() {
        let controller: TutorialViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TutorialViewController") as! TutorialViewController
        controller.delegate = self


        self.navigationController?.pushViewController(controller, animated: true)
    }
    
    func didCloseTutorial() {
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "GoToCreditCard" {
            let nav: UINavigationController = segue.destinationViewController as! UINavigationController
            let controller: CreditCardViewController = nav.viewControllers[0] as! CreditCardViewController
            controller.delegate = self
        }
    }
    
    // MARK: - CreditCardDelegate
    func didSaveCreditCard(token: String, lastFour: String) {
        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
            // actually save credit card
            PFCloud.callFunctionInBackground("updatePayment", withParameters: ["clientId": client.objectId!, "stripeToken": token]) { (results, error) -> Void in
                print("results: \(results) error: \(error)")
                
                Generals.hideLoadingView()

                if error != nil {
                    let message = "Your credit card could not be updated. Please try again."
                    print("error: \(error)")
                    self.simpleAlert("Error saving credit card", defaultMessage: message, error: error)
                }
                else {
                    client.setObject(lastFour, forKey: "stripeFour")
                    client.saveInBackground()
                }
            }
        } else {
            
            Generals.hideLoadingView()

        }
    }
    
    func logout() {
        
        Generals.ShowLoadingView()

        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        tabNabcontroller.popToRootViewControllerAnimated(false)

        
        PFUser.logOutInBackgroundWithBlock { (error) -> Void in
            self.tableView.reloadData()
             Generals.hideLoadingView()

        }
    }
    
    // MARK: - Log in
    func login() {
        let controller: LoginViewController = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("LoginViewController") as! LoginViewController
        let nav = UINavigationController(rootViewController: controller)
        self.navigationController!.presentViewController(nav, animated: true, completion: nil)
    }
    
    func signup() {
        let controller: SignupViewController = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("SignupViewController") as! SignupViewController
        let nav = UINavigationController(rootViewController: controller)
        self.navigationController!.presentViewController(nav, animated: true, completion: nil)
    }
    
    
    func tosController() {
        
        let controller: TOSViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TOSViewController") as! TOSViewController
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "My Account", style: .Done, target: controller, action: "back")
        self.navigationController?.pushViewController(controller, animated: true)
        
    }
    
    func currentWorkoutStatus(request: PFObject) {
        
        Generals.hideLoadingView()

        if let state = request.objectForKey("status") as? String {
            
            if (state == RequestState.Matched.rawValue || state == RequestState.Searching.rawValue)
            {
                self.promptForWorkOutCancel(request)
            }
            else
            {
                self.logout()
            }
        }
        else
        {
            self.logout()
        }

    }
    
    func userNotHavingWorkout() {
        
        Generals.hideLoadingView()

        self.logout()
    }
    
    func promptForWorkOutCancel(request: PFObject) {
        
        var title = "Cancel request?"
        var buttonTitle = "Cancel training"
        var message = "Are you sure you want to cancel your training request?"
        let status: String = request.objectForKey("status") as! String
        var newStatus: String = RequestState.Cancelled.rawValue
        
        if status == RequestState.Training.rawValue {
            
        }
        else if status == RequestState.Matched.rawValue {
            // matched, but not started yet
            title = "Cancel session?"
            buttonTitle = "Cancel session"
            message = "Your session hasn't started yet. Do you want to cancel the session?"
            newStatus = RequestState.Cancelled.rawValue
        }
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: buttonTitle, style: .Default, handler: { (action) -> Void in
            request.setObject(newStatus, forKey: "status")
            request.setObject(NSDate() , forKey: "end")
            request.saveInBackgroundWithBlock({ (success, error) -> Void in
                
                ////cancel session and then logout
                self.logout()

            })
        }))
        
        alert.addAction(UIAlertAction(title: "Cancel", style: .Default, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()
        
    }
    
   
}


