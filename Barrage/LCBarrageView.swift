//
//  LCBarrageView.swift
//  danmu
//
//  Created by CaiGavin on 11/25/15.
//  Copyright © 2015 CaiGavin. All rights reserved.
//

import UIKit

let ScreenWidth = UIScreen.mainScreen().bounds.width
let ScreenHeight = UIScreen.mainScreen().bounds.height

enum BulletType {
    case Top
    case Roll
    case Bottom
}

struct LCBullet {
    var content: String?
    var color: UIColor?
    var fontSize: CGFloat?
    var attrContent: NSAttributedString?
    var bulletType: BulletType = .Roll
}

struct LCTrajectory {
    var locationY: CGFloat
    var coldTime: Int = 0
}

extension Int {
    
}

final class LCBarrageView: UIView {

    // The number of UILabel used to show bullet
    var bulletLabelNumber: Int = 20

    var blockTopBullets = false
    var blockBottomBullets = false

    var defaultColor = UIColor.whiteColor()
    var defaultFontSize: CGFloat = 15.0

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
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if !isTrajectoryCreated {
            createTrajectories()
            isTrajectoryCreated = true
        }
    }

    deinit {
        removeTimer()
    }


    // MARK: Public

    // Process bullets and add bullets to ammunition
    func processBullets(bulletsArray bulletsArray: [LCBullet]?) {
        guard let bulletsArray = bulletsArray where !bulletsArray.isEmpty else {
            return
        }

        var bulletColor = defaultColor
        var bulletFontSize = defaultFontSize

        for var bullet in bulletsArray {
            guard let content = bullet.content where content != "" else {
                continue
            }

            bulletColor = bullet.color ?? defaultColor
            bulletFontSize = bullet.fontSize ?? defaultFontSize

            let attrDict = [NSForegroundColorAttributeName: bulletColor,
                NSFontAttributeName: UIFont.systemFontOfSize(bulletFontSize)
            ]

            let attributedStr = NSMutableAttributedString(string: content)
            attributedStr.addAttributes(attrDict, range: NSMakeRange(0, attributedStr.length))

            bullet.attrContent = attributedStr

            ammunitionArray.append(bullet)
        }
        
        createBulletLabel()
    }

    func addNewBullet(content content: String, color: UIColor?, fontSize: CGFloat? = 15.0, bulletType: BulletType = .Roll) {

        let bulletColor = color ?? defaultColor
        let bulletFontSize = fontSize ?? defaultFontSize

        let attrDict = [NSForegroundColorAttributeName: bulletColor,
            NSFontAttributeName: UIFont.systemFontOfSize(bulletFontSize)
        ]

        let attributedStr = NSMutableAttributedString(string: content)
        attributedStr.addAttributes(attrDict, range: NSMakeRange(0, attributedStr.length))

        let bullet = LCBullet(content: content, color: bulletColor, fontSize: bulletFontSize, attrContent: attributedStr, bulletType: bulletType)

        ammunitionArray.append(bullet)
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

        for i in 0..<trajectoryNumber {
            print("lalalala \(i)")
            let bulletY: CGFloat = CGFloat((Int(viewHeight - 40) / trajectoryNumber) * i) + 20.0
            let trajectory = LCTrajectory(locationY: bulletY, coldTime: 0)
            trajectoriesArray.append(trajectory)
        }
    }

    dynamic private func addBullets() {
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
        ammunitionArray.insert(lastBullet, atIndex: 0)

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
