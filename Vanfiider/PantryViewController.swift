//
//  PantryViewController.swift
//  Vanfiider
//
//  Created by Kang Shiang Yap on 2016-03-04.
//  Copyright © 2016 Fiidup. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import Alamofire
import FastImageCache
import SwiftyJSON

class PantryViewController: UIViewController,UICollectionViewDataSource, UICollectionViewDelegate, UIGestureRecognizerDelegate, UICollectionViewDelegateFlowLayout {

    
    var nextURLRequest: NSURLRequest?
    var populatingPhotos = false
    var photos = [PhotoInfo]()
    var profile_pictures = [PhotoInfo]()
    var captions = [String]()
    var full_names = [String]()
    var locations = [String]()
    let formatName = KMScreenOneThirdSquareFormatName
    
    @IBOutlet var pantryCollectionView: UICollectionView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }

    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        do {
            let user = try User.getUser()
            let request = Instagram.Router.PopularPhotos(user.insta_id, user.access_token)
            let nav = self.navigationController?.navigationBar
            nav?.barStyle = UIBarStyle.BlackOpaque
            
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: UIFont(name: "Zag Bold", size: 21)!]
            populatePhotos(request)
        }catch{
            performSegueWithIdentifier("loginwithinstagramsegue", sender: self)
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    func collectionView(collectionView: UICollectionView, cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCellWithReuseIdentifier("PantryCollectionViewCell",forIndexPath: indexPath) as! PantryCollectionViewCell
        
        let sharedImageCache = FICImageCache.sharedImageCache()
        
        cell.image!.image = nil
        let photo = photos[indexPath.row] as PhotoInfo
        if (cell.photoInfo != photo) {
            
            sharedImageCache.cancelImageRetrievalForEntity(cell.photoInfo, withFormatName: formatName)
            
            cell.photoInfo = photo
        }
        
        sharedImageCache.retrieveImageForEntity(photo, withFormatName: formatName, completionBlock: {
            (photoInfo, _, image) -> Void in
            if (photoInfo as! PhotoInfo) == cell.photoInfo {
                cell.image.image = image
            }
        })
        return cell

    }
    
    func collectionView(collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return photos.count
    }
    
    func populatePhotos(request: URLRequestConvertible) {
        
        if populatingPhotos {
            return
        }
        
        populatingPhotos = true
        
        Alamofire.request(request).responseJSON() {
            (_ , _, result) in
            defer {
                self.populatingPhotos = false
            }
            switch result {
            case .Success(let jsonObject):
                //debugPrint(jsonObject)
                let json = JSON(jsonObject)
                
                if (json["meta"]["code"].intValue  == 200) {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)) {
                        if let urlString = json["pagination"]["next_url"].URL {
                            self.nextURLRequest = NSURLRequest(URL: urlString)
                        } else {
                            self.nextURLRequest = nil
                        }
                        
                        // Extracting images
                        let photoInfos = json["data"].arrayValue
                            
                            .filter {
                                $0["type"].stringValue == "image"
                            }.map({
                                PhotoInfo(sourceImageURL: $0["images"]["standard_resolution"]["url"].URL!)
                            })
                        
                        let lastItem = self.photos.count
                        self.photos.appendContentsOf(photoInfos)
                        
                        //Extracting profile pictures
                        let userInfos = json["data"].arrayValue
                            
                            .filter {
                                $0["type"].stringValue == "image"
                            }.map({
                                PhotoInfo(sourceImageURL: $0["user"]["profile_picture"].URL!)
                            })
                        self.profile_pictures.appendContentsOf(userInfos)
                        
                        //Extracting captions
                        let captionsInfos = json["data"].arrayValue.map({
                            String(stringLiteral: $0["caption"]["text"].stringValue)
                        })
                        self.captions.appendContentsOf(captionsInfos)
                        
                        //Extracting Full Name
                        let fnameInfos = json["data"].arrayValue.map({
                            String(stringLiteral: $0["user"]["full_name"].stringValue)
                        })
                        self.full_names.appendContentsOf(fnameInfos)
                        
                        //Extracting locations
                        let locationsInfos = json["data"].arrayValue.map({
                            String(stringLiteral: $0["location"]["name"].stringValue)
                        })
                        self.locations.appendContentsOf(locationsInfos)
                        
                        let indexPaths = (lastItem..<self.photos.count).map { NSIndexPath(forItem: $0, inSection: 0) }
                        
                        dispatch_async(dispatch_get_main_queue()) {
                            self.pantryCollectionView.insertItemsAtIndexPaths(indexPaths)
                        }
                    }
                }
            case .Failure:
                break;
            }
            
        }
    }
    
    func collectionView(collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
        let size : CGFloat = (self.pantryCollectionView.frame.width - 2)/3
        return CGSize(width: size, height: size)
    }
    
    func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if(scrollView.panGestureRecognizer.velocityInView(self.view).y < 0){
            self.navigationController?.setNavigationBarHidden(true, animated: true)
        }else{
            self.navigationController?.setNavigationBarHidden(false, animated: true)
        }
    }
    
    
    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
