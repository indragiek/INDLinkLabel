//
//  ViewController.swift
//  Example
//
//  Created by Indragie on 12/31/14.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet var label: INDLinkLabel!

    override func viewDidLoad() {
        super.viewDidLoad()
        let RTFPath = NSBundle.mainBundle().pathForResource("text", ofType: "rtf")!
        let RTFData = NSData(contentsOfFile: RTFPath)!
        let options = [NSDocumentTypeDocumentAttribute: NSRTFTextDocumentType]
        
        label.numberOfLines = 0
        label.attributedText = NSAttributedString(data: RTFData, options: options, documentAttributes: nil, error: nil)
        label.linkLongPressHandler = { URL in
            let activityController = UIActivityViewController(activityItems: [URL], applicationActivities: nil)
            self.presentViewController(activityController, animated: true, completion: nil)
        }
    }
}

