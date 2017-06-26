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
    @objc optional func linkLabel(_ label: INDLinkLabel, didTapLinkWithURL URL: URL)
    
    /// Called when a link is long pressed.
    @objc optional func linkLabel(_ label: INDLinkLabel, didLongPressLinkWithURL URL: URL)
    
    /// Called when parsing links from attributed text.
    /// The delegate may determine whether to use the text's original attributes,
    /// use the proposed INDLinkLabel attributes (blue text color, and underlined),
    /// or supply a completely custom set of attributes for the given link.
    @objc optional func linkLabel(_ label: INDLinkLabel, attributesForURL URL: URL, originalAttributes: [String: AnyObject], proposedAttributes: [String: AnyObject]) -> [String: AnyObject]
}

/// A simple UILabel subclass that allows for tapping and long pressing on links
/// (i.e. anything marked with `NSLinkAttributeName`)
@IBDesignable open class INDLinkLabel: UILabel {
    @IBOutlet open weak var delegate: INDLinkLabelDelegate?
    
    // MARK: Styling
    
    override open var attributedText: NSAttributedString? {
        didSet { processLinks() }
    }
    
    override open var lineBreakMode: NSLineBreakMode {
        didSet { textContainer.lineBreakMode = lineBreakMode }
    }
    
    /// The color of the highlight that appears over a link when tapping on it
    @IBInspectable open var linkHighlightColor: UIColor = UIColor(white: 0, alpha: 0.2)
    
    /// The corner radius of the highlight that appears over a link when
    /// tapping on it
    @IBInspectable open var linkHighlightCornerRadius: CGFloat = 2
    
    // MARK: Text Layout
    
