//
//  ViewController.swift
//  Delete
//
//  Created by 蟑螂先生 on 2021/3/18.
//

import UIKit
import Photos

class ViewController: UIViewController {

    override func viewDidLoad() {
        _=authorize()
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
    }
    func authorize()->Bool{
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.audio)
         
        switch status {
        case .authorized:
            return true
             
        case .notDetermined:
            // 请求授权
            AVCaptureDevice.requestAccess(for: AVMediaType.audio, completionHandler: {
                (status) in
                DispatchQueue.main.async(execute: { () -> Void in
                    _ = self.authorize()
                })
            })
        default: ()
        DispatchQueue.main.async(execute: { () -> Void in
            let alertController = UIAlertController(title: "麦克风访问受限",
                                                    message: "点击“设置”，允许访问您的麦克风",
                                                    preferredStyle: .alert)
             
            let cancelAction = UIAlertAction(title:"取消", style: .cancel, handler:nil)
             
            let settingsAction = UIAlertAction(title:"设置", style: .default, handler: {
                (action) -> Void in
                let url = URL(string: UIApplication.openSettingsURLString)
                if let url = url, UIApplication.shared.canOpenURL(url) {
                    if #available(iOS 10, *) {
                        UIApplication.shared.open(url, options: [:],
                                                  completionHandler: {
                                                    (success) in
                        })
                    } else {
                        UIApplication.shared.openURL(url)
                    }
                }
            })
             
            alertController.addAction(cancelAction)
            alertController.addAction(settingsAction)
             
            self.present(alertController, animated: true, completion: nil)
        })
        }
        return false
    }
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func AudioStart(_ sender: UIButton) {
        newAudioQueue.MyAudioQueue.startRecord()
    }
    
    @IBAction func AudioStop(_ sender: UIButton) {
        newAudioQueue.MyAudioQueue.stopRecord()
    }
    
    
    
}
