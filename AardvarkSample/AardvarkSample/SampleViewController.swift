//
//  SampleViewController.swift
//  AardvarkSample
//
//  Created by Dan Federman on 9/21/16.
//  Copyright © 2016 Square, Inc. All rights reserved.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

import Aardvark
import CoreAardvark
import UIKit


class SampleViewController : UIViewController {
    
    let tapLogKey: NSString = "SampleViewcontrollerTapLog"
    
    private var tapRecognizer: UITapGestureRecognizer?
    private var tapGestureLogStore: ARKLogStore?
    
    // MARK: – Initialization
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        
        tapRecognizer = UITapGestureRecognizer(target: self, action: #selector(tapDetected(tapRecognizer:)))
    }
    
    // MARK: – UIViewController
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        guard let tapGestureLogStore = ARKLogStore(persistedLogFileName: "SampleTapLogs.data") else {
            return
        }
        
        tapGestureLogStore.name = "Taps"
        
        // Ensure that the tap log store will only store tap logs.
        tapGestureLogStore.logFilterBlock = { [weak self] logMessage in
            guard let `self` = self else {
                return false
            }
            
            guard let isTapLog = logMessage.userInfo[self.tapLogKey] as? Bool else {
                return false
            }
            
            return isTapLog
        }
        
        // Do not log tap logs to the main tap log store.
        ARKLogDistributor.default().defaultLogStore.logFilterBlock = { [weak self] logMessage in
            guard let `self` = self else {
                return true
            }
            
            guard let isTapLog = logMessage.userInfo[self.tapLogKey] as? Bool else {
                return true
            }
            
            return !isTapLog
        }
        
        ARKLogDistributor.default().add(tapGestureLogStore)
        
        // Store the log store.
        self.tapGestureLogStore = tapGestureLogStore
        
        guard let bugReporter = (UIApplication.shared.delegate as? SampleAppDelegate)?.bugReporter else {
            return
        }
        
        // Add our log store to the bug reporter.
        bugReporter.add([tapGestureLogStore])
    }
    
    override func viewDidAppear(_ animated: Bool) {
        log("\(#function)")
        
        guard let tapRecognizer = tapRecognizer else {
            return
        }
        
        view.addGestureRecognizer(tapRecognizer)
        
        super.viewDidAppear(animated)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        log("\(#function)")
        
        guard let tapRecognizer = tapRecognizer else {
            return
        }
        
        tapRecognizer.view?.removeGestureRecognizer(tapRecognizer)
        
        super.viewDidAppear(animated)
    }
    
    // MARK: – Actions
    
    @IBAction func viewARKLogMessages(_ sender: AnyObject) {
        log("\(#function)")
        let defaultLogsViewController = ARKLogTableViewController()
        navigationController?.pushViewController(defaultLogsViewController, animated: true)
    }
    
    @IBAction func viewTapLogs(_ sender: AnyObject) {
        log("\(#function)")
        
        guard let tapGestureLogStore = tapGestureLogStore else {
            return
        }
        
        guard let tapLogsViewController = ARKLogTableViewController(logStore: tapGestureLogStore, logFormatter: ARKDefaultLogFormatter()) else {
            return
        }
        
        navigationController?.pushViewController(tapLogsViewController, animated: true)
    }
    
    @IBAction func blueButtonPressed(_ sender: AnyObject) {
        log("Blue")
    }
    
    @IBAction func redButtonPressed(_ sender: AnyObject) {
        log("Red")
    }
    
    @IBAction func greenButtonPressed(_ sender: AnyObject) {
        log("Green")
    }
    
    @IBAction func yellowButtonPressed(_ sender: AnyObject) {
        log("Yellow")
    }
    
    // MARK: – Private Methods
    
    @objc
    private func tapDetected(tapRecognizer: UITapGestureRecognizer) {
        guard tapRecognizer == self.tapRecognizer && tapRecognizer.state == .ended else {
            return
        }
        
        log("Tapped \(NSStringFromCGPoint(tapRecognizer.location(in: nil)))", userInfo: [tapLogKey : true as NSNumber])
    }
}
