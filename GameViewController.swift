//
//  ViewController.swift
//  scrollGame
//
//  Created by 保立馨 on 2016/06/02.
//  Copyright © 2016年 Kaoru Hotate. All rights reserved.
//

import UIKit
import SpriteKit

class GameViewController: UIViewController {

	override func viewDidLoad() {
		super.viewDidLoad()
		
		let scene = TitleScene()
		
		let skView = self.view as! SKView
		skView.showsFPS = true
		skView.showsNodeCount = true
		
		skView.ignoresSiblingOrder = false
		scene.scaleMode = .AspectFill
		scene.size = skView.frame.size
				
		skView.presentScene(scene)
		
	}

	override func shouldAutorotate() -> Bool {
		return true
	}
	
	override func supportedInterfaceOrientations() -> UIInterfaceOrientationMask {
		return UIInterfaceOrientationMask.AllButUpsideDown
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}

	override func prefersStatusBarHidden() -> Bool {
		return true
	}

}

