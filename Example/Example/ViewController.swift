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
        let RTFPath = NSBundle.mainBundle().pathForResource("text", ofType: "rtf")!
        let RTFData = NSData(contentsOfFile: RTFPath)!
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
    
    func linkLabel(label: INDLinkLabel, didLongPressLinkWithURL URL: NSURL) {
        let activityController = UIActivityViewController(activityItems: [URL], applicationActivities: nil)
        self.presentViewController(activityController, animated: true, completion: nil)
    }
    
    func linkLabel(label: INDLinkLabel, didTapLinkWithURL URL: NSURL) {
        UIApplication.sharedApplication().openURL(URL)
    }
}
