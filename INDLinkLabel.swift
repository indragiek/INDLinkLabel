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

/// A simple label class that is similar to UILabel but allows for 
/// tapping on links (i.e. anything marked with `NSLinkAttributeName`)
///
/// This is not a drop-in replacement for UILabel, as it does not 
/// implement functionality like font size adjustment, but most of the 
/// commonly used properties are implemented.
public class INDLinkLabel: UIView {
    // MARK: Text Attributes
    
    /// The text displayed by the label.
    ///
    /// Changing this property will also change the value of `attributedText`,
    /// which will contain an attributed version of `text` with attributes
    /// applied based on the style-related properties below.
    public var text: String? {
        get { return _text }
        set {
            _text = newValue
            if let text = _text {
                setAttributedStringForString(text)
            } else {
                clear()
            }
        }
    }
    private var _text: String?
    
    /// The styled text displayed by the label.
    ///
    /// Changing this property will also change the value of `text`, as well
    /// as the values of all of the style-related properties, which will be
    /// set based on the attributes present in this string at index 0.
    public var attributedText: NSAttributedString? {
        get { return _attributedText }
        set {
            _attributedText = newValue
            if let attributedText = attributedText {
                setAttributedString(attributedText)
            } else {
                clear()
            }
        }
    }
    private var _attributedText: NSAttributedString?
    
    private struct Defaults {
        static var font = UIFont.systemFontOfSize(17)
        static var textColor = UIColor.blackColor()
        static var textAlignment = NSTextAlignment.Left
        static var lineBreakMode = NSLineBreakMode.ByTruncatingTail
    }
    
    /// The font of the text.
    ///
    /// This value is applied to the entirety of the string.
    public var font: UIFont {
        get { return _font }
        set {
            _font = newValue
            applyAttributeWithKey(NSFontAttributeName, value: _font)
        }
    }
    private var _font = Defaults.font
    
    /// The color of the text.
    ///
    /// This value is applied to the entirety of the string.
    public var textColor: UIColor {
        get { return _textColor }
        set {
            _textColor = newValue
            applyAttributeWithKey(NSForegroundColorAttributeName, value: _textColor)
        }
    }
    private var _textColor = Defaults.textColor
    
    /// The alignment of the text.
    ///
    /// This value is applied to the entirety of the string.
    public var textAlignment: NSTextAlignment {
        get { return _textAlignment }
        set {
            _textAlignment = newValue
            applyAttributeWithKey(NSParagraphStyleAttributeName, value: _paragraphStyle)
        }
    }
    private var _textAlignment = Defaults.textAlignment
    
    /// The line break mode of the text.
    ///
    /// This value is applied to the entirety of the string.
    public var lineBreakMode: NSLineBreakMode {
        get { return _lineBreakMode }
        set {
            _lineBreakMode = newValue
            textContainer.lineBreakMode = _lineBreakMode
            applyAttributeWithKey(NSParagraphStyleAttributeName, value: _paragraphStyle)
        }
    }
    private var _lineBreakMode = Defaults.lineBreakMode
    
    private var _paragraphStyle: NSParagraphStyle {
        let style = NSMutableParagraphStyle()
        style.alignment = _textAlignment
        style.lineBreakMode = _lineBreakMode
        return style
    }
    
    /// The shadow color of the text.
    ///
    /// This value is applied to the entirety of the string.
    public var shadowColor: UIColor? {
        get { return _shadowColor }
        set {
            _shadowColor = newValue
            applyAttributeWithKey(NSShadowAttributeName, value: _shadow)
        }
    }
    private var _shadowColor: UIColor?
    
    
    /// The shadow offset of the text.
    ///
    /// This value is applied to the entirety of the string.
    public var shadowOffset: CGSize? {
        get { return _shadowOffset }
        set {
            _shadowOffset = newValue
            applyAttributeWithKey(NSShadowAttributeName, value: _shadow)
        }
    }
    private var _shadowOffset: CGSize?
    
    private var _shadow: NSShadow? {
        if let color = _shadowColor {
            let shadow = NSShadow()
            shadow.shadowColor = color
            if let offset = _shadowOffset {
                shadow.shadowOffset = offset
            }
            return shadow
        }
        return nil
    }
    
    /// The color of the highlight that appears over a link when tapping on it
    public var linkHighlightColor: UIColor = UIColor(white: 0, alpha: 0.2)
    
    /// The corner radius of the highlight that appears over a link when 
    /// tapping on it
    public var linkHighlightCornerRadius: CGFloat = 2
    
