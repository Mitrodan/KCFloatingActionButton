//
//  KCFloatingActionButtonItem.swift
//  KCFloatingActionButton-Sample
//
//  Created by LeeSunhyoup on 2015. 10. 5..
//  Copyright © 2015년 kciter. All rights reserved.
//

import UIKit

/**
 Floating Action Button Object's item.
 */
open class KCFloatingActionButtonItem: UIView {

    // MARK: - Properties

    /**
     This object's button size.
     */
    open var size: CGFloat = 42 {
        didSet {
            self.frame = CGRect(x: 0, y: 0, width: size, height: size)
            setCircleViewConstraints()
            circleView.layoutIfNeeded()
        }
    }

    /**
     Button color.
     */
    open var buttonColor: UIColor = UIColor.white {
        didSet {
            circleView.backgroundColor = buttonColor
        }
    }

    /**
     Title label color.
     */
    open var titleColor: UIColor = UIColor.white {
        didSet {
            titleLabel.textColor = titleColor
        }
    }

    /**
     Circle Shadow color.
     */
    open var circleShadowColor: UIColor? = UIColor.black {
        didSet {
            setCircleShadow()
        }
    }

    /**
     Title Shadow color.
     */
    open var titleShadowColor: UIColor? = UIColor.black {
        didSet {
            setTitleShadow()
        }
    }

    /**
     If you touch up inside button, it execute handler.
     */
    open var handler: ((KCFloatingActionButtonItem) -> Void)? = nil

    open var imageOffset: CGPoint = CGPoint.zero
    open var imageSize: CGSize = CGSize(width: 25, height: 25) {
        didSet {
            setIconConstraints()
            iconImageView.layoutIfNeeded()
            
        }
    }

    /**
     Reference to parent
     */
    open weak var actionButton: KCFloatingActionButton?

    /**
     Shape layer of button.
     */
    fileprivate var circleView = UIView()

    fileprivate var circleViewConstraints: [NSLayoutConstraint] = []

    /**
     If you keeping touch inside button, button overlaid with tint layer.
     */
    fileprivate var tintLayer: CAShapeLayer = CAShapeLayer()

    /**
     Item's title label.
     */
    let titleLabel = UILabel()

    fileprivate var titleConstraints: [NSLayoutConstraint] = []


    /**
     Item's title.
     */
    open var title: String? = nil {
        didSet {
            titleLabel.text = title
            titleLabel.layoutIfNeeded()
        }
    }

    /**
     Item's icon image view.
     */
    let iconImageView = UIImageView()

    fileprivate var imageConstraints: [NSLayoutConstraint] = []

    /**
     Item's icon.
     */
    open var icon: UIImage? = nil {
        didSet {
            iconImageView.image = icon
        }
    }
    
    /**
     Item's icon tint color change
     */
    open var iconTintColor: UIColor! = nil {
        didSet {
            let image = iconImageView.image?.withRenderingMode(.alwaysTemplate)
            iconImageView.tintColor = iconTintColor
            iconImageView.image = image
        }
    }

    /**
      itemBackgroundColor change
    */
    public var itemBackgroundColor: UIColor? = nil {
      didSet { circleView.backgroundColor = itemBackgroundColor}
    }

    // MARK: - Initialize

    /**
     Initialize with default property.
     */
    public init() {
        super.init(frame: CGRect(x: 0, y: 0, width: size, height: size))
        setup()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        setup()
    }

    func setup() {

        backgroundColor = UIColor.green

        translatesAutoresizingMaskIntoConstraints = false

        circleView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(circleView)
        setCircleShadow()
        setCircleViewConstraints()


        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        setTitleShadow()
        setTitleConstraints()

        iconImageView.translatesAutoresizingMaskIntoConstraints = false
        iconImageView.contentMode = UIViewContentMode.scaleAspectFill
        addSubview(iconImageView)
        setIconConstraints()

        print("setup ended")
    }

