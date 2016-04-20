//
//  MapViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 8/1/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit
import GoogleMaps
import Parse
import MBProgressHUD
import ParseFacebookUtilsV4

class MapViewController: UIViewController, CLLocationManagerDelegate, GMSMapViewDelegate, UITextFieldDelegate {

    var requestedTrainingType: Int?
    var requestedTrainingLength: Int?
    
    @IBOutlet var mapView: GMSMapView!
    @IBOutlet var iconLocation: UIImageView!
    let locationManager = CLLocationManager()
    var currentLocation: CLLocation?
    
    @IBOutlet var buttonRequest: UIButton!
    
    // address view
    @IBOutlet var inputStreet: UITextField!
    @IBOutlet var inputStreetBg: UIImageView?

    
    var inputManualAddress: UITextField?
    var inputPromoCode: UITextField?

    
    // request status
    var requestMarker: GMSMarker?
    
    var currentRequest: PFObject?
    
    var warnedAboutService: Bool = false
    
    var LocationCompletionHandler: (NSString?) -> Void = { (response) in
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.buttonRequest.enabled = false
        
        locationManager.delegate = self
        
        if (locationManager.respondsToSelector("requestWhenInUseAuthorization")) {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()

        }
        else {
            locationManager.startUpdatingLocation()
        }

        self.mapView.myLocationEnabled = true
        self.iconLocation.layer.zPosition = 1
        self.iconLocation.image = UIImage(named: "iconLocation")!.imageWithRenderingMode(UIImageRenderingMode.AlwaysTemplate)
        self.iconLocation.tintColor = UIColor(red: 215.0/255.0, green: 84.0/255.0, blue: 82.0/255.0, alpha: 1)

        // always allow button
        self.buttonRequest.enabled = true
        self.buttonRequest.layer.zPosition = 1
        self.buttonRequest.alpha = 1

        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]

        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: UIBarButtonItemStyle.Done, target: self, action: "close")
        self.title = "Select Location"
        
        self.inputStreet.clearButtonMode = UITextFieldViewMode.Always;
        
        //done button for keyboard
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        doneToolbar.barStyle = UIBarStyle.BlackTranslucent
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: UIBarButtonItemStyle.Done, target: self, action: Selector("cancelButtonAction"))
        
        let items = NSMutableArray()
        items.addObject(flexSpace)
        items.addObject(done)
        
        doneToolbar.items = [flexSpace,done]
        doneToolbar.sizeToFit()

        self.inputStreet!.inputAccessoryView = doneToolbar

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func close() {
         self.navigationController!.popViewControllerAnimated(true)
       // self.navigationController!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        
        UIApplication.sharedApplication().statusBarStyle = .LightContent
        
        if (self.appDelegate().OptionType == "Train Later")
        {
            self.buttonRequest.setTitle("Schedule a Session", forState: UIControlState.Normal)
        }
        else
        {
            self.buttonRequest.setTitle("Request a Trainer!", forState: UIControlState.Normal)
        }
        
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
        
        self.appDelegate().refreshUser()
    }

    override func warnForLocationPermission() {
        let message: String = "WeTrain needs GPS access to find trainers near you. Please go to your phone settings to enable location access. Go there now?"
        let alert: UIAlertController = UIAlertController(title: "Could not access location", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }
    
    func warnAboutService() {
        self.warnedAboutService = true
        
        // delay 
//        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
//        dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
        
            let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
            let tabNabcontroller : UINavigationController = tcon.selectedViewController as! UINavigationController
            
            if tabNabcontroller.visibleViewController == self {
                
                let message: String = "You are outside the on-demand booking area. Don't worry - just use our handy scheduler to book a session at least an hour in advance so we can get you working out in no time!"
                let alert: UIAlertController = UIAlertController(title: "Sorry!", message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "Close", style: .Cancel, handler: nil))
                alert.addAction(UIAlertAction(title: "Let's Schedule!", style: .Default, handler: { (action) -> Void in
                    self.moveToScheduleScreen()
                }))
                tabNabcontroller.presentViewController(alert, animated: true, completion: nil)
                alert.view.tintColor = UIColor.blackColor()
            }
//        }
        
    }
    
    func goToUserProfile() {
        
        dispatch_async(dispatch_get_main_queue(),{
            
            let controller: UserInfoViewController = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("UserInfoViewController") as! UserInfoViewController
            controller.isUpdate = true
            let nav: UINavigationController = UINavigationController(rootViewController: controller)
            Generals.appRootController().presentViewController(nav, animated: true, completion: nil)

        })

    }


    // MARK: - CLLocationManagerDelegate
    func locationManager(manager: CLLocationManager, didChangeAuthorizationStatus status: CLAuthorizationStatus) {
        mapView.settings.myLocationButton = true
        
        if status == .AuthorizedWhenInUse || status == .AuthorizedAlways {
            locationManager.startUpdatingLocation()
            mapView.myLocationEnabled = true
            mapView.settings.myLocationButton = true
        }
        else if status == .Denied {
            //self.warnForLocationPermission()
            self.currentLocation = CLLocation(latitude: PHILADELPHIA_LAT, longitude: PHILADELPHIA_LON)
            self.updateMapToCurrentLocation()
            print("Authorization is not available")
            self.locationCallbackwithResult("Completed")

        }
        else {
            print("status unknown")
            self.locationCallbackwithResult("Completed")

        }
    }
    
    func locationManager(manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first as CLLocation? {
            locationManager.stopUpdatingLocation()
            self.currentLocation = location
            self.updateMapToCurrentLocation()
            
            if self.warnedAboutService == false {
                if !self.inServiceRange() {
                    
                    let time = dispatch_time(DISPATCH_TIME_NOW, Int64(1 * Double(NSEC_PER_SEC)))
                    dispatch_after(time, dispatch_get_main_queue()) { () -> Void in
                        self.warnAboutService()
                    }
                    
                }
            }
        }
        
        self.locationCallbackwithResult("Completed")
        
    }
    
    func locationManager(manager: CLLocationManager, didFailWithError error: NSError) {
          self.currentLocation = CLLocation(latitude: PHILADELPHIA_LAT, longitude: PHILADELPHIA_LON)
          self.locationCallbackwithResult("FailwithError")
    }


    func updateMapToCurrentLocation() {
        var zoom = self.mapView.camera.zoom
        if zoom < 12 {
            zoom = 17
        }
        self.mapView.camera = GMSCameraPosition(target: self.currentLocation!.coordinate, zoom: zoom, bearing: 0, viewingAngle: 0)
    }
    
    func inServiceRange() -> Bool {
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
        
        if (self.appDelegate().OptionType == "Train Later")
        {
            
            return true
            
//            if dist > SCHEDULE_SERVICE_RANGE_METERS {
//                return false
//            }
        }
        else
        {
            if dist > SERVICE_RANGE_METERS {
                return false
            }
        }
        
        return true
    }
    
    
    
    func locationCallbackwithResult(locationManagerStatus : NSString!) {
        
        let controller: ScheduleConfirmationViewController = self.appDelegate().scheduleConfirmationCon!
        if(controller.confirmationType == confimationScreentype.FromWorkOutReminder){
            
            self.appDelegate().Locationcompletion(result: locationManagerStatus as String)
        }
    }
    
    
    // MARK: - GMSMapView  delegate
    func didTapMyLocationButtonForMapView(mapView: GMSMapView!) -> Bool {
        self.view.endEditing(true)

        if self.currentLocation != nil {
            let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
            if status == CLAuthorizationStatus.Denied {
                self.warnForLocationPermission()
            }
            self.updateMapToCurrentLocation()
        }
        locationManager.startUpdatingLocation()
        return false
    }
    
    func mapView(mapView: GMSMapView!, idleAtCameraPosition position: GMSCameraPosition!) {
        self.currentLocation = CLLocation(latitude: position.target.latitude, longitude: position.target.longitude)
        let coder = CLGeocoder()
        coder.reverseGeocodeLocation(self.currentLocation!) { (results, error) -> Void in
            if error != nil {
                print("error: \(error!.userInfo)")
                self.simpleAlert("Could not find your current address", message: "Please reposition the map and try again")
            }
            else {
                print("result: \(results)")
                if let placemarks: [CLPlacemark]? = results as [CLPlacemark]? {
                    if let placemark: CLPlacemark = placemarks!.first as CLPlacemark! {
                        print("name \(placemark.name) address \(placemark.addressDictionary)")
                        if let dict: [String: AnyObject] = placemark.addressDictionary as? [String: AnyObject] {
                            if let lines = dict["FormattedAddressLines"] {
                                print("lines: \(lines)")
                                if lines.count > 0 {
                                    self.inputStreet.text = lines[0] as? String
                                }
                                if lines.count > 1 {
                                    self.inputStreet.text =   (self.inputStreet.text! as String) + ", " + (lines[1] as? String)!
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // MARK: Location search
    @IBAction func didClickSearch(button: UIButton) {
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.Denied {
            self.warnForLocationPermission()
            return
        }

        let prompt = UIAlertController(title: "Enter Address", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        prompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        prompt.addAction(UIAlertAction(title: "Search", style: .Default, handler: { (action) -> Void in
            self.searchForAddress()
        }))
        prompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Enter your address here"
            self.inputManualAddress = textField
        })
        self.presentViewController(prompt, animated: true, completion: nil)
        prompt.view.tintColor = UIColor.blackColor()

    }
    
    func searchForAddress() {
        if self.inputManualAddress!.text == nil {
            return
        }
        
        let address: String = self.inputManualAddress!.text!
        print("address: \(address)")
        
        self.view.endEditing(true)
        
        let coder = CLGeocoder()
        coder.geocodeAddressString(address, completionHandler: { (results, error) -> Void in
            if error != nil {
                print("error: \(error!.userInfo)")
                self.simpleAlert("Could not find that location", message: "Please check your address and try again")
            }
            else {
                print("result: \(results)")
                if let placemarks: [CLPlacemark]? = results as [CLPlacemark]? {
                    if let placemark: CLPlacemark = placemarks!.first as CLPlacemark! {
                        self.currentLocation = CLLocation(latitude: placemark.location!.coordinate.latitude, longitude: placemark.location!.coordinate.longitude)
                        self.updateMapToCurrentLocation()
                    }
                }
            }
        })
    }
    
    // MARK: - TextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        
        textField.resignFirstResponder()

        self.inputManualAddress = textField
        self.searchForAddress()
        

        return true
    }

    // MARK: - request
    @IBAction func didClickRequest(sender: UIButton) {
        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()
        if status == CLAuthorizationStatus.NotDetermined {
            self.warnForLocationPermission()
            return
        }
        
        if PFUser.currentUser() == nil {
            let alert: UIAlertController = UIAlertController(title: "Please Login or Sign up", message: "Before you start using WeTrain,\n you must create a user profile!", preferredStyle: UIAlertControllerStyle.Alert)
            alert.addAction(UIAlertAction(title: "Close", style: .Cancel, handler: { (action) -> Void in
                print("cancel")
            }))
            alert.addAction(UIAlertAction(title: "Log in", style: .Default, handler: { (action) -> Void in
                self.login()
            }))
            alert.addAction(UIAlertAction(title: "Sign up", style: .Default, handler: { (action) -> Void in
                self.signup()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.blackColor()

            return
        }
        
        
        if sender == self.buttonRequest  {
            
            if self.getRemoteNotificationPremissionStatus()
            {
                if !self.hasPushEnabled() {
                    self.warnForRemoteNotificationPermission()
                    return
                }
            }
            else
            {
                self.registerForRemoteNotifications()
                return
            }
            
        }
        

        
        if (self.appDelegate().OptionType == "Train Later")
        {
            if !self.checkAndAskForCalendarPermission() {
                print("not authorized")
                return
            }
        }
        
        
        Generals.ShowLoadingView()

        
        ///check for "please complete profile"
        let clientObject: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        
        clientObject.fetchInBackgroundWithBlock({ (result, error) -> Void in
            
            if result != nil {
                
                
                let arrayIncomplete = NSMutableArray()
                
               
                if let card = clientObject.objectForKey("card") as? String {
                    if card.characters.count == 0{
                        arrayIncomplete.addObject("Credit Card")
                    }
                } else {
                    arrayIncomplete.addObject("Credit Card")
                }

                
                if let phone = clientObject.objectForKey("phone") as? String {
                    if phone.characters.count == 0{
                        arrayIncomplete.addObject("phone")
                    }
                } else {
                        arrayIncomplete.addObject("phone")
                }
                
                if let checkedTOS = clientObject.objectForKey("checkedTOS") as? Bool {
                    if checkedTOS == false{
                        arrayIncomplete.addObject("Agreed to Terms of Service")
                    }
                } else {
                    arrayIncomplete.addObject("Agreed to Terms of Service")
                }
                
                
                let linkedWithFacebook :Bool = PFFacebookUtils.isLinkedWithUser(PFUser.currentUser()!)
                
                if linkedWithFacebook == true {
                    if let email: String = PFUser.currentUser()!.objectForKey("email") as? String{
                        
                        if email.characters.count == 0{
                            arrayIncomplete.addObject("email")
                        }
                        
                    } else {
                        arrayIncomplete.addObject("email")
                    }
                    
                }
                
            
                Generals.hideLoadingView()

                if arrayIncomplete.count > 0 {
                    
                    let alertMessage = "We need you to fill out some required \n information so we can send you a \n trainer! It only takes a minute, and \n the more you tell us, the more we \n can customize your workout!"
                    
                    /*for var index = 0; index < arrayIncomplete.count; ++index {
                        
                        if (arrayIncomplete.count > 1 && index == arrayIncomplete.count - 1) { /// last element
                            alertMessage = alertMessage.stringByAppendingFormat(" and %@", arrayIncomplete.objectAtIndex(index) as! String)
                        } else if (arrayIncomplete.count > 1 && index > 0) { /// in between
                            alertMessage = alertMessage.stringByAppendingFormat(", %@", arrayIncomplete.objectAtIndex(index) as! String)
                        } else {  /// in first
                            alertMessage = alertMessage.stringByAppendingFormat(" %@", arrayIncomplete.objectAtIndex(index) as! String)
                        }
                        
                    }
                    
                    alertMessage = alertMessage.stringByAppendingString(" before requesting a trainer so that they can contact you. Don't worry it's easy, just head over to the account tab to finish setting up your account!")*/

                    
                    let alert: UIAlertController = UIAlertController(title: "Please Complete Profile", message: alertMessage, preferredStyle: UIAlertControllerStyle.Alert)
                    alert.addAction(UIAlertAction(title: "Update My Profile", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                        self.goToUserProfile()
                    }))
                    
                    self.presentViewController(alert, animated: true, completion: nil)
                    alert.view.tintColor = UIColor.blackColor()

                    return

                }
                
                
            }
            else {
                
                 Generals.hideLoadingView()

                // user's client was not found
                
                let alert: UIAlertController = UIAlertController(title: "Message", message: "User not found. Before you start using WeTrain, you \n must create a user! \n Sign up now?", preferredStyle: UIAlertControllerStyle.Alert)
                alert.addAction(UIAlertAction(title: "Close", style: UIAlertActionStyle.Cancel, handler: { (action) -> Void in
                    print("cancel")
                }))
                
                self.presentViewController(alert, animated: true, completion: nil)
                alert.view.tintColor = UIColor.blackColor()

                return
               
            }
            
             Generals.hideLoadingView()

            self.doRequest()
            
        })


    }
    
    func doRequest(){
        
        
        if !self.inServiceRange() {
            self.warnAboutService()
            return
        }
        
        Generals.ShowLoadingView()


//        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
//        client.refreshInBackgroundWithBlock { (object, error) -> Void in
//            
//            
////            if client.objectForKey("firstName") == nil || client.objectForKey("lastName") == nil || client.objectForKey("phone") == nil || client.objectForKey("photo") == nil {
////                self.simpleAlert("Please complete profile", message: "You must add your name, phone, and photo before requesting a trainer so that they can contact you. Go to the Account tab edit your profile.")
////                
////                MBProgressHUD.hideAllHUDsForView(self.appDelegate().window, animated: false)
////
////                return
////            }
//           
//        }
        
        
        if self.currentLocation != nil {
            if self.inputStreet.text != nil {
                let addressString = "\(self.inputStreet.text!)"
                
                self.moveToConfirmScreen(self.currentLocation!.coordinate)
                
                 Generals.hideLoadingView()
                
                return
            }
            let coder = GMSGeocoder()
            coder.reverseGeocodeCoordinate(self.currentLocation!.coordinate, completionHandler: { (response, error) -> Void in
                if let gmresponse:GMSReverseGeocodeResponse = response as GMSReverseGeocodeResponse! {
                    let results: [AnyObject] = gmresponse.results()
                    let addresses: [GMSAddress] = results as! [GMSAddress]
                    let address: GMSAddress = addresses.first!
                    
                    var addressString: String = ""
                    let lines: [String] = address.lines as! [String]
                    for line: String in lines {
                        addressString = "\(addressString)\n\(line)"
                    }
                    print("Address: \(addressString)")
                    
                    self.moveToConfirmScreen(address.coordinate)
                    
                }
                else {
                    self.simpleAlert("Invalid location", message: "We could not request a session; your current location is invalid")
                    Generals.hideLoadingView()

                }
            })
        }
        else {
            self.simpleAlert("Invalid location", message: "We could not request a session; your current location was invalid")
            Generals.hideLoadingView()

        }
        

    }
    
    
    
    func initiateWorkoutRequest(addressString: String, coordinate: CLLocationCoordinate2D) {
        var dict: [String: AnyObject] = [String: AnyObject]()
        dict = ["time": NSDate(), "lat": Double(coordinate.latitude), "lon": Double(coordinate.longitude), "status":RequestState.Searching.rawValue, "address": addressString]
        
        let request: PFObject = PFObject(className: "Workout", dictionary: dict)
        let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        let id = client.objectId
        print("client: \(client) \(id)")
        request.setObject(client, forKey: "client")
        if self.requestedTrainingType != nil {
            let title = TRAINING_TITLES[self.requestedTrainingType!]
            request.setObject(title, forKey: "type")
        }
        if self.requestedTrainingLength != nil {
            request.setObject(self.requestedTrainingLength!, forKey: "length")
        }
        if TESTING == 1 {
            request.setObject(true, forKey: "testing")
        }
        print("request: \(request)")
        request.saveInBackgroundWithBlock { (success, error) -> Void in
            print("saved: \(success)")
            client.setObject(request, forKey: "workout")
            client.saveInBackground()
            
            if success {
                self.currentRequest = request
                self.performSegueWithIdentifier("GoToRequestState", sender: nil)
                
                // subscribe to channel
                if request.objectId != nil {
                    let currentInstallation = PFInstallation.currentInstallation()
                    let requestId: String = request.objectId!
                    let channelName = "workout_\(requestId)"
                    currentInstallation.addUniqueObject(channelName, forKey: "channels")
                    currentInstallation.setObject(PFUser.currentUser()!.objectId!, forKey: "userId")
                    currentInstallation.saveInBackgroundWithBlock({ (success, error) -> Void in
                        if success {
                            let channels = currentInstallation.objectForKey("channels")
                            print("installation registering while initiating: channel \(channels)")
                        }
                        else {
                            print("installation registering error:\(error)")
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
     
   
    func moveToConfirmScreen(coordinate: CLLocationCoordinate2D) {
        
        
        let controller: ScheduleConfirmationViewController = self.appDelegate().scheduleConfirmationCon!
        
        if(controller.confirmationType != confimationScreentype.FromWorkOutReminder){
            
            controller.confirmationType         = confimationScreentype.FromMap;
        }
        
        if (self.requestedTrainingType != nil){
            controller.requestedTrainingType    = self.requestedTrainingType
        }
        
        if (self.requestedTrainingLength != nil){
            controller.requestedTrainingLength    = self.requestedTrainingLength
        }
        
        controller.addressCoordinate        = coordinate
        controller.isRefresh = true
        controller.parentController         = self
        
        if self.inputStreet.text != nil  {
            controller.requestedLocation = "\(self.inputStreet.text!)"
        }
        
        showConfirmScreen(controller)
       
    }
    
    func showConfirmScreen(controller : ScheduleConfirmationViewController){
        
        self.buttonRequest.hidden = true
        self.inputStreet?.hidden = true
        self.inputStreetBg?.hidden = true
        
        
        
        if self.inServiceRange() == true {
            
            //animate view as like as modal
            controller.view.frame = CGRectMake(self.appDelegate().window!.frame.origin.x, self.appDelegate().window!.frame.size.height, self.appDelegate().window!.frame.size.width, self.appDelegate().window!.frame.size.height)
            self.appDelegate().window!.addSubview(controller.view)
            
            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                
                controller.view.frame =  CGRectMake(self.appDelegate().window!.frame.origin.x, self.appDelegate().window!.frame.origin.y, self.appDelegate().window!.frame.size.width, self.appDelegate().window!.frame.size.height)
                
                self.view.layoutIfNeeded()

                }, completion: { _ in
                    Generals.hideLoadingView()

            })
            
            
            

            
        } else {
            
            
            Generals.hideLoadingView()

            
            if self.currentLocation == nil {
                
                let message: String = "WeTrain is not available in your area. We currently service the Philadelphia area. Please stay tuned for more cities!"
                let alert: UIAlertController = UIAlertController(title: "WeTrain unavailable", message: message, preferredStyle: .Alert)
                alert.addAction(UIAlertAction(title: "ok", style: .Default, handler: { (action) -> Void in
                    self.showConfirmScreen(controller)
                }))
                self.presentViewController(alert, animated: true, completion: nil)
                alert.view.tintColor = UIColor.blackColor()

            }
            else {
                self.warnAboutService()
            }
        }
        
    }
    
    // MARK: - Navigation
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "GoToRequestState" {
            let controller: RequestStatusViewController = segue.destinationViewController as! RequestStatusViewController
            controller.currentRequest = self.currentRequest
        }
        else if segue.identifier == "GoToViewTrainer" {
            let controller: TrainerProfileViewController = segue.destinationViewController as! TrainerProfileViewController
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
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }
    
    func cancelButtonAction()
    {
        self.inputStreet?.resignFirstResponder()
    }
    
    
    func warnForRemoteNotificationPermission() {
        
        dispatch_async(dispatch_get_main_queue(),{
            
            let message: String = "WeTrain needs notifications access to send notifications. Please go to your phone settings to enable notifications access. Go there now?"
            let alert: UIAlertController = UIAlertController(title: "Could not send notifications", message: message, preferredStyle: .Alert)
            
            alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
                self.didClickRequest(UIButton())
            }))
            
            
            alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
                UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            alert.view.tintColor = UIColor.blackColor()
            
        })
        
    }
    
    
    func registerForRemoteNotifications() {
        let alert = UIAlertController(title: "Enable push notifications?", message: "To receive notifications you must enable push. In the next popup, please click OK.", preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: { (action) -> Void in
            self.didClickRequest(UIButton())
        }))
        
        
        alert.addAction(UIAlertAction(title: "OK", style: .Default, handler: { (action) -> Void in
            let settings = UIUserNotificationSettings(forTypes: [.Alert, .Badge, .Sound], categories: nil)
            UIApplication.sharedApplication().registerUserNotificationSettings(settings)
            UIApplication.sharedApplication().registerForRemoteNotifications()
            self.setRemoteNotificationPermissionShown()
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()
        
    }
    

}
