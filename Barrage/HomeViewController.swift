//
//  HomeViewController.swift
//  Barrage
//
//  Created by CaiGavin on 12/17/15.
//  Copyright © 2015 CaiGavin. All rights reserved.
//


// TODO: 屏幕旋转后重新生成弹道

import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }
    @IBAction func pushToSecondBarrageViewController(sender: AnyObject) {
        let nextVC = SecondBarrageViewController()
        self.navigationController?.pushViewController(nextVC, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