    fileprivate func createTintLayer() {
        let castParent : KCFloatingActionButton = superview as! KCFloatingActionButton
        tintLayer.frame = CGRect(x: castParent.itemSize/2 - (size/2), y: 0, width: size, height: size)
        tintLayer.backgroundColor = UIColor.white.withAlphaComponent(0.2).cgColor
        tintLayer.cornerRadius = size/2
        layer.addSublayer(tintLayer)
    }

    fileprivate func setCircleShadow() {
        circleView.layer.shadowOffset = CGSize(width: 1, height: 1)
        circleView.layer.shadowRadius = 2
        if let circleShadowColor = circleShadowColor {
            circleView.layer.shadowColor = circleShadowColor.cgColor
            circleView.layer.shadowOpacity = 0.4
        } else {
            circleView.layer.shadowOpacity = 0.0
        }
    }

    func setTitleShadow() {
        titleLabel.layer.shadowOffset = CGSize(width: 1, height: 1)
        titleLabel.layer.shadowRadius = 2
        if let titleShadowColor = titleShadowColor {
            titleLabel.layer.shadowColor = titleShadowColor.cgColor
            titleLabel.layer.shadowOpacity = 0.4
        } else {
            titleLabel.layer.shadowOpacity = 0.0
        }
    }

    open override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            let touch = touches.first
            if touch?.tapCount == 1 {
                if touch?.location(in: self) == nil { return }
                createTintLayer()
            }
        }
    }

    open override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if touches.count == 1 {
            let touch = touches.first
            if touch?.tapCount == 1 {
                if touch?.location(in: self) == nil { return }
                createTintLayer()
            }
        }
    }

    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        tintLayer.removeFromSuperlayer()
        if touches.count == 1 {
            let touch = touches.first
            if touch?.tapCount == 1 {
                if touch?.location(in: self) == nil { return }
                if actionButton != nil && actionButton!.autoCloseOnTap {
                    actionButton!.close()
                }
                handler?(self)
            }
        }
    }
}

extension KCFloatingActionButtonItem {
    func setTitleConstraints() {
        titleConstraints.forEach {$0.isActive = false}
        titleConstraints.removeAll()

        titleConstraints.append(titleLabel.rightAnchor.constraint(equalTo: self.leftAnchor, constant: -10))
        titleConstraints.append(titleLabel.centerYAnchor.constraint(equalTo: circleView.centerYAnchor))

        titleConstraints.forEach {$0.isActive = true}
    }

    func setIconConstraints() {

        imageConstraints.forEach {$0.isActive = false}
        imageConstraints.removeAll()

        imageConstraints.append(iconImageView.centerYAnchor.constraint(equalTo: circleView.centerYAnchor, constant: imageOffset.y))
        imageConstraints.append(iconImageView.centerXAnchor.constraint(equalTo: circleView.centerXAnchor, constant: imageOffset.x))
        imageConstraints.append(iconImageView.heightAnchor.constraint(equalToConstant: imageSize.height))
        imageConstraints.append(iconImageView.widthAnchor.constraint(equalToConstant: imageSize.width))

        imageConstraints.forEach {$0.isActive = true}

        iconImageView.layoutIfNeeded()
    }

    func setCircleViewConstraints() {

        circleViewConstraints.forEach {$0.isActive = false}
        circleViewConstraints.removeAll()

//        circleViewConstraints.append(circleView.centerYAnchor.constraint(equalTo: self.centerYAnchor))
//        circleViewConstraints.append(circleView.centerXAnchor.constraint(equalTo: self.centerXAnchor))

        circleViewConstraints.append(circleView.topAnchor.constraint(equalTo: self.topAnchor))
        circleViewConstraints.append(circleView.leftAnchor.constraint(equalTo: self.leftAnchor))

        circleViewConstraints.append(circleView.heightAnchor.constraint(equalToConstant: size))
        circleViewConstraints.append(circleView.widthAnchor.constraint(equalToConstant: size))

        circleView.layer.cornerRadius = size / 2

        NSLayoutConstraint.activate(circleViewConstraints)

        //circleViewConstraints.forEach {$0.isActive = true}

        circleView.layoutIfNeeded()
    }
}

func + (left: CGPoint, right: CGPoint) -> CGPoint {
    return CGPoint(x: left.x + right.x, y: left.y + right.y)
}
