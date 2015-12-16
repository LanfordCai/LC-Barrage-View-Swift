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

enum BulletType: Int {
    case Top = 0
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

var kBarrageStatusChanged = "barrageStatusChanged"

final class LCBarrageView: UIView {

    var shortestShootInterval: Double = 0.05 {
        didSet {
            if shortestShootInterval < 0.05 {
                shortestShootInterval = 0.05
            }
        }
    }

    var longestShootInterval: Double = 1.0 {
        didSet {
            if longestShootInterval > 2.0 {
                longestShootInterval = 2.0
            }
        }
    }

    private var defaultColor = UIColor.whiteColor()
    private var defaultFontSize: CGFloat = 15.0

    var shootInterval: Double = 0.1 {
        didSet {
            if shootInterval < shortestShootInterval {
                shootInterval = shortestShootInterval
            }

            if shootInterval > longestShootInterval {
                shootInterval = longestShootInterval
            }

            fire()
        }
    }

    var bulletLabelNumber: Int = 8

    private var flyingBulletsNumber: Int = 0
    
    private var preBulletY: CGFloat = 0.0
    // 弹道数
    private let trajectoryNumber: Int = 20
    
    private var barrageTimer: NSTimer?
    
    // 同时出现的弹幕数，即可复用的 UILabel 数
    private var bulletLabelArray = [UILabel]()

    // 弹幕内容
    private var gunpowderArray = [LCBullet]()

    var topOffset: CGFloat = 10.0
    private var topBulletNumber: Int = 0

    var bottomOffset: CGFloat = 30.0
    private var bottomBulletNumber: Int = 0

    // 加载弹幕内容
    func processBullets(bulletsArray bulletsArray: [LCBullet]?) {
        guard let bulletsArray = bulletsArray where !bulletsArray.isEmpty else {
            print("No contents to present")
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

            gunpowderArray.append(bullet)
        }

        loadBullets()
    }

    // MARK: Life-Cycle
//    override func awakeFromNib() {
//        super.awakeFromNib()
//    }
//    
//    override init(frame: CGRect) {
//        super.init(frame: frame)
//        
//        NSNotificationCenter.defaultCenter().addObserver(self, selector: "barrageStatusChanged:", name: kBarrageStatusChanged, object: nil)
//    }
//
//
//    required init?(coder aDecoder: NSCoder) {
//        super.init(coder: aDecoder)
//        fatalError("init(coder:) has not been implemented")
//    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
        removeTimer()
    }


    // MARK: Configurations
    func barrageStatusChanged(note: NSNotification) {
        guard let barrageStatus = note.object as? Bool else {
            return
        }

        if barrageStatus {
            fire()
        } else {
            removeTimer()
        }
        
//        globalBarrageStatus = barrageStatus 
    }

    
    func fire() {
        // TODO: 这个应该移动到 addBullet??
        guard !gunpowderArray.isEmpty else {
            return
        }
        
        removeTimer()

        // TODO: 换成 CADisplayLink
        barrageTimer = NSTimer.scheduledTimerWithTimeInterval(shootInterval, target: self, selector: "addBullet", userInfo: nil, repeats: true)
    }

    func stop() {
        removeTimer()
    }

    private func removeTimer() {
        barrageTimer?.invalidate()
        barrageTimer = nil
    }


    // MARK: Helpers
    private func loadBullets() {
        for (var idx = 0; idx < bulletLabelNumber; idx++) {
            let bullet = UILabel()
            bulletLabelArray.append(bullet)
            self.addSubview(bullet)
        }
    }

