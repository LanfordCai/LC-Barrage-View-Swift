//
//  LCBarrageView.swift
//  danmu
//
//  Created by Cai Linfeng on 11/25/15.
//  Copyright © 2015 Cai Linfeng. All rights reserved.
//

import UIKit

let ScreenWidth = UIScreen.mainScreen().bounds.width
let ScreenHeight = UIScreen.mainScreen().bounds.height

public enum LCBulletType {
    case Top
    case Roll
    case Bottom
}

public protocol LCBarrageViewDelegate:class {

    func barrageViewDidRunOutOfBullets(barrage: LCBarrageView)
}

public struct LCBullet {
    var content: String?
    var color: UIColor?
    var fontSize: CGFloat?
    var attrContent: NSAttributedString?
    var bulletType: LCBulletType = .Roll
}

public struct LCTrajectory {
    var locationY: CGFloat
    var coldTime: Int = 0
}

public class LCBarrageView: UIView {

    enum BulletShotMode {
        case Random
        case Order
    }

    public weak var delegate: LCBarrageViewDelegate?

    var rollBulletsShotMode: BulletShotMode = .Random
    // The number of CATextLayer used to show bullet
    var bulletLayerNumber: Int = 30

    var blockTopBullets = false
    var blockBottomBullets = false

    var defaultColor = UIColor.whiteColor()
    var defaultFontSize: CGFloat = 15.0

    var circularShot = true

    // Base offset of Top type bullets
    var topOffset: CGFloat = 10.0
    // Base offset of Bottom type bullets
    var bottomOffset: CGFloat = 30.0

    // The base duration to roll a bullet from right to left
    var rollOutDuration: CGFloat = 5.0
    var shootInterval: Double = 0.3 {
        didSet {
            shootInterval = shootInterval < shortestShootInterval ? shortestShootInterval : shootInterval
            shootInterval = shootInterval > longestShootInterval ? longestShootInterval : shootInterval
            fire()
        }
    }


    private var bulletLayerArray = [CATextLayer]()
    private var ammunitionArray = [LCBullet]()
    private var backupAmmunitionArray = [LCBullet]()

    private var shortestShootInterval: Double = 0.1 {
        didSet {
            shortestShootInterval = shortestShootInterval < 0.1 ? 0.1 : shortestShootInterval
        }
    }
    private var longestShootInterval: Double = 1.0 {
        didSet {
            longestShootInterval = longestShootInterval > 1.0 ? 1.0 : longestShootInterval
        }
    }

    private var topBulletNumber: Int = 0
    private var bottomBulletNumber: Int = 0

    // The numbers of bullets shown on BarrageView
    private var flyingBulletsNumber: Int = 0

    private var isTrajectoryCreated = false
    private let trajectoryNumber: Int = 20
    private lazy var trajectoriesArray = [LCTrajectory]()
    private var barrageTimer: NSTimer?


    // MARK: Life-Cycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clearColor()
        self.clipsToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clearColor()
        self.clipsToBounds = true
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override public func layoutSubviews() {
        super.layoutSubviews()

        if !isTrajectoryCreated {
            createTrajectories()
            isTrajectoryCreated = true
        }
    }

    deinit {
        removeTimer()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("[LCBarrageView] LCBarrageView Deinit")
    }


    // MARK: Public

    // Process bullets and add bullets to ammunition
    func processBullets(bulletsArray bulletsArray: [LCBullet]?) {
        guard let bulletsArray = bulletsArray where !bulletsArray.isEmpty else {
            return
        }

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "orientationChanged", name: UIDeviceOrientationDidChangeNotification, object: nil)

        var bulletColor = defaultColor
        var bulletFontSize = defaultFontSize

        for var bullet in bulletsArray {
            if let attrContent = bullet.attrContent where attrContent.length != 0 {
                ammunitionArray.append(bullet)
            } else if let content = bullet.content where content != "" {

                bulletColor = bullet.color ?? defaultColor
                bulletFontSize = bullet.fontSize ?? defaultFontSize

                let attrDict = [NSForegroundColorAttributeName: bulletColor,
                    NSFontAttributeName: UIFont.systemFontOfSize(bulletFontSize)
                ]

                let attributedStr = NSMutableAttributedString(string: content)
                attributedStr.addAttributes(attrDict, range: NSMakeRange(0, attributedStr.length))

                bullet.attrContent = attributedStr

                ammunitionArray.append(bullet)
            } else {
                continue
            }
        }

