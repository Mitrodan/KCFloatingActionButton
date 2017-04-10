//
//  KCFloatingActionButton.swift
//
//  Created by LeeSunhyoup on 2015. 10. 4..
//  Copyright © 2015년 kciter. All rights reserved.
//

import UIKit

public enum KCFABOpenAnimationType {
    case pop
    case fade
    case slideLeft
    case slideUp
    case slideDown
    case none
}

/**
    Floating Action Button Object. It has `KCFloatingActionButtonItem` objects.
    KCFloatingActionButton support storyboard designable.
*/
@IBDesignable
open class KCFloatingActionButton: UIView {
    // MARK: - Properties

    /**
        `KCFloatingActionButtonItem` objects.
    */
    open var items: [KCFloatingActionButtonItem] = []

    /**
        This object's button size.
    */
    open var size: CGFloat = 56 {
        didSet {
            setButtonFrame()
            recalculateItemsOrigin()
        }
    }

    /**
        Padding from bottom right of UIScreen or superview.
    */
    open var paddingX: CGFloat = 14 {
        didSet {
            setButtonFrame()
        }
    }
    open var paddingY: CGFloat = 14 {
        didSet {
            setButtonFrame()
        }
    }

	/**
		Automatically closes child items when tapped
	*/
	@IBInspectable open var autoCloseOnTap: Bool = true

	/**
		Degrees to rotate image
	*/
	@IBInspectable open var rotationDegrees: CGFloat = -45

    /**
     Animation speed of buttons
     */
    @IBInspectable open var animationSpeed: Double = 0.1
    /**
        Button color.
    */
    @IBInspectable open var buttonColor: UIColor = UIColor(red: 73/255.0, green: 151/255.0, blue: 241/255.0, alpha: 1)

    /**
        Button image.
    */
    @IBInspectable open var buttonImage: UIImage? = nil {
        didSet {
            tintButton.setImage(buttonImage, for: .normal)
        }
    }

    /**
        Plus icon color inside button.
    */
    @IBInspectable open var plusColor: UIColor = UIColor(white: 0.2, alpha: 1)

    /**
        Background overlaying color.
    */
    @IBInspectable open var overlayColor: UIColor = UIColor.black.withAlphaComponent(0.3)

    /**
        The space between the item and item.
    */
    @IBInspectable open var itemSpace: CGFloat = 14

    /**
        Child item's default size.
    */
    @IBInspectable open var itemSize: CGFloat = 42 {
        didSet {
            self.items.forEach { item in
                item.size = self.itemSize
            }
            self.recalculateItemsOrigin()
            //self.setNeedsDisplay()
        }
    }

    /**
        Child item's default button color.
    */
    @IBInspectable open var itemButtonColor: UIColor = UIColor.white

    /**
     Child item's default title label color.
     */
    @IBInspectable open var itemTitleColor: UIColor = UIColor.white

	/**
		Child item's image color
	*/
	@IBInspectable open var itemImageColor: UIColor? = nil

    /**
        Child item's default shadow color.
    */
    @IBInspectable open var itemShadowColor: UIColor? = UIColor.black

    let buttonView: UIView = UIView()

    /**

    */
    open var closed: Bool = true

    open var openAnimationType: KCFABOpenAnimationType = .pop

    open var friendlyTap: Bool = true
    
    open var sticky: Bool = false
    
    /**
     Delegate that can be used to learn more about the behavior of the FAB widget.
    */
    @IBOutlet open weak var fabDelegate: KCFloatingActionButtonDelegate?

    /**
        Button shape layer.
    */
    //fileprivate var circleLayer: CAShapeLayer = CAShapeLayer()

    fileprivate var tintButton: UIButton = UIButton(type: .custom)

    /**
        Plus icon shape layer.
    */
    fileprivate var plusLayer: CAShapeLayer = CAShapeLayer()

    /**
        If you keeping touch inside button, button overlaid with tint layer.
    */
    fileprivate var tintLayer: CALayer = CALayer()



    /**
        If you show items, background overlaid with overlayColor.
    */

    fileprivate var overlayView: UIControl = UIControl()

