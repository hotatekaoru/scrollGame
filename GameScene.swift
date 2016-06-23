//
//  GameScene.swift
//  scrollGame
//
//  Created by 保立馨 on 2016/06/02.
//  Copyright © 2016年 Kaoru Hotate. All rights reserved.
//

import SpriteKit
import RealmSwift

class GameScene: SKScene, SKPhysicsContactDelegate {

	/* MARK: 定数定義 */
	struct Constants {
		// Player画像
		static let PlayerImages = ["player1", "player2", "player3", "player4"]
	}

	// 衝突の判定につかうBitMask
	struct ColliderType {
		// プレイキャラに設定するカテゴリ
		static let Player: UInt32 = (1 << 0)
		// 地面に設定するカテゴリ
		static let Ground: UInt32  = (1 << 1)
		// 壁に設定するカテゴリ
		static let Wall: UInt32  = (1 << 2)
	}
	
	/* MARK: 変数定義 */
	// スクリーンの枠外判定を行うノード
	var screenNode: SKNode!
	// プレイキャラ以外の移動オブジェクトを追加するノード
	var baseNode: SKNode!
	// プレイキャラ
	var player: SKSpriteNode!
	// ゲームオーバーフラグ
	var gameOver: Bool = false
	// 更新処理用タイム
	var last:CFTimeInterval!
	// 地面の高さを退避するための変数
	var escapeHeight : CGFloat?
	// スコアを表示するラベル
	var scoreLabelNode: SKLabelNode!
	// スコアの内部変数
	var score: Int!
	// スピードアップ
	var speedUpCount: Int = 0
	// Realmのインスタンスを取得
	let realm = try! Realm()
	
	// ジャンプ可能状況
	enum Jump {
		// 地面着地状態
		case Ground
		// 空中状態
		case Air
		// 二度ジャンプ実施後
		case Jumped
	}
	var jump: Jump = Jump.Ground

	/* MARK: - 関数定義 */
	override func didMoveToView(view: SKView) {
		// 物理シミュレーションを設定
		self.physicsWorld.gravity = CGVector(dx: 0.0, dy: -3.0)
		self.physicsWorld.contactDelegate = self
		
		// 背景を白色に設定
		self.backgroundColor = .whiteColor()
		
		// スコアを初期化
		score = 0

		// 全ノードの親となるノードを生成
		baseNode = SKNode()
		baseNode.speed = 1.7
		self.addChild(baseNode)
		
		// 地面を構築
		self.setupGround()
		// プレイキャラを構築
		self.setupPlayer()
		// スコアラベルの構築
		self.setupScoreLabel()
		// TODO: 音楽
		self.addChild(SKAudioNode(fileNamed: "bgm.m4a"))
	}
	
	// 地面を構築
	func setupGround() {
		let ground = SKTexture(imageNamed: "ground")
		ground.filteringMode = .Nearest
		
		// 初期表示の地面を構築
		let needNumber = 3.0 + (self.frame.size.width / ground.size().width)
		
		let moveGroundAnim = SKAction.moveByX(-ground.size().width, y: 0.0, duration: NSTimeInterval(ground.size().width / 100.0))
		let repeatGroundAnim = SKAction.repeatActionForever(SKAction.sequence([moveGroundAnim]))
		
		for i in 0 ..< Int(needNumber) {
			let sprite = SKSpriteNode(texture: ground)
			sprite.position = CGPoint(x: CGFloat(i) * sprite.size.width, y: sprite.size.height / 2.0)
			
			// 物理シミュレーションを設定
			sprite.physicsBody = SKPhysicsBody(texture: ground, size: ground.size())
			sprite.physicsBody?.dynamic = false
			sprite.physicsBody?.categoryBitMask = ColliderType.Ground
			sprite.runAction(repeatGroundAnim)
			baseNode.addChild(sprite)
		}
	}
	
	// 引数の確率(0〜1)に合わせて、truwを返却する
	func getRundom(rate: Double) -> Bool {
		return arc4random_uniform(UInt32(1 / rate)) == 0
	}

	// プレイキャラを構築
	func setupPlayer() {
		// Playerのパラパラアニメーション作成に必要なSKTextureクラスの配列を定義
		var playerTexture = [SKTexture]()
		// 画像を読み込む
		for imageName in Constants.PlayerImages {
			let texture = SKTexture(imageNamed: imageName)
			texture.filteringMode = .Linear
			playerTexture.append(texture)
		}
		
		// アニメーションを作成
		let playerAnimation = SKAction.animateWithTextures(playerTexture, timePerFrame: 0.2)
		let loopAnimation = SKAction.repeatActionForever(playerAnimation)
		
		player = SKSpriteNode(texture: playerTexture[0])
		player.position = CGPoint(x: self.frame.size.width * 0.25, y: self.frame.size.height * 0.8)
		player.runAction(loopAnimation)
		
		// 物理シミュレーションを設定
		player.physicsBody = SKPhysicsBody(texture: playerTexture[0], size: playerTexture[0].size())
		player.physicsBody?.dynamic = true
		player.physicsBody?.allowsRotation = false
		
		// 衝突判定の設定
		player.physicsBody?.categoryBitMask = ColliderType.Player
		player.physicsBody?.collisionBitMask = ColliderType.Ground | ColliderType.Wall
		player.physicsBody?.contactTestBitMask = ColliderType.Ground | ColliderType.Wall
		
		self.addChild(player)
	}

