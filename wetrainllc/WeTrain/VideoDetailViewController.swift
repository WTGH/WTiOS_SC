//
//  VideoDetailViewController.swift
//  WeTrain
//
//  Created by Sempercon on 29/12/15.
//  Copyright © 2015 Bobby Ren. All rights reserved.
//

import UIKit
import Parse
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

class VideoDetailViewController: UIViewController {
    
    var assetCollection: PHAssetCollection!
    var albumFound : Bool = false
    var collection: PHAssetCollection!
    var assetCollectionPlaceholder: PHObjectPlaceholder!
    
    var parentController : VideoRequsestStatusViewController?
    
    var shareController  : ShareViewController?
    
    // MARK: - View Delegate
    
    override func viewDidLoad() {
        self.createAlbum()
    }
    
    override func viewWillAppear(animated: Bool) {
        self.navigationItem.hidesBackButton = true
    }

    
    // MARK: - Button Action
    @IBAction func didRetryClick () {
        
        self.parentController?.playMotivateMeVideo(false)
    }
    
    @IBAction func didTrainClick () {
        
        let message: String = "Save video to phone?"
        let alert: UIAlertController = UIAlertController(title: "Confirm", message: message, preferredStyle: UIAlertControllerStyle.Alert)
        
        alert.addAction(UIAlertAction(title: "No", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
           self.moveToSelectDuration()
        }))
        
        alert.addAction(UIAlertAction(title: "Yes", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
            self.downloadAndSaveMotivateMeVideo(self)
        }))
        
        self.presentViewController(alert, animated: true, completion: nil)
        alert.view.tintColor = UIColor.blackColor()

       
    }
    
    @IBAction func didUploadClick () {
        
        self.downloadAndSaveMotivateMeVideo(self)
       // self.performSegueWithIdentifier("GoToShare", sender: nil)
        

    }
    
    
    func moveToSelectDuration(){
        
        self.appDelegate().OptionType = "Train Now"
        
        let tcon : UITabBarController = (Generals.appRootController() as UITabBarController?)!
        tcon.selectedIndex = 0
        let tabNabcontroller : UINavigationController = tcon.viewControllers?.first as! UINavigationController
        
        let sController: TrainingLengthViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("TrainingLengthViewController") as! TrainingLengthViewController
        
        tabNabcontroller.pushViewController(sController, animated: false)
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
    
        
    func videoDownloaded(error:NSError!,assetURL:NSURL!){
       
        
        let string: String = "WeTrain"
        let URL: NSURL =  NSURL(string: "assets-library://asset/asset.mov?id=AC931052-4FEA-48CC-9719-14483A479B8A&ext=mov")!
        let activityViewController = UIActivityViewController(activityItems: [string, URL], applicationActivities: nil)
        activityViewController.excludedActivityTypes = [UIActivityTypePrint,UIActivityTypeCopyToPasteboard]
        navigationController?.presentViewController(activityViewController, animated: true) {
        }
//        let string: String = "WeTrain"
//        let URL: NSURL =  assetURL
//        let avAsset : AVAsset = AVAsset(URL: URL)
//
//        let activityViewController = UIActivityViewController(activityItems: [string, avAsset], applicationActivities: nil)
//        navigationController?.presentViewController(activityViewController, animated: true) {
//        }
        
        
//        var title = ""
//        var message = ""
//        if error != nil {
//            title = "Error"
//            message = "Failed to save video"
//        } else {
//            title = "Success"
//            message = "Video saved"
//        }
//        let alert = UIAlertController(title: title, message: message, preferredStyle: .Alert)
//        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertActionStyle.Default, handler: { (action) -> Void in
//            self.moveToSelectDuration()
//        }))
//        self.navigationController!.presentViewController(alert, animated: true, completion: nil)

    }
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
       
        if segue.identifier == "GoToShare" {
            self.shareController = segue.destinationViewController as? ShareViewController
            
            let client: PFObject = PFUser.currentUser()!.objectForKey("client") as! PFObject
            self.shareController!.currentRequest =  (client.objectForKey("motivateMe") as? PFObject)!
        }
    }

}
