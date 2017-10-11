//
//  LCBarrageView.swift
//  danmu
//
//  Created by Cai Linfeng on 11/25/15.
//  Copyright © 2015 Cai Linfeng. All rights reserved.
//

import UIKit

private let ScreenWidth = UIScreen.main.bounds.width
private let ScreenHeight = UIScreen.main.bounds.height

public enum LCBulletType {
    case top
    case roll
    case bottom
}

public protocol LCBarrageViewDelegate: class {

    func barrageViewDidRunOutOfBullets(barrage: LCBarrageView)
}

public struct LCBullet {
    var content: String?
    var color: UIColor?
    var fontSize: CGFloat?
    var attrContent: NSAttributedString?
    var bulletType: LCBulletType = .roll
}

public struct LCTrajectory {
    var locationY: CGFloat
    var coldTime: Int = 0
}

public class LCBarrageView: UIView {

    enum BulletShotMode {
        case random
        case ordered
    }

    public weak var delegate: LCBarrageViewDelegate?

    var rollBulletsShotMode: BulletShotMode = .random
    // The number of CATextLayer used to show bullet
    var bulletLayerNumber: Int = 30

    var blockTopBullets = false
    var blockBottomBullets = false

    var defaultColor = UIColor.white
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

    private var bulletLayerArray: [CATextLayer] = []
    private var ammunitionArray: [LCBullet] = []
    private var backupAmmunitionArray: [LCBullet] = []

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
    private lazy var trajectoriesArray: [LCTrajectory] = []
    private var barrageTimer: Timer?


    // MARK: Life-Cycle

