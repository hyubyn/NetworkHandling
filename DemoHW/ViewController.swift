//
//  ViewController.swift
//  DemoHW
//
//  Created by NguyenVuHuy on 12/11/17.
//  Copyright © 2017 Hyubyn. All rights reserved.
//

import UIKit
import UserNotifications
import CoreLocation
import FirebaseDatabase

fileprivate let link = "https://d2suzd7bkd85tf.cloudfront.net/stixchat/test/resource/15132212904965d7c36dae9d3448cbebcf2602684bf69/1/1513221290498.jpg?v=appresource"

class ViewController: UIViewController, CLLocationManagerDelegate,URLSessionDelegate, URLSessionDataDelegate, NetworkHelperDelegate {

    private var locationManager: CLLocationManager!
    var ref: DatabaseReference!
    var canShowNoti = true
    var firstCheck = false
    
    
    typealias speedTestCompletionHandler = (_ megabytesPerSecond: Double? , _ error: Error?) -> Void
    
    var speedTestCompletionBlock : speedTestCompletionHandler?
    
    var startTime: CFAbsoluteTime!
    var stopTime: CFAbsoluteTime!
    var bytesReceived: Int!
    
    var isChecking = false
    var firstCheckNumber: Double = 0
    var secondCheckNumber: Double = 0
    var thirdCheckNumber: Double = 0
    
    let networkHelper = NetworkHelper()
    var pingGateWayStartTime: CFAbsoluteTime = 0
    var pingGateWayEndTime: CFAbsoluteTime = 0
    var pingServerStartTime: CFAbsoluteTime = 0
    var pingServerEndTime: CFAbsoluteTime = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.allowsBackgroundLocationUpdates = true
        // Check for Location Services
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestAlwaysAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        ref = Database.database().reference()
        
        networkHelper.delegate = self
        
        networkHelper.get_dns_servers()
        
