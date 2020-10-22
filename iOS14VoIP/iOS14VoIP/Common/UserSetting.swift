//
//  UserSetting.swift
//  iOS14VoIP
//
//  Created by 古賀貴伍 on 2020/10/23.
//

import Foundation

@propertyWrapper
struct UserDefault<T> {
    let key: String
    let defaultValue: T

    var wrappedValue: T {
        get {
            return UserDefaults.standard.object(forKey: key) as? T ?? defaultValue
        }
        set {
            UserDefaults.standard.set(newValue, forKey: key)
        }
    }
}

struct UserDefaultsConfig {    
    @UserDefault(key: "deviceToken", defaultValue: "")
    static var deviceToken: String
}
