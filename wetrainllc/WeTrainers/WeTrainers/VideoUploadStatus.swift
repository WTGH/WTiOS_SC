//
//  VideoUploadStatus.swift
//  WeTrainers
//
//  Created by Sempercon on 02/01/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse


class VideoUploadStatus: UIViewController {
    
    var request: PFObject!

    @IBOutlet var statuslbl : UILabel!
    @IBOutlet var progressView : UIProgressView!
    
    
    // MARK: - View Delegate
    
    override func viewDidLoad() {
        self.navigationItem.hidesBackButton = true
    }
    
    override func viewWillAppear(animated: Bool) {
        self.upLoadVideo()
    }
    
    // MARK: - Button Actions
    
    @IBAction func btnDoneClicked(){
        self.navigationController?.popToRootViewControllerAnimated(true)
    }


    // MARK: - Custom methods

    func upLoadVideo() { /// move this function trainer app
        
        self.statuslbl.text = "Video Upload Start"
        self.progressView.progress = 0
        
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let dataPath = documentsDirectory.stringByAppendingPathComponent("motivateMe.mov")
        
        let filePath = NSURL(fileURLWithPath: dataPath)
        
        let dataToUpload : NSData = NSData(contentsOfURL: filePath)!
        
        let videoFile = PFFile(name: "motivateMe.mov", data: dataToUpload)
        
        let client: PFObject = self.request.objectForKey("client") as! PFObject
        
        client.fetchIfNeededInBackgroundWithBlock({ (object, error) -> Void in
            
            if let request: PFObject = client.objectForKey("motivateMe") as? PFObject {
                
                request.setObject(VideoRequestState.VideoUploadedStart.rawValue, forKey: "status")
                
                //change status only
                request.saveInBackground()
                
                //upload recorded video and change staus
                videoFile?.saveInBackgroundWithBlock({ (uploadsuccess, error : NSError?) -> Void in
                    
                    if uploadsuccess {
                        request.setObject(videoFile!, forKey: "video")
                        request.setObject(VideoRequestState.VideoUploaded.rawValue, forKey: "status")
                        request.saveInBackground()
                        
                    }else {
                    }
                    print("uploadvideo error : \(error)")
                    
                    }, progressBlock: ({ (percentDone : CInt) -> Void in
                        
                        //self.labelMessage.text = "\(percentDone)" + "%"
                        
                        let progress : NSNumber = NSNumber(int: percentDone)
                        self.progressView.progress = progress.floatValue / 100
                        
                        if progress == 0 {
                            self.statuslbl.text = "Video Upload Processing"
                        }
                        
                        if progress == 100 {
                            self.statuslbl.text = "Video Upload Finished"
                        }
                        
                    }))
                
            }
            
        })
        
        
        
    }

}
