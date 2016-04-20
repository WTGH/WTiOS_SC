//
//  TOSViewController.swift
//  WeTrain
//
//  Created by Sempercon on 15/02/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class TOSViewController: UIViewController {
    
    @IBOutlet var temptxtPrivacyContent : UITextView!

    @IBOutlet var txtPrivacyContent : UITextView!
    
    var proxyViewForStatusBar : UIView!
    // MARK: - VIEW DELEGATES

    override func viewDidLoad() {
        
        self.userInfoSetTitleBarColor(UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1), tintColor: UIColor(red: 0, green: 122/255, blue: 1, alpha: 1))
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.blackColor()]
        self.title = "Terms of Service & Privacy"
        self.txtPrivacyContent.text = self.temptxtPrivacyContent.text
        self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: self, action: "back")

    }
    
    override func viewDidLayoutSubviews() {
    }
    
    override func viewWillAppear(animated: Bool) {
        
        proxyViewForStatusBar  = UIView(frame: CGRectMake(0, 0,self.view.frame.size.width, 20))
        proxyViewForStatusBar.backgroundColor=UIColor(red: 235/255, green: 235/255, blue: 235/255, alpha: 1)
        self.navigationController!.view.addSubview(proxyViewForStatusBar)
        UIApplication.sharedApplication().statusBarStyle = .Default

    }
    
    override func viewWillDisappear(animated: Bool) {
        proxyViewForStatusBar.removeFromSuperview()
    }
    
    override func viewDidAppear(animated: Bool) {
    }
    
    
    // MARK: - BUTTON ACTIONS

    func close() {
        self.navigationController!.presentingViewController!.dismissViewControllerAnimated(true, completion: nil)
    }
    
  

}
