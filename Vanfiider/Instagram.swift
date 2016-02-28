//
//  Instagram.swift
//  Vanfiider
//
//  Created by Kang Shiang Yap on 2016-02-15.
//  Copyright © 2016 Fiidup. All rights reserved.
//

import Alamofire
import UIKit

struct Instagram {
    
    enum Router: URLRequestConvertible {
        static let baseURLString = "https://api.instagram.com"
        static let clientID = "33ecc171ceb94b37b49aafecf0b72080"
        static let redirectURI = "http://www.fiidup.com/instagram/handleauth"
        static let clientSecret = "16e310abf7c44f05b95538ab86aa61c2"
        
        case PopularPhotos(String, String)
        case requestOauthCode
        
        static func requestAccessTokenURLStringAndParms(code: String) -> (URLString: String, Params: [String: AnyObject]) {
            let params = ["client_id": Router.clientID, "client_secret": Router.clientSecret, "grant_type": "authorization_code", "redirect_uri": Router.redirectURI, "code": code]
            let pathString = "/oauth/access_token"
            let urlString = Instagram.Router.baseURLString + pathString
            return (urlString, params)
        }
        
        // MARK: URLRequestConvertible
        
        var URLRequest: NSMutableURLRequest {
            let result: (path: String, parameters: [String: AnyObject]?) = {
                switch self {
                case .PopularPhotos (let userID, let accessToken):
                    let params = ["access_token": accessToken]
                    let pathString = "/v1/users/" + userID + "/media/recent"
                    return (pathString, params)
                    
                case .requestOauthCode:
                    let pathString = "/oauth/authorize/?client_id=" + Router.clientID + "&redirect_uri=" + Router.redirectURI + "&response_type=code"
                    return (pathString, nil)
                }
            }()
            
            let BaeseURL = NSURL(string: Router.baseURLString)!
            let URLRequest = NSURLRequest(URL: BaeseURL.URLByAppendingPathComponent(result.path))
            let encoding = Alamofire.ParameterEncoding.URL
            return encoding.encode(URLRequest, parameters: result.parameters).0
        }
    }
    
}

extension Alamofire.Request {
    class func imageResponseSerializer() -> GenericResponseSerializer<UIImage> {
        return GenericResponseSerializer { request, response, data in
            guard let validData = data where validData.length > 0 else {
                return .Failure(data, Request.imageDataError())
            }
            
            if let image = UIImage(data: validData, scale: UIScreen.mainScreen().scale) {
                return Result<UIImage>.Success(image)
            }
            else {
                return .Failure(data, Request.imageDataError())
            }
            
        }
    }
    
    func responseImage(completionHandler: (NSURLRequest?, NSHTTPURLResponse?, Result<UIImage>) -> Void) -> Self {
        return response(responseSerializer: Request.imageResponseSerializer(), completionHandler: completionHandler)
    }
    
    private class func imageDataError() -> NSError {
        let failureReason = "Failed to create a valid Image from the response data"
        return Error.errorWithCode(NSURLErrorCannotDecodeContentData, failureReason: failureReason)
    }
}
