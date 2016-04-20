//
//  MotivateMeViewController.swift
//  WeTrainers
//
//  Created by Sempercon on 04/01/16.
//  Copyright © 2016 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
import MobileCoreServices
import AssetsLibrary
import Photos

extension ALAssetsLibrary {
    
    func saveImage(image: UIImage!, toAlbum: String? = nil, withCallback callback: ((error: NSError?) -> Void)?) {
        self.writeImageToSavedPhotosAlbum(image.CGImage, orientation: ALAssetOrientation(rawValue: image.imageOrientation.rawValue)!) { (u, e) -> Void in
            if e != nil {
                if callback != nil {
                    callback!(error: e)
                }
                return
            }
            
            if toAlbum != nil {
                self.addAssetURL(u, toAlbum: toAlbum!, withCallback: callback)
            }
        }
    }
    
    func saveVideo(assetUrl: NSURL!, toAlbum: String? = nil, withCallback callback: ((error: NSError?) -> Void)?) {
        self.writeVideoAtPathToSavedPhotosAlbum(assetUrl, completionBlock: { (u, e) -> Void in
            if e != nil {
                if callback != nil {
                    callback!(error: e)
                }
                return;
            }
            
            if toAlbum != nil {
                self.addAssetURL(u, toAlbum: toAlbum!, withCallback: callback)
            }
        })
    }
    
    
    func addAssetURL(assetURL: NSURL!, toAlbum: String!, withCallback callback: ((error: NSError?) -> Void)?) {
        
        var albumWasFound = false
        
        // Search all photo albums in the library
        self.enumerateGroupsWithTypes(ALAssetsGroupAlbum, usingBlock: { (group, stop) -> Void in
            
            // Compare the names of the albums
            if group != nil && toAlbum == group.valueForProperty(ALAssetsGroupPropertyName) as! String {
                albumWasFound = true
                
                // Get the asset and add to the album
                self.assetForURL(assetURL, resultBlock: { (asset) -> Void in
                    group.addAsset(asset)
                    
                    if callback != nil {
                        callback!(error: nil)
                    }
                    
                    }, failureBlock: callback)
                
                // Album was found, bail out of the method
                return
            }
            else if group == nil && albumWasFound == false {
                // Photo albums are over, target album does not exist, thus create it
                
                // Create new assets album
                self.addAssetsGroupAlbumWithName(toAlbum, resultBlock: { (group) -> Void in
                    
                    // Get the asset and add to the album
                    self.assetForURL(assetURL, resultBlock: { (asset) -> Void in
                        group.addAsset(asset)
                        
                        if callback != nil {
                            callback!(error: nil)
                        }
                        
                        }, failureBlock: callback)
                    
                    }, failureBlock: callback)
                
                return
            }
            }, failureBlock: callback)
    }
    
}