	// スコアラベルを構築
	func setupScoreLabel() {
		// フォント名"Arial Bold"でラベル名を作成
		scoreLabelNode = SKLabelNode(fontNamed: "Arial Bold")
		scoreLabelNode.fontColor = UIColor.blackColor()
		scoreLabelNode.position = CGPoint(x: self.frame.width / 1.4, y: self.frame.size.height / 1.1)
		scoreLabelNode.zPosition = 100.0
		scoreLabelNode.text = String("score : \(score)")
		
		self.addChild(scoreLabelNode)
	}
	
	// MARK: 更新処理
	override func update(currentTime: CFTimeInterval) {
		// lastが未定義ならば、今の時間を入れる。
		last = last ?? currentTime

		// プレイヤー位置チェック
		checkPlayerLocation()

		let timeInterval = 0.6 / Double(baseNode.speed)
		if last + timeInterval <= currentTime {
			// 地面作成
			setupNewGround()

			if !gameOver {
				// スコア加算
				scoreUp()
				// スピードアップ
				speedUp()
			}

			last = currentTime
		}
	}
	
	// プレイヤー位置チェック
	func checkPlayerLocation() {
		if !gameOver && !(0.23 ... 0.27 ~= Double(player.position.x / self.frame.size.width)) {
			let movePlayer = SKAction.moveTo(CGPointMake(self.frame.size.width * 0.25, player.position.y + CGFloat(1.0)), duration: 0.01)
			player.runAction(movePlayer)
		}
	}
	
	// 地面作成
	func setupNewGround() {

		let ground = SKTexture(imageNamed: "ground")
		ground.filteringMode = .Nearest
		// 移動する距離を算出
		let distanceToMove = CGFloat(self.frame.size.width + 3.0 * ground.size().width)
		
		let moveAnim = SKAction.moveByX(-distanceToMove, y: 0.0, duration: NSTimeInterval(distanceToMove / 100.0))
		let removeAnim = SKAction.removeFromParent()
		let groundAnim = SKAction.sequence([moveAnim, removeAnim])
		
		// 新しい地面を生成するメソッドを呼び出すアニメーションを作成
		let newGroundAnim = SKAction.runBlock({
			let groundNode = SKNode()
			groundNode.position = CGPoint(x: self.frame.size.width + ground.size().width * 2, y: 0.0)
			
			// 地面の高さを算出
			let baseHeight = UInt32(self.frame.size.height / 12)
			// 初期作成の場合（escapeHeightがnilの場合）地面の高さにbaseHeightを設定
			var rundomHeight = CGFloat(baseHeight)
			// 初期作成以外の場合（escapeHeightがnil以外の場合）地面の高さに直前の地面の高さを設定
			if let height = self.escapeHeight {
				rundomHeight = height
			}
			if self.getRundom(0.5) {
				rundomHeight = CGFloat(arc4random_uniform(baseHeight * 3) + baseHeight)
			}
			self.escapeHeight = rundomHeight
			
			// 地面のspriteNodeを作成
			let groundSpriteNode = SKSpriteNode(texture: ground)
			groundSpriteNode.position = CGPoint(x:0.0, y: rundomHeight)
			
			// 地面ノードに物理シミュレーションを設定
			groundSpriteNode.physicsBody = SKPhysicsBody(texture: ground, size: groundSpriteNode.size)
			groundSpriteNode.physicsBody?.dynamic = false
			groundSpriteNode.physicsBody?.categoryBitMask = ColliderType.Ground
			groundSpriteNode.physicsBody?.contactTestBitMask = ColliderType.Player
			groundNode.addChild(groundSpriteNode)
			
			// 地面（下部）のspriteNodeを作成
			let underground = SKTexture(imageNamed: "underground")
			underground.filteringMode = .Nearest
			let undergroundNeedNumber = 1.0 + (rundomHeight / underground.size().height)
			
			for i in 0 ..< Int(undergroundNeedNumber) {
				let sprite = SKSpriteNode(texture: underground)
				sprite.position = CGPoint(x:0.0, y: rundomHeight - ground.size().height * 0.5 - (CGFloat(i) + 0.5) * underground.size().height)
				groundNode.addChild(sprite)
			}
			
			// ゲームオーバーを判定する障害物ノードを作成
			let wallNode = SKNode()
			wallNode.position = CGPoint(x: -groundSpriteNode.size.width / 2 - 0.01, y: rundomHeight / 2 + CGFloat(baseHeight) / 2)
			let wallSpriteNode = SKSpriteNode()
			wallSpriteNode.size = CGSize(width: 2.0, height: rundomHeight)
			wallNode.addChild(wallSpriteNode)
			
			// 障害物ノードに物理シミュレーションを生成
			wallNode.physicsBody = SKPhysicsBody(rectangleOfSize: wallSpriteNode.size)
			wallNode.physicsBody?.dynamic = false
			wallNode.physicsBody?.categoryBitMask = ColliderType.Wall
			wallNode.physicsBody?.contactTestBitMask = ColliderType.Player
			groundNode.addChild(wallNode)
			
			groundNode.runAction(groundAnim)
			self.baseNode.addChild(groundNode)
		})
		
		self.runAction(newGroundAnim)
	}
	