        print(networkHelper.getGatewayIP())
        
    }

    func didPingDefaultGateWay(_ result: Bool) {
        print("Has ping to default gateway with result: \(result)")
        pingGateWayEndTime = CFAbsoluteTimeGetCurrent()
        print("Has ping to default gateway with time: \(pingGateWayEndTime - pingGateWayStartTime)s")
        print("Start ping to server d2suzd7bkd85tf.cloudfront.net")
        pingServerStartTime = CFAbsoluteTimeGetCurrent()
        networkHelper.pingToServer()
        
    }
    
    func didPingServer(_ result: Bool) {
        print("Has ping to Server with result: \(result)")
        pingServerEndTime = CFAbsoluteTimeGetCurrent()
        print("Has ping to Server with time: \(pingServerEndTime - pingServerStartTime)s")
        print("Start test download file")
        testSpeed { (_) in
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func downloadButtonTapped(_ sender: Any) {
        UIApplication.shared.open(URL(string: "https://goo.gl/jnLhhc")!)
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !firstCheck {
            firstCheck = true
            return
        }
        do {
            Network.reachability = try Reachability(hostname: "www.google.com")
            do {
                try Network.reachability?.start()
                guard let status = Network.reachability?.status else { return }
                switch status {
                case .unreachable: // not connect to network
                    self.canShowNoti = true
                    break;
                default:
                    showNetworkInfo()
                }
            } catch let error as Network.Error {
                print(error)
            } catch {
                print(error)
            }
        } catch {
            print(error)
        }
        
    }

    func testSpeed(completionBlock: @escaping (CGFloat) -> ())  {
        
        
        let url = URL(string: link)
        let request = URLRequest(url: url!)
        
        let session = URLSession.shared
        
        let startTime = Date()
        
        let task =  session.dataTask(with: request) { (data, resp, error) in
            
            guard error == nil && data != nil else{
                
                print("connection error or data is nill")
                completionBlock(0)
                return
            }
            
            guard resp != nil else{
                print("respons is nill")
                completionBlock(0)
                return
            }
            
            
            let length  = CGFloat((resp?.expectedContentLength)!) * 8   // convert to bit
            
            let elapsed = CGFloat(Date().timeIntervalSince(startTime))
            
            print("Size of file downloaded = \(length)")
            
            print("elapsed: \(elapsed)")
            
            print("Speed: \(length/(elapsed * 1048576.0)) Mbps")  // convert from bps to Mbps
            completionBlock(length/elapsed)
            
            
        }
        
        
        task.resume()
        
        
    }
    
    @objc func showNetworkInfo() {
        if !canShowNoti {
            return
        }
        let wifiName = NetworkChecker().getSSID()
        
        guard wifiName != nil else {
            
            //// TODO: Alert -----
            print("no wifi name")
            self.canShowNoti = true
            return
        }
        
        self.canShowNoti = false
        print("my network name is: \(wifiName!)")
        
        let content = UNMutableNotificationContent()
        content.title = "Wifi connected!!"
        content.body = "Your device has been connected to wifi name \(wifiName!)"
        content.badge = 0
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 1.0, repeats: false)
        let request = UNNotificationRequest(identifier: "timerOne", content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
        
        // push to firebase
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM-dd-yyyy HH:mm"
        let dateInFormat = dateFormatter.string(from: Date())
        self.ref.child("Connected").child(dateInFormat).setValue(["SSID": wifiName!])
        
        // check ping to Default Gateway first
        
        print("Start ping to gateway")
        pingGateWayStartTime = CFAbsoluteTimeGetCurrent()
        networkHelper.ping(toAddress: networkHelper.getGatewayIP())
        
//        testSpeed { (firstTime) in
//            self.testSpeed(completionBlock: { (secondTime) in
//                print("Avarage of 2 times = \((firstTime + secondTime) / 2) Mb/s")
//            })
//        }
        
//        checkForSpeedTest()
    }
    
    
    func testDownloadSpeedWithTimout(timeout: TimeInterval, withCompletionBlock: @escaping speedTestCompletionHandler) {
        
        guard let url = URL(string: link) else { return }
        
        startTime = CFAbsoluteTimeGetCurrent()
        stopTime = startTime
        bytesReceived = 0
        
        speedTestCompletionBlock = withCompletionBlock
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.timeoutIntervalForResource = timeout
        let session = URLSession.init(configuration: configuration, delegate: self, delegateQueue: nil)
        session.dataTask(with: url).resume()
        
    }
    
    func checkForSpeedTest() {
        testSpeed { (speed) in
            
        }
//        testDownloadSpeedWithTimout(timeout: 5.0) { (speed, error) in
//            if let mb = speed {
////                mb *= 8
//                print("Download Speed 1 time: \(mb) Mbps")
//                self.firstCheckNumber = mb
//            }
//            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30), execute: {
//                print("Start check second time")
//                self.testDownloadSpeedWithTimout(timeout: 5.0) { (speed, error) in
//                    if let mb = speed {
////                        mb *= 8
//                        print("Download Speed second time: \(mb) Mbps")
//                        self.secondCheckNumber = mb
//                    }
//                    DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(30), execute: {
//                        print("Start check second time")
//                        self.testDownloadSpeedWithTimout(timeout: 5.0) { (speed, error) in
//                            if let mb = speed {
////                                mb *= 8
//                                print("Download Speed third time: \(mb) Mbps")
//                                self.thirdCheckNumber = mb
//
//                                let result = self.thirdCheckNumber * 0.5 + self.secondCheckNumber * 0.3 + self.firstCheckNumber * 0.2
//                                print("Final result speed: \(result) Mbps")
//                            }
//                        }
//                    })
//                }
//            })
//
//        }
        
    }
    
  
  
    func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
        bytesReceived! += data.count
        stopTime = CFAbsoluteTimeGetCurrent()
    }
    
    func urlSession(_ session: URLSession, task: URLSessionTask, didCompleteWithError error: Error?) {
        
        let elapsed = stopTime - startTime
        
        if let aTempError = error as NSError?, aTempError.domain != NSURLErrorDomain && aTempError.code != NSURLErrorTimedOut && elapsed == 0  {
            speedTestCompletionBlock?(nil, error)
            return
        }
        print("elapsed time: \(elapsed) width data in bit: \(Double(bytesReceived * 8))")
        let speed = elapsed != 0 ? Double(bytesReceived * 8) / (elapsed * 1048576)  : -1
        speedTestCompletionBlock?(speed, nil)
        
    }

    @IBAction func testSpeedTapped(_ sender: Any) {
        checkForSpeedTest()
    }
    
}

