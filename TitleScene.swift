//
//  TitleScene.swift
//  scrollGame
//
//  Created by 保立馨 on 2016/06/06.
//  Copyright © 2016年 Kaoru Hotate. All rights reserved.
//

import SpriteKit
import RealmSwift

class TitleScene: SKScene {

	// Realmのインスタンスを取得
	let realm = try! Realm()

	override func didMoveToView(view: SKView) {
		self.backgroundColor = .whiteColor()
		
		// TODO: タイトル出力（タイトル決まらないからずっとやらなそう）
		
		// スタートラベル出力
		setupStartLabel()
		
		// ハイスコア出力
		setupHighScoreLabel()

	}

	// スタートラベル出力
	func setupStartLabel() {
		let startLabel = SKLabelNode(fontNamed: "Copperplate")
		startLabel.text = "Start"
		startLabel.fontSize = 40
		startLabel.fontColor = UIColor.blackColor()
		startLabel.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2)
		self.addChild(startLabel)
	}
	
	// ハイスコア出力
	func setupHighScoreLabel() {
		let bestRecord = realm.objects(Record).sorted("score", ascending: false).first
		if let record = bestRecord {
			let recordLabel = SKLabelNode(fontNamed: "Copperplate")
			recordLabel.text = "HighScore : " + String(record.score)
			recordLabel.fontSize = 30
			recordLabel.fontColor = UIColor.blackColor()
			recordLabel.position = CGPoint(x: self.frame.size.width / 2, y: self.frame.size.height / 2.5)
			self.addChild(recordLabel)
			
		}
	}

	// 画面押下時
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		if let _ = touches.first as UITouch? {
			let scene = GameScene(size: self.scene!.size)
			scene.scaleMode = SKSceneScaleMode.AspectFill
			self.view!.presentScene(scene)
		}
	}
	
	override func update(currentTime: CFTimeInterval) {}

}
