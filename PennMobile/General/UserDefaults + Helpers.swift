//
//  UserDefaults + Helpers.swift
//  PennMobile
//
//  Created by Josh Doman on 7/31/17.
//  Copyright © 2017 PennLabs. All rights reserved.
//

import Foundation

//Mark: UserDefaultsKeys
extension UserDefaults {
    enum UserDefaultsKeys: String {
        case deviceUUID
        case deviceToken
        case controllerSettings
        case sessionCount
        case laundryPreferences
        case isOnboarded
        case gsrUSer
        case appVersion
    }
}

// Mark: Permanent DeviceUUID
extension UserDefaults {
    func set(deviceUUID: String) {
        set(deviceUUID, forKey: UserDefaultsKeys.deviceUUID.rawValue)
        synchronize()
    }
    
    func getDeviceUUID() -> String? {
        return string(forKey: UserDefaultsKeys.deviceUUID.rawValue)
        
    }
    
    func isFirstTimeUser() -> Bool {
        return getDeviceUUID() == nil
    }
}

// Mark: VC Controller Settings (order of VCs)
extension UserDefaults {
    func set(vcDisplayNames: [String]) {
        set(vcDisplayNames, forKey: UserDefaultsKeys.controllerSettings.rawValue)
        synchronize()
    }
    
    func getVCDisplayNames() -> [String]? {
        return array(forKey: UserDefaultsKeys.controllerSettings.rawValue) as? [String]
    }
}

extension UserDefaults {
    func set(sessionCount: Int) {
        set(sessionCount, forKey: UserDefaultsKeys.sessionCount.rawValue)
        synchronize()
    }
    
    func getSessionCount() -> Int? {
        return integer(forKey: UserDefaultsKeys.sessionCount.rawValue)
    }
    
    func incrementSessionCount() {
        if let count = getSessionCount() {
            UserDefaults.standard.set(sessionCount: count + 1)
        } else {
            set(sessionCount: 0)
        }
    }
}

// Mark: Permanent Device Token (for push notifications)
extension UserDefaults {
    func set(deviceToken: String) {
        set(deviceToken, forKey: UserDefaultsKeys.deviceToken.rawValue)
        synchronize()
    }
    
    func getDeviceToken() -> String? {
        return string(forKey: UserDefaultsKeys.deviceToken.rawValue)
    }
}

// Mark: Laundry Preferences
extension UserDefaults {
    func set(preferences: [Int]) {
        set(preferences, forKey: UserDefaultsKeys.laundryPreferences.rawValue)
        synchronize()
    }
    
    func getLaundryPreferences() -> [Int]? {
        return array(forKey: UserDefaultsKeys.laundryPreferences.rawValue) as? [Int]
    }
}

// Mark: Onboarding Status
extension UserDefaults {
    func setIsOnboarded(value: Bool) {
        set(value, forKey: UserDefaultsKeys.isOnboarded.rawValue)
        synchronize()
    }

    func isOnboarded() -> Bool {
        return bool(forKey: UserDefaultsKeys.isOnboarded.rawValue)
    }
}

// Mark: - GSR User
extension UserDefaults {
    func setGSRUser(value: GSRUser) {
        let encoder = JSONEncoder()
        if let encoded = try? encoder.encode(value) {
            UserDefaults.standard.set(encoded, forKey: UserDefaultsKeys.gsrUSer.rawValue)
        }
        synchronize()
    }
    
    func getGSRUser() -> GSRUser? {
        let decoder = JSONDecoder()
        if let decodedData = UserDefaults.standard.data(forKey: UserDefaultsKeys.gsrUSer.rawValue) {
            return try? decoder.decode(GSRUser.self, from: decodedData)
        }
        return nil
    }
    
    func clearGSRUser() {
        removeObject(forKey: UserDefaultsKeys.gsrUSer.rawValue)
    }
}

// MARK: - App Version
extension UserDefaults {
    func isNewAppVersion() -> Bool {
        let prevAppVersion = string(forKey: UserDefaultsKeys.appVersion.rawValue) ?? ""
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        return prevAppVersion != version
    }
    
    func setAppVersion() {
        let version = Bundle.main.infoDictionary!["CFBundleShortVersionString"] as! String
        set(version, forKey: UserDefaultsKeys.appVersion.rawValue)
        synchronize()
    }
}

