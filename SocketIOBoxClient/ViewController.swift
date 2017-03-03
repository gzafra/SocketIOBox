//
//  ViewController.swift
//  SocketIOBoxClient
//
//  Created by Zafra, Guillermo on 24/02/2017.
//

import UIKit
import WebKit

class ViewController: UIViewController {
    var socketBox: SocketIOBox!
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        socketBox = SocketIOBox(delegate: self, url: URL(string: "https://freeport-socketio-test.herokuapp.com/")!, token: "YOUR_AUTH_TOKEN")
        
        socketBox.on("message") { data in
            let jsonString = NSString(data: data as! Data, encoding: String.Encoding.utf8.rawValue)! as String
            print(jsonString)
        }
        
        _ = socketBox.beginConnection()
    }
}

extension ViewController: SocketIOBoxProtocol {
    
    func onMessage(event: String, data: Data, socket: SocketIOBox) {
        print("Event: \(event) -- Message: \(data)")
    }
}

