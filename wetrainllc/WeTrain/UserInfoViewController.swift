//
//  UserInfoViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 10/19/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import Photos
import ParseFacebookUtilsV4
import MBProgressHUD

let genders = ["Select gender", "Male", "Female", "Other"]
class UserInfoViewController: UIViewController, UITextFieldDelegate, CreditCardDelegate, UIPickerViewDelegate, UIPickerViewDataSource, UIGestureRecognizerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    @IBOutlet weak var buttonPhotoView: UIButton!
    @IBOutlet weak var buttonEditPhoto: UIButton!
    
    @IBOutlet var inputFirstName: UITextField!
    @IBOutlet var inputLastName: UITextField!
    @IBOutlet var inputPhone: UITextField!
    @IBOutlet var inputGender: UITextField!
    @IBOutlet var inputAge: UITextField!
    @IBOutlet var inputInjuries: UITextField!
    @IBOutlet var inputCreditCard: UITextField!
    @IBOutlet var inputEmail: UITextField!
    @IBOutlet var txtTOS: UITextView!
    @IBOutlet var lblAcceptTOS: UILabel!


    var currentInput: UITextField?
    
    @IBOutlet var scrollView: UIScrollView!
    @IBOutlet var viewScrollContent: UIView!
    @IBOutlet var constraintContentWidth: NSLayoutConstraint!
    @IBOutlet var constraintContentHeight: NSLayoutConstraint!
    
    @IBOutlet var constraintScrollTopOffset: NSLayoutConstraint!
    @IBOutlet var constraintScrollContentTopOffset: NSLayoutConstraint!

    @IBOutlet var constraintTopOffset: NSLayoutConstraint!
    @IBOutlet var constraintBottomOffset: NSLayoutConstraint!
    
    var isSignup:Bool = false
    var isUpdate:Bool = false

    var selectedPhoto: UIImage?
    
    var client: PFObject?
    
    var proxyViewForStatusBar : UIView!
    var checked: Bool = false
    
    @IBOutlet var viewTOS: UIView!
    @IBOutlet var buttonTOS: UIButton!

    var viewLoaded:Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.userInfoSetTitleBarColor(UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), tintColor: UIColor(red: 0, green: 122/255, blue: 1, alpha: 1))
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        
     
     
        
        // Do any additional setup after loading the view.
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "Save", style: .Done, target: self, action: "didUpdateInfo:")
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillShow:", name: UIKeyboardWillShowNotification, object: nil)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillHide:", name: UIKeyboardWillHideNotification, object: nil)
        
        let picker = UIPickerView()
        picker.delegate = self
        picker.dataSource = self
        self.inputGender.inputView = picker

        let keyboardDoneButtonView: UIToolbar = UIToolbar()
        keyboardDoneButtonView.sizeToFit()
        keyboardDoneButtonView.barStyle = UIBarStyle.Black
        keyboardDoneButtonView.tintColor = UIColor.whiteColor()
        let button: UIBarButtonItem = UIBarButtonItem(title: "Next", style: UIBarButtonItemStyle.Done, target: self, action: "dismissKeyboard")
        let flex: UIBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        keyboardDoneButtonView.setItems([flex, button], animated: true)
        
        self.inputPhone.inputAccessoryView = keyboardDoneButtonView
        self.inputEmail.inputAccessoryView = keyboardDoneButtonView
        self.inputFirstName.inputAccessoryView = keyboardDoneButtonView

        self.inputLastName.inputAccessoryView = keyboardDoneButtonView
        self.inputPhone.inputAccessoryView = keyboardDoneButtonView
        self.inputAge.inputAccessoryView = keyboardDoneButtonView
        self.inputGender.inputAccessoryView = keyboardDoneButtonView
        self.inputInjuries.inputAccessoryView = keyboardDoneButtonView
        
        
        var paddingview : UIView = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputPhone.leftView  = paddingview
        self.inputPhone.leftViewMode = UITextFieldViewMode.Always
        
        paddingview  = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputCreditCard.leftView  = paddingview
        self.inputCreditCard.leftViewMode = UITextFieldViewMode.Always
        
        paddingview  = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputEmail.leftView  = paddingview
        self.inputEmail.leftViewMode = UITextFieldViewMode.Always
        
        paddingview  = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputFirstName.leftView  = paddingview
        self.inputFirstName.leftViewMode = UITextFieldViewMode.Always
        
        paddingview = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputLastName.leftView  = paddingview
        self.inputLastName.leftViewMode = UITextFieldViewMode.Always
        
        paddingview  = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputAge.leftView  = paddingview
        self.inputAge.leftViewMode = UITextFieldViewMode.Always
        
        paddingview  = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputGender.leftView  = paddingview
        self.inputGender.leftViewMode = UITextFieldViewMode.Always
        
        paddingview  = UIView(frame: CGRectMake(0, 0, 5, self.inputPhone.frame.size.height))
        self.inputInjuries.leftView  = paddingview
        self.inputInjuries.leftViewMode = UITextFieldViewMode.Always
        
        let tap = UITapGestureRecognizer(target: self, action: "handleGesture:")
        tap.delegate = self
        self.viewScrollContent.addGestureRecognizer(tap)
        let tap2 = UITapGestureRecognizer(target: self, action: "handleGesture:")
        self.view.addGestureRecognizer(tap2)

        if self.isSignup {
            let left: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: "cancel")
            left.tintColor = UIColor.orangeColor()
            self.navigationItem.leftBarButtonItem = left
        }
        else if self.isUpdate {
            
            let left: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: "cancel")
            left.tintColor = UIColor.orangeColor()
            self.navigationItem.leftBarButtonItem = left
        }
        else {
            
             self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "My Account", style: .Done, target: self, action: "back")
        }
        
        let clientObject: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
        clientObject.fetchInBackgroundWithBlock({ (result, error) -> Void in
            self.client = clientObject
            if result != nil {
                if let file = self.client!.objectForKey("photo") as? PFFile {
                    file.getDataInBackgroundWithBlock { (data, error) -> Void in
                        if data != nil {
                            let photo: UIImage = UIImage(data: data!)!
                            self.buttonPhotoView.setImage(photo, forState: .Normal)
                            self.buttonPhotoView.layer.cornerRadius = self.buttonPhotoView.frame.size.width / 2
                            
                            self.buttonEditPhoto.setTitle("Edit photo", forState: .Normal)
                            self.selectedPhoto = photo
                        }
                    }
                }
                
                // populate all info
                if let firstName = self.client!.objectForKey("firstName") as? String {
                    print("first: \(firstName)")
                    self.inputFirstName.text = firstName
                }
                if let lastName = self.client!.objectForKey("lastName") as? String {
                    self.inputLastName.text = lastName
                }
                if let phone = self.client!.objectForKey("phone") as? String {
                    self.inputPhone.text = phone
                }
                if let age = self.client!.objectForKey("age") as? String {
                    self.inputAge.text = age
                }
                if let gender = self.client!.objectForKey("gender") as? String {
                    self.inputGender.text = gender
                }
                if let injuries = self.client!.objectForKey("injuries") as? String {
                    self.inputInjuries.text = injuries
                }
                if let last4: String = self.client!.objectForKey("stripeFour") as? String{
                    self.inputCreditCard.text = "Credit Card: *\(last4)"
                }
                
                let linkedWithFacebook :Bool = PFFacebookUtils.isLinkedWithUser(PFUser.currentUser()!)
                
                if let checkedTOS = clientObject.objectForKey("checkedTOS") as? Bool {
                    
                    self.checked = checkedTOS
                }
                self.refreshButton()

                
                if linkedWithFacebook == true {
                    self.constraintTopOffset.constant = 57
                    self.inputEmail.hidden = false
//                    self.viewTOS.hidden = false
//                    self.txtTOS.hidden  = false
                    self.constraintContentHeight.constant = 920
                  
                    if let email: String = PFUser.currentUser()!.objectForKey("email") as? String{
                        self.inputEmail.text = email
                    }
                    
                } else {
                    self.constraintTopOffset.constant = 15
                    self.inputEmail.hidden = true
//                    self.viewTOS.hidden = true
//                    self.txtTOS.hidden  = true
                    self.constraintContentHeight.constant = 875


                }
                
                
            }
            else {
                // user's client was deleted; create a new one
                self.client! = PFObject(className: "Client")
                PFUser.currentUser()!.setObject(self.client!, forKey: "client")
                PFUser.currentUser()!.saveInBackground()
            }
        })
        
        
        let placeholderstring  = "Phone Number*"
        var holderMutableString = NSMutableAttributedString()
        holderMutableString = NSMutableAttributedString(string: placeholderstring, attributes: [NSFontAttributeName:self.inputPhone.font!])
        holderMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSRange(location:12,length:1))
        self.inputPhone.attributedPlaceholder = holderMutableString
        
        
        let cplaceholderstring  = "Credit Card Info*"
        var cholderMutableString = NSMutableAttributedString()
        cholderMutableString = NSMutableAttributedString(string: cplaceholderstring, attributes: [NSFontAttributeName:self.inputPhone.font!])
        cholderMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSRange(location:16,length:1))
        self.inputCreditCard.attributedPlaceholder = cholderMutableString
        
        
        let eplaceholderstring  = "Email*"
        var eholderMutableString = NSMutableAttributedString()
        eholderMutableString = NSMutableAttributedString(string: eplaceholderstring, attributes: [NSFontAttributeName:self.inputPhone.font!])
        eholderMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSRange(location:5,length:1))
        self.inputEmail.attributedPlaceholder = eholderMutableString
        
        
        let lblAcceptTOSstring  = "I have read and agree to the Terms of Service*"
        var lblAcceptTOSstringMutableString = NSMutableAttributedString()
        lblAcceptTOSstringMutableString = NSMutableAttributedString(string: lblAcceptTOSstring, attributes: [NSFontAttributeName:self.inputPhone.font!])
        lblAcceptTOSstringMutableString.addAttribute(NSForegroundColorAttributeName, value: UIColor.redColor(), range: NSRange(location:lblAcceptTOSstring.characters.count - 1,length:1))
        self.lblAcceptTOS.attributedText = lblAcceptTOSstringMutableString
        
        
        
        
        
       
        if self.inputEmail.hidden {
            self.constraintContentHeight.constant = 870
        } else {
            self.constraintContentHeight.constant = 920
        }


    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        
        if !viewLoaded {
            self.txtTOS.setContentOffset(CGPointMake(0, 0), animated: true)
        }

    }

    
    override func viewWillAppear(animated: Bool) {
        self.scrollView.setContentOffset(CGPointMake(0, 0), animated: false)
        UIApplication.sharedApplication().statusBarStyle = .Default
        
        
        proxyViewForStatusBar  = UIView(frame: CGRectMake(0, 0,self.view.frame.size.width, 20))
        proxyViewForStatusBar.backgroundColor=UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        self.navigationController!.view.addSubview(proxyViewForStatusBar)
        UIApplication.sharedApplication().statusBarStyle = .Default


    }
    
    override func viewWillDisappear(animated: Bool) {
        proxyViewForStatusBar.removeFromSuperview()
    }
  
    
    func nothing() {
        // hides left button
    }

    func dismissKeyboard() {
        if self.currentInput! == self.inputPhone {
            self.inputCreditCard.becomeFirstResponder()
        }
        else if self.currentInput! == self.inputCreditCard {
            self.inputEmail.becomeFirstResponder()
        }
        else if self.currentInput! == self.inputEmail {
            self.inputFirstName.becomeFirstResponder()
        }
        else if self.currentInput! == self.inputFirstName {
            self.inputLastName.becomeFirstResponder()
        }
        else if self.currentInput! == self.inputLastName {
            self.inputAge.becomeFirstResponder()
        }
        else if self.currentInput! == self.inputAge {
            self.inputGender.becomeFirstResponder()
        }
        else if self.currentInput! == self.inputGender {
            self.inputInjuries.becomeFirstResponder()
        }
        else {
            self.view.endEditing(true)
        }
    }
    
    func handleGesture(sender: UIGestureRecognizer) {
        if sender.isKindOfClass(UITapGestureRecognizer) {
            self.view.endEditing(true)
        }
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer.isKindOfClass(UITapGestureRecognizer) {
            let location: CGPoint = touch.locationInView(self.viewScrollContent)
            for input: UIView in [self.inputFirstName, self.inputLastName, self.inputPhone, self.inputGender, self.inputAge, self.inputInjuries, self.inputCreditCard] {
                if CGRectContainsPoint(input.frame, location) {
                    return false
                }
            }
        }
        return true
    }

    func didUpdateInfo(sender: AnyObject) {

        
            
        let phone = self.inputPhone.text
        if phone?.characters.count == 0 {
            self.simpleAlert("Please enter a valid phone number", message: nil)
            return
        }
        
        let four = self.inputCreditCard.text
        if four?.characters.count == 0 {
            self.simpleAlert("Please enter a valid credit card", message: nil)
            return
        }
        
        if (self.inputEmail.hidden == false) {
            
            let email = self.inputEmail.text
            if email?.characters.count == 0 {
                self.simpleAlert("Please enter a valid email address", message: nil)
                return
            }
            
            if !self.isValidEmail(email!) {
                self.simpleAlert("Please enter a valid email address", message: nil)
                return
            }
            
        }
        
        if  self.checked  != true {
             self.simpleAlert("Please agree to the Terms and Conditions", message: "You must read the Terms and Conditions and check the box to continue.")
            return
        }
        
        
        /*
        let gender = self.inputGender.text
        if gender?.characters.count == 0 {
        self.simpleAlert("Please enter your gender", message: nil)
        return
        }
        
        let age = self.inputAge.text
        if age?.characters.count == 0 {
        self.simpleAlert("Please enter your age", message: nil)
        return
        }
        */

        /*
        let four = self.inputCreditCard.text
        if four?.characters.count == 0 {
            let alert: UIAlertController = UIAlertController(title: "Skip payment method?", message: "Are you sure you want to complete signup without adding your credit card? You won't be able to request a workout. You can add a credit card later.", preferredStyle: .Alert)
            alert.addAction(UIAlertAction(title: "Continue signup", style: .Default, handler: { (action) -> Void in
                self.updateClientProfile()
            }))
            alert.addAction(UIAlertAction(title: "Add payment", style: .Cancel, handler: { (action) -> Void in
                self.inputCreditCard.becomeFirstResponder()
            }))
            self.presentViewController(alert, animated: true, completion: nil)
        }
        else {
            self.updateClientProfile()
        }
        */
        self.updateClientProfile()
    }
    

    func updateClientProfile() {
        
        
        let linkedWithFacebook :Bool = PFFacebookUtils.isLinkedWithUser(PFUser.currentUser()!)
        
//        if linkedWithFacebook == true {
//            
//            if !self.checked {
//                self.simpleAlert("Please agree to the Terms and Conditions", message: "You must read the Terms and Conditions and check the box to continue.")
//                return
//            }
//        }
        
        Generals.ShowLoadingView()

        // update profile information
        var clientDict: [String: AnyObject] = ["firstName": self.inputFirstName.text!, "phone": self.inputPhone.text!];
        if self.inputLastName.text != nil {
            clientDict["lastName"] = self.inputLastName.text!
        }
        if self.inputAge.text != nil {
            clientDict["age"] = self.inputAge.text!
        }
        if self.inputGender.text != nil {
            clientDict["gender"] = self.inputGender.text!
        }
        if self.inputInjuries.text != nil {
            clientDict["injuries"] = self.inputInjuries.text!
        }
        
        self.client!.setValuesForKeysWithDictionary(clientDict)
        let user = PFUser.currentUser()!
        self.client!.setObject(user, forKey: "user")
        
        if self.selectedPhoto != nil {
            let data: NSData = UIImageJPEGRepresentation(self.selectedPhoto!, 0.8)!
            let file: PFFile = PFFile(name: "profile.jpg", data: data)!
            self.client!.setObject(file, forKey: "photo")
        }
        
        
//        if linkedWithFacebook == true {
//            self.client!.setObject(self.checked, forKey: "checkedTOS")
//        }
        
        self.client!.setObject(self.checked, forKey: "checkedTOS")


        
        self.client!.saveInBackgroundWithBlock { (success, error) -> Void in
            if error != nil {
                let message = "We could not create your user profile."
                self.simpleAlert("Error creating profile", defaultMessage: message, error: error)
                return
            }
            else {
                print("signup succeeded")
                if self.isSignup || self.isUpdate {
                    self.navigationController!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
                }
                else {
                    self.navigationController!.popToRootViewControllerAnimated(true)
                }
            }
            
               Generals.hideLoadingView()
        }
        
        
        if self.inputEmail.text != nil {
            
            if self.inputEmail.text?.characters.count > 0 {
                
                PFUser.currentUser()?.setObject(self.inputEmail.text!, forKey: "email")
                PFUser.currentUser()?.saveInBackground()
            }
        }
    }
    
    func cancel(){
         self.navigationController!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    func refreshButton() {
        if self.checked {
            self.buttonTOS.setImage(UIImage(named: "boxChecked")!, forState: .Normal)
        }
        else {
            self.buttonTOS.setImage(UIImage(named: "boxUnchecked")!, forState: .Normal)
        }
    }
    
    @IBAction func didClickCheck(button : UIButton) {
        
        viewLoaded = true

//            if self.checked {
//                return
//            }
        
            self.checked = !self.checked
            self.refreshButton()
            
    }
    
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    // MARK: - keyboard notifications
    func keyboardWillShow(notification: NSNotification) {
        
        if self.currentInput != nil {
            
            let point : CGPoint = self.currentInput!.superview!.convertPoint(self.currentInput!.frame.origin, toView:self.view)
            
            let info:NSDictionary = notification.userInfo!
            let keyboardSize = (info[UIKeyboardFrameBeginUserInfoKey] as! NSValue).CGRectValue()
            let keyboardHeight: CGFloat = (self.view.frame.size.height - (keyboardSize.height + 60))
            
            print(keyboardHeight)
            print(point.y)

            
            if  keyboardHeight < point.y{
                
                let diff = point.y - (self.view.frame.size.height - keyboardSize.height)
                
                self.scrollView.setContentOffset(CGPointMake(0, self.scrollView.contentOffset.y + (diff + 50)), animated: true)
                
            }
            
        }
      
        
    }
    
    func keyboardWillHide(notification: NSNotification) {
        
        self.scrollView.setContentOffset(CGPointMake(0, 0), animated: true)

    }
    
    // MARK: - TextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.inputPhone {
            self.inputCreditCard.becomeFirstResponder()
        }
        
        return true
    }
    
    func textFieldShouldBeginEditing(textField: UITextField) -> Bool {
        if textField == self.inputCreditCard {
            self.view.endEditing(true)
            self.goToCreditCard()
            return false
        }
        
        self.currentInput = textField
        return true
    }
    
    func goToCreditCard() {
        let nav = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("CreditCardNavigationController") as! UINavigationController
        let controller: CreditCardViewController = nav.viewControllers[0] as! CreditCardViewController
        controller.delegate = self
        
        self.presentViewController(nav, animated: true) { () -> Void in
        }
    }
    
    // MARK: - CreditCardDelegate
    func didSaveCreditCard(token: String, lastFour: String) {
        
        // actually save credit card
        PFCloud.callFunctionInBackground("updatePayment", withParameters: ["clientId": self.client!.objectId!, "stripeToken": token]) { (results, error) -> Void in
            
            Generals.hideLoadingView()

            if error == nil {
                self.inputCreditCard.text = "Credit Card: *\(lastFour)"
                self.client!.setObject(lastFour, forKey: "stripeFour")
                self.client!.saveInBackground()
            }
            else {
                self.simpleAlert("Could not save credit card", defaultMessage: "There was an error updating your credit card.", error: error)
            }
        }
    }
    
    // MARK: - UIPickerViewDelegate
    func numberOfComponentsInPickerView(pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return 4 // select, MFO
    }
    
    func pickerView(pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        print("row: \(row)")
        print("genders \(genders)")
        return genders[row]
    }
    
    func pickerView(pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        if row == 0 {
            self.inputGender.text = nil
        }
        self.inputGender.text = genders[row]
    }
    
    // MARK: - Photo
    @IBAction func didClickAddPhoto(sender: UIButton) {
        let picker: UIImagePickerController = UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .ActionSheet)
        if UIImagePickerController.isSourceTypeAvailable(.Camera) {
            alert.addAction(UIAlertAction(title: "Camera", style: .Default, handler: { (action) -> Void in
                let cameraStatus = AVCaptureDevice.authorizationStatusForMediaType(AVMediaTypeVideo)
                if cameraStatus == .Denied {
                    self.warnForCameraAccess()
                }
                else {
                    // go to camera
                    picker.sourceType = .Camera
                    self.presentViewController(picker, animated: true, completion: nil)
                }
            }))
        }
        alert.addAction(UIAlertAction(title: "Photo library", style: .Default, handler: { (action) -> Void in
            let libraryStatus = PHPhotoLibrary.authorizationStatus()
            if libraryStatus == .Denied {
                self.warnForLibraryAccess()
            }
            else {
                // go to library
                picker.sourceType = .PhotoLibrary
                self.presentViewController(picker, animated: true, completion: nil)
            }
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }
    
    func warnForLibraryAccess() {
        let message: String = "WeTrain needs photo library access to load your profile picture. Would you like to go to your phone settings to enable the photo library?"
        let alert: UIAlertController = UIAlertController(title: "Could not access photos", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }
    
    func warnForCameraAccess() {
        let message: String = "WeTrain needs camera access to take your profile photo. Would you like to go to your phone settings to enable the camera?"
        let alert: UIAlertController = UIAlertController(title: "Could not access camera", message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .Cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .Default, handler: { (action) -> Void in
            UIApplication.sharedApplication().openURL(NSURL(string: UIApplicationOpenSettingsURLString)!)
        }))
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

    }

    func imagePickerController(picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.buttonPhotoView.setImage(image, forState: .Normal)
        self.buttonEditPhoto.setTitle("Edit photo", forState: .Normal)
        self.selectedPhoto = image
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    // MARK: - Navigation
    
}
