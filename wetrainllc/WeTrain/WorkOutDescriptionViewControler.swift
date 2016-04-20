//
//  WorkOutDescriptionViewControler.swift.swift
//  WeTrain
//
//  Created by Sempercon on 18/01/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit

class customCollectionCell : UICollectionViewCell {
    
    @IBOutlet var workoutView   : UIView!
    @IBOutlet var workoutBgImg  : UIImageView!
    @IBOutlet var workoutTitle  : UILabel!
    @IBOutlet var workoutDetail : UILabel!

    @IBOutlet var workoutDesc   : UITextView!
    
   
}


class WorkOutDescriptionViewControler : UIViewController , UICollectionViewDelegate, UICollectionViewDataSource{
    
    @IBOutlet var descCollectionView : UICollectionView!
    var selectedExerciseType: Int?
    var selectedExerciseLength: Int?
    
    // MARK: - VIEW DELEGATES

    override func viewDidLoad() {
     
        
        if self.appDelegate().randomWorkOutIndex.count == 0 || self.appDelegate().randomWorkOutIndex == nil {
            self.generaterandomWorkOut()
        }
        
        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        self.navigationItem.title = "Workout Description"
        
        
        let myBackButton:UIButton = UIButton(type: UIButtonType.Custom)
        myBackButton.addTarget(self, action: "back", forControlEvents: UIControlEvents.TouchUpInside)
        myBackButton.setTitle("Back", forState: UIControlState.Normal)
        myBackButton.titleLabel?.font = UIFont.systemFontOfSize(17)
        myBackButton.setImage(UIImage(named: "backBtn"), forState: UIControlState.Normal)
        myBackButton.setTitleColor(UIColor.whiteColor(), forState: UIControlState.Normal)
        myBackButton.frame = CGRectMake(0, 0, 30, 30)
        myBackButton.contentEdgeInsets = UIEdgeInsetsMake(0, -19, 0, 0)
        myBackButton.titleEdgeInsets = UIEdgeInsetsMake(0, -10, 0, 0)
        
        myBackButton.sizeToFit()
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(customView: myBackButton)

        let flowlayout : UICollectionViewFlowLayout = self.descCollectionView.collectionViewLayout as!  UICollectionViewFlowLayout
        flowlayout.itemSize = CGSizeMake(self.view.frame.size.width/2, Generals.get_visible_size(self).height/3)
        
        
        // cell selection background
        let colorView = UIView()
        colorView.backgroundColor = UIColor(red: 255/255, green: 127/255, blue: 38/255, alpha: 0.8)
        UICollectionViewCell.appearance().selectedBackgroundView = colorView
    }
    
    override func viewWillAppear(animated: Bool) {
        self.descCollectionView.reloadData()
    }
    
    
    // MARK: - BUTTON ACTIONS
    func back() {
        self.navigationController!.popViewControllerAnimated(true)
    }

    @IBAction func didClickMoveButton (){
        
        self.descCollectionView.setContentOffset(CGPointMake(0, self.descCollectionView.contentSize.height - self.descCollectionView.frame.size.height), animated: true)
    }
    
    
    
    // MARK: - COLLECTIONVIEW DELEGATE
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("DescCell", forIndexPath: indexPath) as! customCollectionCell
        
        let row = indexPath.row
        cell.workoutTitle.text = TRAINING_TITLES[row]
        cell.workoutView.layer.borderColor = UIColor(red: 130/255.0, green: 191/255.0, blue: 154/255.0, alpha: 1.0).CGColor
        cell.workoutView.layer.borderWidth = 0.5
        cell.workoutDetail.text = TRAINING_SUBTITLES[row]
        
        let name = DESC_ICONS[row] as String
        cell.workoutBgImg .image = UIImage(named: name)!
        
        if cell.selectedBackgroundView == nil {
            
            let colorView = UIView()
            colorView.backgroundColor = UIColor(red: 255/255, green: 127/255, blue: 38/255, alpha: 0.8)
            cell.selectedBackgroundView = colorView
        }
        
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.selectedExerciseType = indexPath.row
        self.performSegueWithIdentifier("GoToSpecificDesc", sender: self)
    }
    
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        
        if segue.identifier == "GoToSpecificDesc" {

            let controller = segue.destinationViewController as! SpecificWODescController
            controller.isShowTrainNow = true
            controller.requestedTrainingType = self.selectedExerciseType
            controller.requestedTrainingLength = self.selectedExerciseLength
        }
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return .LightContent
    }

}