//
//  SecondBarrageViewController.swift
//  Barrage
//
//  Created by Cai Linfeng on 12/17/15.
//  Copyright © 2015 Cai Linfeng. All rights reserved.
//

import UIKit

class SecondBarrageViewController: UIViewController {

    private let colorArray = [
        UIColor.redColor(),
        UIColor.whiteColor(),
        UIColor.blueColor(),
        UIColor.brownColor(),
        UIColor.purpleColor(),
        UIColor.greenColor(),
        UIColor.magentaColor(),
        UIColor.orangeColor(),
        UIColor.yellowColor()
    ]

    // The Label used to load bullets(comments)
    // Note: When the shotInterval and the rollOutDuration of bullet are really short, we may need a number of labels, which is larger than the number of bullets(comments), to hold the comments for the comments would be present circularly in Default. 
    // TODO: 取消循环模式
    private let bulletLayerNumber: Int = 60
    // The number of bullet(comment)
    private let bulletNumber: Int = 40
    private let smallFontSize: CGFloat = 15.0
    private let largeFontSize: CGFloat = 20.0

    private var barrageView: LCBarrageView?


    // MARK: Life-Cycle Methods

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = UIColor.whiteColor()

        setupBarrage()
    }

    deinit {
        barrageView?.stop()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }


    // MARK: Private Methods

    private func setupBarrage() {
        let testView = UIView(frame: CGRect(x: 0, y: 64, width: ScreenWidth, height: ScreenWidth))
        testView.backgroundColor = UIColor.blackColor()
        view.addSubview(testView)

        barrageView = LCBarrageView()
        testView.addSubview(barrageView!)
        barrageView!.translatesAutoresizingMaskIntoConstraints = false

        let width = NSLayoutConstraint(
            item: barrageView!,
            attribute: .Width,
            relatedBy: .Equal,
            toItem: testView,
            attribute: .Width,
            multiplier: 1.0,
            constant: 0)

        let height = NSLayoutConstraint(
            item: barrageView!,
            attribute: .Height,
            relatedBy: .Equal,
            toItem: testView,
            attribute: .Height,
            multiplier: 1.0,
            constant: 0)

        let top = NSLayoutConstraint(
            item: barrageView!,
            attribute: .Top,
            relatedBy: .Equal,
            toItem: testView,
            attribute: .Top,
            multiplier: 1.0,
            constant: 0)

        let leading = NSLayoutConstraint(
            item: barrageView!,
            attribute: .Leading,
            relatedBy: .Equal,
            toItem: testView,
            attribute: .Leading,
            multiplier: 1.0,
            constant: 0)

        testView.addConstraints([width, height, top, leading])

        generateComments()

        let fireButton = UIButton(frame: CGRectMake(0, ScreenWidth + 64, ScreenWidth, 50))
        fireButton.setTitle("Fire", forState: .Normal)
        fireButton.setTitle("Stop", forState: .Selected)
        fireButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        fireButton.backgroundColor = UIColor.redColor()
        fireButton.addTarget(self, action: "barrageOnOrOff:", forControlEvents: .TouchUpInside)
        view.addSubview(fireButton)
    }

    private func generateComments() {
        var fontSizeFactor: UInt32
        var commentsArray = [LCBullet]()
        var bulletTypeFactor: UInt32
        var colorPicker: UInt32

        for i in 0..<bulletNumber {
            var comment = "Bullet\(i)"

            fontSizeFactor = arc4random_uniform(2)
            let fontSize: CGFloat = fontSizeFactor == 0 ? smallFontSize : largeFontSize

            for _ in 0..<(fontSizeFactor + 2) {
                comment += "Biu"
            }

            bulletTypeFactor = arc4random_uniform(3)

            for _ in 0..<(bulletTypeFactor + 2) {
                comment += "Biu~"
            }

            colorPicker = arc4random_uniform(UInt32(colorArray.count))

            var bullet = LCBullet()
            bullet.content = comment
            bullet.fontSize = fontSize
            bullet.color = colorArray[Int(colorPicker)]

            switch bulletTypeFactor {
            case 0:
                bullet.bulletType = .Top
            case 1:
                bullet.bulletType = .Roll
            default:
                bullet.bulletType = .Bottom
            }

            commentsArray.append(bullet)
        }

        barrageView!.bulletLayerNumber = bulletLayerNumber
        barrageView!.processBullets(bulletsArray: commentsArray)
    }

    @objc func barrageOnOrOff(button: UIButton) {

        button.selected = !button.selected
        if button.selected {
            barrageView?.fire()
        } else {
            barrageView?.stop()
        }
    }
}
