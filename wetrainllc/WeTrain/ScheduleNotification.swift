//
//  ScheduleNotification.swift
//  WeTrain
//
//  Created by Sempercon on 21/01/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

////ScheduleNotification
class ScheduleNotification : UIView {

    @IBOutlet var logoimg : UIImageView!
    var notificationView : UIView!
    
    static func getView() -> UIView {
        return NSBundle.mainBundle().loadNibNamed("ScheduleNotification", owner: nil, options: nil)[0] as! UIView
    }
    
    // MARK: - VIEW DELEGATES
    
    override func drawRect(rect: CGRect) {
        
        self.logoimg.layer.cornerRadius = 5
    
    }
    
    static func showNotificationView(){
        
        let notificationView = self.getView()
        let window           = UIApplication.sharedApplication().keyWindow
        
        notificationView.frame = CGRectMake((window!.frame.origin.x), -(notificationView.frame.size.height), (window!.frame.size.width), (notificationView.frame.size.height))
        
        window!.addSubview(notificationView)
        
        UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
            
        notificationView.frame = CGRectMake((window!.frame.origin.x), 20, (window!.frame.size.width), (notificationView.frame.size.height))
            
            }, completion: nil)
        
        
        let delay = 2.0 * Double(NSEC_PER_SEC)
        let time = dispatch_time(DISPATCH_TIME_NOW, Int64(delay))
        dispatch_after(time, dispatch_get_main_queue(), {
            
            UIView.animateWithDuration(0.3, delay: 0.0, options: UIViewAnimationOptions.CurveEaseOut, animations: {
                
                notificationView.frame = CGRectMake((window!.frame.origin.x), -(notificationView.frame.size.height), (window!.frame.size.width), (notificationView.frame.size.height))
                
                }, completion: {_ in
                    notificationView.removeFromSuperview()
            })
        })

    }
  

}
