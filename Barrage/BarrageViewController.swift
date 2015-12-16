//
//  BarrageViewController.swift
//  Barrage
//
//  Created by CaiGavin on 12/16/15.
//  Copyright © 2015 CaiGavin. All rights reserved.
//

import UIKit

class BarrageViewController: UIViewController {


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

    @IBOutlet weak var barrageView: LCBarrageView!

    @IBOutlet weak var commentTextLabel: UITextField!

    @IBOutlet weak var fireButton: UIButton!

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        configuration()
        generateComments()
    }

    private func configuration() {
        commentTextLabel.delegate = self
        colorBar = [redButton, yellowButton, greenButton, blueButton]
        fontBar = [smallFontButton, largeFontButton]
        smallFontButton.selected = true
        chosedFontSize = 15.0
    }

    private func generateComments() {
        var fontSizeFactor: UInt32
        var commentsArray = [LCBullet]()
        for i in Range(start: 0, end: 10) {
            let comment = "Bullet\(i)"

            fontSizeFactor = arc4random_uniform(2)
            let fontSize: CGFloat = fontSizeFactor == 0 ? 15.0 : 20.0

            var bullet = LCBullet()
            bullet.content = comment
            bullet.fontSize = fontSize

            commentsArray.append(bullet)
        }

        barrageView.bulletLabelNumber = 10
//        barrageView.

        barrageView.processBullets(bulletsArray: commentsArray)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

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

    @IBAction func barrageSpeedUp(sender: AnyObject) {
        barrageView.shootInterval -= 0.1
    }

    @IBAction func barrageSpeedDown(sender: AnyObject) {
        barrageView.shootInterval += 0.1
        
    }
}

extension BarrageViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(textField: UITextField) {
    }

    func textFieldShouldReturn(textField: UITextField) -> Bool {
        guard let text = textField.text else {
            print("No input")
            return false
        }

        print("Ready to loadNewBullet")
        barrageView.loadNewBullet(contentStr: text, color: chosedColor, fontSize: chosedFontSize)

        return true
    }
}