    override open var numberOfLines: Int {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
        }
    }
    
    override open var adjustsFontSizeToFitWidth: Bool {
        didSet {
            if adjustsFontSizeToFitWidth {
                fatalError("INDLinkLabel does not support the adjustsFontSizeToFitWidth property")
            }
        }
    }
    
    // MARK: Private
    
    fileprivate var layoutManager = NSLayoutManager()
    fileprivate var textStorage = NSTextStorage()
    fileprivate var textContainer = NSTextContainer()
    
    fileprivate struct LinkRange {
        let URL: Foundation.URL
        let glyphRange: NSRange
    }
    
    fileprivate var linkRanges: [LinkRange]?
    fileprivate var tappedLinkRange: LinkRange? {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: Initialization
    
    fileprivate func commonInit() {
        precondition(!adjustsFontSizeToFitWidth, "INDLinkLabel does not support the adjustsFontSizeToFitWidth property")
        
        textContainer.maximumNumberOfLines = numberOfLines
        textContainer.lineBreakMode = lineBreakMode
        textContainer.lineFragmentPadding = 0
        
        layoutManager = NSLayoutManager()
        layoutManager.addTextContainer(textContainer)
        
        textStorage = NSTextStorage()
        textStorage.addLayoutManager(layoutManager)
        
        isUserInteractionEnabled = true
        
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(INDLinkLabel.handleTap(_:))))
        addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(INDLinkLabel.handleLongPress(_:))))
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    // MARK: Attributes
    
    fileprivate struct DefaultLinkAttributes {
        static let Color = UIColor.blue
        static let UnderlineStyle = NSUnderlineStyle.styleSingle
    }
    
    fileprivate func processLinks() {
        var ranges = [LinkRange]()
        if let attributedText = attributedText {
            textStorage.setAttributedString(attributedText)
            textStorage.enumerateAttribute(NSLinkAttributeName, in: NSRange(location: 0, length: textStorage.length), options: []) { (value, range, _) in
                // Because NSLinkAttributeName supports both NSURL and NSString
                // values. *sigh*
                let URL: Foundation.URL? = {
                    if let string = value as? String {
                        return Foundation.URL(string: string)
                    } else {
                        return value as? Foundation.URL
                    }
                }()
                
                if let URL = URL {
                    let glyphRange = self.layoutManager.glyphRange(forCharacterRange: range, actualCharacterRange: nil)
                    ranges.append(LinkRange(URL: URL, glyphRange: glyphRange))
                    
                    // Remove `NSLinkAttributeName` to prevent `UILabel` from applying
                    // the default styling.
                    self.textStorage.removeAttribute(NSLinkAttributeName, range: range)
                    
                    let originalAttributes = self.textStorage.attributes(at: range.location, effectiveRange: nil)
                    var proposedAttributes = originalAttributes
                    
                    if originalAttributes[NSForegroundColorAttributeName] == nil {
                        proposedAttributes[NSForegroundColorAttributeName] = DefaultLinkAttributes.Color
                    }
                    if originalAttributes[NSUnderlineStyleAttributeName] == nil {
                        proposedAttributes[NSUnderlineStyleAttributeName] = DefaultLinkAttributes.UnderlineStyle.rawValue
                    }
                    
                    let acceptedAttributes = self.delegate?.linkLabel?(self, attributesForURL: URL, originalAttributes: originalAttributes as [String : AnyObject], proposedAttributes: proposedAttributes as [String : AnyObject])
                        ?? proposedAttributes;
                    self.textStorage.setAttributes(acceptedAttributes, range: range)
                }
            }
        }
        linkRanges = ranges
        super.attributedText = textStorage
    }
    
    // MARK: Drawing
    
    open override func draw(_ rect: CGRect) {
        super.draw(rect)
        
        if let linkRange = tappedLinkRange {
            linkHighlightColor.setFill()
            for rect in highlightRectsForGlyphRange(linkRange.glyphRange) {
                let path = UIBezierPath(roundedRect: rect, cornerRadius: linkHighlightCornerRadius)
                path.fill()
            }
        }
    }
    
    fileprivate func highlightRectsForGlyphRange(_ range: NSRange) -> [CGRect] {
        var rects = [CGRect]()
        layoutManager.enumerateLineFragments(forGlyphRange: range) { (_, rect, _, effectiveRange, _) in
            let boundingRect = self.layoutManager.boundingRect(forGlyphRange: NSIntersectionRange(range, effectiveRange), in: self.textContainer)
            rects.append(boundingRect)
        }
        return rects
    }
    
    // MARK: Touches
    
    fileprivate func linkRangeAtPoint(_ point: CGPoint) -> LinkRange? {
        if let linkRanges = linkRanges {
            // Passing in the UILabel's fitting size here doesn't work, the height
            // needs to be unrestricted for it to correctly lay out all the text.
            // Might be due to a difference in the computed text sizes of `UILabel`
            // and `NSLayoutManager`.
            textContainer.size = CGSize(width: bounds.width, height: CGFloat.greatestFiniteMagnitude)
            layoutManager.ensureLayout(for: textContainer)
            let boundingRect = layoutManager.boundingRect(forGlyphRange: layoutManager.glyphRange(for: textContainer), in: textContainer)
            
            if boundingRect.contains(point) {
                let glyphIndex = layoutManager.glyphIndex(for: point, in: textContainer)
                for linkRange in linkRanges {
                    if NSLocationInRange(glyphIndex, linkRange.glyphRange) {
                        return linkRange
                    }
                }
            }
        }
        return nil
    }
    
    open override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Any taps that don't hit a link are ignored and passed to the next
        // responder.
        return linkRangeAtPoint(point) != nil
    }
    
    @objc fileprivate func handleTap(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .ended:
            tappedLinkRange = linkRangeAtPoint(gestureRecognizer.location(ofTouch: 0, in: self))
        default:
            tappedLinkRange = nil
        }
        
        if let linkRange = tappedLinkRange {
            delegate?.linkLabel?(self, didTapLinkWithURL: linkRange.URL)
            tappedLinkRange = nil
        }
    }
    
    @objc fileprivate func handleLongPress(_ gestureRecognizer: UIGestureRecognizer) {
        switch gestureRecognizer.state {
        case .began:
            tappedLinkRange = linkRangeAtPoint(gestureRecognizer.location(ofTouch: 0, in: self))
        default:
            tappedLinkRange = nil
        }
        
        if let linkRange = tappedLinkRange {
            delegate?.linkLabel?(self, didLongPressLinkWithURL: linkRange.URL)
        }
    }
}