    override public func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.clear
        self.clipsToBounds = true
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
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
        NotificationCenter.default.removeObserver(self)
        print("[LCBarrageView] LCBarrageView Deinit")
    }


    // MARK: Public

    // Process bullets and add bullets to ammunition
    func processBullets(bulletsArray bullets: [LCBullet]?) {
        guard let bullets = bullets, !bullets.isEmpty else {
            return
        }

        NotificationCenter.default.addObserver(self, selector: #selector(orientationChanged), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)

        var bulletColor = defaultColor
        var bulletFontSize = defaultFontSize

        for var bullet in bullets {
            if let attrContent = bullet.attrContent, attrContent.length != 0 {
                ammunitionArray.append(bullet)
            } else if let content = bullet.content, content != "" {

                bulletColor = bullet.color ?? defaultColor
                bulletFontSize = bullet.fontSize ?? defaultFontSize

                let attrDict = [
                    NSAttributedStringKey.foregroundColor: bulletColor,
                    NSAttributedStringKey.font: UIFont.systemFont(ofSize: bulletFontSize)
                    ] as [NSAttributedStringKey : Any]

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

    func addNewBullet(attrContent: NSAttributedString?, bulletType: LCBulletType = .roll) {
        guard let attrContent = attrContent, attrContent.length != 0 else {
            print("[LCBarrageView] Invalid input")
            return
        }

        let bullet = LCBullet(content: nil, color: nil, fontSize: nil, attrContent: attrContent, bulletType: bulletType)
        ammunitionArray.append(bullet)
        backupAmmunitionArray.append(bullet)
    }

    func addNewBullet(content: String?, color: UIColor?, fontSize: CGFloat? = 15.0, bulletType: LCBulletType = .roll) {
        guard let content = content, content != "" else {
            print("[LCBarrageView] Invalid input")
            return
        }

        let bulletColor = color ?? defaultColor
        let bulletFontSize = fontSize ?? defaultFontSize

        let attrDict = [
            NSAttributedStringKey.foregroundColor: bulletColor,
            NSAttributedStringKey.font: UIFont.systemFont(ofSize: bulletFontSize)
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

        barrageTimer = Timer.scheduledTimer(timeInterval:
            shootInterval,
            target: self,
            selector: #selector(addBullets),
            userInfo: nil,
            repeats: true
        )
    }

    func stop() {
        UIView.animate(withDuration: 0.4, animations: {
            self.frame.origin.x = -self.frame.width
        }) { (_) in
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

        guard flyingBulletsNumber <= bulletLayerNumber,
            let bulletLayer = bulletLayerArray.last,
            let lastBullet = ammunitionArray.last else {
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
            ammunitionArray.insert(lastBullet, at: 0)
        } else {
            if ammunitionArray.isEmpty {
                removeTimer()
                delegate?.barrageViewDidRunOutOfBullets(barrage: self)
            }
        }

        let gunpowderStr = bulletLayerStr.string
        var range = NSMakeRange(0, 1)
        let attrDict = bulletLayerStr.attributes(at: 0, effectiveRange: &range)

        let bulletLayerSize = gunpowderStr.size(withAttributes: attrDict)

        switch lastBullet.bulletType {
        case .top:
            shootTopBullet(bulletLayer: bulletLayer, bulletLayerSize: bulletLayerSize)
        case .bottom:
            shootBottomBullet(bulletLayer: bulletLayer, bulletLayerSize: bulletLayerSize)
        case .roll:
            shootRollBullet(bulletLayer: bulletLayer, bulletLayerSize: bulletLayerSize)
        }
    }

    private func shootBottomBullet(bulletLayer: CATextLayer, bulletLayerSize: CGSize) {
        let viewHeight = self.bounds.height

        guard !blockTopBullets else {
            bulletLayerArray.insert(bulletLayer, at: 0)
            return
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        flyingBulletsNumber += 1
        let bulletLayerY: CGFloat = viewHeight - bottomOffset
        let bulletLayerX: CGFloat = 0.5 * (self.bounds.width - bulletLayerSize.width)
        bulletLayer.frame = CGRect(x: bulletLayerX, y: bulletLayerY, width: bulletLayerSize.width, height: bulletLayerSize.height)
        bottomOffset += bulletLayerSize.height
        bottomBulletNumber += 1
        if bottomBulletNumber > 13 - Int(25 * shootInterval) || bottomOffset > viewHeight - 40 {
            bottomOffset = 30
            bottomBulletNumber = 0
        }
        delayBySeconds(seconds: 2.0) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            bulletLayer.frame = .zero
            strongSelf.bulletLayerArray.insert(bulletLayer, at: 0)
            strongSelf.flyingBulletsNumber -= 1
            CATransaction.commit()
        }

    }

    private func shootTopBullet(bulletLayer: CATextLayer, bulletLayerSize: CGSize) {
        let viewHeight = self.bounds.height

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        guard !blockTopBullets else {
            bulletLayerArray.insert(bulletLayer, at: 0)
            return
        }

        flyingBulletsNumber += 1
        let bulletLayerY: CGFloat = topOffset
        let bulletLayerX: CGFloat = 0.5 * (self.bounds.width - bulletLayerSize.width)
        bulletLayer.frame = CGRect(x: bulletLayerX, y: bulletLayerY, width: bulletLayerSize.width, height: bulletLayerSize.height)
        topOffset += bulletLayerSize.height
        topBulletNumber += 1
        if topBulletNumber > 13 - Int(25 * shootInterval) || topOffset > viewHeight - 40 {
            topOffset = 10
            topBulletNumber = 0
        }
        delayBySeconds(seconds: 2.0) { [weak self] in
            guard let strongSelf = self else {
                return
            }
            bulletLayer.frame = .zero
            strongSelf.bulletLayerArray.insert(bulletLayer, at: 0)
            strongSelf.flyingBulletsNumber -= 1
            CATransaction.commit()
        }
    }

    private func forceCooling() {
        for i in 0..<trajectoryNumber {
            trajectoriesArray[i].coldTime -= 1
        }
    }

    private func shootRollBullet(bulletLayer: CATextLayer, bulletLayerSize: CGSize) {
        let viewWidth = self.layer.bounds.width

        guard let bulletTextStr = bulletLayer.string as? NSAttributedString else {
            return
        }

        let bulletText = bulletTextStr.string

        for i in 0..<trajectoryNumber {
            if trajectoriesArray[i].coldTime != 0 {
                trajectoriesArray[i].coldTime -= 1
            }
        }

        var pickedTrajectory: Int

        switch rollBulletsShotMode {
        case .random:
            var pickTime: Int = 0
            pickedTrajectory = Int(arc4random_uniform(UInt32(trajectoryNumber)))
            while trajectoriesArray[pickedTrajectory].coldTime > 0 {
                pickedTrajectory = Int(arc4random_uniform(UInt32(trajectoryNumber)))
                pickTime += 1
                if pickTime % trajectoryNumber == 0 {
                    forceCooling()
                }
            }
        case .ordered:
            pickedTrajectory = 0
            while trajectoriesArray[pickedTrajectory].coldTime > 0 {
                pickedTrajectory += 1
                if pickedTrajectory >= trajectoryNumber - 1 {
                    pickedTrajectory = 0
                    forceCooling()
                }
            }
        }

        trajectoriesArray[pickedTrajectory].coldTime = bulletText.characters.count / 2
        let bulletLayerY = trajectoriesArray[pickedTrajectory].locationY

        let bulletFrame = CGRect(x: viewWidth, y: bulletLayerY, width: bulletLayerSize.width, height: bulletLayerSize.height)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bulletLayer.frame = bulletFrame
        bulletLayer.anchorPoint = CGPoint(x: 0.0, y: 0.0)
        bulletLayer.position = CGPoint(x: viewWidth, y: bulletLayerY)
        let duration: CGFloat = CGFloat(arc4random() % 10) / 10.0 + rollOutDuration

        flyingBulletsNumber += 1

        CATransaction.setCompletionBlock { [weak self] () -> Void in
            bulletLayer.frame = .zero
            self?.bulletLayerArray.insert(bulletLayer, at: 0)
            self?.flyingBulletsNumber -= 1
        }

        let transitionAnimation = CABasicAnimation(keyPath: "position.x")
        transitionAnimation.fromValue = bulletFrame.origin.x
        transitionAnimation.toValue = -bulletLayerSize.width
        transitionAnimation.duration = Double(duration)
        transitionAnimation.repeatCount = 0
        transitionAnimation.isRemovedOnCompletion = true
        bulletLayer.add(transitionAnimation, forKey: nil)
        CATransaction.commit()
    }
}

private func delayBySeconds(seconds: Double, delayedCode: @escaping () -> Void) {

    DispatchQueue.main.asyncAfter(deadline: DispatchTime.now() + seconds) {
        delayedCode()
    }
}

