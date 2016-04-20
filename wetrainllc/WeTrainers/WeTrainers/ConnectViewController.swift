//
//  ConnectViewController.swift
//  WeTrainers
//
//  Created by Bobby Ren on 9/24/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class ConnectViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, ClientInfoDelegate, CLLocationManagerDelegate {

    @IBOutlet var labelStatus: UILabel!
    @IBOutlet var buttonAction: UIButton!
    @IBOutlet var buttonShift: UIButton!
    @IBOutlet var allWorkouts: [PFObject]?
    @IBOutlet var nearbyWorkouts: [PFObject]?
    
    @IBOutlet var tableView: UITableView!
    
    @IBOutlet var motivateMetableView: UITableView!
    
    @IBOutlet var allMotivateMeRequest: [PFObject]?
    @IBOutlet var nearbyMotivateMeRequest: [PFObject]?


    var motivateMeRequest : Bool!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?

    var status: String?
    
    var shouldWarnIfRegisterPushFails: Bool = false // if user has denied push before, then registerForRemoteNotifications will not trigger a failure. Thus we have to manually warn after a certain time that the user needs to go to settings.
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]

        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Info", style: .Plain, target: self, action: "goToInfo")
        
        let user = PFUser.currentUser()!
        let trainer = user.objectForKey("trainer") as! PFObject
        status = trainer.objectForKey("status") as? String

        if !self.hasPushEnabled() {
            
            if self.getRemoteNotificationPremissionStatus()
            {
                    self.warnForRemoteNotificationRegistrationFailure()
            }
            else
            {
                self.registerForRemoteNotifications()
            }
        }
        
        if status == "available" {
            // make a call to load any existing requests that we won't get through notifications because they were made already
            self.loadExistingRequestsWithCompletion({ (results) -> Void in
                self.refreshStatus()
                self.reloadTable()
               // self.reloadMotivateMeTable()
                
            })
        }
        
        if trainer.objectForKey("workout") != nil {
            let request = trainer.objectForKey("workout") as! PFObject
            request.fetchInBackgroundWithBlock({ (object, error) -> Void in
                let status = request.objectForKey("status") as! String
                if status == RequestState.Matched.rawValue {
                    self.motivateMeRequest = false
                    self.performSegueWithIdentifier("GoToClientRequest", sender: request)
                }
                else if status == RequestState.Training.rawValue {
                    if let start = request.objectForKey("start") as? NSDate {
                        let minElapsed = NSDate().timeIntervalSinceDate(start) / 60
                        let length = request.objectForKey("length") as! Int
                        print("started at \(start) time passed \(minElapsed) workout length \(length)")
                        if Int(minElapsed) > length {
                            print("completing training")
                            request.setObject(RequestState.Complete.rawValue, forKey: "status")
                            request.saveInBackground()
                        }
                        else {
                            self.motivateMeRequest = false
                            self.performSegueWithIdentifier("GoToClientRequest", sender: request)
                        }
                    }
                }
                ////check for Rating
                else if status == RequestState.Complete.rawValue {
                    if request.objectId != nil {
                        
                        ///rating view not shown for client yet
                        if request.objectForKey("trainerRating") == nil{
                            self.showRatingView()
                        }
                        
                    }
                }
            })
        }
        else if trainer.objectForKey("motivateMe") != nil {
            let request = trainer.objectForKey("motivateMe") as! PFObject
            request.fetchInBackgroundWithBlock({ (object, error) -> Void in
                let status = request.objectForKey("status") as! String
                if status == RequestState.Matched.rawValue {
                    self.motivateMeRequest = true
                    self.performSegueWithIdentifier("GoToClientRequest", sender: request)
                }
            })
        }
        
        
    
        // updates UI based on web
        self.refreshStatus()
        
        
        let notificationCenter = NSNotificationCenter.defaultCenter()
        
        // Add observer:
        notificationCenter.addObserver(self,
            selector:Selector("applicationDidBecomeActiveNotification"),
            name:UIApplicationDidBecomeActiveNotification,
            object:nil)
        
        
        // listen for push enabled
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "pushEnabled", name: "push:enabled", object: nil)

        // listen for push failure
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "warnForRemoteNotificationRegistrationFailure", name: "push:enable:failed", object: nil)

        // listen for request notifications
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "didReceiveRequest:", name: "request:received", object: nil)
        
        // location
        locationManager.delegate = self
        let loc: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if loc == CLAuthorizationStatus.AuthorizedAlways || loc == CLAuthorizationStatus.AuthorizedWhenInUse{
            locationManager.startUpdatingLocation()
        }
        else if loc == CLAuthorizationStatus.Denied {
            self.warnForLocationPermission()
        }
        else {
            if (locationManager.respondsToSelector("requestWhenInUseAuthorization")) {
                locationManager.requestWhenInUseAuthorization()
            }
            else {
                locationManager.startUpdatingLocation()
            }
        }
    }
    
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
    
    func applicationDidBecomeActiveNotification(){
        self.refreshStatus()
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        
        // if location is nil, then we haven't tried to load location yet so let locationManager work
        // if location is non-nil and location has been disabled, warn
        if self.currentLocation != nil {
            let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
            if status == CLAuthorizationStatus.Denied {
                self.warnForLocationPermission()
            }
        }
        else {
            // can come here if location permission has already be requested, was initially denied then enabled through settings, but now doesn't start location
            locationManager.startUpdatingLocation()
        }
        
       // self.reloadMotivateMeTable()

    }

    func warnForLocationPermission() {
        let message: String = "WeTrainers needs GPS access to find clients near you. Please go to your phone settings to enable location access. Go there now?"
        let alert: UIAlertController = UIAlertController(title: "Could not access location", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func registerForRemoteNotifications() {
        let alert = UIAlertController(title: "Enable push notifications?", message: "To receive client notifications you must enable push. In the next popup, please click OK.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
          
            self.setRemoteNotificationPermissionShown()

            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()

            self.shouldWarnIfRegisterPushFails = true
            self.buttonAction.enabled = false
            self.buttonAction.alpha = 0.5
            
//            let time = dispatch_time(DISPATCH_TIME_NOW, Int64(5 * Double(NSEC_PER_SEC)))
//            dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
//                if self.shouldWarnIfRegisterPushFails {
//                    self.warnForRemoteNotificationRegistrationFailure()
//                }
//            }
            
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func warnForRemoteNotificationRegistrationFailure() {
        self.shouldWarnIfRegisterPushFails = false
        self.buttonAction.enabled = true
        self.buttonAction.alpha = 1
        self.labelStatus.text = "Notifications is required for Trainer"
        let alert = UIAlertController(title: "Change notification settings?", message: "Push notifications are disabled, so you can't receive client requests. Would you like to go to the Settings to update them?", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            print("go to settings")
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
    }
    
    func pushEnabled() {
        self.buttonAction.enabled = true
        self.buttonAction.alpha = 1
        self.shouldWarnIfRegisterPushFails = false
    }
    
    // MARK: - Status
    @IBAction func didClickButton(sender: UIButton) {
        // the status is made of two parts: the first part is what actually gets saved to parse, and the second part is a local status
        
        if sender == self.buttonShift {
            
            let loc: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
            
            
            if (loc == CLAuthorizationStatus.Denied) {
                self.warnForLocationPermission()
            }
            else if  self.hasPushEnabled() == false {
                
                if self.getRemoteNotificationPremissionStatus()
                {
                    if !self.hasPushEnabled() {
                        self.warnForRemoteNotificationRegistrationFailure()
                        return
                    }
                }
                else
                {
                    self.registerForRemoteNotifications()
                    return
                }
            }
            else if self.status == "disconnected" {
                if self.hasPushEnabled() {
                    let trainer = PFUser.currentUser()!.objectForKey("trainer") as! PFObject
                    self.status = trainer.objectForKey("status") as? String
                    self.updateStatus(self.status!)
                }
                else {
                    
                    if self.getRemoteNotificationPremissionStatus()
                    {
                        if !self.hasPushEnabled() {
                            self.warnForRemoteNotificationRegistrationFailure()
                        }
                    }
                    else
                    {
                        self.registerForRemoteNotifications()
                    }
                    
                    
                }
            }
            else if self.status == "available" {
                // end a shift
                self.updateStatus("off")
                let currentInstallation = PFInstallation.currentInstallation()
                currentInstallation.removeObject("Trainers", forKey: "channels")
                currentInstallation.saveInBackground()
            }
            else {
                //if self.status == "off" || self.status == nil {
                // start a shift
                self.updateStatus("available")
                let currentInstallation = PFInstallation.currentInstallation()
                currentInstallation.addUniqueObject("Trainers", forKey: "channels")
                currentInstallation.saveInBackground()
                self.loadExistingRequestsWithCompletion({ (results) -> Void in
                    self.refreshStatus()
                    self.reloadTable()
                   // self.reloadMotivateMeTable()
                })
                self.buttonAction.hidden = false
            }
        }
        else if sender == self.buttonAction {
            if self.hasPushEnabled() == false {
                // skip notifications
                let user = PFUser.currentUser()!
                let trainer = user.objectForKey("trainer") as! PFObject
                var actualStatus = trainer.objectForKey("status") as? String
                if actualStatus == nil {
                    actualStatus = "off"
                }
                self.updateStatus(actualStatus!)
            }
            else {
                self.loadExistingRequestsWithCompletion({ (results) -> Void in
                    self.refreshStatus()
                    self.reloadTable()
                   // self.reloadMotivateMeTable()
                })
            }
        }
    }
    
    func updateStatus(newStatus: String) {
        self.status = newStatus

        let statusString = newStatus as NSString
        let location = statusString.rangeOfString(".").location
        var trainerStatus = newStatus
        if location != NSNotFound {
            let index = newStatus.startIndex.advancedBy(location)
            trainerStatus = newStatus.substringToIndex(index)
        }
        
        let user = PFUser.currentUser()!
        let trainer = user.objectForKey("trainer") as! PFObject
        trainer.setObject(trainerStatus, forKey: "status")
        trainer.saveInBackgroundWithBlock({ (success, error) -> Void in
            if success {
                self.refreshStatus()
            }
            else {
                self.simpleAlert("Error", message: "Your status could not be updated. Please try again")
            }
        })
    }
    
    func refreshStatus() {
        let user = PFUser.currentUser()!
        let trainer = user.objectForKey("trainer") as! PFObject
        status = trainer.objectForKey("status") as? String
        self.tableView.hidden = true
        
        
        let loc: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
       
        
        if (self.hasPushEnabled() == false &&  (loc == CLAuthorizationStatus.Denied  || loc == CLAuthorizationStatus.NotDetermined)) {
            
            self.labelStatus.text = "Location and Notifications are required for Trainer"
            self.buttonShift.setTitle("Enable Location", forState: .Normal)
            self.buttonAction.setTitle("Remind me later", forState: .Normal)
            self.buttonAction.hidden = false
        }
        else if (loc == CLAuthorizationStatus.Denied  || loc == CLAuthorizationStatus.NotDetermined) {
            self.labelStatus.text = "Location is required for Trainer"
            self.buttonShift.setTitle("Enable Location", forState: .Normal)
            self.buttonAction.setTitle("Remind me later", forState: .Normal)
            self.buttonAction.hidden = false
        }
        else if self.hasPushEnabled() == false {
            self.labelStatus.text = "Notifications is required for Trainer"
            self.buttonShift.setTitle("Enable Notifications", forState: .Normal)
            self.buttonAction.setTitle("Remind me later", forState: .Normal)
            self.buttonAction.hidden = false
        }
        else if status == "available" {
            self.buttonAction.setTitle("Refresh list", forState: .Normal)
            self.buttonAction.hidden = false
            self.buttonShift.setTitle("End shift", forState: .Normal)
            if self.clientsAvailable() {
                self.labelStatus.text = "Clients available"
                self.tableView.hidden = false
            }
            else {
                self.labelStatus.text = "Waiting for client"
                self.tableView.hidden = true
            }
        }
        else {
            // if status == nil || status! == "off" {
            self.labelStatus.text = "Off duty"
            self.buttonShift.setTitle("Start shift", forState: .Normal)
            self.buttonAction.hidden = true
        }
    }
    
    func clientsAvailable() -> Bool {
        if self.nearbyWorkouts == nil {
            return false
        }
        if self.nearbyWorkouts!.count == 0 {
            return false
        }
        return true
    }

    // MARK: - Requests
    func didReceiveRequest(notification: NSNotification) {
        let userInfo = notification.userInfo as? [String: AnyObject]
        print("Sent info: \(userInfo!)")
        
        self.loadExistingRequestsWithCompletion { (results) -> Void in
            self.refreshStatus()
            self.reloadTable()
           // self.reloadMotivateMeTable()
        }
    }

    func loadExistingRequestsWithCompletion(completion: (results: [PFObject]?) -> Void) {
        
        
        /// get workout
        let query = PFQuery(className: "Workout")
        // don't actually need to search for given training request - display all active requests
        query.whereKey("status", equalTo: "requested")
        query.whereKeyDoesNotExist("trainer")
        if TESTING == 0 {
            query.whereKey("testing", notEqualTo: true)
        }
        self.labelStatus.text = "Searching for clients"
        query.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            if error != nil {
                print("could not query")
            }
            self.allWorkouts = results
            completion(results: results!)
        }
        
        
        //get MotivateMerequest
        
        let mquery = PFQuery(className: "MotivateMe")
        // don't actually need to search for given training request - display all active requests
        mquery.whereKey("status", equalTo: "requested")
        mquery.whereKeyDoesNotExist("trainer")
        if TESTING == 0 {
            mquery.whereKey("testing", notEqualTo: true)
        }
        mquery.findObjectsInBackgroundWithBlock { (results, error) -> Void in
            if error != nil {
                print("could not query for motivateMe")
            }
            self.allMotivateMeRequest = results
            completion(results: results!)
        }

    }
    
    // MARK: - TableViewDatasource
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
//        if tableView == self.motivateMetableView {
//            
//            if self.nearbyMotivateMeRequest != nil {
//                return self.nearbyMotivateMeRequest!.count
//            }
//            
//        }
        
        if tableView == self.tableView {

            if self.nearbyWorkouts != nil {
                return self.nearbyWorkouts!.count
            }
        }
        return 0
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if tableView == self.tableView {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TrainingRequestCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.currentLocation = self.currentLocation
            
            let request: PFObject = self.nearbyWorkouts![indexPath.row] as PFObject
            cell.setupWithRequest(request)
            
            return cell
        }
        else {
            
            let cell = tableView.dequeueReusableCellWithIdentifier("Cell", forIndexPath: indexPath) as! TrainingRequestCell
            cell.selectionStyle = UITableViewCellSelectionStyle.None
            cell.currentLocation = self.currentLocation
            
            let request: PFObject = self.nearbyMotivateMeRequest![indexPath.row] as PFObject
            cell.setupMotivateMeWithRequest(request)
            
            return cell

        }
     
    }
    
    func tableView(tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 1
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
        if tableView == self.tableView {
            let request: PFObject = self.nearbyWorkouts![indexPath.row] as PFObject
            self.connect(request)
        } else{
            let request: PFObject = self.nearbyMotivateMeRequest![indexPath.row] as PFObject
            self.connectMotivateMe(request)
        }
        
        
     
    }
    
    func connect(request: PFObject) {
        // TODO:
        // attempt to update the request with current trainer information. check to make sure request hasn't been accepted.
        // do this on Parse Cloudcode.
        // if request successfully updates, set request status to accepted
        // start a workout.
        
        self.motivateMeRequest = false
        request.fetchInBackgroundWithBlock { (workout, error) -> Void in
            if workout != nil {
                if workout!.objectForKey("status") as! String == "requested" {
                    self.performSegueWithIdentifier("GoToClientRequest", sender: request)
                    return
                }
            }
            self.simpleAlert("Client not available", message: "This workout is no longer available.", completion: { () -> Void in
                self.clientsDidChange()
            })
        }
        
    }
    
    func connectMotivateMe(request: PFObject) {
        // TODO:
        // attempt to update the request with current trainer information. check to make sure request hasn't been accepted.
        // do this on Parse Cloudcode.
        // if request successfully updates, set request status to accepted
        // start a MotivateMe.
        
        self.motivateMeRequest = true
        request.fetchInBackgroundWithBlock { (motivateMe, error) -> Void in
            if motivateMe != nil {
                if motivateMe!.objectForKey("status") as! String == "requested" {
                    self.performSegueWithIdentifier("GoToMotivateMe", sender: request)
                    return
                }
            }
            self.simpleAlert("Client not available", message: "This workout is no longer available.", completion: { () -> Void in
                self.clientsDidChange()
            })
        }
        
    }

    
    // MARK: - ClientInfoDelegate
    func clientsDidChange() {
        self.loadExistingRequestsWithCompletion({ (results) -> Void in
            self.refreshStatus()
            self.reloadTable()
           // self.reloadMotivateMeTable()
        })
    }
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "GoToClientRequest" {
            let request = sender as! PFObject
            let controller = segue.destinationViewController as! ClientInfoViewController
            controller.request = request
            controller.delegate = self
            
        }
        else if segue.identifier == "GoToMotivateMe" {
            let request = sender as! PFObject
            let controller = segue.destinationViewController as! MotivateMeViewController
            controller.request = request
        }
        
    }

    func goToInfo() {
        // about me
        self.performSegueWithIdentifier("GoToTrainerProfile", sender: nil)
    }
    
    // MARK: - CLLocationManagerDelegate
    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
        }
        else if status == .Denied {
            self.warnForLocationPermission()
            self.currentLocation = CLLocation(latitude: PHILADELPHIA_LAT, longitude: PHILADELPHIA_LON)
            print("Authorization is not available")
        }
        else {
            print("status unknown")
        }
        
        self.refreshStatus()
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first as CLLocation? {
            print("\(location)")
            self.currentLocation = location
            self.reloadTable()
            //self.reloadMotivateMeTable()
        }
    }

    func reloadTable() {
        if self.nearbyWorkouts == nil {
            self.nearbyWorkouts = [PFObject]()
        }
        self.nearbyWorkouts!.removeAll()
        
        if self.allWorkouts != nil {
            for request: PFObject in self.allWorkouts! {
                // load distance
                if self.currentLocation != nil {
                    let lat = request.objectForKey("lat") as? Double
                    let lon = request.objectForKey("lon") as? Double
                    if lat != nil && lon != nil {
                        let clientLocation: CLLocation = CLLocation(latitude: lat!, longitude: lon!)
                        let dist:Double = self.currentLocation!.distanceFromLocation(clientLocation)
                        request.setObject(dist, forKey: "distance") // local variable
                        
//                         ////Test

                        if dist < REQUEST_DISTANCE_METERS {
                            self.nearbyWorkouts!.append(request)
                        }
                        else {
                            print("distance too large: \(dist)")
                        }
                    }
                }
                else {
                    self.nearbyWorkouts!.append(request)
                }
            }
        }
        let sorted: [PFObject] = self.nearbyWorkouts!.sort { (p1, p2) -> Bool in
            if let d1:Double = p1.objectForKey("distance") as? Double {
                if let d2:Double = p2.objectForKey("distance") as? Double {
                    if d1 < d2 {
                        return true
                    }
                    return false
                }
                return false
            }
            return true
        }
        self.nearbyWorkouts = sorted

//        if self.nearbyWorkouts!.count == 0 {
//            self.tableView.hidden = true
//        }
//        else {
//            self.tableView.hidden = false
//        }
        
        self.refreshStatus()
        self.tableView.reloadData()
    }
    
    func reloadMotivateMeTable() {
       
        if self.allMotivateMeRequest != nil {
            self.nearbyMotivateMeRequest = self.allMotivateMeRequest
        }
  
        if self.nearbyMotivateMeRequest != nil {
            
            if self.nearbyMotivateMeRequest!.count == 0 {
                self.motivateMetableView.hidden = true
            }
            else {
                self.motivateMetableView.hidden = false
            }
            self.motivateMetableView.reloadData()
        }
        
    }
    
    func setRemoteNotificationPermissionShown (){
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "remoteNotificationPermissionShown")
    }
    
    
    func getRemoteNotificationPremissionStatus () -> Bool {
        return  NSUserDefaults.standardUserDefaults().boolForKey("remoteNotificationPermissionShown")
    }
    
    func warnForRemoteNotificationPermission() {
        
        dispatch_async(dispatch_get_main_queue(),{
            
            let message: String = "WeTrain needs notifications access to send notifications. Please go to your phone settings to enable notifications access. Go there now?"
            let alert: UIAlertController = UIAlertController(title: "Could not send notifications", message: message, preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
            }))
            
            alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.blackColor()
            
        })
        
    }
    

}
