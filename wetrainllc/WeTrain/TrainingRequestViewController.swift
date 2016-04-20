//
//  TrainingRequestViewController.swift
//  WeTrain
//
//  Created by Bobby Ren on 8/2/15.
//  Copyright (c) 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse

class TrainingRequestViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate {
    let TAG_ICON = 1
    let TAG_TITLE = 2
    let TAG_DETAILS = 3
    
    var selectedExerciseType: Int?
    var selectedExerciseLength: Int?
    
    var shouldHighlightEmergencyAlert: Bool = true
    
    @IBOutlet var CollectionView : UICollectionView!


    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        
        
        if self.appDelegate().randomWorkOutIndex.count == 0 || self.appDelegate().randomWorkOutIndex == nil {
            self.generaterandomWorkOut()
        }
        
        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]

        self.navigationItem.title = "Select Workout"

         self.navigationController?.navigationBar.topItem?.backBarButtonItem = UIBarButtonItem(title: "Back", style: .Done, target: self, action: "back")

        
        let flowlayout : UICollectionViewFlowLayout = self.CollectionView.collectionViewLayout as!  UICollectionViewFlowLayout
        flowlayout.itemSize = CGSizeMake(self.view.frame.size.width/2, Generals.get_visible_size(self).height/3)

        // cell selection background
        let colorView = UIView()
        colorView.backgroundColor = UIColor(red: 255/255, green: 127/255, blue: 38/255, alpha: 0.8)
        UICollectionViewCell.appearance().selectedBackgroundView = colorView
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        self.shouldHighlightEmergencyAlert = true
        self.CollectionView.reloadData()

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    func back() {
        // pops the next button
        self.navigationController!.popViewControllerAnimated(true)
    }

    // MARK: - Table view data source
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return 6
    }
    
    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("WorkOutCell", forIndexPath: indexPath) as! customCollectionCell
        
        let row =   self.appDelegate().randomWorkOutIndex.objectAtIndex(indexPath.row) as! Int
        let name = DESC_ICONS[row] as String
        cell.workoutBgImg .image = UIImage(named: name)!
        cell.workoutTitle.text = TRAINING_TITLES[row]
        cell.workoutDetail.text = TRAINING_SUBTITLES[row]
        
        cell.workoutView.layer.borderColor = UIColor(red: 130/255.0, green: 191/255.0, blue: 154/255.0, alpha: 1.0).CGColor
        cell.workoutView.layer.borderWidth = 0.5

        if cell.selectedBackgroundView == nil {
            
            let colorView = UIView()
            colorView.backgroundColor = UIColor(red: 255/255, green: 127/255, blue: 38/255, alpha: 0.8)
            cell.selectedBackgroundView = colorView
        }
        
       
        return cell
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        
        self.selectedExerciseType = indexPath.row
        self.performSegueWithIdentifier("GoToMap", sender: self)
    }
    

    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.

        if segue.identifier == "GoToMap" {
            let controller = segue.destinationViewController as! MapViewController
            
            let trainingType =   self.appDelegate().randomWorkOutIndex.objectAtIndex(self.selectedExerciseType!) as! Int
            controller.requestedTrainingType = trainingType
            controller.requestedTrainingLength = self.selectedExerciseLength
        }
        
        if segue.identifier == "GoToWODesc" {
            let controller = segue.destinationViewController as! SpecificWODescController
            controller.isShowTrainNow = true
            controller.requestedTrainingType = self.selectedExerciseType
            controller.requestedTrainingLength = self.selectedExerciseLength
        }
    }

}