    // MARK: Text Layout

    public var numberOfLines: Int = 1 {
        didSet {
            textContainer.maximumNumberOfLines = numberOfLines
            invalidateDisplayAndLayout()
        }
    }
    
    // MARK: Tap Handling
    
    public typealias LinkHandler = NSURL -> Void
    
    /// Called when a link is tapped.
    ///
    /// If no handler is provided, the link will be opened using 
    /// `UIApplication.openURL()`
    public var linkTapHandler: LinkHandler?
    
    /// Called when a link is long pressed.
    ///
    /// If no handler is provided, nothing will happen on logn press.
    public var linkLongPressHandler: LinkHandler?
    
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
        
        contentMode = .Redraw
        
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
    
    // MARK: Applying Attributes
    
    private func clear() {
        textStorage.deleteCharactersInRange(NSRange(location: 0, length: textStorage.length))
        invalidateDisplayAndLayout()
        linkRanges = nil
    }
    
    private func setAttributedStringForString(string: String) {
        textStorage.mutableString.setString(string)
        cacheLinkRanges()
        
        applyAttributeWithKey(NSFontAttributeName, value: _font)
        applyAttributeWithKey(NSForegroundColorAttributeName, value: _textColor)
        applyAttributeWithKey(NSParagraphStyleAttributeName, value: _paragraphStyle)
        applyAttributeWithKey(NSShadowAttributeName, value: shadow)
        
        _attributedText = textStorage.copy() as? NSAttributedString
    }
    
    private func setAttributedString(attrString: NSAttributedString) {
        textStorage.setAttributedString(attrString)
        cacheLinkRanges()
        invalidateDisplayAndLayout()
        
        let attributes = attrString.attributesAtIndex(0, effectiveRange: nil)
        _font = (attributes[NSFontAttributeName] as? UIFont) ?? Defaults.font
        _textColor = (attributes[NSFontAttributeName] as? UIColor) ?? Defaults.textColor
        
        let paragraphStyle = attributes[NSParagraphStyleAttributeName] as? NSParagraphStyle
        _textAlignment = paragraphStyle?.alignment ?? Defaults.textAlignment
        _lineBreakMode = paragraphStyle?.lineBreakMode ?? Defaults.lineBreakMode
        
        let shadow = attributes[NSShadowAttributeName] as? NSShadow
        _shadowColor = shadow?.shadowColor as? UIColor
        _shadowOffset = shadow?.shadowOffset
    }
    
    private func applyAttributeWithKey(key: String, value: AnyObject?) {
        let range = NSRange(location: 0, length: textStorage.length)
        if let value: AnyObject = value {
            textStorage.addAttribute(key, value: value, range: range)
        } else {
            textStorage.removeAttribute(key, range: range)
        }
        invalidateDisplayAndLayout()
    }
    
    private func invalidateDisplayAndLayout() {
        setNeedsDisplay()
        invalidateIntrinsicContentSize()
    }
    
    private func cacheLinkRanges() {
        var ranges = [LinkRange]()
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
            }
        }
        linkRanges = ranges
    }
    
    // MARK: Drawing
    
    public override func drawRect(rect: CGRect) {
        textContainer.size = bounds.size
        
        let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
        layoutManager.drawBackgroundForGlyphRange(glyphRange, atPoint: bounds.origin)
        layoutManager.drawGlyphsForGlyphRange(glyphRange, atPoint: bounds.origin)
        
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
    
    // MARK: Layout
    
    private var contentSize: CGSize {
        let glyphRange = layoutManager.glyphRangeForTextContainer(textContainer)
        return layoutManager.boundingRectForGlyphRange(glyphRange, inTextContainer: textContainer).size
    }
    
    public override func intrinsicContentSize() -> CGSize {
        textContainer.size = bounds.size
        return contentSize
    }
    
    public override func sizeThatFits(size: CGSize) -> CGSize {
        textContainer.size = size
        return contentSize
    }
    
    // MARK: Touches
    
    private func linkRangeAtPoint(point: CGPoint) -> LinkRange? {
        if let linkRanges = linkRanges {
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
            if let handler = linkTapHandler {
                handler(linkRange.URL)
            } else {
                UIApplication.sharedApplication().openURL(linkRange.URL)
            }
        }
    }
    
    @objc private func handleLongPress(gestureRecognizer: UIGestureRecognizer) {
        if let linkRange = tappedLinkRange {
            if let handler = linkLongPressHandler {
                handler(linkRange.URL)
            }
        }
    }
}

