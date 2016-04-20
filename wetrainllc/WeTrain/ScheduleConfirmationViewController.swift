//
//  ScheduleConfirmationViewController.swift
//  WeTrain
//
//  Created by Sempercon on 25/12/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import EventKit
import Parse
import MBProgressHUD

extension Double {
    /// Rounds the double to decimal places value
    func roundToPlaces(places:Int) -> Double {
        let divisor = pow(10.0, Double(places))
        return round(self * divisor) / divisor
    }
}


class ScheduleConfirmationViewController: UIViewController,UIGestureRecognizerDelegate,UITextFieldDelegate {
    
    var requestedTrainingType: Int?
    var requestedTrainingLength: Int?

    var requestedLocation: NSString?
    var workOutReminderInfo : NSDictionary?
    var addressCoordinate   : CLLocationCoordinate2D?
    var isRefresh   : Bool?
    var savedCalendarEventId: NSString? = ""
    var temppromoCode: String? = ""
    
    @IBOutlet var dateLbl         : UILabel!
    @IBOutlet var sessionLbl      : UILabel!
    @IBOutlet var locationlbl     : UILabel!
    @IBOutlet var priceLbl        : UILabel!
    @IBOutlet var transactioFeeLbl: UILabel!
    @IBOutlet var totalAmtLbl     : UILabel!
    
    
    @IBOutlet var transactionBgView     : UIView!
    @IBOutlet var transactionView       : UIView!
    @IBOutlet var transactionfeeDesc    : UILabel!
    
    @IBOutlet var transFeeWidthCons      : NSLayoutConstraint!
    @IBOutlet var transFeeHeightCons     : NSLayoutConstraint!

    
    var confirmationType : confimationScreentype?
    
    let evtStore = EKEventStore()
    
    @IBOutlet var lblScheduleInfo : UILabel?
    @IBOutlet var lblMessage : UILabel?
    
    @IBOutlet var btnCancel : UIButton?
    @IBOutlet var btnConfirm : UIButton?
    @IBOutlet var btnEdit    : UIButton?
    @IBOutlet var btnClose    : UIButton?

    @IBOutlet var inputPromoCode  : UITextField?
    @IBOutlet var invalidPromoCode     : UIImageView!


    var CurrentScheduleInfo : PFObject?
    var isConfim : Bool!
    var userPromoCode : PFObject?
    var parentController : AnyObject?
    
     var isNeedScreenMove : Bool!
    
    var isPromoCodeValidationProcessing : Bool! = false
    
    @IBOutlet var DetailPopup     : UIView!
    @IBOutlet var cancelPopup     : UIView!
    @IBOutlet var cancelPopupBtnClose     : UIButton!
    @IBOutlet var cancelPopupBtnCancel     : UIButton!




    // MARK: - View delegates
    
    override func viewDidLoad() {
        
        let left: UIBarButtonItem = UIBarButtonItem(title: "Cancel", style: .Done, target: self, action: "close")
        left.tintColor = UIColor.orangeColor()
        self.navigationItem.leftBarButtonItem = left
        self.navigationItem.title = "Confirm"
        
        let tap = UITapGestureRecognizer(target: self, action: "handleGesture:")
        tap.delegate = self
        self.view.addGestureRecognizer(tap)
        
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillShow:"), name:UIKeyboardWillShowNotification, object: nil);
        NSNotificationCenter.defaultCenter().addObserver(self, selector: Selector("keyboardWillHide:"), name:UIKeyboardWillHideNotification, object: nil);
        
        
        //done button for keyboard
        let doneToolbar: UIToolbar = UIToolbar(frame: CGRectMake(0, 0, 320, 50))
        doneToolbar.barStyle = UIBarStyle.BlackTranslucent
        
        let flexSpace = UIBarButtonItem(barButtonSystemItem: UIBarButtonSystemItem.FlexibleSpace, target: nil, action: nil)
        let done: UIBarButtonItem = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.Done, target: self, action: Selector("doneButtonAction"))
        
        let items = NSMutableArray()
        items.addObject(flexSpace)
        items.addObject(done)
        
        doneToolbar.items = [flexSpace,done]
        doneToolbar.sizeToFit()
        
        if self.inputPromoCode == nil {
            self.inputPromoCode = UITextField()
            self.invalidPromoCode = UIImageView()
            self.btnEdit = UIButton()
            
            var title = "Close"
            var titleString : NSMutableAttributedString = NSMutableAttributedString(string: title)
//            titleString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: NSMakeRange(0,title.characters.count))
            titleString.addAttribute(NSFontAttributeName, value: UIFont(name: self.btnClose!.titleLabel!.font.fontName, size: 15)!, range: NSMakeRange(0, titleString.length))
            self.btnClose!.setAttributedTitle(titleString, forState: .Normal)
            
            
            title = "Cancel This Session"
            titleString = NSMutableAttributedString(string: title)
//            titleString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: NSMakeRange(0,title.characters.count))
            titleString.addAttribute(NSFontAttributeName, value: UIFont(name: self.btnCancel!.titleLabel!.font.fontName, size: 15)!, range: NSMakeRange(0, titleString.length))
            self.btnCancel!.setAttributedTitle(titleString, forState: .Normal)
            
            
            
            title = "Yes Cancel It"
            titleString = NSMutableAttributedString(string: title)
//            titleString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: NSMakeRange(0,title.characters.count))
            titleString.addAttribute(NSFontAttributeName, value: UIFont(name: self.cancelPopupBtnCancel!.titleLabel!.font.fontName, size: 15)!, range: NSMakeRange(0, titleString.length))
            self.cancelPopupBtnCancel!.setAttributedTitle(titleString, forState: .Normal)
            
            
            title = "Close"
            titleString = NSMutableAttributedString(string: title)
//            titleString.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: NSMakeRange(0,title.characters.count))
            titleString.addAttribute(NSFontAttributeName, value: UIFont(name: self.cancelPopupBtnClose!.titleLabel!.font.fontName, size: 15)!, range: NSMakeRange(0, titleString.length))
            self.cancelPopupBtnClose!.setAttributedTitle(titleString, forState: .Normal)

            
        }
        
        
        
