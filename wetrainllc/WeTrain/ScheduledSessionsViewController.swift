//
//  ScheduledSessionsViewController.swift
//  WeTrain
//
//  Created by Sempercon on 09/03/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ScheduledSessionsViewController: UIViewController {

    @IBOutlet  var scheulesTableView : UITableView!
    var scheduleSessions = [PFObject]()
    
    let dateFormatter = NSDateFormatter()
    let weekDayformatter = NSDateFormatter()

    let calendar = NSCalendar.currentCalendar()
    
    var proxyViewForStatusBar: UIView!
    
    var scheduleConfirmationCon : ScheduleConfirmationViewController!
    var isShowNoRecords : Bool!

    // MARK: - VIEW DELEGATES

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.userInfoSetTitleBarColor(UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), tintColor: UIColor(red: 0, green: 122/255, blue: 1, alpha: 1))
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        self.title = "Scheduled Sessions"
        
        ///intialize calendar
        dateFormatter.dateFormat = "M/d/yy @ h:mm a"
        dateFormatter.timeZone   = NSTimeZone.systemTimeZone()
        dateFormatter.locale     = NSLocale.systemLocale()
        
        self.getSchedules()
        
        self.scheduleConfirmationCon = (UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("SessionDetailPopup") as! ScheduleConfirmationViewController)
        self.scheduleConfirmationCon?.view

    }
    
    override func viewWillAppear(animated: Bool) {
        
        proxyViewForStatusBar  = UIView(frame: CGRectMake(0, 0,self.view.frame.size.width, 20))
        proxyViewForStatusBar.backgroundColor=UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        self.navigationController!.view.addSubview(proxyViewForStatusBar)
              UIApplication.sharedApplication().statusBarStyle = .Default
        
        self.isShowNoRecords = false
        
    }
    
    override func viewDidDisappear(animated: Bool) {
        proxyViewForStatusBar.removeFromSuperview()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: - BUTTON ACTIONS
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    
    // MARK: - CUSTOM METHODS
    
    func getSchedules() {
        
         self.isShowNoRecords =  false
        
        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
            
            ////get ScheduleInfo
            
            let timeNow = NSDate()
            
            let createQuery : PFQuery = PFQuery(className: "ScheduleInfo")
            createQuery.whereKey("client", equalTo: client)
            createQuery.whereKey("status", equalTo: ScheduleState.Created.rawValue)
            createQuery.whereKey("scheduledTime", greaterThan: timeNow)
            
            let selfConfirmQuery : PFQuery = PFQuery(className: "ScheduleInfo")
            selfConfirmQuery.whereKey("client", equalTo: client)
            selfConfirmQuery.whereKey("status", equalTo: ScheduleState.SelfConfirmed.rawValue)
            selfConfirmQuery.whereKey("scheduledTime", greaterThan: timeNow)
            
            let searchingQuery : PFQuery = PFQuery(className: "ScheduleInfo")
            searchingQuery.whereKey("client", equalTo: client)
            searchingQuery.whereKey("status", equalTo: ScheduleState.Searching.rawValue)
            searchingQuery.whereKey("scheduledTime", greaterThan: timeNow)

            let combinedQuery : PFQuery = PFQuery.orQueryWithSubqueries([createQuery,selfConfirmQuery,searchingQuery])
            combinedQuery.orderByAscending("scheduledTime")
            
            Generals.ShowLoadingView()

            combinedQuery.findObjectsInBackgroundWithBlock {
                (objects:[PFObject]?, error:NSError?) -> Void in
                
                self.isShowNoRecords =  true

                if error == nil {
                    
                   self.scheduleSessions =  objects!
                   self.scheulesTableView.reloadData()
                    
                } else {
                    
                }
                

                Generals.hideLoadingView()
            }
        
        }
        

        
    }
    
    func formatScheduleDate (scheduleddate : NSDate) -> NSString {
        
        var dateStr = dateFormatter.stringFromDate(scheduleddate)
         weekDayformatter.dateFormat = "EEEE"
         dateStr = weekDayformatter.stringFromDate(scheduleddate) + " " +  dateStr
        
        return dateStr
    }
    
    func showSessionDetailPopup(selectedIndex : Int){
        
        self.scheduleConfirmationCon.parentController = self
        self.scheduleConfirmationCon.cancelPopup.hidden = true
        self.scheduleConfirmationCon.DetailPopup.hidden = false
        
        if let schedule : PFObject = self.scheduleSessions[selectedIndex] {
            
            self.scheduleConfirmationCon.confirmationType = confimationScreentype.SessonDetails
            self.scheduleConfirmationCon.loadSessionDetails(schedule)
            
            //animate view as like as modal
            self.scheduleConfirmationCon.view.frame = CGRectMake(self.appDelegate().window!.frame.origin.x, self.appDelegate().window!.frame.size.height, self.appDelegate().window!.frame.size.width, self.appDelegate().window!.frame.size.height)
            
            self.appDelegate().window!.addSubview(self.scheduleConfirmationCon.view)
            
            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                
                self.scheduleConfirmationCon.view.frame =  CGRectMake(self.appDelegate().window!.frame.origin.x, self.appDelegate().window!.frame.origin.y, self.appDelegate().window!.frame.size.width, self.appDelegate().window!.frame.size.height)
                
                self.view.layoutIfNeeded()
                }, completion: nil)

        }
        
        
    }
    
    
    func scheculeCancelled (schedule : PFObject!) {
        
        
        let app:UIApplication = UIApplication.sharedApplication()
        
        ///to test
        print(app.scheduledLocalNotifications!.count)

        for oneEvent in app.scheduledLocalNotifications! {
            let notification = oneEvent as UILocalNotification
            let userInfoCurrent = notification.userInfo! as! [String:AnyObject]
            let uid = userInfoCurrent["scheduleInfoId"]! as! String
            if uid == schedule.objectId {
                //Cancelling local notification
                app.cancelLocalNotification(notification)
                self.appDelegate().removeScheduleInfo_from_UserDefault(NSMutableDictionary(dictionary: notification.userInfo!))
                break;
            }
        }
        
        
        ///to test
        print(app.scheduledLocalNotifications!.count)
        
        if self.scheduleSessions.contains(schedule){
            self.scheduleSessions.removeAtIndex( self.scheduleSessions.indexOf(schedule)! )
            self.scheulesTableView.reloadData()
        }
        
        if self.scheduleSessions.count == 0 {
            self.isShowNoRecords = true
        }
        
    }
    
    // MARK: - TABLEVIEW DATASOURCE
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if scheduleSessions.count == 0 && isShowNoRecords == true {
            return 1
        }
        
        return scheduleSessions.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("sessionCell", forIndexPath: indexPath)
        
        if scheduleSessions.count == 0 {
            
            cell.textLabel?.font = UIFont.systemFontOfSize(15.0)
            cell.textLabel!.text = "No Scheduled Sessions Found"
            cell.textLabel?.textAlignment = NSTextAlignment.Center
            cell.accessoryType = .None
            cell.accessoryView = nil
            return cell

        }
        
        cell.textLabel?.textAlignment = NSTextAlignment.Left
        
        if let schedule = scheduleSessions[indexPath.row] as PFObject! {
            
            if schedule.allKeys.contains("scheduledTime") {
                
                if let scheduledTime: NSDate = schedule.objectForKey("scheduledTime") as? NSDate {
                    
                    cell.textLabel!.text = self.formatScheduleDate(scheduledTime) as String
                }
            }
            
        }
        
        cell.textLabel?.font = UIFont.systemFontOfSize(15.0)
        
        if (cell.accessoryView == nil) {
            let arrowImage = UIImageView(frame: CGRectMake(0, 0, 10, 15))
            arrowImage.image =  UIImage(named: "rightArrow")
            cell.accessoryView = arrowImage
        }
        
        
            
      
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        if scheduleSessions.count > indexPath.row {
            
            showSessionDetailPopup(indexPath.row)
            
        }

        tableView.deselectRowAtIndexPath(indexPath, animated: true)

    }
    

   
}