class MotivateMeViewController: UIViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    var motivateMeRequest : Bool!
    var recordedvideoURL : NSURL!
    
    var assetCollection: PHAssetCollection!
    var albumFound : Bool = false
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    var imagePicker : UIImagePickerController!
    
    let trainer: PFObject = PFUser.currentUser()!.objectForKey("trainer") as! PFObject

    var request: PFObject!
    var client: PFObject?
    
    @IBOutlet var statuslbl : UILabel!
    @IBOutlet var activityIndicator  : UIActivityIndicatorView!


    // MARK: - UIIMAGEPICKER
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "Motivate Me!"

        self.setTitleBarColor(UIColor.blackColor(), tintColor: UIColor.whiteColor())
        self.navigationController!.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName:UIColor.whiteColor()]
        
        self.navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Close", style: .Done, target: self, action: "close")
        
        self.statuslbl.text = "Fetching"
        self.activityIndicator.hidden = false
        self.activityIndicator.startAnimating()
        
        // Do any additional setup after loading the view.
        request.fetchIfNeededInBackgroundWithBlock { (object, error) -> Void in
            self.client = self.request.objectForKey("client") as? PFObject
            self.client!.fetchIfNeededInBackgroundWithBlock({ (object, error) -> Void in
                
                self.activityIndicator.hidden = true
                self.activityIndicator.stopAnimating()

                self.acceptMotivateRequest()
                self.showCamera()
            })
        }
        
        
    }
    
    
    func acceptMotivateRequest() {
        let trainerId: String = self.trainer.objectId! as String
        let params = ["motivateMeId": self.request.objectId!, "trainerId": trainerId]
        PFCloud.callFunctionInBackground("acceptMotivateMeRequest", withParameters: params) { (results, error) -> Void in
            if error != nil {
                print("could not request training request")
                self.simpleAlert("Could not accept client", message: "The client's training session is no longer available.", completion: { () -> Void in
                    self.close()
                })
            }
            else {
                print("training session is yours")
                self.request.fetchInBackgroundWithBlock({ (object, error) -> Void in
                })
            }
        }
    }

    func close() {
        self.navigationController!.popViewControllerAnimated(true)
    }
    
    func showCamera(){
        
        if let request: PFObject = self.client!.objectForKey("motivateMe") as? PFObject {
            request.setObject(VideoRequestState.VideoRecordStarted.rawValue, forKey: "status")
            request.saveInBackground()
        }
        
        if UIImagePickerController.isSourceTypeAvailable(
            UIImagePickerControllerSourceType.Camera) {
                
                imagePicker = UIImagePickerController()
                
                imagePicker.delegate = self
                imagePicker.sourceType =
                    UIImagePickerControllerSourceType.Camera
                imagePicker.mediaTypes = [kUTTypeMovie as String]
                imagePicker.allowsEditing = false
                imagePicker.videoMaximumDuration = 15
                imagePicker.videoQuality = UIImagePickerControllerQualityType.Type640x480
                self.navigationController!.presentViewController(imagePicker, animated: true,
                    completion: nil)
        }
    }
    
    func imagePickerControllerDidCancel(picker: UIImagePickerController) {
        picker.dismissViewControllerAnimated(true, completion: nil)
    }
    
    func imagePickerController(picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : AnyObject]) {
        
        //self.performSegueWithIdentifier("GoToUploadStatus", sender: request)
        
        self.recordedvideoURL = info[UIImagePickerControllerMediaURL] as! NSURL
        
        // save video temporarily on documentdirectory
        let videoData = NSData(contentsOfURL: self.recordedvideoURL)
        let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
        let documentsDirectory: AnyObject = paths[0]
        let dataPath = documentsDirectory.stringByAppendingPathComponent("motivateMe.mov")
        
        videoData?.writeToFile(dataPath, atomically: false)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "watermarkAdded", name: "watermarkAddedSuccessfully", object: nil)
        
        
        let avsController : AVSEViewController = AVSEViewController()
        avsController.OverlayInit()
    }
    
    func watermarkAdded(){
        
        imagePicker.dismissViewControllerAnimated(true, completion: { () -> Void in
            
            // save video temporarily on documentdirectory
            let paths = NSSearchPathForDirectoriesInDomains(NSSearchPathDirectory.DocumentDirectory, NSSearchPathDomainMask.UserDomainMask, true)
            let documentsDirectory: AnyObject = paths[0]
            let dataPath = documentsDirectory.stringByAppendingPathComponent("motivateMe.mov")
            
            //confirm user to save video to album
            let alert = UIAlertController(title: nil, message: "Would like to save the video?", preferredStyle: .ActionSheet)
            alert.addAction(UIAlertAction(title: "Cancel", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
                self.dismissViewControllerAnimated(true, completion: nil)
                self.startUpload()
            }))
            alert.addAction(UIAlertAction(title: "Ok", style: .Default, handler: { (action) -> Void in
                
                self.createAlbum()
                self.saveVideoToPhotoAlbum(dataPath)
                
                self.dismissViewControllerAnimated(true, completion: nil)
            }))
            self.presentViewController(alert, animated: true, completion: nil)
            
        })
    }
    
    func createAlbum() {
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", "WeTrain")
        let collection : PHFetchResult = PHAssetCollection.fetchAssetCollectionsWithType(.Album, subtype: .Any, options: fetchOptions)
        
        if let _: AnyObject = collection.firstObject {
            self.albumFound = true
            assetCollection = collection.firstObject as! PHAssetCollection
        } else {
            PHPhotoLibrary.sharedPhotoLibrary().performChanges({
                let createAlbumRequest : PHAssetCollectionChangeRequest = PHAssetCollectionChangeRequest.creationRequestForAssetCollectionWithTitle("WeTrain")
                self.assetCollectionPlaceholder = createAlbumRequest.placeholderForCreatedAssetCollection
                }, completionHandler: { success, error in
                    self.albumFound = (success ? true: false)
                    
                    if (success) {
                        let collectionFetchResult = PHAssetCollection.fetchAssetCollectionsWithLocalIdentifiers([self.assetCollectionPlaceholder.localIdentifier], options: nil)
                        print(collectionFetchResult)
                        self.assetCollection = collectionFetchResult.firstObject as! PHAssetCollection
                    }
            })
        }}
    
    func saveVideoToPhotoAlbum (videoPath : String!) {
        
        ALAssetsLibrary().writeVideoAtPathToSavedPhotosAlbum(NSURL(fileURLWithPath: videoPath), completionBlock: { (assetURL:NSURL!, error:NSError!) -> Void in
            
//            var title = ""
//            var message = ""
//            if error != nil {
//                title = "Error"
//                message = "Failed to save video"
//            } else {
//                title = "Success"
//                message = "Video saved"
//            }
            
            ALAssetsLibrary().addAssetURL(assetURL, toAlbum: "WeTrain", withCallback: nil)
            
//            let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
//            alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
//            }))
//            self.presentViewController(alert, animated: true, completion: nil)
            
        })
        
        self.startUpload()
    }
    
    func startUpload(){

        self.upLoadVideo(self.request)

        dispatch_after(DISPATCH_TIME_NOW, dispatch_get_main_queue()) { () -> Void in
            self.navigationController?.popViewControllerAnimated(true)
        }

    }
    
    


}