	// スコア加算
	func scoreUp() {
		score = score + 1
		scoreLabelNode.text = String("score : \(score)")
	}
	
	// スピードアップ
	func speedUp() {
		// とりあえず、10マス進んだらスピードアップ
		if speedUpCount > 5 {
			speedUpCount = 0
			baseNode.speed += 0.1
		} else {
			speedUpCount += 1
		}
	}
	
	// MARK: 画面押下時
	override func touchesBegan(touches: Set<UITouch>, withEvent event: UIEvent?) {
		// ゲーム中の場合
		if !gameOver {
			// 0回目
			switch jump {
			case .Ground:
				jump = Jump.Air
				for touch in touches {
					_ = touch.locationInNode(self)
					player.physicsBody?.velocity = CGVector.zero
					player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 33.0))
				}
			case .Air:
				jump = Jump.Jumped
				for touch in touches {
					_ = touch.locationInNode(self)
					player.physicsBody?.velocity = CGVector.zero
					player.physicsBody?.applyImpulse(CGVector(dx: 0.0, dy: 13.0))
				}
			// 何もしない
			default: break
			}
			
			// ゲームオーバー時のアニメーションが終わるまでは、遷移できないようにする
		} else if baseNode.speed == 0.0 && player.speed == 0.0{
			// ゲームオーバー時の処理
			let scene = TitleScene(size: self.scene!.size)
			scene.scaleMode = SKSceneScaleMode.AspectFill
			self.view!.presentScene(scene)			
		}
		
	}
	
	// MARK: 衝突開始時
	func didBeginContact(contact: SKPhysicsContact) {
		// すでに、ゲームオーバーの場合
		if gameOver {
			return
		}
		
		let groundType = ColliderType.Ground
		let wallType = ColliderType.Wall
		
		// 地面着地時の処理
		if contact.bodyA.categoryBitMask == groundType
			|| contact.bodyB.categoryBitMask == groundType {
			jump = Jump.Ground
		}
		// 障害物押下時の処理
		if contact.bodyA.categoryBitMask == wallType
			|| contact.bodyB.categoryBitMask == wallType {
			gameOver = true
			
			// ゲームオーバーアニメーション追加
			setGameOverAnim()
			// 順位取得
			let ranking = getRanking()
			print(ranking)

			// 10位以内なら登録
			if ranking <= 10 {
				// スコア登録
				registNewScore()
			}
			
		}

	}
	
	// ゲームオーバーアニメーション追加
	func setGameOverAnim(){
		let point = player.position
		player.removeFromParent()
		// 回転アニメーション
		player = SKSpriteNode(imageNamed: "dead")
		player.position = CGPoint(x: point.x, y: point.y)
		let rolling = SKAction.rotateByAngle(-CGFloat(M_PI) * 2.0, duration: 2.0)
		let scaleout = SKAction.scaleTo(CGFloat(5.0), duration: 2.0)
		let moveCenter = SKAction.moveTo(CGPointMake(self.frame.size.width / 2, self.frame.size.height / 2), duration: 2.0)
		let deadAnim = SKAction.group([scaleout, rolling, moveCenter])
		player.runAction(deadAnim, completion: {
			// ローリングアニメーション停止時に、プレイキャラのアニメーション停止
			self.player.speed = 0.0
			self.baseNode.speed = 0.0
		})
		self.addChild(player)
	}
	
	// 順位取得
	func getRanking() -> Int {
		// 着順（self.scoreよりも早いscoreを持つレコード件数 + 1）を返却
		return realm.objects(Record).filter("score > %@", self.score as AnyObject).count + 1
	}

	// スコアの登録
	func registNewScore() {
		// 追加するデータを用意
		let record = Record()
		record.score = self.score
		record.date = NSDate()
		
		// データを追加
		try! realm.write() {
			realm.add(record)
		}
	}
	
}