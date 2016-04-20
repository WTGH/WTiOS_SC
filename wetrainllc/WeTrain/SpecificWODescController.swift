//
//  SpecificWODescController.swift
//  WeTrain
//
//  Created by Sempercon on 29/01/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD

class SpecificWODescController: UIViewController, currentWODelegate {
    
    @IBOutlet var workOutImg        : UIImageView!
    @IBOutlet var lblWoDescription  : UILabel!
    
    @IBOutlet var constrainlblDescWidth     : NSLayoutConstraint!
    @IBOutlet var constrainlblDescheight    : NSLayoutConstraint!
    @IBOutlet var buttonTrainNow            : UIButton!
    var rightBarButton : UIBarButtonItem!


    var requestedTrainingType: Int?
    var requestedTrainingLength: Int?
    var isShowTrainNow: Bool?
    
    // MARK: VIEW DELEGATES
    
    override func viewDidLoad() {
        
        
        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        //self.navigationItem.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: self, action: "back")
        
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: self, action: "back")
        self.navigationItem.title = TRAINING_TITLES[requestedTrainingType!]
        
        if isShowTrainNow == true {
            
            self.rightBarButton = UIBarButtonItem(title: "Train Now", style: UIBarButtonItemStyle.Done, target: self, action: "didClicktrainNow")
            self.rightBarButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.systemFontOfSize(17),
                NSForegroundColorAttributeName : UIColor.whiteColor()],
                forState: UIControlState.Normal)
            
            self.navigationItem.rightBarButtonItem = self.rightBarButton

        }
        
        self.lblWoDescription.text = TRAINING_DESC[requestedTrainingType!]
        
        let name = TRAINING_ICONS[requestedTrainingType!] as String
        self.workOutImg.image = UIImage(named: name)!
        
        
        if (UIScreen.mainScreen().bounds.height <= 480) {
            self.lblWoDescription.font = UIFont.systemFontOfSize(13)
        }

        
        self.constrainlblDescWidth.constant = self.view.frame.size.width - 60;

        let label:UILabel = UILabel(frame: CGRectMake(0, 0, self.constrainlblDescWidth.constant, CGFloat.max))
        label.numberOfLines = 0
        label.lineBreakMode = NSLineBreakMode.ByWordWrapping
        label.font = self.lblWoDescription.font
        label.text = self.lblWoDescription.text
        label.sizeToFit()
        
        self.constrainlblDescheight.constant = label.frame.height;
        
        changeTrainNowApperance(true)
        self.getCurrentWorkOutStatus(true, callBackcontroller: self)

    }
    
    
    func back() {
        // pops the next button
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    
    func didClicktrainNow() {
         //self.performSegueWithIdentifier("GoToMap", sender: self)
        
        self.appDelegate().OptionType = "Train Now"
        self.appDelegate().ScheduleTime = nil
        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        tabNabcontroller.popToRootViewControllerAnimated(false)
        
        let tController: TrainingLengthViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TrainingLengthViewController") as! TrainingLengthViewController
        

        tController.isBackToSpecificWO = true
        tabNabcontroller.visibleViewController?.navigationController!.pushViewController(tController, animated: false)

        
    }
    
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        
        if segue.identifier == "GoToMap" {
            let controller = segue.destinationViewController as! MapViewController
            controller.requestedTrainingType = self.requestedTrainingType
            controller.requestedTrainingLength = self.requestedTrainingLength
        }
      
    }
    
    
    // MARK: - WORKOUT DELEGATE
    // MARK: - WORKOUT DELEGATE
    
    func currentWorkoutStatus(request: PFObject) {
        Generals.hideLoadingView()
        
        if let state = request.objectForKey("status") as? String {
            
            if (state == RequestState.Matched.rawValue || state == RequestState.Searching.rawValue || state == RequestState.Training.rawValue)
            {
                changeTrainNowApperance(true)
            }
            else
            {
                changeTrainNowApperance(false)
            }
        }
        else
        {
            changeTrainNowApperance(false)
        }
        
        
    }
    
    func userNotHavingWorkout() {
        Generals.hideLoadingView()
        changeTrainNowApperance(false)
    }
    
    func changeTrainNowApperance(isHide: Bool){
        
        if isHide {
            
            self.navigationItem.rightBarButtonItem?.enabled = false
            
            self.rightBarButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.systemFontOfSize(17),
                NSForegroundColorAttributeName : UIColor.clearColor()],
                forState: UIControlState.Normal)
            
            
        } else {
            
            self.navigationItem.rightBarButtonItem?.enabled = true
            
            self.rightBarButton.setTitleTextAttributes([
                NSFontAttributeName : UIFont.systemFontOfSize(17),
                NSForegroundColorAttributeName :  UIColor.whiteColor()],
                forState: UIControlState.Normal)
            
        }
        
    }

    
    
}
