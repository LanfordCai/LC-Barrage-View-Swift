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

// TODO: 取消循环
// TODO: 弹道查找模式

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

    public weak var delegate: LCBarrageViewDelegate?
    // The number of UILabel used to show bullet
    var bulletLabelNumber: Int = 20

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

    private var bulletLabelArray = [UILabel]()
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
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
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
        print("LCBarrageView Deinit")
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
        createBulletLabel()
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
        removeTimer()
    }


    // MARK: Private

    private func removeTimer() {
        barrageTimer?.invalidate()
        barrageTimer = nil
    }

    private func createBulletLabel() {
        for _ in 0..<bulletLabelNumber {
            let bullet = UILabel()
            bulletLabelArray.append(bullet)
            self.addSubview(bullet)
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
        guard flyingBulletsNumber <= bulletLabelNumber else {
            return
        }

        guard let bulletLabel = bulletLabelArray.last else {
            return
        }

        guard let lastBullet = ammunitionArray.last else {
            return
        }

        bulletLabelArray.removeLast()
        let shootedBullet = lastBullet.attrContent
        bulletLabel.attributedText = shootedBullet
        ammunitionArray.removeLast()
        if circularShot {
            ammunitionArray.insert(lastBullet, atIndex: 0)
        } else {
            if ammunitionArray.isEmpty {
                removeTimer()
                delegate?.barrageViewDidRunOutOfBullets(self)
            }
        }

        let gunpowderStr = (bulletLabel.attributedText?.string)! as NSString
        var range = NSMakeRange(0, 1)
        let attrDict = bulletLabel.attributedText?.attributesAtIndex(0, effectiveRange: &range)

        let bulletLabelSize = gunpowderStr.sizeWithAttributes(attrDict)

        switch lastBullet.bulletType {
        case .Top:
            shootTopBullet(bulletLabel: bulletLabel, bulletLabelSize: bulletLabelSize)
        case .Bottom:
            shootBottomBullet(bulletLabel: bulletLabel, bulletLabelSize: bulletLabelSize)
        case .Roll:
            shootRollBullet(bulletLabel: bulletLabel, bulletLabelSize: bulletLabelSize)
        }
    }

    private func shootBottomBullet(bulletLabel bulletLabel: UILabel, bulletLabelSize: CGSize) {
        let viewHeight = self.bounds.height

        guard !blockBottomBullets else {
            bulletLabelArray.insert(bulletLabel, atIndex: 0)
            return
        }

        flyingBulletsNumber++
        let bulletLabelY: CGFloat = self.bounds.height - bottomOffset
        let bulletLabelX: CGFloat = 0.5 * (self.bounds.width - bulletLabelSize.width)
        bulletLabel.frame = CGRectMake(bulletLabelX, bulletLabelY, bulletLabelSize.width, bulletLabelSize.height)
        bulletLabel.alpha = 0.8

        bottomOffset += bulletLabelSize.height

        UIView.animateKeyframesWithDuration(2.0, delay: 0.0, options: .AllowUserInteraction, animations: { () -> Void in
            bulletLabel.alpha = 1.0
        }, completion: { _ in
            bulletLabel.alpha = 0.0
            self.bulletLabelArray.insert(bulletLabel, atIndex: 0)
            self.bottomBulletNumber++

            // The Relationship between bulletNumber and shootInterval: bottomBulletNumber should smaller than 13 - 30 * shootInterval
            if self.bottomBulletNumber > 13 - Int(30 * self.shootInterval) || self.bottomOffset > viewHeight - 40  {
                self.bottomOffset = 30
                self.bottomBulletNumber = 0
            }
            self.flyingBulletsNumber--
        })
    }

    private func shootTopBullet(bulletLabel bulletLabel: UILabel, bulletLabelSize: CGSize) {
        let viewHeight = self.bounds.height

        guard !blockTopBullets else {
            bulletLabelArray.insert(bulletLabel, atIndex: 0)
            return
        }

        flyingBulletsNumber++
        let bulletLabelY: CGFloat = topOffset
        let bulletLabelX: CGFloat = 0.5 * (self.bounds.width - bulletLabelSize.width)
        bulletLabel.frame = CGRectMake(bulletLabelX, bulletLabelY, bulletLabelSize.width, bulletLabelSize.height)
        bulletLabel.alpha = 0.8

        topOffset += bulletLabelSize.height

        UIView.animateKeyframesWithDuration(2.0, delay: 0.0, options: .AllowUserInteraction, animations: { () -> Void in
            bulletLabel.alpha = 1.0
        }, completion: { _ in
            bulletLabel.alpha = 0.0
            self.bulletLabelArray.insert(bulletLabel, atIndex: 0)
            self.topBulletNumber++
            if self.topBulletNumber > 13 - Int(30 * self.shootInterval) || self.topOffset > viewHeight - 40 {
                self.topOffset = 10
                self.topBulletNumber = 0
            }
            self.flyingBulletsNumber--
        })
    }

    private func shootRollBullet(bulletLabel bulletLabel: UILabel, bulletLabelSize: CGSize) {
        let viewWidth = self.bounds.width

        for i in 0..<trajectoryNumber {
            if trajectoriesArray[i].coldTime != 0 {
                trajectoriesArray[i].coldTime--
            }
        }

        var pickedTrajectory: Int = Int(arc4random_uniform(UInt32(trajectoryNumber)))
        while trajectoriesArray[pickedTrajectory].coldTime != 0 {
            pickedTrajectory = Int(arc4random_uniform(UInt32(trajectoryNumber)))
        }

        trajectoriesArray[pickedTrajectory].coldTime = (bulletLabel.text?.characters.count)! / 2
        let bulletLabelY = trajectoriesArray[pickedTrajectory].locationY

        let bulletFrame = CGRectMake(viewWidth, bulletLabelY, bulletLabelSize.width, bulletLabelSize.height)
        bulletLabel.frame = bulletFrame
        bulletLabel.alpha = 1.0

        let duration: CGFloat = CGFloat(arc4random() % 10) / 10.0 + rollOutDuration

        let endPoint = CGPointMake(0 - bulletLabelSize.width, bulletLabel.frame.origin.y)
        let endRect = CGRectMake(endPoint.x, endPoint.y, bulletLabelSize.width, bulletLabelSize.height)

        flyingBulletsNumber++

        UIView.animateWithDuration(NSTimeInterval(duration), animations: { () -> Void in
            UIView.setAnimationCurve(.Linear)
            bulletLabel.frame = endRect
        }, completion: { _ in
            self.bulletLabelArray.insert(bulletLabel, atIndex: 0)
            self.flyingBulletsNumber--
        })
    }
}
