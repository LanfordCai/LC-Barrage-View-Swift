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

    @IBOutlet weak var barrageView: LCBarrageView!

    @IBOutlet weak private var commentTextLabel: UITextField!

    @IBOutlet weak private var fireButton: UIButton!

    @IBOutlet weak private var shootIntervalLabel: UILabel!
    @IBOutlet weak private var rollOutDrationLabel: UILabel!

    private let colors: [UIColor] = [
        .red,
        .white,
        .blue,
        .brown,
        .purple,
        .green,
        .magenta,
        .lightGray,
        .orange,
        .yellow
    ]


    // MARK: Life-Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configuration()
        generateComments()
    }

    deinit {
        barrageView.stop()
        NotificationCenter.default.removeObserver(self)
    }


    // MARK: Helpers
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        editTextField.resignFirstResponder()
    }


    // MARK: Private Methods

    private func configuration() {
        commentTextLabel.delegate = self
        barrageView.delegate = self
        barrageView.rollBulletsShotMode = .random

        colorBar = [redButton, yellowButton, greenButton, blueButton]
        fontBar = [smallFontButton, largeFontButton]
        bulletTypeBar = [topTypeButton, rollTypeButton, bottomTypeButton]

        smallFontButton.isSelected = true
        chosedFontSize = 15.0
        rollTypeButton.isSelected = true
        chosedType = .roll

        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillChangeFrame), name: NSNotification.Name.UIKeyboardWillChangeFrame, object: nil)
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

            for _ in 0..<(bulletTypeFactor + 3) {
                comment += "Biu~"
            }

            colorPicker = arc4random_uniform(10)

            // Add Content, fontSize and Color to make bullet
            var bullet = LCBullet()
            bullet.content = comment
            bullet.fontSize = fontSize
            bullet.color = colors[Int(colorPicker)]

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
                bullet.bulletType = .top
            case 1:
                bullet.bulletType = .roll
            default:
                bullet.bulletType = .bottom
            }

            commentsArray.append(bullet)
        }

        barrageView.bulletLayerNumber = 20

        barrageView.processBullets(bulletsArray: commentsArray)
    }

    @objc func barrageViewBeTapped() {
        editTextField.resignFirstResponder()
    }


    // MARK: Actions

    @IBAction func fire(_ sender: UIButton) {
        if fireButton.isSelected {
            barrageView.stop()
        } else {
            barrageView.fire()
        }

        fireButton.isSelected = !fireButton.isSelected
    }


    @IBAction func sendComment(_ sender: AnyObject) {
        textFieldShouldReturn(commentTextLabel)
    }

    @IBAction func colorButtonTapped(_ sender: UIButton) {
        sender.isSelected = !sender.isSelected
        chosedColor = sender.isSelected ? sender.backgroundColor : UIColor.blue

        for button in colorBar {
            if button.tag != sender.tag {
                button.isSelected = false
            }
        }
    }

    @IBAction func fontButtonTapped(_ sender: AnyObject?) {
        for button in fontBar {
            button.isSelected = !button.isSelected
            if button.isSelected {
                chosedFontSize = button.tag == 201 ? 15.0 : 20.0
            }
        }
    }

    @IBAction func bulletTypeButtonTapped(_ bulletTypeButton: UIButton) {
        bulletTypeButton.isSelected = true

        switch bulletTypeButton.tag {
        case 301:
            chosedType = .top
        case 303:
            chosedType = .bottom
        default:
            chosedType = .roll
        }

        for button in bulletTypeBar {
            if button.tag != bulletTypeButton.tag {
                button.isSelected = false
            }
        }
    }

    @IBAction func rollOutDurationBeLonger(_ sender: AnyObject) {
        barrageView.rollOutDuration *= 2.0
        rollOutDrationLabel.text = "\(barrageView.rollOutDuration)"
    }

    @IBAction func rollOutDurationBeShorter(_ sender: AnyObject) {
        barrageView.rollOutDuration /= 2.0
        rollOutDrationLabel.text = "\(barrageView.rollOutDuration)"
    }

    @IBAction func blockTopBullets(_ blockTopButton: UIButton) {
        blockTopButton.isSelected = !blockTopButton.isSelected
        barrageView.blockTopBullets = !barrageView.blockTopBullets
    }

    @IBAction func blockBottomBullets(_ blockBottomButton: UIButton) {
        blockBottomButton.isSelected = !blockBottomButton.isSelected
        barrageView.blockBottomBullets = !barrageView.blockBottomBullets
    }


    @IBAction func shootIntervalBeLonger(_ sender: AnyObject) {
        barrageView.shootInterval += 0.1
        shootIntervalLabel.text = "\(barrageView.shootInterval)"
    }

    @IBAction func shootIntervalBeShorter(_ sender: AnyObject) {
        barrageView.shootInterval -= 0.1
        shootIntervalLabel.text = "\(barrageView.shootInterval)"
    }

    @IBAction func circularShotChanged(_ sender: UISwitch) {
        barrageView.circularShot = !barrageView.circularShot
    }

    @IBAction func rollBulletsShotModeChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0:
            barrageView.rollBulletsShotMode = .random
        default:
            barrageView.rollBulletsShotMode = .ordered
        }
    }

}


// MARK: BarrageViewDelegate Methods

extension FirstBarrageViewController: LCBarrageViewDelegate {

    func barrageViewDidRunOutOfBullets(barrage: LCBarrageView) {
        fireButton.isSelected = false
        barrageView.stop()
        barrageView.reloadBullets()
    }
}


// MARK: - TextFieldDelegate Methods

extension FirstBarrageViewController: UITextFieldDelegate {

    @objc func keyboardWillChangeFrame(note: NSNotification) {
        guard let keyboardFrame = (note.userInfo![UIKeyboardFrameEndUserInfoKey] as AnyObject).cgRectValue else {
            return
        }

        let distance = keyboardFrame.origin.y - UIScreen.main.bounds.height

        self.editViewBottomConstraint.constant = -distance
        UIView.animate(withDuration: 0.3) { () -> Void in
            self.view.layoutIfNeeded()
        }
    }

    @discardableResult
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {

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

