//
//  User.swift
//  Vanfiider
//
//  Created by Kang Shiang Yap on 2016-02-16.
//  Copyright © 2016 Fiidup. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON

class User{
    
    enum UserError: ErrorType {
        case InvalidKey
        case FetchUserError
    }
    
    var username : String = ""
    var insta_id : String = ""
    var full_name : String = ""
    var profile_picture : String = ""
    var access_token : String = ""
    
    // Might need to change
    init(username : String, id: String, full_name: String, profile_picture: String, access_token: String){
        self.username = username
        self.insta_id = id
        self.full_name = full_name
        self.profile_picture = profile_picture
        self.access_token = access_token
    }
    
    init(){
        
    }
    
    func modify(modification: () -> Void){
        modification()
        NSNotificationCenter.defaultCenter().postNotificationName("modifyUser", object: nil)
    }
    
    static func getUser() throws -> User{
        do {
            let username = try getInfo("username")
            let insta_id = try getInfo("insta_id")
            let full_name = try getInfo("full_name")
            let profile_picture = try getInfo("profile_picture")
            let access_token = try getInfo("access_token")
            return User(username: username, id: insta_id, full_name: full_name, profile_picture: profile_picture, access_token: access_token)
        } catch {
            throw UserError.FetchUserError
        }
    }
    
    static func getInfo(attribute: String) throws -> String{
        let defaults = NSUserDefaults.standardUserDefaults()
        if let attr = defaults.stringForKey(attribute){
            return attr
        }else{
            throw UserError.InvalidKey
        }
    }
    
    
    func update_db(){
        Alamofire.request(.POST, "http://www.fiidup.com/users/instagram", parameters: ["username":self.username, "insta_id":self.insta_id, "full_name": self.full_name, "profile_picture":self.profile_picture, "access_token": self.access_token], encoding: .JSON)
            .responseJSON { request, response, rslt in
                if (rslt.value == nil){
                    print("not data")
                    print(response)
                    print(request)
                    print(rslt)
                    //NSNotificationCenter.defaultCenter().postNotificationName("pushNotificationToDriverFailure", object: nil)
                }else{
                    print("Server's response!")
                    let defaults = NSUserDefaults.standardUserDefaults()
                    let json =
                    JSON(rslt.value!)
                    defaults.setObject(self.username, forKey: "username")
                    defaults.setObject(self.insta_id, forKey: "insta_id")
                    defaults.setObject(self.full_name, forKey: "full_name")
                    defaults.setObject(self.profile_picture, forKey: "profile_picture")
                    defaults.setObject(self.access_token, forKey: "access_token")
                    print(json)
                    //NSNotificationCenter.defaultCenter().postNotificationName("modifyUser", object: nil)
                }
        }
    }
}