//
//  AvailableTrainers.swift
//  WeTrain
//
//  Created by Sempercon on 08/02/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class AvailableTrainers : UIView {
    
   @IBOutlet var imgTrainerStatus        : UIImageView!
   @IBOutlet var lblAvailableTrainers    : UILabel!

   @IBOutlet var centerLayoutConstarin    : NSLayoutConstraint!
    
    static func getView() -> UIView {
        return NSBundle.mainBundle().loadNibNamed("AvailableTrainers", owner: nil, options: nil)[0] as! UIView
    }
    
    // MARK: - VIEW DELEGATES
    
    override func drawRect(rect: CGRect) {
        
//        self.imgTrainerStatus.hidden = true
//        self.lblAvailableTrainers.hidden = true
        
    }
    
    func getAvailableTrainer () {
        
        let availbleTrainer : Int32  =  Int32((arc4random_uniform(20)+1)) + Int32((arc4random_uniform(30)+1))   + 20
        self.lblAvailableTrainers.text =  "\(availbleTrainer) Trainers Waiting For You"
        
//        self.imgTrainerStatus.hidden = true
//        self.lblAvailableTrainers.hidden = true
//
//        
//        ////get promocode to check valid
//        let query : PFQuery = PFQuery(className: "Trainer")
//        query.whereKey("status", equalTo: "available")
//        query.countObjectsInBackgroundWithBlock { (count, _) -> Void in
//            
//            print(count)
//            
//            // Do any additional setup after loading the view.
//            let availbleTrainer : Int32  =  count + Int32((arc4random_uniform(30)+1))   + 20
//            self.lblAvailableTrainers.text =  "\(availbleTrainer) Trainers Waiting For You"
//            
//            self.imgTrainerStatus.hidden = false
//            self.lblAvailableTrainers.hidden = false
//            
//            self.lblAvailableTrainers.sizeToFit()
//            
//            //self.centerLayoutConstarin.constant = self.frame.size.width / 2
//            
//            
//        }
    }
}