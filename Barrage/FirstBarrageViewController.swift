//
//  FirstBarrageViewController.swift
//  Barrage
//
//  Created by Cai Linfeng on 12/16/15.
//  Copyright © 2015 Cai Linfeng. All rights reserved.
//

import UIKit


class FirstBarrageViewController: UIViewController {

    @IBOutlet weak private var editView: UIView!
    @IBOutlet weak private var editViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak private var editTextField: UITextField!
    @IBOutlet weak private var smallFontButton: UIButton!
    @IBOutlet weak private var largeFontButton: UIButton!
    private var fontBar = [UIButton]()
    private var chosedFontSize: CGFloat?

    @IBOutlet weak private var redButton: UIButton!
    @IBOutlet weak private var yellowButton: UIButton!
    @IBOutlet weak private var greenButton: UIButton!
    @IBOutlet weak private var blueButton: UIButton!
    private var colorBar = [UIButton]()
    private var chosedColor: UIColor?

    @IBOutlet weak private var topTypeButton: UIButton!
    @IBOutlet weak private var rollTypeButton: UIButton!
    @IBOutlet weak private var bottomTypeButton: UIButton!
    private var bulletTypeBar = [UIButton]()
    private var chosedType: LCBulletType?

    @IBOutlet weak private var barrageView: LCBarrageView!

    @IBOutlet weak private var commentTextLabel: UITextField!

    @IBOutlet weak private var fireButton: UIButton!

    @IBOutlet weak private var shootIntervalLabel: UILabel!
    @IBOutlet weak private var rollOutDrationLabel: UILabel!

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


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configuration()
        generateComments()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    deinit {
        barrageView.stop()
        NSNotificationCenter.defaultCenter().removeObserver(self)
        print("FirstVC Deinit")
    }


