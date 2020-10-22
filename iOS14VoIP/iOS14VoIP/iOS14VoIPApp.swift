//
//  iOS14VoIPApp.swift
//  iOS14VoIP
//
//  Created by 古賀貴伍 on 2020/10/23.
//

import SwiftUI
import CoreData
import os
import PushKit
import CallKit
import AVFoundation
import AudioToolbox

@main
struct iOS14VoIPApp: App {
    @UIApplicationDelegateAdaptor private var appdelegate:AppDelegate
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

// AppDelegateを使用してデバイストークンを取得する
class AppDelegate:NSObject {
    var provider: CXProvider?
    private let controller = CXCallController()
    let configuration = CXProviderConfiguration()
}

extension AppDelegate:UIApplicationDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
                
        self.registerForPushNotifications()
        self.voipRegistation()
        return true
    }
    
    // 通常のPush通知
    func registerForPushNotifications(){
        let center = UNUserNotificationCenter.current()
        // Push通知の取得可否のポップアップ表示、一度許可したらずっと許可される
        center.requestAuthorization(options: [.alert,.badge,.sound]){ granted,error in
            
            if error != nil { return }
            
            if granted {
                // registerForRemoteNotifications()が描画処理と被ってしまうと落ちる警告が表示されるので鬱陶しい
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }
    
    // VoIPの初期設定
    func voipRegistation(){
        let pushRegistry = PKPushRegistry(queue: .main)
        pushRegistry.delegate = self
        pushRegistry.desiredPushTypes = [.voIP]
    }
    
    // Push通知のToken取得
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {}
    // Push通知のToken取得失敗
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {}
}


extension AppDelegate:PKPushRegistryDelegate{
    
    // VoIPのTokenを取得する
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        let deviceToken = pushCredentials.token.map { String(format: "%02x", $0) }.joined()
        // 内部に保持する
        UserDefaultsConfig.deviceToken = deviceToken
    }
    
    // Token 取得失敗
    func pushRegistry(_ registry: PKPushRegistry, didInvalidatePushTokenFor type: PKPushType) {}
    
    // VoIPでの着信
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        // voip 通信以外は抜ける
        guard type == .voIP else { return }
        let uuid = UUID()
        let update = CXCallUpdate()
        
        // aps　ペイロードの情報を受け取る
        let pay = payload.dictionaryPayload["aps"] as! [String: Any]
        update.remoteHandle = CXHandle(type: .generic, value: "")  // 第二引数は null を入れない
        update.localizedCallerName = (pay["alert"] as! String) // 指定していないと「不明」と表示される
        update.hasVideo = false  // trueの場合「アプリ名ビデオ」、falseの場合「アプリ名オーディオ」と表示される
        let configuration = CXProviderConfiguration()
        configuration.supportedHandleTypes = [.generic]

        self.provider = CXProvider(configuration: configuration)
        
        self.provider?.setDelegate(self, queue: nil)
        
        // CallKit着信画面を表示。
        self.provider?.reportNewIncomingCall(with: uuid, update: update, completion: { error in
            if let error = error {
                 print("reportNewIncomingCall error: \(error.localizedDescription)")
            }
            DispatchQueue.main.async {
                completion()
            }
        })
    }
}

extension AppDelegate:CXProviderDelegate {
    
    func providerDidReset(_ provider: CXProvider) {
   
    }
    // 応答ボタン押下時のアクション
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
    
        DispatchQueue.main.async {
            let action = CXEndCallAction(call: UUID())
            let transaction = CXTransaction(action: action)
            self.controller.request(transaction) { error in
                if let error = error {
                    print("CXEndCallAction error: \(error.localizedDescription)")
                }
            }
        }
    }
    // 通話終了時及び着信中に拒否ボタン押下で呼ばれるアクション
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
    }
    
    func provider(_ provider: CXProvider, timedOutPerforming action: CXAction) {
    }
}
