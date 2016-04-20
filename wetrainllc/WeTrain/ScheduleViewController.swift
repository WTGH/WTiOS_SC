//
//  ScheduleViewController.swift
//  WeTrain
//
//  Created by Sempercon on 24/12/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import GoogleMaps
import Parse

@objc class ScheduleViewController: UIViewController, SBFLatDatePickerDelegate, CLLocationManagerDelegate {
    
    var datePicker : SBFlatDatePicker!
    var dateFormatter : NSDateFormatter!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    var isScheduleEdit: Bool?

    
    override func viewDidLoad() {
        
        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: self, action: "back")
        
        
        self.title = "Schedule"
        ///add custom datepicker
        datePicker  = SBFlatDatePicker(frame: CGRectMake(0, 20, self.view.frame.size.width, self.view.frame.size.height - self.tabBarController!.tabBar.frame.size.height - 40))
        datePicker.delegate = self
        
        
        datePicker.backgroundColor = UIColor.whiteColor()
        datePicker.dayRange = NSMutableIndexSet(indexesInRange: NSMakeRange(0, 365))
        
        datePicker.minuterange = NSMutableIndexSet()
        datePicker.minuterange.addIndex(0)
        datePicker.minuterange.addIndex(15)
        datePicker.minuterange.addIndex(30)
        datePicker.minuterange.addIndex(45)
        
        datePicker.dayFormat = "EEE MMM dd";
        
        self.view.addSubview(datePicker)
        
        dateFormatter               = NSDateFormatter()
        dateFormatter.locale        = NSLocale.systemLocale()
        dateFormatter.timeZone      = NSTimeZone.systemTimeZone()
        dateFormatter.dateFormat    = "EEE dd MM HH mm a"
        dateFormatter.dateFormat    = "hh:mm a"
        
        locationManager.delegate = self
        if (locationManager.respondsToSelector("requestWhenInUseAuthorization")) {
            locationManager.requestWhenInUseAuthorization()
        }
        else {
            locationManager.startUpdatingLocation()
        }
        
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.Denied {
            self.warnForLocationPermission()
        }

    }
    
    override func viewDidAppear(animated: Bool) {

        if (self.appDelegate().ScheduleTime != nil) {
            
            let startdate : NSDate = NSDate()
            //startdate = startdate.dateByAddingTimeInterval(-(3 * 86400))
                
            self.moveToSelectedDate(startdate, endDate: self.appDelegate().ScheduleTime!)
        }
        
        // if location is nil, then we haven't tried to load location yet so let locationManager work
        // if location is non-nil and location has been disabled, warn
        if self.currentLocation != nil {
           
        }
        else {
            // can come here if location permission has already be requested, was initially denied then enabled through settings, but now doesn't start location
            locationManager.startUpdatingLocation()
        }


    }
    
    func moveToSelectedDate(startDate: NSDate, endDate: NSDate)
    {
        let calendar = NSCalendar.currentCalendar()
        //let components = calendar.components([.Day], fromDate: startDate, toDate: endDate, options: [])
       let components = calendar.components([.Day], fromDate: calendar.startOfDayForDate(startDate), toDate: calendar.startOfDayForDate(endDate), options: [])
        datePicker.seTDay(Int32(components.day), withTime: dateFormatter.stringFromDate(self.appDelegate().ScheduleTime!))
    }
    
    // MARK: - Button Actions
    func back() {
        // pops the next button
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    @IBAction func didTimeSlected () {
        
    }
    
    
    // MARK: - DATE PICKER DELEGATE
    
    func flatDatePicker(datePicker: SBFlatDatePicker!, saveDate date: NSDate!) {
        
         self.appDelegate().ScheduleTime = date;
         self.performSegueWithIdentifier("GoToDuration", sender: nil)
    }
    
    
    
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
        }
        else if status == .Denied {
            //self.warnForLocationPermission()
            self.currentLocation = CLLocation(latitude: PHILADELPHIA_LAT, longitude: PHILADELPHIA_LON)
            datePicker.currentLocation = CLLocation(latitude: PHILADELPHIA_LAT, longitude: PHILADELPHIA_LON)
            print("Authorization is not available")
        }
        else {
            print("status unknown")
        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first as CLLocation? {
            locationManager.stopUpdatingLocation()
            
            self.currentLocation = location
            datePicker.currentLocation = location
        }
    }
    
    func inServiceRange() -> Bool {
        
        
       // At this point, the user will always be able to edit the time (regardless if it’s within 1 hour)
       // and still request EVEN if they are NOT within the Train Now service area.
        
        if (self.isScheduleEdit == true) {
            return true
        }
        
        // create a user flag instead of checking current location
        if PFUser.currentUser() == nil {
            return true
        }
        
        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
            
            if client.allKeys.contains("locationOverride") {
                
                if let override: Bool = client.objectForKey("locationOverride") as? Bool {
                    if override == true {
                        return true
                    }
                }
                
            }
        }
        
        let phila: CLLocation = CLLocation(latitude: PHILADELPHIA_LAT, longitude: PHILADELPHIA_LON)
        if self.currentLocation == nil {
            return false
        }
        let dist = self.currentLocation!.distanceFromLocation(phila)
        print("distance from center city: \(dist)")
        
        if dist > SERVICE_RANGE_METERS {
            return false
        }
        
        return true
    }
   

}