    /**
        Keep track of whether overlay open animation completes, to avoid animation conflicts.
     */
    fileprivate var overlayViewDidCompleteOpenAnimation: Bool = true

    /**
        If you created this object from storyboard or `initWithFrame`, this property set true.
    */
    fileprivate var isCustomFrame: Bool = false

    // MARK: - Initialize

    /**
        Initialize with default property.
    */
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        backgroundColor = UIColor.clear
        setObserver()
        setupButton()
    }

    /**
        Initialize with custom size.
    */
    public init(size: CGFloat) {
        self.size = size
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        backgroundColor = UIColor.clear
        setObserver()
        setupButton()
    }

    /**
        Initialize with custom frame.
    */
    public override init(frame: CGRect) {
        super.init(frame: frame)
        size = min(frame.size.width, frame.size.height)
        backgroundColor = UIColor.clear
        isCustomFrame = true
        setObserver()
        setupButton()
    }

    /**
        Initialize from storyboard.
    */
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        size = min(frame.size.width, frame.size.height)
        backgroundColor = UIColor.clear
        clipsToBounds = false
        isCustomFrame = true
        setObserver()
        setupButton()
    }

    // MARK: - Method


    /**
        Items open.
    */
    open func open() {
        if(items.count > 0){

            setOverlayView()
            self.superview?.insertSubview(overlayView, belowSubview: self)
            overlayView.addTarget(self, action: #selector(close), for: .touchUpInside)

            overlayViewDidCompleteOpenAnimation = false
            UIView.animate(withDuration: 0.3, delay: 0,
                usingSpringWithDamping: 0.55,
                initialSpringVelocity: 0.3,
                options: UIViewAnimationOptions(), animations: { () -> Void in
                    self.plusLayer.transform = CATransform3DMakeRotation(self.degreesToRadians(self.rotationDegrees), 0.0, 0.0, 1.0)
                    self.overlayView.alpha = 1
                }, completion: {(f) -> Void in
                    self.overlayViewDidCompleteOpenAnimation = true
            })


            switch openAnimationType {
            case .pop:
                popAnimationWithOpen()
            case .fade:
                fadeAnimationWithOpen()
            case .slideLeft:
                slideLeftAnimationWithOpen()
            case .slideUp:
                slideUpAnimationWithOpen()
            case .slideDown:
                slideDownAnimationWithOpen()
            case .none:
                noneAnimationWithOpen()
            }
        }

        fabDelegate?.KCFABOpened?(self)
        closed = false
    }

    /**
        Items close.
    */
    open func close() {
        if(items.count > 0){
            overlayView.removeTarget(self, action: #selector(close), for: UIControlEvents.touchUpInside)

            let colorView = UIView()
            colorView.backgroundColor = overlayView.backgroundColor
            colorView.frame = overlayView.bounds
            overlayView.addSubview(colorView)
            overlayView.sendSubview(toBack: colorView)
            overlayView.backgroundColor = .clear

            UIView.animate(withDuration: animationSpeed * TimeInterval(items.count + 1), delay: 0,
                usingSpringWithDamping: 0.6,
                initialSpringVelocity: 0.8,
                options: [], animations: { () -> Void in
                    self.plusLayer.transform = CATransform3DMakeRotation(self.degreesToRadians(0), 0.0, 0.0, 1.0)
                    colorView.alpha = 0
                }, completion: {(_) -> Void in
                    if self.overlayViewDidCompleteOpenAnimation {
                        self.overlayView.removeFromSuperview()
                    }
                    self.overlayView.layer.shouldRasterize = false
                    colorView.removeFromSuperview()

            })

            switch openAnimationType {
            case .pop:
                popAnimationWithClose()
            case .fade:
                fadeAnimationWithClose()
            case .slideLeft:
                slideLeftAnimationWithClose()
            case .slideUp:
                slideUpAnimationWithClose()
            case .slideDown:
                slideDownAnimationWithClose()
            case .none:
                noneAnimationWithClose()
            }
        }

        fabDelegate?.KCFABClosed?(self)
        closed = true
    }

    /**
        Items open or close.
    */
    open func toggle() {
        guard items.count > 0 else {
            fabDelegate?.emptyKCFABSelected?(self)
            return
        }
        closed ? open() : close()
    }

    /**
        Add custom item
    */
    open func addItem(item: KCFloatingActionButtonItem) {
        let big = size > item.size ? size : item.size
        let small = size <= item.size ? size : item.size
        item.frame.origin = CGPoint(x: big/2-small/2, y: big/2-small/2)
        item.alpha = 0
		item.actionButton = self
        items.append(item)
    }

    /**
        Add item with title.
    */
    @discardableResult
    open func addItem(title: String) -> KCFloatingActionButtonItem {
        let item = KCFloatingActionButtonItem()
        itemDefaultSet(item)
        item.title = title
        addItem(item: item)
        return item
    }

    /**
        Add item with title and icon.
    */
    @discardableResult
    open func addItem(_ title: String, icon: UIImage?) -> KCFloatingActionButtonItem {
        let item = KCFloatingActionButtonItem()
        itemDefaultSet(item)
        item.title = title
        item.icon = icon
        addItem(item: item)
        return item
    }

    /**
     Add item with title and handler.
     */
    @discardableResult
    open func addItem(title: String, handler: @escaping ((KCFloatingActionButtonItem) -> Void)) -> KCFloatingActionButtonItem {
        let item = KCFloatingActionButtonItem()
        itemDefaultSet(item)
        item.title = title
        item.handler = handler
        addItem(item: item)
        return item
    }

    /**
        Add item with title, icon or handler.
    */
    @discardableResult
    open func addItem(_ title: String, icon: UIImage?, handler: @escaping ((KCFloatingActionButtonItem) -> Void)) -> KCFloatingActionButtonItem {
        let item = KCFloatingActionButtonItem()
        itemDefaultSet(item)
        item.title = title
        item.icon = icon
        item.handler = handler
        addItem(item: item)
        return item
    }

    /**
        Add item with icon.
    */
    @discardableResult
    open func addItem(icon: UIImage?) -> KCFloatingActionButtonItem {
        let item = KCFloatingActionButtonItem()
        itemDefaultSet(item)
        item.icon = icon
        addItem(item: item)
        return item
    }

    /**
        Add item with icon and handler.
    */
    @discardableResult
    open func addItem(icon: UIImage?, handler: @escaping ((KCFloatingActionButtonItem) -> Void)) -> KCFloatingActionButtonItem {
        let item = KCFloatingActionButtonItem()
        itemDefaultSet(item)
        item.icon = icon
        item.handler = handler
        addItem(item: item)
        return item
    }

    /**
        Remove item.
    */
    open func removeItem(item: KCFloatingActionButtonItem) {
        guard let index = items.index(of: item) else { return }
        items[index].removeFromSuperview()
        items.remove(at: index)
    }

    /**
        Remove item with index.
    */
    open func removeItem(index: Int) {
        items[index].removeFromSuperview()
        items.remove(at: index)
    }

    fileprivate func setupButton() {

        addSubview(tintButton)

        tintButton.backgroundColor = buttonColor

        tintButton.setImage(buttonImage, for: .normal)

        tintButton.layer.masksToBounds = true
        tintButton.layer.addSublayer(tintLayer)

        setPlusLayer()
        tintButton.layer.addSublayer(plusLayer)

        tintButton.addTarget(self, action: #selector(toggle), for: .touchUpInside)

        tintButton.clipsToBounds = true

        tintButton.addTarget(self, action: #selector(highlightButtonBackground(_:)), for: [.touchDown])
        tintButton.addTarget(self, action: #selector(dehighlightButtonBackground(_:)), for: [.touchDragExit, .touchUpInside, .touchUpOutside, .touchCancel])

        setButtonFrame()

        tintButton.layer.shadowOffset = CGSize(width: 1, height: 1)
        tintButton.layer.shadowRadius = 2
        tintButton.layer.shadowColor = UIColor.black.cgColor
        tintButton.layer.shadowOpacity = 0.4



    }

     func highlightButtonBackground(_ button: UIButton) {
        tintLayer.backgroundColor =  UIColor.white.withAlphaComponent(0.2).cgColor
    }

    func dehighlightButtonBackground(_ button: UIButton) {
        tintLayer.backgroundColor = UIColor.clear.cgColor
    }

    fileprivate func setButtonFrame() {

        tintButton.frame.origin = .zero
        tintButton.frame.size = CGSize.init(width: size, height: size)

        tintButton.layer.cornerRadius = size / 2

        tintLayer.frame = tintButton.bounds
        plusLayer.frame = tintButton.bounds
    }

    fileprivate func setPlusLayer() {
        plusLayer.lineCap = kCALineCapRound
        plusLayer.strokeColor = plusColor.cgColor
        plusLayer.lineWidth = 2.0
        plusLayer.path = plusBezierPath().cgPath
    }

    fileprivate func setOverlayView() {
		setOverlayFrame()
        overlayView.backgroundColor = overlayColor
        overlayView.alpha = 0
        overlayView.isUserInteractionEnabled = true

    }
	fileprivate func setOverlayFrame() {
		overlayView.frame = CGRect(
			x: 0,y: 0,
			width: UIScreen.main.bounds.width,
			height: UIScreen.main.bounds.height
		)
	}

    fileprivate func plusBezierPath() -> UIBezierPath {
        let path = UIBezierPath()
        path.move(to: CGPoint(x: size/2, y: size/3))
        path.addLine(to: CGPoint(x: size/2, y: size-size/3))
        path.move(to: CGPoint(x: size/3, y: size/2))
        path.addLine(to: CGPoint(x: size-size/3, y: size/2))
        return path
    }

    fileprivate func itemDefaultSet(_ item: KCFloatingActionButtonItem) {
        item.buttonColor = itemButtonColor

		/// Use separate color (if specified) for item button image, or default to the plusColor
		item.iconImageView.tintColor = itemImageColor ?? plusColor

        item.titleColor = itemTitleColor
        item.circleShadowColor = itemShadowColor
        item.titleShadowColor = itemShadowColor
        item.size = itemSize
    }

    fileprivate func setRightBottomFrame(_ keyboardSize: CGFloat = 0) {
        if superview == nil {
            frame = CGRect(
                x: (UIScreen.main.bounds.size.width - size) - paddingX,
                y: (UIScreen.main.bounds.size.height - size - keyboardSize) - paddingY,
                width: size,
                height: size
            )
        } else {
            frame = CGRect(
                x: (superview!.bounds.size.width-size) - paddingX,
                y: (superview!.bounds.size.height-size-keyboardSize) - paddingY,
                width: size,
                height: size
            )
        }

        if friendlyTap == true {
            frame.size.width += paddingX
            frame.size.height += paddingY
        }
    }

    fileprivate func recalculateItemsOrigin() {
        for item in items {
            let big = size > item.size ? size : item.size
            let small = size <= item.size ? size : item.size
            item.frame.origin = CGPoint(x: big/2-small/2, y: big/2-small/2)
        }
    }

    fileprivate func setObserver() {
        NotificationCenter.default.addObserver(self, selector: #selector(deviceOrientationDidChange(_:)), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

    deinit {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIKeyboardWillShow, object: nil)
        NotificationCenter.default.removeObserver(self, name:NSNotification.Name.UIKeyboardWillHide, object: nil)
    }

//    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesBegan(touches, with: event)
//        if isTouched(touches) {
//            //setTintLayer()
//        }
//    }
//
//    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
//        super.touchesEnded(touches, with: event)
//        //tintLayer.removeFromSuperlayer()
//        if isTouched(touches) {
//            toggle()
//        }
//    }
//
//    fileprivate func isTouched(_ touches: Set<UITouch>) -> Bool {
//        return touches.count == 1 && touches.first?.tapCount == 1 && touches.first?.location(in: self) != nil
//    }

    open override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if (object as? UIView) == superview && keyPath == "frame" {
            if isCustomFrame == false {
                setRightBottomFrame()
                setOverlayView()
            } else {
                size = min(frame.size.width, frame.size.height)
            }
        } else if (object as? UIScrollView) == superview && keyPath == "contentOffset" {
            let scrollView = object as! UIScrollView
            frame.origin.x = ((self.superview!.bounds.size.width - size) - paddingX) + scrollView.contentOffset.x
            frame.origin.y = ((self.superview!.bounds.size.height - size) - paddingY) + scrollView.contentOffset.y
        }
    }

    open override func willMove(toSuperview newSuperview: UIView?) {
        superview?.removeObserver(self, forKeyPath: "frame")
        if sticky == true {
            if let superviews = self.getAllSuperviews() {
                for superview in superviews {
                    if superview is UIScrollView {
                        superview.removeObserver(self, forKeyPath: "contentOffset", context:nil)
                    }
                }
            }
        }
        super.willMove(toSuperview: newSuperview)
    }

    var superViewConstraints: [NSLayoutConstraint] = []

    open override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard let superview = superview else { return }
        superview.addObserver(self, forKeyPath: "frame", options: [], context: nil)
        if sticky == true {
            if let superviews = self.getAllSuperviews() {
                for superview in superviews {
                    if superview is UIScrollView {
                        superview.addObserver(self, forKeyPath: "contentOffset", options: .new, context:nil)
                    }
                }
            }
        }
        self.frame = superview.bounds
        setRightBottomFrame()
        setButtonFrame()
    }

    internal func deviceOrientationDidChange(_ notification: Notification) {
        guard let keyboardSize: CGFloat = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height else {
            return
        }

		/// Update overlay frame for new orientation dimensions
		setOverlayFrame()

        if isCustomFrame == false {
            setRightBottomFrame(keyboardSize)
        } else {
            size = min(frame.size.width, frame.size.height)
        }
    }

    internal func keyboardWillShow(_ notification: Notification) {
        guard let keyboardSize: CGFloat = (notification.userInfo?[UIKeyboardFrameBeginUserInfoKey] as? NSValue)?.cgRectValue.size.height else {
            return
        }
        
        if sticky == true {
            return
        }

        if isCustomFrame == false {
            setRightBottomFrame(keyboardSize)
        } else {
            size = min(frame.size.width, frame.size.height)
        }

        let animationTime: TimeInterval = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRaw: UInt = (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        let animationOption: UIViewAnimationOptions = animationCurveRaw != 0 ? UIViewAnimationOptions(rawValue: animationCurveRaw<<16) : []

        UIView.animate(withDuration: animationTime, delay: 0, options: animationOption, animations: {
            self.frame = CGRect(
                x: UIScreen.main.bounds.width-self.size - self.paddingX,
                y: UIScreen.main.bounds.height-self.size - keyboardSize - self.paddingY,
                width: self.size,
                height: self.size
            )
            }, completion: nil)
    }

    internal func keyboardWillHide(_ notification: Notification) {
        
        if sticky == true {
            return
        }

        let animationTime: TimeInterval = (notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue ?? 0
        let animationCurveRaw: UInt = (notification.userInfo?[UIKeyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        let animationOption: UIViewAnimationOptions = animationCurveRaw != 0 ? UIViewAnimationOptions(rawValue: animationCurveRaw<<16) : []
        
        UIView.animate(withDuration: animationTime, delay: 0, options: animationOption, animations: {
            if self.isCustomFrame == false {
                self.setRightBottomFrame()
            } else {
                self.size = min(self.frame.size.width, self.frame.size.height)
            }

            }, completion: nil)
    }
}

/**
    Opening animation functions
 */
extension KCFloatingActionButton {
    /**
        Pop animation
     */
    fileprivate func popAnimationWithOpen() {
        guard let superview = superview else { return }

        var itemHeight: CGFloat = 0
        var delay = 0.0
        let buttonOrigin = superview.convert(self.frame.origin, to: overlayView)
        for item in items {
            if item.isHidden == true { continue }
            overlayView.addSubview(item)
            itemHeight += item.size + itemSpace
            item.layer.transform = CATransform3DIdentity
            item.frame.origin.y = buttonOrigin.y - itemHeight
            item.frame.size.width = item.size
            item.frame.size.height = item.size
            item.center.x = buttonOrigin.x + size / 2
            item.alpha = 0
            item.updateFrameBeforeAnimation()
            item.layer.transform = CATransform3DMakeScale(0.4, 0.4, 1)
            UIView.animate(withDuration: 0.3, delay: delay, usingSpringWithDamping: 0.55, initialSpringVelocity: 0.3,
                            options: UIViewAnimationOptions.curveEaseInOut, animations: { () -> Void in
                item.layer.transform = CATransform3DIdentity
                item.alpha = 1
            }, completion: {(_) in
                    item.updateFrameAfterAnimation()
                })

            delay += animationSpeed
        }
    }

    fileprivate func popAnimationWithClose() {
        var delay = 0.0
        for item in items.reversed() {
            if item.isHidden == true { continue }
            item.updateFrameBeforeAnimation()
            UIView.animate(withDuration: 0.15, delay: delay, options: UIViewAnimationOptions.curveEaseInOut, animations: { () -> Void in
                item.layer.transform = CATransform3DMakeScale(0.4, 0.4, 1)
                item.alpha = 0
            }, completion: {(_) in
                item.updateFrameAfterAnimation()
                item.removeFromSuperview()
            })
            delay += animationSpeed
        }
    }

    /**
        Fade animation
     */
    fileprivate func fadeAnimationWithOpen() {
        guard let superview = superview else { return }

        let buttonOrigin = superview.convert(self.frame.origin, to: overlayView)

        var itemHeight: CGFloat = 0
        var delay = 0.0

        for item in items {
            if item.isHidden == true { continue }
            overlayView.addSubview(item)
            itemHeight += item.size + itemSpace
            item.alpha = 0
            item.frame.size.width = item.size
            item.frame.size.height = item.size
            item.frame.origin.y = buttonOrigin.y - itemHeight
            item.center.x = buttonOrigin.x + size / 2

            item.updateFrameBeforeAnimation()

            UIView.animate(withDuration: animationSpeed,
                                       delay: delay,
                                       options: UIViewAnimationOptions.curveEaseIn,
                                       animations: { () -> Void in
                                        item.alpha = 1
                }, completion:  {(_) in
                    item.updateFrameAfterAnimation()
                })

            delay += animationSpeed
        }
    }

    fileprivate func fadeAnimationWithClose() {
        var delay = 0.0
        for item in items.reversed() {
            if item.isHidden == true { continue }
            item.updateFrameBeforeAnimation()
            UIView.animate(withDuration: animationSpeed,
                                       delay: delay,
                                       options: UIViewAnimationOptions.curveEaseOut,
                                       animations: { () -> Void in
                                        item.alpha = 0
                }, completion: {(_) in
                    item.updateFrameAfterAnimation()
                    item.removeFromSuperview()
                })
            delay += animationSpeed
        }
    }

    /**
        Slide left animation
     */
    fileprivate func slideLeftAnimationWithOpen() {
        guard let superview = superview else { return }

        let buttonOrigin = superview.convert(self.frame.origin, to: overlayView)

        var itemHeight: CGFloat = 0
        var delay = 0.0
        for item in items {
            if item.isHidden == true { continue }
            overlayView.addSubview(item)
            itemHeight += item.size + itemSpace
            item.frame.origin.x = superview.bounds.size.width - buttonOrigin.x
            item.frame.origin.y = buttonOrigin.y - itemHeight
            item.frame.size.width = item.size
            item.frame.size.height = item.size
            item.updateFrameBeforeAnimation()
            UIView.animate(withDuration: animationSpeed, delay: delay,
                                       usingSpringWithDamping: 0.55,
                                       initialSpringVelocity: 0.3,
                                       options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                                        item.center.x = buttonOrigin.x + self.size/2
                                        item.alpha = 1
                }, completion:   {(_) in
                    item.updateFrameAfterAnimation()
                })

            delay += animationSpeed
        }
    }

    fileprivate func slideLeftAnimationWithClose() {
        guard let superview = superview else { return }

        let buttonOrigin = superview.convert(self.frame.origin, to: overlayView)

        var delay = 0.0
        for item in items.reversed() {
            if item.isHidden == true { continue }
            item.updateFrameBeforeAnimation()
            UIView.animate(withDuration: animationSpeed, delay: delay, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                item.frame.origin.x = superview.bounds.size.width - buttonOrigin.x
                item.alpha = 0
                }, completion: {(_) in
                    item.updateFrameAfterAnimation()
                    item.removeFromSuperview()
                })
            delay += animationSpeed
        }
    }

    /**
        Slide up animation
     */
    fileprivate func slideUpAnimationWithOpen() {
        guard let superview = superview else { return }

        let buttonOrigin = superview.convert(self.frame.origin, to: overlayView)

        var itemHeight: CGFloat = 0

        for item in items {
            if item.isHidden == true { continue }
            overlayView.addSubview(item)
            itemHeight += item.size + itemSpace
            item.frame.size.width = item.size
            item.frame.size.height = item.size
            item.frame.origin.y = buttonOrigin.y
            item.center.x = buttonOrigin.x + size/2
            item.updateFrameBeforeAnimation()

            UIView.animate(withDuration: animationSpeed, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                                        item.frame.origin.y = buttonOrigin.y - itemHeight
                                        item.alpha = 1
                }, completion: {(_) in
                    item.updateFrameAfterAnimation()
                })
        }
    }

    fileprivate func slideUpAnimationWithClose() {
        guard let superview = superview else { return }

        let buttonOrigin = superview.convert(self.frame.origin, to: overlayView)

        for item in items.reversed() {
            if item.isHidden == true { continue }
            UIView.animate(withDuration: animationSpeed, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                item.frame.origin.y = buttonOrigin.y
                item.alpha = 0
                }, completion: {(_) in
                    item.removeFromSuperview()
                    item.updateFrameAfterAnimation()
                })
        }
    }

    /**
        Slide down animation
     */
    fileprivate func slideDownAnimationWithOpen() {

        guard let superview = superview else { return }

        let buttonOrigin = superview.convert(self.frame.origin, to: overlayView)

        var itemHeight: CGFloat = 0
        for item in items {
            if item.isHidden == true { continue }
            overlayView.addSubview(item)
            itemHeight += item.size + itemSpace
            item.frame.size.width = item.size
            item.frame.size.height = item.size
            item.center.x = buttonOrigin.x + size/2
            item.updateFrameBeforeAnimation()
            UIView.animate(withDuration: animationSpeed, delay: 0, options: UIViewAnimationOptions.curveEaseIn, animations: { () -> Void in
                                        item.frame.origin.y = buttonOrigin.y - itemHeight
                                        item.alpha = 1
                }, completion: {(_) in
                    item.updateFrameAfterAnimation()
                })
        }
    }

    fileprivate func slideDownAnimationWithClose() {
        for item in items.reversed() {
            if item.isHidden == true { continue }
            item.updateFrameBeforeAnimation()
            UIView.animate(withDuration: animationSpeed, delay: 0, options: UIViewAnimationOptions.curveEaseOut, animations: { () -> Void in
                item.frame.origin.y = 0
                item.alpha = 0
                }, completion: {(_) in
                    item.updateFrameAfterAnimation()
                    item.removeFromSuperview()
                })
        }
    }

    /**
        None animation
     */
    fileprivate func noneAnimationWithOpen() {
        var itemHeight: CGFloat = 0
        let buttonYMin = self.frame.minY
        for item in items {
            if item.isHidden == true { continue }
            itemHeight += item.size + itemSpace
            item.frame.size.width = item.size
            item.frame.size.height = item.size
            item.frame.origin.y = buttonYMin - itemHeight
            item.alpha = 1
        }
    }

    fileprivate func noneAnimationWithClose() {
        for item in items.reversed() {
            if item.isHidden == true { continue }
            item.frame.origin.y = 0
            item.alpha = 0
            item.removeFromSuperview()
        }
    }
}

/**
    Util functions
 */
extension KCFloatingActionButton {
    fileprivate func degreesToRadians(_ degrees: CGFloat) -> CGFloat {
        return degrees / 180.0 * CGFloat(Double.pi)
    }
}

extension UIView {
    fileprivate func getAllSuperviews() -> [UIView]? {
        if (self.superview == nil) {
            return nil
        }
        
        var superviews: [UIView] = []
        
        superviews.append(self.superview!)
        if let allSuperviews = self.superview!.getAllSuperviews() {
            superviews.append(contentsOf: allSuperviews)
        }
        
        return superviews
    }
}
