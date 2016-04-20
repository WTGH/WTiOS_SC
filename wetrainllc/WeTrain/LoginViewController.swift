//
//  LoginViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 8/2/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import ParseFacebookUtilsV4

class LoginViewController: UIViewController, UITextFieldDelegate, UIScrollViewDelegate, UIGestureRecognizerDelegate {

    @IBOutlet var inputLogin: UITextField!
    @IBOutlet var inputPassword: UITextField!
    @IBOutlet var buttonLogin: UIButton!
    @IBOutlet var buttonSignup: UIButton!
    
    var emailText : UITextField?
    
    
    // MARK: - VIEW DELEGATES

    override func viewDidLoad() {
        super.viewDidLoad()

        self.reset()
        // Do any additional setup after loading the view.

        self.setTitleBarColor(UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), tintColor: UIColor(red: 0, green: 122/255, blue: 1, alpha: 1))

        let tap = UITapGestureRecognizer(target: self, action: "handleGesture:")
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        let left: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: "close")
        left.tintColor = UIColor.orangeColor()
        self.navigationItem.leftBarButtonItem = left
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
    
    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .Default
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func reset() {
        self.inputPassword.text = nil;

        self.inputLogin.superview!.layer.borderWidth = 1;
        self.inputLogin.superview!.layer.borderColor = UIColor.lightGrayColor().CGColor;
        self.inputPassword.superview!.layer.borderWidth = 1;
        self.inputPassword.superview!.layer.borderColor = UIColor.lightGrayColor().CGColor;
    }
        
    func handleGesture(sender: UIGestureRecognizer) {
        if sender.isKindOfClass(UITapGestureRecognizer) {
            self.view.endEditing(true)
        }
    }
    
    func close() {
        self.navigationController!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func gestureRecognizer(gestureRecognizer: UIGestureRecognizer, shouldReceiveTouch touch: UITouch) -> Bool {
        if gestureRecognizer.isKindOfClass(UITapGestureRecognizer) {
            let location: CGPoint = touch.locationInView(self.view)
            for input: UIView in [self.inputLogin, self.inputPassword, self.buttonLogin] {
                if CGRectContainsPoint(input.frame, location) {
                    return false
                }
            }
        }
        return true
    }
    
    
    // MARK: - BUTTON ACTIONS

    @IBAction func didClickLogin(sender: UIButton) {
        if self.inputLogin.text?.characters.count == 0 {
            self.simpleAlert("Please enter a login email", message: nil)
            return
        }
        if self.inputPassword.text?.characters.count == 0 {
            self.simpleAlert("Please enter a password", message: nil)
            return
        }
        
        let username: String = self.inputLogin.text!
        let password: String = self.inputPassword.text!
        PFUser.logInWithUsernameInBackground(username, password: password) { (user, error) -> Void in
            print("logged in")
            if user != nil {
                self.loggedIn()
            }
            else {
                let title = "Login error"
                var message: String?
                if error?.code == 100 {
                    message = "Please check your internet connection"
                }
                else if error?.code == 101 {
                    message = "Invalid email or password"
                }
                
                self.simpleAlert(title, message: message)
            }
        }
    }
    
    @IBAction func didClickSignup(sender: UIButton) {
        let nav: UINavigationController = UIStoryboard(name: "Login", bundle: nil).instantiateViewControllerWithIdentifier("SignupNavigationController") as! UINavigationController
        self.appDelegate().window!.rootViewController?.dismissViewControllerAnimated(true, completion: nil)
        self.appDelegate().window!.rootViewController!.presentViewController(nav, animated: true, completion: nil)
    }
    
    func loggedIn() {
        self.close()
        self.appDelegate().checkForUserCurrentWorkoutStatus()
    }
    
    
    @IBAction func didClickForgotPassword () {
        
        let prompt = UIAlertController(title: "Enter Email To Reset Password", message: nil, preferredStyle: UIAlertControllerStyle.Alert)
        prompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
        prompt.addAction(UIAlertAction(title: "Reset", style: .Default, handler: { (action) -> Void in
            
            self.requestForgotPassword()
        }))
        prompt.addTextFieldWithConfigurationHandler({(textField: UITextField!) in
            textField.placeholder = "Email"
            self.emailText = textField
        })
        self.presentViewController(prompt, animated: true, completion: nil)
        prompt.view.tintColor = UIColor.blackColor()

    }
    
    @IBAction func didClickFacebookLogin () {
        
        self.loginWithFacebook(self,isCheckedTos: false)
       
    }
    
    
    func signupError(error: NSError?) {
        self.navigationItem.rightBarButtonItem?.enabled = true
        let title = "Signup error"
        var message: String?
        if error?.code == 100 {
            message = "Please check your internet connection"
        }
        else if error?.code == 202 {
            message = "Username already taken"
        }
        
        self.simpleAlert(title, message: message)
    }
    
    // MARK: - ForgotPassword
    
    func requestForgotPassword () {
        
        PFUser.requestPasswordResetForEmailInBackground((self.emailText?.text)!, block: {
            (isSucess :Bool,error : NSError?) -> Void in
            
            var message = ""
            
            if isSucess {
                message = "Email to reset password is sent. Please check your email."
            }
            else{
                message = "There was an error on request. Please try again." + (error?.localizedDescription)!
            }
            
            let prompt = UIAlertController(title: "Message", message: message, preferredStyle: UIAlertControllerStyle.Alert)
            prompt.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: nil))
            self.presentViewController(prompt, animated: true, completion: nil)
            prompt.view.tintColor = UIColor.blackColor()


        })
    }

    
    
    // MARK: - TextFieldDelegate
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if textField == self.inputLogin {
            self.inputPassword.becomeFirstResponder()
            return false
        }
        else {
            textField.resignFirstResponder()
        }
        return true
    }
    
    
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        
        if segue.identifier == "GoToUserInfo" {
            let controller: UserInfoViewController = segue.destinationViewController as! UserInfoViewController
            controller.isSignup = true
        }
        
    }

    
    // MARK: - UITEXTFEILD DELEGATE
    
    func keyboardWillShow(sender: NSNotification) {
        //self.view.frame.origin.y -= 150
    }
    
    func keyboardWillHide(sender: NSNotification) {
        //self.view.frame.origin.y += 150
    }

}
