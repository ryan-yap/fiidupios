//
//  FacebookLoginViewController.swift
//  Vanfiider
//
//  Created by Kang Shiang Yap on 2016-02-15.
//  Copyright © 2016 Fiidup. All rights reserved.
//

import UIKit
import Foundation
import CoreData
import Alamofire
import SwiftyJSON

import UIKit
import Foundation
import CoreData
import Alamofire
import SwiftyJSON

class FacebookLoginViewController: UIViewController {
    
    @IBOutlet weak var webView: UIWebView!
    var coreDataStack: CoreDataStack!
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func back(){
        self.dismissViewControllerAnimated(true, completion: nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        webView.hidden = true
        NSURLCache.sharedURLCache().removeAllCachedResponses()
        if let cookies = NSHTTPCookieStorage.sharedHTTPCookieStorage().cookies {
            for cookie in cookies {
                NSHTTPCookieStorage.sharedHTTPCookieStorage().deleteCookie(cookie)
            }
        }
        
        let request = NSURLRequest(URL: Instagram.Router.requestOauthCode.URLRequest.URL!, cachePolicy: .ReloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 10.0)
        self.webView.loadRequest(request)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        /*if segue.identifier == "unwindToPhotoBrowser" && segue.destinationViewController.isKindOfClass(PhotoBrowserCollectionViewController.classForCoder()) {
        let photoBrowserCollectionViewController = segue.destinationViewController as! PhotoBrowserCollectionViewController
        if let user = sender?.valueForKey("user") as? User {
        photoBrowserCollectionViewController.user = user
        
        }
        }*/
    }
    
}

extension FacebookLoginViewController: UIWebViewDelegate {
    func webView(webView: UIWebView, shouldStartLoadWithRequest request: NSURLRequest, navigationType: UIWebViewNavigationType) -> Bool {
        debugPrint(request.URLString)
        let urlString = request.URLString
        if let range = urlString.rangeOfString(Instagram.Router.redirectURI + "?code=") {
            
            let location = range.endIndex
            let code = urlString.substringFromIndex(location)
            debugPrint(code)
            requestAccessToken(code)
            return false
        }
        return true
    }
    
    func requestAccessToken(code: String) {
        let request = Instagram.Router.requestAccessTokenURLStringAndParms(code)
        
        Alamofire.request(.POST, request.URLString, parameters: request.Params)
            .responseJSON {
                (_, _, result) in
                switch result {
                case .Success(let jsonObject):
                    //debugPrint(jsonObject)
                    let json = JSON(jsonObject)
                    print("HEOHEOHE")
                    print(json)
                    if let accessToken = json["access_token"].string, userID = json["user"]["id"].string {
                        //let user = NSEntityDescription.insertNewObjectForEntityForName("User", inManagedObjectContext: self.coreDataStack.context) as! User
                        //user.userID = userID
                        //user.accessToken = accessToken
                        //self.coreDataStack.saveContext()
                        //self.performSegueWithIdentifier("unwindToPhotoBrowser", sender: ["user": user])
                    }
                case .Failure:
                    break;
                }
        }
    }
    
    func webViewDidFinishLoad(webView: UIWebView) {
        webView.hidden = false
    }
    
    func webView(webView: UIWebView, didFailLoadWithError error: NSError?) {
        
    }
}