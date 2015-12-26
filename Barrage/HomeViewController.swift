//
//  HomeViewController.swift
//  Barrage
//
//  Created by Cai Linfeng on 12/17/15.
//  Copyright © 2015 Cai Linfeng. All rights reserved.
//


import UIKit

class HomeViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func pushToSecondBarrageViewController(sender: AnyObject) {
        let nextVC = SecondBarrageViewController()
        self.navigationController?.pushViewController(nextVC, animated: true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
}
