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

struct LCBullet {
    var content: String?
    var color: UIColor?
    var fontSize: CGFloat?
    var attrContent: NSAttributedString?
}

var kBarrageStatusChanged = "barrageStatusChanged"

final class LCBarrageView: UIView {

    var defaultColor = UIColor.whiteColor()
    var defaultFontSize: CGFloat = 15.0

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
    
    // 色表
    private let colorArray = [
        UIColor.redColor(),
        UIColor.whiteColor(),
        UIColor.blueColor(),
        UIColor.brownColor(),
        UIColor.purpleColor(),
        UIColor.greenColor(),
        UIColor.magentaColor(),
        UIColor.lightGrayColor(),
        UIColor.orangeColor(),
        UIColor.yellowColor()
    ]
    
    // 加载弹幕内容
    var bulletContentArray: [String]? {
        didSet {
//            if let contents = bulletContentArray where !contents.isEmpty {
//                for content in contents {
////                    let color: UIColor = randomColor()
//                    let colorIndex: Int = Int(arc4random_uniform(UInt32(colorArray.count)))
//                    let color = colorArray[colorIndex]
//                    let attrDict = [NSForegroundColorAttributeName: color,
//                        NSFontAttributeName: UIFont.systemFontOfSize(15)
//                    ]
//                    
//                    let attributedStr = NSMutableAttributedString(string: content)
//                    attributedStr.addAttributes(attrDict, range: NSMakeRange(0, attributedStr.length))
//                    self.gunpowderArray.append(attributedStr)
//                }
//                loadBullets()
//            }
        }
    }

    var bulletColorArray: [UIColor]? {
        didSet {

        }
    }

    var bulletFontSizeArray: [CGFloat]? {
        didSet {

        }
    }

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

            self.gunpowderArray.append(bullet)
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
        
        barrageTimer = NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "addBullet", userInfo: nil, repeats: true)
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
    func loadNewBullet(contentStr content: String?, color: UIColor?, fontSize: CGFloat?) {
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

        let bullet = LCBullet(content: content, color: bulletColor, fontSize: bulletFontSize, attrContent: attributedStr)

        self.gunpowderArray.append(bullet)
    }


    func addBullet() {

        guard flyingBulletsNumber <= bulletLabelNumber else {
            return
        }
        
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
        
        // MARK: 不是正确的姿势
        let viewHeight = self.bounds.height == 0.0 ? ScreenWidth : self.bounds.height
        let viewWidth = self.bounds.width == 0.0 ? ScreenWidth : self.bounds.width

        var bulletY: CGFloat = CGFloat(Int(arc4random()) % (Int(viewHeight - 40) / trajectoryNumber)) * CGFloat(trajectoryNumber) + 20
        
        while bulletY == preBulletY {
            bulletY = CGFloat(Int(arc4random()) % (Int(viewHeight - 40) / trajectoryNumber)) * CGFloat(trajectoryNumber) + 20

        }
        
        preBulletY = bulletY
        
        let bulletFrame = CGRectMake(viewWidth, bulletY, bulletSize.width, bulletSize.height)
        bullet.frame = bulletFrame
        
        shoot(bullet: bullet)
    }
    
    private func shoot(bullet bullet: UIView) {
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
