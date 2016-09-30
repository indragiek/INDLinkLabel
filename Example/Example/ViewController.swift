//
//  ViewController.swift
//  Example
//
//  Created by Indragie on 12/31/14.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

import UIKit

class ViewController: UIViewController, INDLinkLabelDelegate {
    
    @IBOutlet var label: INDLinkLabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let RTFPath = Bundle.main.path(forResource: "text", ofType: "rtf")!
        let RTFData = try! Data(contentsOf: URL(fileURLWithPath: RTFPath))
        let options = [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType]
        
        label.numberOfLines = 0
        do {
            label.attributedText = try NSAttributedString(data: RTFData, options: options, documentAttributes: nil)
        } catch _ {
            label.attributedText = nil
        }
        label.delegate = self
    }
    
    // MARK: INDLinkLabelDelegate
    
    func linkLabel(_ label: INDLinkLabel, didLongPressLinkWithURL URL: Foundation.URL) {
        let activityController = UIActivityViewController(activityItems: [URL], applicationActivities: nil)
        self.present(activityController, animated: true, completion: nil)
    }
    
    func linkLabel(_ label: INDLinkLabel, didTapLinkWithURL URL: Foundation.URL) {
        UIApplication.shared.openURL(URL)
    }
}
