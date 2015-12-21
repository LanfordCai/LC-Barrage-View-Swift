//
//  FirstBarrageViewController.swift
//  Barrage
//
//  Created by CaiGavin on 12/16/15.
//  Copyright © 2015 CaiGavin. All rights reserved.
//

import UIKit

class FirstBarrageViewController: UIViewController {
    @IBOutlet weak var editView: UIView!
    @IBOutlet weak var editViewBottomConstraint: NSLayoutConstraint!

    @IBOutlet weak var editTextField: UITextField!
    @IBOutlet weak var smallFontButton: UIButton!
    @IBOutlet weak var largeFontButton: UIButton!
    var fontBar = [UIButton]()
    var chosedFontSize: CGFloat?

    @IBOutlet weak var redButton: UIButton!
    @IBOutlet weak var yellowButton: UIButton!
    @IBOutlet weak var greenButton: UIButton!
    @IBOutlet weak var blueButton: UIButton!
    var colorBar = [UIButton]()
    var chosedColor: UIColor?

    @IBOutlet weak var topTypeButton: UIButton!
    @IBOutlet weak var rollTypeButton: UIButton!
    @IBOutlet weak var bottomTypeButton: UIButton!
    var bulletTypeBar = [UIButton]()
    var chosedType: BulletType?

    @IBOutlet weak var barrageView: LCBarrageView!

    @IBOutlet weak var commentTextLabel: UITextField!

    @IBOutlet weak var fireButton: UIButton!

    @IBOutlet weak var shootIntervalLabel: UILabel!
    @IBOutlet weak var rollOutDrationLabel: UILabel!

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

        NSNotificationCenter.defaultCenter().addObserver(self, selector: "keyboardWillChangeFrame:", name: UIKeyboardWillChangeFrameNotification, object: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }


    // MARK: Methods

    override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
        super.touchesBegan(touches, withEvent: event)
        editTextField.resignFirstResponder()
    }

    private func configuration() {
        commentTextLabel.delegate = self
        colorBar = [redButton, yellowButton, greenButton, blueButton]
        fontBar = [smallFontButton, largeFontButton]
        bulletTypeBar = [topTypeButton, rollTypeButton, bottomTypeButton]
        smallFontButton.selected = true
        chosedFontSize = 15.0

        rollTypeButton.selected = true
        chosedType = .Roll
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

        barrageView.bulletLabelNumber = 60

        barrageView.processBullets(bulletsArray: commentsArray)
    }

    dynamic private func barrageViewBeTapped() {
        editTextField.resignFirstResponder()
    }

    dynamic private func keyboardWillChangeFrame(note: NSNotification) {
        let keyboardFrame = note.userInfo![UIKeyboardFrameEndUserInfoKey]!.CGRectValue
        let distance = keyboardFrame.origin.y - ScreenHeight

        self.editViewBottomConstraint.constant = -distance
        UIView.animateWithDuration(0.3) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }


    // MARK: Actions

    @IBAction func fire(sender: AnyObject) {
        if let fireButton = sender as? UIButton {
            if fireButton.selected {
                barrageView.stop()
            } else {
                barrageView.fire()
            }

            fireButton.selected = !fireButton.selected
        }
    }

    @IBAction func sendComment(sender: AnyObject) {
        textFieldShouldReturn(commentTextLabel)
    }

    @IBAction func colorButtonTapped(sender: AnyObject?) {
        guard let colorButton = sender as? UIButton else {
            return
        }

        colorButton.selected = !colorButton.selected
        chosedColor = colorButton.selected ? colorButton.backgroundColor : UIColor.blueColor()

        for button in colorBar {
            if button.tag != colorButton.tag {
                button.selected = false
            }
        }
    }

    @IBAction func fontButtonTapped(sender: AnyObject?) {
        guard let _ = sender as? UIButton else {
            return
        }

        for button in fontBar {
            button.selected = !button.selected
            if button.selected {
                chosedFontSize = button.tag == 201 ? 15.0 : 20.0
            }
        }
    }

    @IBAction func bulletTypeButtonTapped(sender: AnyObject?) {
        guard let bulletTypeButton = sender as? UIButton else {
            return
        }

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

    @IBAction func blockTopBullets(sender: AnyObject) {
        guard let blockTopButton = sender as? UIButton else {
            return
        }

        blockTopButton.selected = !blockTopButton.selected
        barrageView.blockTopBullets = !barrageView.blockTopBullets
    }

    @IBAction func blockBottomBullets(sender: AnyObject) {
        guard let blockBottomButton = sender as? UIButton else {
            return
        }

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

}

extension FirstBarrageViewController: UITextFieldDelegate {


    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let text = textField.text else {
            print("No input")
            return false
        }

        barrageView.addNewBullet(content: text, color: chosedColor, fontSize: chosedFontSize, bulletType: chosedType!)
        textField.text = ""
        textField.resignFirstResponder()
        return true
    }
}

