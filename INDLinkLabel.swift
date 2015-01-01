//
//  INDLinkLabel.swift
//  Example
//
//  Created by Indragie on 12/31/14.
//  Copyright (c) 2014 Indragie Karunaratne. All rights reserved.
//

import UIKit

public class INDLinkLabel: UIView {
    // MARK: Text Attributes
    
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
    
    public var font: UIFont {
        get { return _font }
        set {
            _font = newValue
            applyAttributeWithKey(NSFontAttributeName, value: _font)
        }
    }
    private var _font = Defaults.font
    
    public var textColor: UIColor {
        get { return _textColor }
        set {
            _textColor = newValue
            applyAttributeWithKey(NSForegroundColorAttributeName, value: _textColor)
        }
    }
    private var _textColor = Defaults.textColor
    
    public var textAlignment: NSTextAlignment {
        get { return _textAlignment }
        set {
            _textAlignment = newValue
            applyAttributeWithKey(NSParagraphStyleAttributeName, value: _paragraphStyle)
        }
    }
    private var _textAlignment = Defaults.textAlignment
    
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
    
    public var shadowColor: UIColor? {
        get { return _shadowColor }
        set {
            _shadowColor = newValue
            applyAttributeWithKey(NSShadowAttributeName, value: _shadow)
        }
    }
    private var _shadowColor: UIColor?
    
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
    
    public var linkHighlightColor: UIColor = UIColor(white: 0, alpha: 0.2)
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
    public var linkTapHandler: LinkHandler?
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
    
    // MARK: Tap Handling
    
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