    // MARK: Helpers

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        editTextField.resignFirstResponder()
    }


    // MARK: Private Methods


    private func configuration() {
        commentTextLabel.delegate = self
        barrageView.delegate = self

        colorBar = [redButton, yellowButton, greenButton, blueButton]
        fontBar = [smallFontButton, largeFontButton]
        bulletTypeBar = [topTypeButton, rollTypeButton, bottomTypeButton]

        smallFontButton.selected = true
        chosedFontSize = 15.0
        rollTypeButton.selected = true
        chosedType = .Roll

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
    }

    private func generateComments() {
        var fontSizeFactor: UInt32
        var commentsArray = [LCBullet]()
        var bulletTypeFactor: UInt32
        var colorPicker: UInt32

        for i in 0..<40 {
            var comment = "Bullet\(i)"

            fontSizeFactor = arc4random_uniform(2)
            let fontSize: CGFloat = fontSizeFactor == 0 ? 15.0 : 20.0

            for _ in 0..<(fontSizeFactor + 2) {
                comment += "Biu"
            }

            bulletTypeFactor = arc4random_uniform(3)

            for _ in 0..<(bulletTypeFactor + 2) {
                comment += "Biu~"
            }

            colorPicker = arc4random_uniform(10)

            // Add Content, fontSize and Color to make bullet
            var bullet = LCBullet()
            bullet.content = comment
            bullet.fontSize = fontSize
            bullet.color = colorArray[Int(colorPicker)]

            // Add attributedString directly
//            var bullet = LCBullet()
//            let attrDict = [NSForegroundColorAttributeName: colorArray[Int(colorPicker)],
//                NSFontAttributeName: UIFont.systemFontOfSize(fontSize)
//            ]
//
//            let commentStr = NSMutableAttributedString(string: comment)
//            commentStr.addAttributes(attrDict, range: NSMakeRange(0, commentStr.length))
//            bullet.attrContent = commentStr

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

        barrageView.bulletLabelNumber = 60

        barrageView.processBullets(bulletsArray: commentsArray)
    }

    @objc func barrageViewBeTapped() {
        editTextField.resignFirstResponder()
    }


    // MARK: Actions

    @IBAction func fire(fireButton: UIButton) {
        if fireButton.selected {
            barrageView.stop()
        } else {
            barrageView.fire()
        }

        fireButton.selected = !fireButton.selected
    }

    @IBAction func sendComment(sender: AnyObject) {
        textFieldShouldReturn(commentTextLabel)
    }

    @IBAction func colorButtonTapped(colorButton: UIButton) {
        colorButton.selected = !colorButton.selected
        chosedColor = colorButton.selected ? colorButton.backgroundColor : UIColor.blueColor()

        for button in colorBar {
            if button.tag != colorButton.tag {
                button.selected = false
            }
        }
    }

    @IBAction func fontButtonTapped(sender: AnyObject?) {
        for button in fontBar {
            button.selected = !button.selected
            if button.selected {
                chosedFontSize = button.tag == 201 ? 15.0 : 20.0
            }
        }
    }

    @IBAction func bulletTypeButtonTapped(bulletTypeButton: UIButton) {
        bulletTypeButton.selected = true

        switch bulletTypeButton.tag {
        case 301:
            chosedType = .Top
        case 303:
            chosedType = .Bottom
        default:
            chosedType = .Roll
        }

        for button in bulletTypeBar {
            if button.tag != bulletTypeButton.tag {
                button.selected = false
            }
        }
    }

    @IBAction func rollOutDurationBeLonger(sender: AnyObject) {
        barrageView.rollOutDuration *= 2.0
        rollOutDrationLabel.text = "\(barrageView.rollOutDuration)"
    }

    @IBAction func rollOutDurationBeShorter(sender: AnyObject) {
        barrageView.rollOutDuration /= 2.0
        rollOutDrationLabel.text = "\(barrageView.rollOutDuration)"
    }

    @IBAction func blockTopBullets(blockTopButton: UIButton) {
        blockTopButton.selected = !blockTopButton.selected
        barrageView.blockTopBullets = !barrageView.blockTopBullets
    }

    @IBAction func blockBottomBullets(blockBottomButton: UIButton) {
        blockBottomButton.selected = !blockBottomButton.selected
        barrageView.blockBottomBullets = !barrageView.blockBottomBullets
    }


    @IBAction func shootIntervalBeLonger(sender: AnyObject) {
        barrageView.shootInterval += 0.1
        shootIntervalLabel.text = "\(barrageView.shootInterval)"
    }

    @IBAction func shootIntervalBeShorter(sender: AnyObject) {
        barrageView.shootInterval -= 0.1
        shootIntervalLabel.text = "\(barrageView.shootInterval)"
    }

    @IBAction func circularShotChanged(sender: UISwitch) {
        barrageView.circularShot = !barrageView.circularShot
    }


}


// MARK: BarrageViewDelegate Methods

extension FirstBarrageViewController: LCBarrageViewDelegate {

    func barrageViewDidRunOutOfBullets(barrage: LCBarrageView) {
        fireButton.selected = false
        barrageView.reloadBullets()
    }
}

// MARK: - TextFieldDelegate Methods


extension FirstBarrageViewController: UITextFieldDelegate {

    @objc func keyboardWillChangeFrame(note: NSNotification) {
        let keyboardFrame = note.userInfo![UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        let distance = keyboardFrame.origin.y - ScreenHeight

        self.editViewBottomConstraint.constant = -distance
        UIView.animateWithDuration(0.3) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {

        // Add Content, fontSize and Color to make bullet
        barrageView.addNewBullet(content: textField.text, color: chosedColor, fontSize: chosedFontSize, bulletType: chosedType!)

        // Add attributedString directly
//        let attrDict = [NSForegroundColorAttributeName: chosedColor ?? UIColor.redColor(),
//            NSFontAttributeName: UIFont.systemFontOfSize(chosedFontSize ?? 17.0)
//        ]
//
//        let commentStr = NSMutableAttributedString(string: textField.text!)
//        commentStr.addAttributes(attrDict, range: NSMakeRange(0, commentStr.length))
//
//        barrageView.addNewBullet(attrContent: commentStr)

        textField.text = ""
        textField.resignFirstResponder()
        return true
    }
}

