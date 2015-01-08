//
//  INDLinkLabel.swift
//  INDLinkLabel
//
//  Created by Indragie on 12/31/14.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:

//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.

//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import UIKit

@objc public protocol INDLinkLabelDelegate {
    /// Called when a link is tapped.
    optional func linkLabel(label: INDLinkLabel, didTapLinkWithURL URL: NSURL)
    
    /// Called when a link is long pressed.
    optional func linkLabel(label: INDLinkLabel, didLongPressLinkWithURL URL: NSURL)
}

/// A simple UILabel subclass that is similar to UILabel but allows for
/// tapping on links (i.e. anything marked with `NSLinkAttributeName`)
@IBDesignable public class INDLinkLabel: UILabel {
    public weak var delegate: INDLinkLabelDelegate?
    
    // MARK: Styling
    
    override public var attributedText: NSAttributedString! {
        didSet { processLinks() }
    }
    
    override public var lineBreakMode: NSLineBreakMode {
        didSet { textContainer.lineBreakMode = lineBreakMode }
    }
    
    /// The color of the highlight that appears over a link when tapping on it
    @IBInspectable public var linkHighlightColor: UIColor = UIColor(white: 0, alpha: 0.2)
    
    /// The corner radius of the highlight that appears over a link when
    /// tapping on it
    @IBInspectable public var linkHighlightCornerRadius: CGFloat = 2
    
    // MARK: Text Layout
    
    override public var numberOfLines: Int {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
        }
    }
    
    // MARK: Private
    
    private var layoutManager: NSLayoutManager!
    private var textStorage: NSTextStorage!
    private var textContainer: NSTextContainer!
    
    private struct LinkRange {
        let URL: NSURL
        let glyphRange: NSRange
    }
    
    private var linkRanges: [LinkRange]?
    private var tappedLinkRange: LinkRange?
    
    // MARK: Initialization
    
    private func commonInit() {
        textContainer = NSTextContainer()
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        textContainer.lineFragmentPadding = 0
        
        layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        userInteractionEnabled = true
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: Selector("handleTap:")))
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: Selector("handleLongPress:")))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // MARK: Attributes

    private func processLinks() {
        var ranges = [LinkRange]()
        textStorage.setAttributedString(attributedText)
        textStorage.enumerateAttribute(NSLinkAttributeName, inRange: NSRange(location: 0, length: textStorage.length), options: nil) { (value, range, _) in
            // Because NSLinkAttributeName supports both NSURL and NSString
            // values. *sigh*
            let URL: NSURL? = {
                if let string = value as? String {
                    return NSURL(string: string)
                } else if let URL = value as? NSURL {
                    return URL
                }
                return nil
            }()
            
            if let URL = URL {
                let glyphRange = self.layoutManager.glyphRangeForCharacterRange(range, actualCharacterRange: nil)
                ranges.append(LinkRange(URL: URL, glyphRange: glyphRange))
                
                // Remove `NSLinkAttributeName` to prevent `UILabel` from applying
                // the default styling.
                let attributes = self.textStorage.attributesAtIndex(range.location, effectiveRange: nil)
                if attributes[NSForegroundColorAttributeName] == nil {
                    self.textStorage.addAttribute(NSForegroundColorAttributeName, value: UIColor.blueColor(), range: range)
                }
                if attributes[NSUnderlineStyleAttributeName] == nil {
                    self.textStorage.addAttribute(NSUnderlineStyleAttributeName, value: NSUnderlineStyle.StyleSingle.rawValue, range: range)
                }
                self.textStorage.removeAttribute(NSLinkAttributeName, range: range)
            }
        }
        linkRanges = ranges
        super.attributedText = textStorage
    }
    
    // MARK: Drawing
    
    public override func drawRect(rect: CGRect) {
        super.drawRect(rect)
        
        if let linkRange = tappedLinkRange {
            linkHighlightColor.setFill()
            for rect in highlightRectsForGlyphRange(linkRange.glyphRange) {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: linkHighlightCornerRadius)
                path.fill()
            }
        }
    }
    
    private func highlightRectsForGlyphRange(range: NSRange) -> [CGRect] {
        var rects = [CGRect]()
        layoutManager.enumerateLineFragmentsForGlyphRange(range) { (_, rect, _, effectiveRange, _) in
            let boundingRect = self.layoutManager.boundingRectForGlyphRange(NSIntersectionRange(range, effectiveRange), inTextContainer: self.textContainer)
            rects.append(boundingRect)
        }
        return rects
    }
    
    // MARK: Touches
    
    private func linkRangeAtPoint(point: CGPoint) -> LinkRange? {
        if let linkRanges = linkRanges {
            textContainer.size = CGSize(width: CGRectGetWidth(bounds), height: CGFloat.max)
            layoutManager.ensureLayoutForTextContainer(textContainer)
            
            let glyphIndex = layoutManager.glyphIndexForPoint(point, inTextContainer: textContainer)
            for linkRange in linkRanges {
                if NSLocationInRange(glyphIndex, linkRange.glyphRange) {
                    return linkRange
                }
            }
        }
        return nil
    }
    
    public override func touchesBegan(touches: NSSet, withEvent event: UIEvent) {
        tappedLinkRange = linkRangeAtPoint(touches.anyObject()!.locationInView(self))
        setNeedsDisplay()
    }
    
    public override func touchesEnded(touches: NSSet, withEvent event: UIEvent) {
        tappedLinkRange = nil
        setNeedsDisplay()
    }
    
    public override func touchesCancelled(touches: NSSet!, withEvent event: UIEvent!) {
        tappedLinkRange = nil
        setNeedsDisplay()
    }
    
    @objc private func handleTap(gestureRecognizer: UIGestureRecognizer) {
        if let linkRange = tappedLinkRange {
            delegate?.linkLabel?(self, didTapLinkWithURL: linkRange.URL)
        }
    }
    
    @objc private func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if let linkRange = tappedLinkRange {
            delegate?.linkLabel?(self, didLongPressLinkWithURL: linkRange.URL)
        }
    }
}
