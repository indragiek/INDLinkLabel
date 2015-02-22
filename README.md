## INDLinkLabel
### A simple, no frills `UILabel` subclass with support for links

All I wanted was a `UILabel` that had support for handling taps on links. I didn't want loads of additional styling properties or built in support for parsing links and hashtags. I just wanted to be able to give it an `NSAttributedString` that had links already marked using `NSLinkAttributeName` and have it handle taps on those links like the way `UITextView` does. I couldn't find an existing project that met that criteria so I built this.

Run the example app to see it in action:

![Example app](screenshot.png)

### Handling Link Actions

`INDLinkLabel` provides two delegate methods that are called when a link is tapped or long pressed:

```swift
optional func linkLabel(label: INDLinkLabel, didTapLinkWithURL URL: NSURL)
optional func linkLabel(label: INDLinkLabel, didLongPressLinkWithURL URL: NSURL)
```
### Limitations

`UILabel`'s `adjustsFontSizeToFitWidth` property (and its associated properties) are not supported.

### Swift 1.2

Support for compiling under Swift 1.2 (Xcode 6.3) is in the `swift-1.2` branch.

### Contact

* Indragie Karunaratne
* [@indragie](http://twitter.com/indragie)
* [http://indragie.com](http://indragie.com)

### License

`INDLinkLabel` is licensed under the MIT License. See `LICENSE` for more information.
