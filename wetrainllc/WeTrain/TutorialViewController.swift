//
//  TutorialViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 10/19/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import MBProgressHUD

protocol TutorialDelegate: class {
    func didCloseTutorial()
}

class TutorialViewController: UIViewController, TutorialScrollDelegate, currentWODelegate {
    
    @IBOutlet weak var tutorialView: TutorialScrollView!
    var tutorialCreated: Bool = false
    weak var delegate: TutorialDelegate?
    var rightBarButton : UIBarButtonItem!
    
    var allPages: [String] = ["IntroTutorial0", "IntroTutorial1", "IntroTutorial2", "IntroTutorial3", "IntroTutorial4", "IntroTutorial5", "IntroTutorial6"]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        
        self.rightBarButton = UIBarButtonItem(title: "Train Now", style: UIBarButtonItemStyle.Done, target: self, action: "start")
        self.rightBarButton.setTitleTextAttributes([
            NSFontAttributeName : UIFont.systemFontOfSize(17),
            NSForegroundColorAttributeName : UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)],
            forState: UIControlState.Normal)
        
        self.navigationItem.rightBarButtonItem = self.rightBarButton

        
        self.setTitleBarColor(UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), tintColor: UIColor(red: 0, green: 122/255, blue: 1, alpha: 1))
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "My Account", style: .Done, target: self, action: "back")
//
//        let trainNowButton:UIButton = UIButton(type: UIButtonType.Custom)
//        trainNowButton.addTarget(self, action: "start", forControlEvents: UIControlEvents.TouchUpInside)
//        trainNowButton.setTitle("Train Now", forState: UIControlState.Normal)
//        trainNowButton.titleLabel?.font = UIFont.systemFontOfSize(15)
//        trainNowButton.setTitleColor(UIColor.blackColor(), forState: UIControlState.Normal)
//        trainNowButton.sizeToFit()
//        self.rightBarButton = UIBarButtonItem(customView: trainNowButton)
//        self.navigationItem.rightBarButtonItem = self.rightBarButton
        
//        self.navigationItem.rightBarButtonItem?.enabled = false
        
        changeTrainNowApperance(true)
        self.getCurrentWorkOutStatus(true, callBackcontroller: self)

    }
    
    override func viewWillAppear(animated: Bool) {
        UIApplication.sharedApplication().statusBarStyle = .Default
    }


    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if !self.tutorialCreated {
            self.tutorialView.setTutorialPages(allPages)
            self.tutorialCreated = true
            self.tutorialView.delegate = self
        }
    }
    
    func start() {
       // self.delegate!.didCloseTutorial()
        NSUserDefaults.standardUserDefaults().setBool(true, forKey: "tutorial:seen")
        
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
    
    // MARK: TutorialScrollDelegate
    func didScrollToPage(page: Int32) {
        
//        if Int(page) == self.allPages.count - 1 {
//            
//            self.rightBarButton.setTitleTextAttributes([
//                NSFontAttributeName : UIFont.systemFontOfSize(15),
//                NSForegroundColorAttributeName : UIColor.blackColor()],
//                forState: UIControlState.Normal)
//        }
//        else {
//            
//            self.rightBarButton.setTitleTextAttributes([
//                NSFontAttributeName : UIFont.systemFontOfSize(15),
//                NSForegroundColorAttributeName : UIColor.lightGrayColor()],
//                forState: UIControlState.Normal)
//        }
    }
    
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */
    
    
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
                NSForegroundColorAttributeName : UIColor(red: 0, green: 122/255, blue: 1, alpha: 1)],
                forState: UIControlState.Normal)

        }
        
    }

}
