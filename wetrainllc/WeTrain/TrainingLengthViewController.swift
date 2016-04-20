//
//  TrainingLengthViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 10/19/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class TrainingLengthViewController: UIViewController {

    @IBOutlet weak var button30: UIButton!
    @IBOutlet weak var button60: UIButton!
    
    @IBOutlet var bgbutton30    : UIView!
    @IBOutlet var bgbutton60    : UIView!
    
    var isBackToSpecificWO       : Bool! = false
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
     

        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: self, action: "back")

//        if self.isBackToSpecificWO == true{
//            
//            
//            let myBackButton:UIButton = UIButton(type: UIButtonType.Custom)
//            myBackButton.addTarget(self, action: "back", forControlEvents: UIControlEvents.TouchUpInside)
//            myBackButton.setTitle("Back", forState: UIControlState.Normal)
//            myBackButton.titleLabel?.font = UIFont.systemFontOfSize(17)
//            myBackButton.setImage(UIImage(named: "backBtn"), forState: UIControlState.Normal)
//            myBackButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
//            myBackButton.frame = CGRectMake(0, 0, 30, 30)
//            myBackButton.contentEdgeInsets = UIEdgeInsetsMake(0, -19, 0, 0)
//            myBackButton.titleEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0)
//
//            myBackButton.sizeToFit()
//            self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: myBackButton)
//            
//        }
    }

    override func viewWillAppear(animated: Bool) {
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: - Navigation
    func back() {
        // pops the next button
        
        if self.isBackToSpecificWO == true {
            let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
            tcon.selectedIndex = 1
        } else {
            self.navigationController!.popViewControllerAnimated(true)
        }
    }

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
        if segue.identifier == "GoToTrainingRequest" {
            let controller = segue.destinationViewController as! TrainingRequestViewController
            if sender != nil && sender! as! UIButton == self.button30 {
                controller.selectedExerciseLength = 30
                self.changeButtonBGColor(30)
            }
            else if sender != nil && sender! as! UIButton == self.button60 {
                controller.selectedExerciseLength = 60
                self.changeButtonBGColor(60)
            }
        }
        if segue.identifier == "GoToRequestState" {
            let controller = segue.destinationViewController as! RequestStatusViewController
            let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
            let request: PFObject = client.objectForKey("workout") as! PFObject
            controller.currentRequest = request
        }
    }
    

    
    
    // MARK: - CUSTOM METHODS
    
    func changeButtonBGColor(trainingDuration : Int!){
        

    }
    
  
}