        backupAmmunitionArray = ammunitionArray
        createBulletLayerArray()
    }

    func addNewBullet(attrContent attrContent: NSAttributedString?, bulletType: LCBulletType = .Roll) {
        guard let attrContent = attrContent where attrContent.length != 0 else {
            print("[LCBarrageView] Invalid input")
            return
        }

        let bullet = LCBullet(content: nil, color: nil, fontSize: nil, attrContent: attrContent, bulletType: bulletType)
        ammunitionArray.append(bullet)
        backupAmmunitionArray.append(bullet)
    }

    func addNewBullet(content content: String?, color: UIColor?, fontSize: CGFloat? = 15.0, bulletType: LCBulletType = .Roll) {
        guard let content = content where content != "" else {
            print("[LCBarrageView] Invalid input")
            return
        }

        let bulletColor = color ?? defaultColor
        let bulletFontSize = fontSize ?? defaultFontSize

        let attrDict = [NSForegroundColorAttributeName: bulletColor,
            NSFontAttributeName: UIFont.systemFontOfSize(bulletFontSize)
        ]

        let attributedStr = NSMutableAttributedString(string: content)
        attributedStr.addAttributes(attrDict, range: NSMakeRange(0, attributedStr.length))

        let bullet = LCBullet(content: content, color: bulletColor, fontSize: bulletFontSize, attrContent: attributedStr, bulletType: bulletType)

        ammunitionArray.append(bullet)
        backupAmmunitionArray.append(bullet)
    }

    func reloadBullets() {
        ammunitionArray = backupAmmunitionArray
    }

    func fire() {
        guard !ammunitionArray.isEmpty else {
            return
        }
        
        removeTimer()

        barrageTimer = NSTimer.scheduledTimerWithTimeInterval(
            shootInterval,
            target: self,
            selector: "addBullets",
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        UIView.animateWithDuration(0.4, animations: { () -> Void in
            self.frame.origin.x = -self.frame.width
            }) { (_) -> Void in
                self.layer.sublayers?.removeAll()
                self.reset()
                self.frame.origin.x = 0.0
        }
        removeTimer()
    }


    // MARK: Private

    private func removeTimer() {
        barrageTimer?.invalidate()
        barrageTimer = nil
    }

    private func reset() {
        reloadBullets()
        createBulletLayerArray()
        for var trajectory in trajectoriesArray {
            trajectory.coldTime = 0
        }

        topOffset = 10
        bottomOffset = 30
        topBulletNumber = 0
        bottomBulletNumber = 0
        flyingBulletsNumber = 0
    }

    private func createBulletLayerArray() {
        bulletLayerArray.removeAll()
        for _ in 0..<bulletLayerNumber {
            let layer = CATextLayer()
            bulletLayerArray.append(layer)
            self.layer.addSublayer(layer)
        }
    }

    private func createTrajectories() {
        let viewHeight = self.bounds.height
        trajectoriesArray.removeAll()
        for i in 0..<trajectoryNumber {
            let bulletY: CGFloat = CGFloat((Int(viewHeight - 40) / trajectoryNumber) * i) + 20.0
            let trajectory = LCTrajectory(locationY: bulletY, coldTime: 0)
            trajectoriesArray.append(trajectory)
        }
    }

    @objc func orientationChanged() {
        isTrajectoryCreated = false
    }

    @objc func addBullets() {

        guard flyingBulletsNumber <= bulletLayerNumber else {
            return
        }

        guard let bulletLayer = bulletLayerArray.last else {
            return
        }

        guard let lastBullet = ammunitionArray.last else {
            return
        }

        bulletLayerArray.removeLast()
        let shootedBullet = lastBullet.attrContent
        bulletLayer.string = shootedBullet

        guard let bulletLayerStr = bulletLayer.string as? NSAttributedString else {
            return
        }

        ammunitionArray.removeLast()
        if circularShot {
            ammunitionArray.insert(lastBullet, atIndex: 0)
        } else {
            if ammunitionArray.isEmpty {
                removeTimer()
                delegate?.barrageViewDidRunOutOfBullets(self)
            }
        }

        let gunpowderStr = bulletLayerStr.string
        var range = NSMakeRange(0, 1)
        let attrDict = bulletLayerStr.attributesAtIndex(0, effectiveRange: &range)

        let bulletLayerSize = gunpowderStr.sizeWithAttributes(attrDict)

        switch lastBullet.bulletType {
        case .Top:
            shootTopBullet(bulletLayer: bulletLayer, bulletLayerSize: bulletLayerSize)
        case .Bottom:
            shootBottomBullet(bulletLayer: bulletLayer, bulletLayerSize: bulletLayerSize)
        case .Roll:
            shootRollBullet(bulletLayer: bulletLayer, bulletLayerSize: bulletLayerSize)
        }
    }

    private func shootBottomBullet(bulletLayer bulletLayer: CATextLayer, bulletLayerSize: CGSize) {
        let viewHeight = self.bounds.height

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        // TODO: guard??
        guard !blockTopBullets else {
            bulletLayerArray.insert(bulletLayer, atIndex: 0)
            return
        }

        flyingBulletsNumber++
        let bulletLayerY: CGFloat = viewHeight - bottomOffset
        let bulletLayerX: CGFloat = 0.5 * (self.bounds.width - bulletLayerSize.width)
        bulletLayer.frame = CGRectMake(bulletLayerX, bulletLayerY, bulletLayerSize.width, bulletLayerSize.height)
        bottomOffset += bulletLayerSize.height
        bottomBulletNumber++
        if bottomBulletNumber > 13 - Int(25 * shootInterval) || bottomOffset > viewHeight - 40 {
            bottomOffset = 30
            bottomBulletNumber = 0
        }
        delayBySeconds(2.0) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            bulletLayer.frame = CGRectZero
            strongSelf.bulletLayerArray.insert(bulletLayer, atIndex: 0)
            strongSelf.flyingBulletsNumber--
            CATransaction.commit()
        }

    }

    private func shootTopBullet(bulletLayer bulletLayer: CATextLayer, bulletLayerSize: CGSize) {
        let viewHeight = self.bounds.height

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        guard !blockTopBullets else {
            bulletLayerArray.insert(bulletLayer, atIndex: 0)
            return
        }

        flyingBulletsNumber++
        let bulletLayerY: CGFloat = topOffset
        let bulletLayerX: CGFloat = 0.5 * (self.bounds.width - bulletLayerSize.width)
        bulletLayer.frame = CGRectMake(bulletLayerX, bulletLayerY, bulletLayerSize.width, bulletLayerSize.height)
        topOffset += bulletLayerSize.height
        topBulletNumber++
        if topBulletNumber > 13 - Int(25 * shootInterval) || topOffset > viewHeight - 40 {
            topOffset = 10
            topBulletNumber = 0
        }
        delayBySeconds(2.0) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            bulletLayer.frame = CGRectZero
            strongSelf.bulletLayerArray.insert(bulletLayer, atIndex: 0)
            strongSelf.flyingBulletsNumber--
            CATransaction.commit()
        }
    }

    private func forceCooling() {
        for i in 0..<trajectoryNumber {
        trajectoriesArray[i].coldTime--
        }
    }

    private func shootRollBullet(bulletLayer bulletLayer: CATextLayer, bulletLayerSize: CGSize) {
        let viewWidth = self.layer.bounds.width

        guard let bulletTextStr = bulletLayer.string as? NSAttributedString else {
            return
        }

        let bulletText = bulletTextStr.string

        for i in 0..<trajectoryNumber {
            if trajectoriesArray[i].coldTime != 0 {
                trajectoriesArray[i].coldTime--
            }
        }

        var pickedTrajectory: Int

        switch rollBulletsShotMode {
        case .Random:
            var pickTime: Int = 0
            pickedTrajectory = Int(arc4random_uniform(UInt32(trajectoryNumber)))
            while trajectoriesArray[pickedTrajectory].coldTime > 0 {
                pickedTrajectory = Int(arc4random_uniform(UInt32(trajectoryNumber)))
                pickTime++
                if pickTime % trajectoryNumber == 0 {
                    forceCooling()
                }
            }
        case .Order:
            pickedTrajectory = 0
            while trajectoriesArray[pickedTrajectory].coldTime > 0 {
                pickedTrajectory++
                if pickedTrajectory >= trajectoryNumber - 1 {
                    pickedTrajectory = 0
                    forceCooling()
                }
            }
        }

        trajectoriesArray[pickedTrajectory].coldTime = bulletText.characters.count / 2
        let bulletLayerY = trajectoriesArray[pickedTrajectory].locationY

        let bulletFrame = CGRectMake(viewWidth, bulletLayerY, bulletLayerSize.width, bulletLayerSize.height)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bulletLayer.frame = bulletFrame
        bulletLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        bulletLayer.position = CGPoint(x: viewWidth, y: bulletLayerY)
        let duration: CGFloat = CGFloat(arc4random() % 10) / 10.0 + rollOutDuration

        flyingBulletsNumber++

        CATransaction.setCompletionBlock { [weak self] () -> Void in
            bulletLayer.frame = CGRectZero
            self?.bulletLayerArray.insert(bulletLayer, atIndex: 0)
            self?.flyingBulletsNumber--
        }

        let transitionAnimation = CABasicAnimation(keyPath: "position.x")
        transitionAnimation.fromValue = bulletFrame.origin.x
        transitionAnimation.toValue = -bulletFrame.origin.x
        transitionAnimation.duration = Double(duration)
        transitionAnimation.repeatCount = 0
        transitionAnimation.removedOnCompletion = true
        bulletLayer.addAnimation(transitionAnimation, forKey: nil)
        CATransaction.commit()
    }
}

private func delayBySeconds(seconds: Double, delayedCode: () -> ()) {
    let targetTime = dispatch_time(DISPATCH_TIME_NOW, Int64(Double(NSEC_PER_SEC) * seconds))
    dispatch_after(targetTime, dispatch_get_main_queue()) {
        delayedCode()
    }
}