        self.inputPromoCode!.inputAccessoryView = doneToolbar
    }

    override func viewWillAppear(animated: Bool) {
        
        if (self.isRefresh == false) {return}
            
        self.isRefresh = false
        
        self.btnCancel?.userInteractionEnabled = false
        self.btnConfirm?.userInteractionEnabled = false
        self.btnEdit?.userInteractionEnabled = false
        
        self.btnConfirm?.alpha = 0.6
        self.btnEdit?.alpha = 0.6
        self.btnCancel?.alpha = 0.6
        
        self.inputPromoCode?.text = ""
        self.dateLbl.text = ""
        self.sessionLbl.text = ""
        self.locationlbl.text = ""
        self.priceLbl.text = ""
        self.transactioFeeLbl.text = ""
        self.totalAmtLbl.attributedText = NSMutableAttributedString(string: "")
        self.invalidPromoCode.hidden = true

        if confirmationType == confimationScreentype.FromMap {
           
            self.loadScheduleInfo()
            self.inputPromoCode?.text = ""
           
        } else if confirmationType == confimationScreentype.FromWorkOutReminder {

            //self.lblScheduleInfo?.text = "Fetching..."
            //self.fetchScheduleInfo()
            self.loadScheduleInfo()
            self.inputPromoCode?.text = ""

        }
        else if confirmationType == confimationScreentype.SessonDetails {
            
            self.loadScheduleInfo()
            self.inputPromoCode?.text = ""
            
        }
       
    }
    
    // MARK: - Update UI
    
    func handleGesture(sender: UIGestureRecognizer) {
        if sender.isKindOfClass(UITapGestureRecognizer) {
            self.view.endEditing(true)
        }
    }

    func loadScheduleInfo () {
        
           self.transactionView.hidden = true
           self.transactionBgView.hidden = true
           self.transFeeWidthCons.constant  = 0
           self.transFeeHeightCons.constant = 0
          //self.transactionView.layer.cornerRadius = 5
        
        
            self.inputPromoCode?.font = UIFont.systemFontOfSize(14.0)
            self.inputPromoCode?.textColor = UIColor.blackColor()
            self.inputPromoCode?.layer.borderColor = UIColor.clearColor().CGColor
            self.inputPromoCode?.layer.borderWidth = 0

            self.invalidPromoCode.hidden = true
           //self.inputPromoCode?.layer.borderColor = UIColor.clearColor().CGColor
           // self.inputPromoCode?.layer.borderWidth = 0
        
            let dateFormatter = NSDateFormatter()
            dateFormatter.AMSymbol = "am"
            dateFormatter.PMSymbol = "pm"

            //Specify Format of String to Parse
            dateFormatter.dateFormat = "MMM. *** @ h:mm a"
            
            var date = NSDate()
            if self.appDelegate().ScheduleTime != nil{
                date = self.appDelegate().ScheduleTime! }
            
            let calendar = NSCalendar.currentCalendar()
            let components = calendar.components([.Day], fromDate: date)
        
            var dateStr = dateFormatter.stringFromDate(date)
            dateStr = dateStr.stringByReplacingOccurrencesOfString("***", withString: "\(components.day)" + daySuffix(date))
            self.dateLbl.text = dateStr
        
        
            self.sessionLbl.text  = TRAINING_TITLES[self.requestedTrainingType!] + " for " + "\(self.requestedTrainingLength!) min"
            self.locationlbl.text = self.requestedLocation as? String
        
        
            self.sessionLbl.text  = TRAINING_TITLES[self.requestedTrainingType!] + " for " + "\(self.requestedTrainingLength!) min"
            self.locationlbl.text = self.requestedLocation as? String
      
        
            var coststr : Double = 17
            if self.requestedTrainingLength! == 60 {
                coststr = 25 }
            self.priceLbl.text    = "$" + String(format:"%.2f", coststr) +  ""
        
      
            var transactionfee = 0.3 + (0.029 * coststr)
            transactionfee = Double(transactionfee).roundToPlaces(2)
        
            self.transactioFeeLbl.text    = "$" + String(format:"%.2f", transactionfee) + ""
            self.transactioFeeLbl.sizeToFit()
        
            let totalAmt : Double = coststr + transactionfee
        
            let firstString  = NSMutableAttributedString(string: String(format:"$%.2f", totalAmt))
            firstString.addAttribute(NSFontAttributeName, value: UIFont(name: self.totalAmtLbl.font.fontName, size: 15)!, range: NSMakeRange(0, firstString.length))
            
            let SecondString  = NSMutableAttributedString(string: "")
            SecondString.addAttribute(NSFontAttributeName, value: UIFont(name: self.totalAmtLbl.font.fontName, size: 10)!, range: NSMakeRange(0, SecondString.length))
        
            firstString.appendAttributedString(SecondString)
        
            self.totalAmtLbl.attributedText    = firstString
        
        
            if self.CurrentScheduleInfo != nil {
                
                if let request: PFObject = self.CurrentScheduleInfo!.objectForKey("promoCode") as? PFObject {
                    request.fetchInBackgroundWithBlock({ (promocode : PFObject?, error) -> Void in
                        
                        if promocode!.objectForKey("promoCode") != nil{
                            self.userPromoCode = promocode
                            self.inputPromoCode?.text       = promocode!.objectForKey("promoCode") as! String?
                            self.calculateDiscountAndTranSactionfee()
                        }
                        
                        //to show fetched Scheduleinfo detail
                       // self.loadScheduleInfo()
                        
                    })
                }
            }
        
            self.btnCancel?.userInteractionEnabled = true
            self.btnConfirm?.userInteractionEnabled = true
            self.btnEdit?.userInteractionEnabled = true
        
            self.btnConfirm?.alpha = 1
            self.btnEdit?.alpha = 1
            self.btnCancel?.alpha = 1
       
    }
    
    func daySuffix(date: NSDate) -> String {
        
            let calendar = NSCalendar.currentCalendar()
            let dayOfMonth = calendar.component(.Day, fromDate: date)
        
            switch dayOfMonth {
                case 1: fallthrough
                case 21: fallthrough
                case 31: return "st"
                case 2: fallthrough
                case 22: return "nd"
                case 3: fallthrough
                case 23: return "rd"
                default: return "th"
            }
    }
    
    func close() {
        self.navigationController!.presentingViewController?.dismissViewControllerAnimated(true, completion: nil)
    }
    
    
    func verifyPromoCodeOnCloud() {
        
        if (PFUser.currentUser() == nil) {
            return;
        }
        
        if (self.isPromoCodeValidationProcessing == true) {
            return;
        }
        
        self.isPromoCodeValidationProcessing = true
        self.userPromoCode = nil
        
        Generals.ShowLoadingView()
        
        if self.inputPromoCode?.text!.characters.count == 0{
            
            ///set true for empty promocode
            self.PromocodeValidated(true)
            self.isPromoCodeValidationProcessing = false

        }
        else
        {
            
            let uPromoCode : String = (self.inputPromoCode?.text)!
            
            if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
                
                let params = ["promoCode":uPromoCode ,"clientId": client.objectId!]
                
                PFCloud.callFunctionInBackground("validatePromoCode", withParameters: params) { (results, error) -> Void in
                    
                    print("validatePromoCode: \(results) error: \(error)")
                    
                    
                    if error == nil
                    {
                        if let promoCode : PFObject = results as? PFObject {
                            
                            self.userPromoCode = promoCode
                            self.PromocodeValidated(true)
                            
                        }
                        else
                        {
                            self.PromocodeValidated(false)
                        }
                    }
                    else
                    {
                        self.PromocodeValidated(false)
                    }
                    
                    self.isPromoCodeValidationProcessing = false

                }
            }
            else
            {
                    self.PromocodeValidated(false)
                   self.isPromoCodeValidationProcessing = false

            }
            
        }
        
        
       
       
    }
    
    
    func verifyPromocode() {
        
         self.userPromoCode = nil
        
        Generals.ShowLoadingView()


        
        if self.inputPromoCode?.text!.characters.count == 0{
            
            ///set true for empty promocode
            self.PromocodeValidated(true)
            
        } else {
            
            
            let inputString = self.inputPromoCode?.text

            ////get promocode to check valid
            let query : PFQuery = PFQuery(className: "PromoCode")
            query.whereKey("active", equalTo: true)
            query.findObjectsInBackgroundWithBlock {
                (objects:[PFObject]?, error:NSError?) -> Void in
                
                if error == nil {
                    
                    print("Successfully retrieved \(objects!.count) promocode.")

                    var isValidPromoCode : Bool = false

                    if objects?.count == 0{  /// no promocode found
                        isValidPromoCode = false
                        self.PromocodeValidated(isValidPromoCode)
                    } else {
                        
                        if let objects = objects {
                            
                            for var index = 0; index < objects.count; ++index {
                                
                                let object = objects[index]
                                print(object["promoCode"] as! String?)
                                print(self.inputPromoCode?.text)
                                
                                let promocode = object["promoCode"] as! String?
                                
                                ///check user entered promocode
                                if inputString?.lowercaseString == promocode?.lowercaseString {
                                    isValidPromoCode = true
                                    self.userPromoCode = object
                                    
                                   //check user already used promocode
                                    let prmoCodeRelation  = self.userPromoCode?.relationForKey("usedClients")
                                    let relationquery = prmoCodeRelation?.query()
                                    
                                    let clientObject: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
                                    relationquery?.whereKey("objectId", equalTo: clientObject.objectId!)
                                    relationquery!.countObjectsInBackgroundWithBlock { (count, _) -> Void in
                                        
                                        print("Check for client promocode usage")
                                        print(count)
                                        
                                        if count == 0 {
                                            self.PromocodeValidated(isValidPromoCode)
                                        } else {
                                            self.PromocodeValidated(false)
                                        }
                                    }
                                    
                                    break
                                }
                                
                                if index  == objects.count - 1 {
                                    self.PromocodeValidated(isValidPromoCode)
                                }
                            }
                        }
                    }
                    
                } else {
                    
                    self.simpleAlert("Message", message: "Error in validating promocode. Please try again.")
                    print("Error: \(error!) \(error!.userInfo)")
                    //self.PromocodeValidated(false)
                    
                    self.btnCancel?.userInteractionEnabled = true
                    self.btnConfirm?.userInteractionEnabled = true
                    self.btnEdit?.userInteractionEnabled = true
                    self.btnConfirm?.alpha = 1
                    self.btnEdit?.alpha = 1
                    self.btnCancel?.alpha = 1
                }
            }
        }
        
    }
    
    func showActualPrice() {
        
        var coststr : Double = 17
        if self.requestedTrainingLength! == 60 {
            coststr = 25 }
        self.priceLbl.text    = "$" + String(format:"%.2f", coststr) +  ""
        
        
        var transactionfee = 0.3 + (0.029 * coststr)
        transactionfee = Double(transactionfee).roundToPlaces(2)
        
        self.transactioFeeLbl.text    = "$" + String(format:"%.2f", transactionfee) + ""
        
        
        let totalAmt : Double = coststr + transactionfee
        
        let firstString  = NSMutableAttributedString(string: String(format:"$%.2f", totalAmt))
        firstString.addAttribute(NSFontAttributeName, value: UIFont(name: self.totalAmtLbl.font.fontName, size: 15)!, range: NSMakeRange(0, firstString.length))
        
        let SecondString  = NSMutableAttributedString(string: "")
        SecondString.addAttribute(NSFontAttributeName, value: UIFont(name: self.totalAmtLbl.font.fontName, size: 10)!, range: NSMakeRange(0, SecondString.length))
        
        firstString.appendAttributedString(SecondString)
        
        self.totalAmtLbl.attributedText    = firstString
    }
    
    func calculateDiscountAndTranSactionfee(){
        
        if self.userPromoCode != nil {
            
            var coststr : Double = 17
            if self.requestedTrainingLength! == 60 {
                coststr = 25 }
            
            //// session price with discount
            let discPercentage = self.userPromoCode?.objectForKey("discountPercentage")  as! Double?
            coststr = coststr - (coststr * (discPercentage! / 100))
            self.priceLbl.text    = "$" +  String(format:"%.2f", coststr) + ""
           
            //// transaction fee for discounted amount
            var transactionfee = 0.3 + (0.029 * coststr)
            transactionfee = Double(transactionfee).roundToPlaces(2)
            
            if coststr == 0 {
                transactionfee = 0
            }
            
            let totalAmt : Double = coststr + transactionfee
            
            self.transactioFeeLbl.text    = "$" + String(format:"%.2f", transactionfee) + ""

            let firstString  = NSMutableAttributedString(string: "$" + String(format:"%.2f", totalAmt))
            firstString.addAttribute(NSFontAttributeName, value: UIFont(name: self.totalAmtLbl.font.fontName, size: 15)!, range: NSMakeRange(0, firstString.length))
            
            let SecondString  = NSMutableAttributedString(string: "")
            SecondString.addAttribute(NSFontAttributeName, value: UIFont(name: self.totalAmtLbl.font.fontName, size: 10)!, range: NSMakeRange(0, SecondString.length))
            
            firstString.appendAttributedString(SecondString)
            
            self.totalAmtLbl.attributedText    = firstString

            
        }
    }
    
    func PromocodeValidated (isValid : Bool!){
        
         self.btnCancel?.userInteractionEnabled = true
        self.btnConfirm?.userInteractionEnabled = true
        self.btnEdit?.userInteractionEnabled = true
        self.btnConfirm?.alpha = 1
        self.btnEdit?.alpha = 1
        self.btnCancel?.alpha = 1

        
         Generals.hideLoadingView()
        
        if isValid == true {
            
             self.invalidPromoCode.hidden = true
           // self.inputPromoCode?.layer.borderColor = UIColor.clearColor().CGColor
            //self.inputPromoCode?.layer.borderWidth = 0
            
            self.calculateDiscountAndTranSactionfee()
            
            if self.isNeedScreenMove == true{
                
                if self.isConfim == true {
                    self.confirmClicked()
                } else {
                    self.editclicked()
                }
            }
          
            
        } else {
            
             self.invalidPromoCode.hidden = false
           // self.inputPromoCode?.layer.borderColor = UIColor.redColor().CGColor
            //self.inputPromoCode?.layer.borderWidth = 2.0
            self.inputPromoCode?.text = "Invalid Promo Code"
            self.inputPromoCode?.font = UIFont.boldSystemFontOfSize(14.0)
            self.inputPromoCode?.textColor = UIColor.redColor()
            self.showActualPrice()
        }
        

    }
    
    // MARK: - Button Action
    
    @IBAction func didClickConfirm() {

        if(self.inputPromoCode!.text == "Invalid Promo Code"){
            
            self.userPromoCode = nil
            self.isNeedScreenMove = true
            self.inputPromoCode?.resignFirstResponder()
            self.isConfim = true
            self.PromocodeValidated(true)

//            let alert = UIAlertController(title: "Message", message:"Enter a valid promo code", preferredStyle: .Alert)
//            let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
//            alert.addAction(OKAction)
//            self.presentViewController(alert, animated: true, completion: nil)
//            alert.view.tintColor = UIColor.blackColor()
//
            return
            
        }
        
        self.isNeedScreenMove = true
        self.inputPromoCode?.resignFirstResponder()
        self.isConfim = true
        self.verifyPromoCodeOnCloud()
    }
    
    @IBAction func didClickEdit() {
        
        self.isConfim = false
        self.isNeedScreenMove = true

        if self.appDelegate().OptionType == "Train Now" {
            self.editclicked()
        } else {
            self.verifyPromoCodeOnCloud()
        }
    }
    
    @IBAction func didClickCancel() {
        
        
        self.dismissView()
        
        return

        
        if self.appDelegate().OptionType == "Train Now" {
            self.moveToHome()
        }
        else {
            
            let request: PFObject
            if self.CurrentScheduleInfo != nil {
                request = self.CurrentScheduleInfo!
                request.setObject(ScheduleState.Canceled.rawValue, forKey: "status")
                request.saveInBackgroundWithBlock { (success, error) -> Void in
                    print("saved: \(success)")
                    
                    if success {
                        self.savedCalendarEventId = nil
                        self.confirmationType = confimationScreentype.None
                        self.CurrentScheduleInfo = nil
                        
                    }
                    else {
                        let message = "There was an issue on saving. Please try again."
                        print("error: \(error)")
                        self.simpleAlert("Could not save workout", defaultMessage: message, error: error)
                    }
                }

                self.moveToHome()
            }
            else {
                self.moveToHome()
            }
        }
        
        self.dismissView()
    }
  
    @IBAction func didClickTranscationFee(){
        
        self.transactionBgView.hidden = false
        self.transactionView.hidden = false
        
        //self.transactionView.layer.borderColor = self.appDelegate().getAppThemeColor().CGColor
        //self.transactionView.layer.borderWidth = 2
        
        self.transactionfeeDesc.text = "WeTrain aims to offer the lowest prices to our clients.\n\nThis transaction fee represents a payment processing fee that our vendors charge for each transaction.\n\nWeTrain does not profit from any portion of this fee."

//        self.transactionfeeDesc.text = "WeTrain was found to offer the lowest prices to the consumer!\n\nThis transaction fee represents a payment processing fee that WeTrain is changed for every transaction by ites service providers.\n\nWetrain does not profit from any portion of this fee as 100% is passed along to ensure payments are processed."
        
        
        //animate view 
        self.transFeeWidthCons.constant = 0
        self.transFeeHeightCons.constant = 0

        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.transFeeWidthCons.constant  = 170
            self.transFeeHeightCons.constant = 140
            
            self.view.layoutIfNeeded()
            }, completion: nil)
       
        
    }
    
    
    @IBAction func didCloseTranscationFee(){
        
        //animate view
      
        
        UIView.animateWithDuration(0.5, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.transFeeWidthCons.constant  = 0
            self.transFeeHeightCons.constant = 0
            
            self.view.layoutIfNeeded()
            }, completion: { (finished: Bool) -> Void in
                
                self.transactionView.hidden = true
                self.transactionBgView.hidden = true
                self.transFeeWidthCons.constant  = 0
                self.transFeeHeightCons.constant = 0
        })
        

    }
    
    @IBAction func btnSessionCancelClicked() {
        
        
        self.cancelPopup.hidden = false
        self.DetailPopup.hidden = true
        self.transactionBgView.hidden = true

        self.cancelPopup.alpha = 0.6
        
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.cancelPopup.alpha = 1
            self.view.layoutIfNeeded()
            
            }, completion: {_ in
                
        })
        
    }
    
    @IBAction func btnSessionCLoseClicked() {
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.view.frame =  CGRectMake(self.view.frame.origin.x, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)
            
            self.view.layoutIfNeeded()
            }, completion: {_ in
                
                self.view.removeFromSuperview()
                //self.confirmationType = confimationScreentype.None
                
                
                
        })
    }

    
    
    @IBAction func cancelPopupCloseClicked (){
        
        
        self.cancelPopup.hidden = true
        self.DetailPopup.hidden = false
        self.transactionBgView.hidden = true
        
        self.DetailPopup.alpha = 0.6
        
        UIView.animateWithDuration(1, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.DetailPopup.alpha = 1
            self.view.layoutIfNeeded()
            
            }, completion: {_ in
                
        })

        
        //self.btnSessionCLoseClicked()

    }
    
    @IBAction func cancelPoupCancelClicked () {
        
//        let request: PFObject
//        if self.CurrentScheduleInfo != nil {
//            request = self.CurrentScheduleInfo!
//            request.setObject(ScheduleState.Canceled.rawValue, forKey: "status")
//            request.saveInBackgroundWithBlock { (success, error) -> Void in
//                print("saved: \(success)")
//                
//                if success {
//                    self.savedCalendarEventId = nil
//                    self.confirmationType = confimationScreentype.None
//                    self.CurrentScheduleInfo = nil
//                    
//                }
//                else {
//                    let message = "There was an issue on saving. Please try again."
//                    print("error: \(error)")
//                    self.simpleAlert("Could not save workout", defaultMessage: message, error: error)
//                }
//            }
//            
//        }
        
        self.btnSessionCLoseClicked()

        cancelScheduleOnCloud()
        
        
    }
    
    
    func cancelScheduleOnCloud() {
        
        if (PFUser.currentUser() == nil) {
            return;
        }
        
        
        Generals.ShowLoadingView()
        
        let params = ["Schedule":self.CurrentScheduleInfo!.objectId!]
        
        PFCloud.callFunctionInBackground("cancelScheduleSession", withParameters: params) { (results, error) -> Void in
            
            print("cancelScheduleSession: \(results) error: \(error)")
            
            if error == nil
            {
                if (self.parentController?.isKindOfClass(ScheduledSessionsViewController) != nil) {
                    
                    let sCon = self.parentController as! ScheduledSessionsViewController
                    sCon.scheculeCancelled(self.CurrentScheduleInfo)
                    
                    self.savedCalendarEventId = nil
                    self.confirmationType = confimationScreentype.None
                    self.CurrentScheduleInfo = nil
                    
                }
                
            }
            else
            {
                self.simpleAlert("Could not cancel schedule", defaultMessage: "Error in canceling Schedule. Please try again.", error: error)
                
                
            }
            
            Generals.hideLoadingView()
            
        }
        
        
        
    }
    
    
    
    // MARK: - Custom Methods
    
    func confirmClicked(){
        
        if (self.parentController!.isKindOfClass(MapViewController)){
            
            let mCon : MapViewController = self.parentController as! MapViewController
            if  mCon.inServiceRange() == false{
                mCon.warnAboutService()
                self.dismissView()
                return
            }
        }
        
        Generals.ShowLoadingView()

        
        
        self.dismissView()
        
        ///// confirm for train now
        if self.appDelegate().OptionType == "Train Now"
        {
            //self.testMultipleWo(self.requestedLocation as! String, coordinate: self.addressCoordinate!)
            
            self.initiateWorkoutRequest(self.requestedLocation as! String, coordinate: self.addressCoordinate!)

        }
        else if self.appDelegate().OptionType == "Train Later"           ///// confirm for Train Later
        {
            
            ////schedule created with in 5 miles and within a hour need to enter as schedule and rreate a wo immediately
            
            let workOutStartInterval = self.appDelegate().ScheduleTime!.timeIntervalSinceDate(NSDate()) / 60
            print("workOutStartInterval " + "\(workOutStartInterval)")

            
            /// intiate workOut request
            if confirmationType == confimationScreentype.FromWorkOutReminder {
                
                if(workOutStartInterval <= 60)
                {
                    self.addScheduleRequest(self.requestedLocation as! String, coordinate: self.addressCoordinate!,scheduleState: ScheduleState.Searching)
                }
                else
                {
                    self.addScheduleRequest(self.requestedLocation as! String, coordinate: self.addressCoordinate!,scheduleState: ScheduleState.Searching)
                }
                return
            }
            
            if !self.checkAndAskForCalendarPermission() {
                
                 Generals.hideLoadingView()
                print("not authorized")
                return
            }
            
            var event : EKEvent!
            
            if self.savedCalendarEventId == nil {
                event = EKEvent(eventStore: self.evtStore)
            } else {
                event = self.evtStore.eventWithIdentifier(self.savedCalendarEventId as! String)
            }
            
            
            if event == nil {
                event = EKEvent(eventStore: self.evtStore)
            }
            
            
            event!.title = "WeTrain Workout"
            event!.startDate = self.appDelegate().ScheduleTime!
            event.location  = self.requestedLocation as? String
            
            
            if self.requestedTrainingLength != nil {
                event!.endDate = event!.startDate.dateByAddingTimeInterval(30*60) // 30 minutes WorkOut
                if self.requestedTrainingLength! == 60 {
                    event!.endDate = event!.startDate.dateByAddingTimeInterval(60*60) // 60 minutes WorkOut
                }
            }
            
            event!.calendar = self.evtStore.defaultCalendarForNewEvents
            
            var calendarNotes = "Workout Type : " + TRAINING_TITLES[self.requestedTrainingType!]
            calendarNotes = calendarNotes + "\nDuration : " + "\(self.requestedTrainingLength!) min"
            calendarNotes = calendarNotes + "\nPrice : " + (self.totalAmtLbl.attributedText?.string)!
            event.notes = calendarNotes

            
            do
            {
                try self.evtStore.saveEvent(event!, span: EKSpan.ThisEvent, commit: true)
                self.savedCalendarEventId = event!.eventIdentifier
            }
            catch
            {
                let nserror = error as NSError
                
//                let alert = UIAlertController(title: "Calendar could not save", message: nserror.localizedDescription, preferredStyle: .Alert)
//                let OKAction = UIAlertAction(title: "OK", style: .Default, handler: nil)
//                alert.addAction(OKAction)
//                self.presentViewController(alert, animated: true, completion: nil)
//                alert.view.tintColor = UIColor.blackColor()

            }
            
            
            
            if(workOutStartInterval <= 60)
            {
                self.addScheduleRequest(self.requestedLocation as! String, coordinate: self.addressCoordinate!,scheduleState: ScheduleState.Searching)
            }
            else
            {
                self.addScheduleRequest(self.requestedLocation as! String, coordinate: self.addressCoordinate!,scheduleState: ScheduleState.Created)
            }
            
            
        }
        
       
    }
    
    func editclicked(){
        
        self.dismissView()

        ///// move to traininglength Controller
        if self.appDelegate().OptionType == "Train Now"
        {
            
            var trainingLengthCon : UIViewController!
            
            if let viewControllers = navigationController?.viewControllers {
                for viewController in viewControllers {
                    // some process
                    if viewController.isKindOfClass(TrainingLengthViewController) {
                        trainingLengthCon = viewController
                    }
                }
            }
            
            if trainingLengthCon != nil {
                self.parentController!.navigationController!!.popToViewController(trainingLengthCon, animated: true)
                
            } else {
                
                let sController: TrainingLengthViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TrainingLengthViewController") as! TrainingLengthViewController
                 self.parentController!.navigationController!!.pushViewController(sController, animated: false)
            }
            
           
            
        }
        else if self.appDelegate().OptionType == "Train Later"   ///// edit for Train Later
        {
           
            let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
            tcon.selectedIndex = 0
            let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
            tabNabcontroller.popToRootViewControllerAnimated(false)
            
            let sController: ScheduleViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ScheduleViewController") as! ScheduleViewController
            sController.isScheduleEdit = true
            tabNabcontroller.pushViewController(sController, animated: false)

            self.dismissView()

        }
        
        
        /*  let controller: UIViewController?  = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("MainTabController") as UIViewController?
        
        UIApplication.sharedApplication().keyWindow!.rootViewController?.dismissViewControllerAnimated(false, completion: nil)
        UIApplication.sharedApplication().keyWindow!.rootViewController?.presentViewController(controller!, animated: false, completion: { () -> Void in
        
        let sController: ScheduleViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("ScheduleViewController") as! ScheduleViewController
        
        let tcon : UITabBarController = (controller as! UITabBarController?)!
        
        let fnavController = tcon.selectedViewController as! UINavigationController
        fnavController.pushViewController(sController, animated: false)
        
        })
        */
    }
    

    func scheduleLocalNotification (request : PFObject) {
        
        ///notify user before 90 min of scheduled time
        let notifyTime : NSDate = self.appDelegate().ScheduleTime!.dateByAddingTimeInterval(-(90 * 60))
        
        let localNotification = UILocalNotification()
        localNotification.fireDate = notifyTime
        localNotification.alertBody = "Hey! It’s almost time to workout!"
        localNotification.alertAction = "Start"
        localNotification.category = "Workout"
        
        var dict: [String: AnyObject] = [String: AnyObject]()
        dict = ["scheduledTime": self.appDelegate().ScheduleTime!, "scheduleInfoId":request.objectId!]
        
        
        var mdict: NSMutableDictionary = NSMutableDictionary()
        mdict = ["scheduledTime": self.appDelegate().ScheduleTime!, "scheduleInfoId":request.objectId!]

        
        localNotification.userInfo = dict
        
        UIApplication.sharedApplication().scheduleLocalNotification(localNotification)
        
        dispatch_async(dispatch_get_main_queue()) { () -> Void in
            
            self.setScheduleInfo_in_UserDefault(mdict)

            let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
            tcon.selectedIndex = 0
            
            let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
            tabNabcontroller.popToRootViewControllerAnimated(false)
        }
        
        let delay = 2.0 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            ScheduleNotification.showNotificationView()
        })
        
        
        //// save userid for self confirm work out request.
        let installation = PFInstallation.currentInstallation()
        installation.setObject(PFUser.currentUser()!.objectId!, forKey: "userId")
        installation.saveInBackground()
        
         Generals.hideLoadingView()

    }
    
    func dismissView () {
        
        let mController : MapViewController = self.parentController as! MapViewController
        
        if self.parentController!.isKindOfClass(MapViewController) {
            mController.buttonRequest.hidden = false
            mController.inputStreet?.hidden = false
            mController.inputStreetBg?.hidden = false
            
            
            ////move to scheduled address
            if mController.inputStreet.text != self.requestedLocation {
                
                mController.inputStreet.text = self.requestedLocation as? String
                mController.inputManualAddress =  mController.inputStreet
                mController.searchForAddress()
                
            }
           
        }
     

        self.didCloseTranscationFee()
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
            self.view.frame =  CGRectMake(self.view.frame.origin.x, self.view.frame.size.height, self.view.frame.size.width, self.view.frame.size.height)
            
            self.view.layoutIfNeeded()
            }, completion: {_ in
                
            self.view.removeFromSuperview()
            //self.confirmationType = confimationScreentype.None
                

                
        })
    }
    
    func moveToHome(){
        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        tabNabcontroller.popToRootViewControllerAnimated(false)

    }
    
    // MARK: - Custom Parse Methods

    func addScheduleRequest(addressString: String, coordinate: CLLocationCoordinate2D,scheduleState : ScheduleState) {
        var dict: [String: AnyObject] = [String: AnyObject]()
        
        
            let request: PFObject
        
            if self.CurrentScheduleInfo != nil {
                request = self.CurrentScheduleInfo!
                
                if scheduleState ==  ScheduleState.Searching{
                    request.setObject(ScheduleState.Searching.rawValue, forKey: "status")
                }else{
                    request.setObject(ScheduleState.Edited.rawValue, forKey: "status")
                }
                request.setObject(self.appDelegate().ScheduleTime!, forKey: "scheduledTime")
                request.setObject(Double(coordinate.latitude), forKey: "lat")
                request.setObject(Double(coordinate.longitude), forKey: "lon")
                request.setObject(addressString, forKey: "address")

                
            }
            else {
                dict = ["scheduledTime": self.appDelegate().ScheduleTime!, "lat": Double(coordinate.latitude), "lon": Double(coordinate.longitude), "status":ScheduleState.Created.rawValue, "address": addressString]
                request = PFObject(className: "ScheduleInfo", dictionary: dict)
                
                if scheduleState ==  ScheduleState.Searching{
                    request.setObject(ScheduleState.Searching.rawValue, forKey: "status")
                }else{
                    request.setObject(ScheduleState.Created.rawValue, forKey: "status")
                }
            }
        
        
        
            let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
            let id = client.objectId
            print("client: \(client) \(id)")
            request.setObject(client, forKey: "client")
            if self.requestedTrainingType != nil {
                let title = TRAINING_TITLES[self.requestedTrainingType!]
                request.setObject(title, forKey: "workOutType")
            }
            if self.requestedTrainingLength != nil {
                request.setObject(self.requestedTrainingLength!, forKey: "length")
            }
            if TESTING == 1 {
                request.setObject(true, forKey: "testing")
            }
        
            if self.userPromoCode != nil {
                request.setObject(self.userPromoCode!, forKey: "promoCode")
            }
        
            if self.savedCalendarEventId != nil {
                request.setObject(self.savedCalendarEventId!, forKey: "calendarEventId")
            }

            print("request: \(request)")
            request.saveInBackgroundWithBlock { (success, error) -> Void in
                print("saved: \(success)")
                client.setObject(request, forKey: "ScheduleInfo")
                client.saveInBackground()
                
                if success {
                    
                    self.CurrentScheduleInfo = request

                    
                    if scheduleState == ScheduleState.Searching // intiate workout request noe
                    {
                        self.initiateWorkoutRequest(self.requestedLocation as! String, coordinate: self.addressCoordinate!)
                    }
                    else // add localnotification as reminder for scheduled workout
                    {
                        // schedule localnotication
                        if request.objectId != nil {
                            self.scheduleLocalNotification(request)
                        }
                        
                        //self.CurrentScheduleInfo = nil

                    }
                    
                    self.savedCalendarEventId = nil
                    self.confirmationType = confimationScreentype.None

                    
                }
                else {
                    let message = "There was an issue on saving. Please try again."
                    print("error: \(error)")
                    self.simpleAlert("Could not save workout", defaultMessage: message, error: error)
                }
            }
        
        
    }
    
    func fetchScheduleInfo(completion: (result: String) -> Void) {
        
        let query : PFQuery = PFQuery(className: "ScheduleInfo")
        query.whereKey("objectId", equalTo: (workOutReminderInfo?.objectForKey("scheduleInfoId"))!)
        
        query.findObjectsInBackgroundWithBlock {
            (objects:[PFObject]?, error:NSError?) -> Void in
            
            
            if error == nil {
                
                // The find succeeded.
                print("Successfully retrieved \(objects!.count) workoutReminder.")
                
                // Do something with the found objects
                if let objects = objects {
                    
                    for object in objects {
                        
                        ///wo are shuffled so to get index of current index of wo
                        
                        self.requestedTrainingType  = (TRAINING_TITLES.indexOf(object["workOutType"] as! (String)) as Int?)!
                        self.CurrentScheduleInfo        = object
                        self.requestedTrainingLength    = object["length"] as! Int?
                        self.requestedLocation          =  object["address"] as! NSString!
                        self.addressCoordinate          = CLLocationCoordinate2D.init(latitude: (object["lat"] as! Double?)!, longitude: (object["lon"] as! Double?)!)
                        self.appDelegate().ScheduleTime = object["scheduledTime"] as! NSDate?
                        self.savedCalendarEventId       = object["calendarEventId"] as! NSString?
                        
                        
                        
                        if let request: PFObject = object["promoCode"] as? PFObject {
                            request.fetchInBackgroundWithBlock({ (promocode : PFObject?, error) -> Void in
                                
                                if promocode!.objectForKey("promoCode") != nil{
                                    self.userPromoCode = promocode
                                    self.inputPromoCode?.text       = promocode!.objectForKey("promoCode") as! String?
                                    self.calculateDiscountAndTranSactionfee()
                                }
                                
                                //to show fetched Scheduleinfo detail
                                self.loadScheduleInfo()
                                
                            })
                        } else {
                            
                            //to show fetched Scheduleinfo detail
                            self.loadScheduleInfo()
                        }
                        
                        
//                        
//                        if let client: PFObject = PFUser.currentUser()!.objectForKey("client") as? PFObject {
//                            print("sdfdsf")
//
//                            print(client)
//
//                            if client.allKeys.contains("objectId") {
//                                if let currentClientId: String = client.objectForKey("objectId") as? String {
//                                    
//                                    let scheduledClientId: PFObject = (object["client"] as! PFObject?)!
//                                    
//                                    print(scheduledClientId)
//                                    print(scheduledClientId.objectForKey("objectId"))
//
//                                    if currentClientId != scheduledClientId.objectForKey("objectId") as? NSString {
//                                        completion(result:"differntUser")
//                                        return
//                                    }
//                                }
//                                
//                            }
//                        }
                        
                        completion(result:object["status"] as! String!)
                    }
                    
                } else {
                    completion(result:"")

                }
                
            } else {
                // Log details of the failure
                print("Error: \(error!) \(error!.userInfo)")
                completion(result:"")
                
                self.simpleAlert("Error", defaultMessage: "Error occured. Please try again", error: error)

            }
            
        }
        
        
    }
    
    
    func loadSessionDetails (scheduleInfo : PFObject!){
        
        if scheduleInfo != nil {
            
            self.requestedTrainingType      = (TRAINING_TITLES.indexOf(scheduleInfo["workOutType"] as! (String)) as Int?)!
            self.CurrentScheduleInfo        = scheduleInfo
            self.requestedTrainingLength    = scheduleInfo["length"] as! Int?
            self.requestedLocation          =  scheduleInfo["address"] as! NSString!
            self.addressCoordinate          = CLLocationCoordinate2D.init(latitude: (scheduleInfo["lat"] as! Double?)!, longitude: (scheduleInfo["lon"] as! Double?)!)
            self.appDelegate().ScheduleTime = scheduleInfo["scheduledTime"] as! NSDate?
            self.savedCalendarEventId       = scheduleInfo["calendarEventId"] as! NSString?
            
            if let request: PFObject = scheduleInfo["promoCode"] as? PFObject {
                request.fetchInBackgroundWithBlock({ (promocode : PFObject?, error) -> Void in
                    
                    if promocode!.objectForKey("promoCode") != nil{
                        self.userPromoCode = promocode
                        self.inputPromoCode?.text       = promocode!.objectForKey("promoCode") as! String?
                        self.calculateDiscountAndTranSactionfee()
                    }
                    
                    //to show fetched Scheduleinfo detail
                    self.loadScheduleInfo()
                    
                })
            } else {
                
                //to show fetched Scheduleinfo detail
                self.loadScheduleInfo()
            }
        }
        
    }
    
    func testMultipleWo (addressString: String, coordinate: CLLocationCoordinate2D) {
        
        for (var i = 0 ; i < 10 ; i++ ){
            
            self.initiateWorkoutRequest(addressString + " \(i)" , coordinate: coordinate)
            print(addressString + " \(i)")
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
        
            if self.userPromoCode != nil {
               request.setObject(self.userPromoCode!, forKey: "promoCode")
            }
        
        
        
            if self.CurrentScheduleInfo != nil {
                
                request.setObject( (self.CurrentScheduleInfo?.objectForKey("scheduledTime"))! , forKey: "scheduledTime")
                request.setObject((self.CurrentScheduleInfo)!, forKey: "scheduleInfo")
            }
        
           self.CurrentScheduleInfo = nil

        
            print("request: \(request)")
            request.saveInBackgroundWithBlock { (success, error) -> Void in
                print("saved: \(success)")
                client.setObject(request, forKey: "workout")
                client.saveInBackground()
                
                if success {
                    
                    if (self.parentController!.isKindOfClass(MapViewController)){
                        let mCon : MapViewController = self.parentController as! MapViewController
                        mCon.performSegueWithIdentifier("GoToRequestState", sender: nil)
                    }
                    
                    
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
                
                Generals.hideLoadingView()

            }
        }
    
        // MARK: - Navigation
        // In a storyboard-based application, you will often want to do a little preparation before navigation
        override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
            // Get the new view controller using segue.destinationViewController.
            // Pass the selected object to the new view controller.
            if segue.identifier == "GoToTimepicker" {
                segue.destinationViewController.hidesBottomBarWhenPushed = false
            }
           
        }
    
    
       // MARK: - UITEXTFEILD DELEGATE

        func keyboardWillShow(sender: NSNotification) {
            
            if (UIScreen.mainScreen().bounds.height <= 480) {
                
                if self.view.frame.origin.y == 0{
                    self.view.frame.origin.y -= 280
                }
            }else{
                
                if self.view.frame.origin.y == 0{
                    self.view.frame.origin.y -= 200
                }
            }
            
        }
        
        func keyboardWillHide(sender: NSNotification) {
            
            if (UIScreen.mainScreen().bounds.height <= 480) {
                self.view.frame.origin.y += 280
            }else {
                
                self.view.frame.origin.y += 200
            }
            
            if(self.inputPromoCode?.text != "Invalid Promo Code"){
                temppromoCode = self.inputPromoCode?.text
            }
            
            if self.inputPromoCode?.text?.characters.count > 0{
                
                self.isNeedScreenMove = false
                self.verifyPromoCodeOnCloud()
                
                self.btnCancel?.userInteractionEnabled = false
                self.btnConfirm?.userInteractionEnabled = false
                self.btnEdit?.userInteractionEnabled = false
                
                self.btnConfirm?.alpha = 0.7
                self.btnEdit?.alpha = 0.3
                 self.btnCancel?.alpha = 0.3
                
            }
            else {
                
                self.btnCancel?.userInteractionEnabled = true
                self.btnConfirm?.userInteractionEnabled = true
                self.btnEdit?.userInteractionEnabled = true
                
                self.btnConfirm?.alpha = 1
                self.btnEdit?.alpha = 1
                 self.btnCancel?.alpha = 1
            }

            
        }
    
        func textFieldDidBeginEditing(textField: UITextField) {
            
            if(textField.text == "Invalid Promo Code"){
                
               // textField.text = temppromoCode
                
                textField.text = ""
                temppromoCode  = ""
                self.inputPromoCode?.font = UIFont.systemFontOfSize(14.0)
                self.inputPromoCode?.textColor = UIColor.blackColor()
                self.inputPromoCode?.layer.borderColor = UIColor.clearColor().CGColor
                self.inputPromoCode?.layer.borderWidth = 0
                 self.invalidPromoCode.hidden = true
            } else {
                temppromoCode = textField.text
            }
            
            self.btnCancel?.userInteractionEnabled = false
            self.btnConfirm?.userInteractionEnabled = false
            self.btnEdit?.userInteractionEnabled = false
            
            self.btnConfirm?.alpha = 0.7
            self.btnEdit?.alpha = 0.3
            self.btnCancel?.alpha = 0.3
        
        }
    
    
        func textFieldShouldReturn(textField: UITextField) -> Bool {
          
            textField.resignFirstResponder()
           // self.didClickConfirm()
            
            
            if self.inputPromoCode?.text?.characters.count > 0{
                
                self.isNeedScreenMove = false
                self.verifyPromoCodeOnCloud()
                
                self.btnCancel?.userInteractionEnabled = false
                self.btnConfirm?.userInteractionEnabled = false
                self.btnEdit?.userInteractionEnabled = false
                
                self.btnConfirm?.alpha = 0.7
                self.btnEdit?.alpha = 0.3
                 self.btnCancel?.alpha = 0.3

            }
            
            
            return true
        }
    
        func doneButtonAction()
        {
            self.inputPromoCode?.resignFirstResponder()
            //self.didClickConfirm()
            
            
            if self.inputPromoCode?.text?.characters.count > 0{
                
                self.isNeedScreenMove = false
                self.verifyPromoCodeOnCloud()
                
                self.btnCancel?.userInteractionEnabled = false
                self.btnConfirm?.userInteractionEnabled = false
                self.btnEdit?.userInteractionEnabled = false
                
                self.btnConfirm?.alpha = 0.7
                self.btnEdit?.alpha = 0.3
                self.btnCancel?.alpha = 0.3
                
            } else {
                
                self.btnCancel?.userInteractionEnabled = true
                self.btnConfirm?.userInteractionEnabled = true
                self.btnEdit?.userInteractionEnabled = true
                
                self.btnConfirm?.alpha = 1
                self.btnEdit?.alpha = 1
                self.btnCancel?.alpha = 1
            }
        }


}
