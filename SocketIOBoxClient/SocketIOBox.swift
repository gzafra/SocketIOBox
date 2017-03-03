//
//  SocketIOBox.swift
//  SocketIOBoxClient
//
//  Created by Zafra, Guillermo on 24/02/2017.
//

import UIKit
import WebKit

protocol SocketIOBoxProtocol: class {
    func onMessage(event: String, data: Data, socket: SocketIOBox)
}

enum SocketStatus {
    case disconnected
    case connected
}

typealias SocketEventCallback = (Any) -> ()

class SocketIOBox: NSObject {
    // MARK: - Properties
    var delegate: SocketIOBoxProtocol?
    var socketStatus: SocketStatus = .disconnected
    fileprivate var theWebView: WKWebView!
    fileprivate var token: String!
    fileprivate var contentLoaded = false
    fileprivate var eventHandlers = [String: SocketEventCallback]()
    fileprivate var url: URL!
    
    // MARK: - Lifecycle
    convenience init(delegate: SocketIOBoxProtocol, url: URL, token: String) {
        self.init()
        self.delegate = delegate
        self.url = url
        self.token = token
    }
    
    // MARK: - Public methods
    func on(_ eventName: String, handler: @escaping SocketEventCallback) {
        eventHandlers[eventName] = handler
        
        // Only send to WebKit if content is already loaded. Otherwise it will be added on load
        if contentLoaded {
            setupEvent(eventName)
        }
    }
    
    func beginConnection() -> Bool {
        guard let window = UIApplication.shared.windows.first else {
            print("No visible window")
            return false
        }
        
        guard let htmlFilePath = Bundle.main.path(forResource: "JavascriptClient", ofType: "html"), let contents =  try? NSString(contentsOfFile: htmlFilePath, encoding: String.Encoding.utf8.rawValue) else {
            print("Could load content of HTML")
            return false
        }

        let theConfiguration = WKWebViewConfiguration()
        theConfiguration.userContentController.add(self, name: "interOp")
        
        theWebView = WKWebView(frame: CGRect(x: 0, y: 40, width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height), configuration: theConfiguration)
        theWebView.navigationDelegate = self
        theWebView.loadHTMLString(contents as String, baseURL: URL(fileURLWithPath: htmlFilePath))

        window.addSubview(theWebView)
        
        return true
    }
    
    func endConnection() {
        theWebView.evaluateJavaScript("socket.disconnect();") { (any, error) in
            print("addEvent - Any: \(any), Error: \(error)")
        }
        
        theWebView.removeFromSuperview()
        theWebView = nil
    }
    
    // MARK: - Private methods
    fileprivate func setupSocket() {
        theWebView.evaluateJavaScript("setupSocket('\(url.absoluteString)', '\(token!)')") { (any, error) in
            print("setupSocket - Any: \(any), Error: \(error)")
        }
    }
    
    fileprivate func setupEvent(_ eventName: String) {
        theWebView.evaluateJavaScript("addEvent('\(eventName)')") { (any, error) in
            print("addEvent - Any: \(any), Error: \(error)")
        }
    }
    
    fileprivate func startSocket() {
        theWebView.evaluateJavaScript("startSocket()") { (any, error) in
            print("startSocket - Any: \(any), Error: \(error)")
        }
    }
}

extension SocketIOBox: WKScriptMessageHandler {
    
    internal func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        let sentData = message.body as! NSDictionary
        
        guard let event = sentData.object(forKey: "event") as? String,
            let data = sentData.object(forKey: "data"),
            let jsonData = try? JSONSerialization.data(withJSONObject: data, options: []) else {
                print("Error decoding message: \(sentData)")
                return
        }
        
        socketStatus = event == "connected" ? .connected : .disconnected

        self.delegate?.onMessage(event: event  , data: jsonData, socket: self)
        
        if let callback = eventHandlers[event] {
            callback(jsonData)
        }
    }
}

extension SocketIOBox: WKNavigationDelegate {
    
    internal func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        contentLoaded = true
        setupSocket()
        
        eventHandlers.forEach { eventName, _ in
            setupEvent(eventName)
        }
        
        startSocket()
    }
}
