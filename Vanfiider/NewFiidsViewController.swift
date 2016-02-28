//
//  LoginViewController.swift
//  Vanfiider
//
//  Created by Kang Shiang Yap on 2016-02-15.
//  Copyright © 2016 Fiidup. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import Alamofire
import FastImageCache
import SwiftyJSON

class NewFiidsTableViewCell : UITableViewCell {
    // MARK: - IBOutlets
    var photoInfo: PhotoInfo?
    var profilePictureInfo: PhotoInfo?
    
    @IBOutlet var roundboarded: UIView!
    @IBOutlet var captions: UITextView!
    @IBOutlet var full_name: UILabel!
    @IBOutlet var photo: UIImageView!
    @IBOutlet var profile_picture: UIImageView!
    @IBOutlet var place: UILabel!
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        backgroundColor = UIColor(white: 0.1, alpha: 1.0)
        photo.frame = CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.size.width, height: UIScreen.mainScreen().bounds.size.width)
        addSubview(photo)
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        //self.profile_picture.layer.cornerRadius = self.profile_picture.frame.size.width/2
    }
}

class NewFiidsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource,UIGestureRecognizerDelegate {

    var nextURLRequest: NSURLRequest?
    var populatingPhotos = false
    var photos = [PhotoInfo]()
    var profile_pictures = [PhotoInfo]()
    var captions = [String]()
    var full_names = [String]()
    var locations = [String]()
    
    
    let formatName = KMScreenWideSquareFormatName
    let newfiidsCellIdentifier = "NewFiidsTableViewCell"
    
    @IBOutlet var newFiidsTable: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.newFiidsTable.rowHeight = UIScreen.mainScreen().bounds.size.width + 150
        do {
            let user = try User.getUser()
            let request = Instagram.Router.PopularPhotos(user.insta_id, user.access_token)
//            let screenWidth = UIScreen.mainScreen().bounds.size.width
            let nav = self.navigationController?.navigationBar
            nav?.barStyle = UIBarStyle.BlackOpaque
//            let view = UIView(frame: CGRect(x: screenWidth/4, y: 10, width: screenWidth/2, height: 40))
//            let title = UILabel(frame: CGRect(x: view.frame.size.width/4, y: 0, width: view.frame.size.width/2, height: 30))
//            title.text = "Vanfiider"
//            title.font = UIFont(name: "Zag Bold.otf", size: 20)
//            view.addSubview(title)
//            nav?.addSubview(view)
//   
//            navigationItem.titleView = view
            self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.whiteColor(),
                NSFontAttributeName: UIFont(name: "Zag Bold", size: 21)!]
            populatePhotos(request)
        }catch{
            performSegueWithIdentifier("loginwithinstagramsegue", sender: self)
        }
        // Do any additional setup after loading the view.
    }
    
    override func preferredStatusBarStyle() -> UIStatusBarStyle {
        return UIStatusBarStyle.LightContent
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
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
                            self.newFiidsTable.insertRowsAtIndexPaths(indexPaths, withRowAnimation: .Fade)
                        }
                        
                        
    
                        
                    }
                    
                }
            case .Failure:
                break;
            }
            
        }
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return photos.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier(self.newfiidsCellIdentifier, forIndexPath: indexPath) as! NewFiidsTableViewCell
        
        let sharedImageCache = FICImageCache.sharedImageCache()
        
        cell.imageView!.image = nil
        cell.profile_picture.image = nil
        
        let layer = cell.profile_picture.layer
        layer.cornerRadius = cell.profile_picture.frame.size.width/2;
        layer.masksToBounds = true
        
        let photo = photos[indexPath.row] as PhotoInfo
        if (cell.photoInfo != photo) {
            
            sharedImageCache.cancelImageRetrievalForEntity(cell.photoInfo, withFormatName: formatName)
            
            cell.photoInfo = photo
        }
        
        sharedImageCache.retrieveImageForEntity(photo, withFormatName: formatName, completionBlock: {
            (photoInfo, _, image) -> Void in
            if (photoInfo as! PhotoInfo) == cell.photoInfo {
                cell.photo.image = image
            }
        })
        
        let profile_picture = self.profile_pictures[indexPath.row] as PhotoInfo
        if (cell.profilePictureInfo != profile_picture) {
            sharedImageCache.cancelImageRetrievalForEntity(cell.profilePictureInfo, withFormatName: formatName)
            cell.profilePictureInfo = profile_picture
        }
        
        sharedImageCache.retrieveImageForEntity(profile_picture, withFormatName: formatName, completionBlock: {
            (photoInfo, _, image) -> Void in
            if (photoInfo as! PhotoInfo) == cell.profilePictureInfo {
                cell.profile_picture.image = image
            }
        })
        
        cell.full_name.text = self.full_names[indexPath.row]
        cell.captions.text = self.captions[indexPath.row]
        let fixedWidth = cell.captions.frame.size.width
        cell.captions.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = cell.captions.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        var newFrame = cell.captions.frame
        newFrame.size = CGSize(width: max(newSize.width, fixedWidth), height: newSize.height)
        cell.captions.frame = newFrame;
        cell.place.text = self.locations[indexPath.row]
        cell.roundboarded.layer.cornerRadius = cell.roundboarded.frame.size.height/2
        cell.roundboarded.layer.masksToBounds = true
        return cell
    }
    
    func tableView(tableView: UITableView, heightForRowAtIndexPath indexPath: NSIndexPath) -> CGFloat {
        let textView = UITextView(frame: CGRect(x: 0, y: 0, width: UIScreen.mainScreen().bounds.size.width, height: 10))
        textView.text = self.captions[indexPath.row]
        let fixedWidth = textView.frame.size.width
        textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        let newSize = textView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.max))
        return UIScreen.mainScreen().bounds.size.width + 8 + 61 + 8 + newSize.height*1.3 + 25
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