    // 添加评论
    func loadNewBullet(contentStr content: String?, color: UIColor?, fontSize: CGFloat? = 15.0, bulletType: BulletType = .Roll) {
        guard let content = content else {
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

        gunpowderArray.append(bullet)
    }


    func addBullet() {

        guard flyingBulletsNumber <= bulletLabelNumber else {
            return
        }

        // bullet 是 UILabel 囧
        guard let bullet = bulletLabelArray.last else {
            print("No BulletLabel")
            return
        }

        guard let lastGunpowder = gunpowderArray.last else {
            print("No Gunpower")
            return
        }

        bulletLabelArray.removeLast()
        let shootedGunpowder = lastGunpowder.attrContent
        bullet.attributedText = shootedGunpowder
        gunpowderArray.removeLast()
        gunpowderArray.insert(lastGunpowder, atIndex: 0)

        let gunpowderStr = (bullet.attributedText?.string)! as NSString

        // TODO: 可以用 attributes:EffectiveRange 来替代，但是在 Swift 中如何使用指针？

        // TODO: 要处理，直接改模型吧
        let bulletColor = lastGunpowder.color ?? defaultColor
        let bulletFontSize = lastGunpowder.fontSize ?? defaultFontSize
        let attrDict = [NSForegroundColorAttributeName: bulletColor,
            NSFontAttributeName: UIFont.systemFontOfSize(bulletFontSize)
        ]

        let bulletSize = gunpowderStr.sizeWithAttributes(attrDict)

        switch lastGunpowder.bulletType {
        case .Top:
            shootTopBullet(bullet: bullet, bulletSize: bulletSize)
        case .Bottom:
            shootBottomBullet(bullet: bullet, bulletSize: bulletSize)
        default:
            shootRollBullet(bullet: bullet, bulletSize: bulletSize)
        }
    }

    private func shootBottomBullet(bullet bullet: UILabel, bulletSize: CGSize) {
        flyingBulletsNumber++
        let bulletY: CGFloat = self.bounds.height - bottomOffset
        let bulletX: CGFloat = 0.5 * (self.bounds.width - bulletSize.width)
        bullet.frame = CGRectMake(bulletX, bulletY, bulletSize.width, bulletSize.height)
        bullet.alpha = 0.8

        bottomOffset += bulletSize.height

        UIView.animateKeyframesWithDuration(1.0, delay: 0.0, options: .AllowUserInteraction, animations: { () -> Void in
            bullet.alpha = 1.0
            }) { (_) -> Void in
                bullet.alpha = 0.0
                self.bulletLabelArray.insert(bullet, atIndex: 0)
                self.bottomBulletNumber++
                if self.bottomBulletNumber > 5 {
                    self.bottomOffset = 30
                    self.bottomBulletNumber = 0
                }
                self.flyingBulletsNumber--
        }
    }

    private func shootTopBullet(bullet bullet: UILabel, bulletSize: CGSize) {
        flyingBulletsNumber++
        let bulletY: CGFloat = topOffset
        let bulletX: CGFloat = 0.5 * (self.bounds.width - bulletSize.width)
        bullet.frame = CGRectMake(bulletX, bulletY, bulletSize.width, bulletSize.height)
        bullet.alpha = 0.8

        topOffset += bulletSize.height

        UIView.animateKeyframesWithDuration(1.0, delay: 0.0, options: .AllowUserInteraction, animations: { () -> Void in
            bullet.alpha = 1.0
            }) { (_) -> Void in
                bullet.alpha = 0.0
                self.bulletLabelArray.insert(bullet, atIndex: 0)
                self.topBulletNumber++
                if self.topBulletNumber > 5 {
                    self.topOffset = 10
                    self.topBulletNumber = 0
                }
                self.flyingBulletsNumber--
        }
    }
    
    private func shootRollBullet(bullet bullet: UIView, bulletSize: CGSize) {
        let viewHeight = self.bounds.height == 0.0 ? ScreenWidth : self.bounds.height
        let viewWidth = self.bounds.width == 0.0 ? ScreenWidth : self.bounds.width


        // MARK: Roll
        var bulletY: CGFloat = CGFloat(Int(arc4random()) % (Int(viewHeight - 40) / trajectoryNumber)) * CGFloat(trajectoryNumber) + 20

        while bulletY == preBulletY {
            bulletY = CGFloat(Int(arc4random()) % (Int(viewHeight - 40) / trajectoryNumber)) * CGFloat(trajectoryNumber) + 20
        }

        preBulletY = bulletY

        let bulletFrame = CGRectMake(viewWidth, bulletY, bulletSize.width, bulletSize.height)
        bullet.frame = bulletFrame
        bullet.alpha = 1.0
        let randomFactor = arc4random() % 6
        let duration = randomFactor + 3
        
        let endPoint = CGPointMake(0 - bullet.bounds.width, bullet.frame.origin.y)
        let endRect = CGRectMake(endPoint.x, endPoint.y, bullet.bounds.width, bullet.bounds.height)
        
        flyingBulletsNumber++
        
        UIView.animateWithDuration(NSTimeInterval(duration), animations: { () -> Void in
            UIView.setAnimationCurve(.Linear)
            bullet.frame = endRect
            }) { (_) -> Void in
                self.bulletLabelArray.insert(bullet as! UILabel, atIndex: 0)
                self.flyingBulletsNumber--
        }
    }
}
