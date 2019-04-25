//
//  GameScene.swift
//  Bubble
//
//  Created by Alex Rodriguez on 12/27/16.
//  Copyright © 2016 magnitude. All rights reserved.
//

import SpriteKit
import GameplayKit

class GameScene: SKScene {
    
    struct PhysicsCategory {
        static let Player : UInt32 = 1
        static let Bubble : UInt32 = 2
        static let Spike : UInt32 = 3
    }
    
    
    let gameLayer = SKNode()
    let pauseLayer = SKNode()
    
    let menu = SKNode()
    let menuCurrentScore = SKLabelNode()
    let menuHighScore = SKLabelNode()
    
    let spikeSpace = 1500

    let player = SKNode()
    let targetLine = SKShapeNode()
    let cameraNode = SKCameraNode()
    let pauseButton = SKNode()
    var resetCords = CGPoint()
    
    
    var bubbles: [SKNode] = []
    var spikes: [SKNode] = []
    var playerCurrentTarget: CGPoint?
    var score = 0
    var highScore = 0
    let scoreLabel = SKLabelNode()
    var touchOngoing = false
    
    struct defaultsKeys {
        static let highScoreKey = "highScore"
    }
    
    var playerSpeed = CGFloat(400)
    
    override func didMove(to view: SKView) {
        self.backgroundColor = .white
        addChild(gameLayer)
        
        setupScene()
        
        physicsWorld.contactDelegate = self
        
        addChild(cameraNode)
        
        camera = cameraNode
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        let pausePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 15, height: 75),
                                     cornerRadius: 20)
        let pauseLine = SKShapeNode(path: pausePath.cgPath)
        let pauseLine2 = SKShapeNode(path: pausePath.cgPath)
        pauseLine2.position.x += 25
        
        pauseButton.addChild(pauseLine)
        pauseButton.addChild(pauseLine2)
        
        pauseLine.fillColor = SKColor(hex: 0xC0EDB4)
        pauseLine.strokeColor = SKColor(hex: 0xC0EDB4)
        pauseLine2.fillColor = SKColor(hex: 0xC0EDB4)
        pauseLine2.strokeColor = SKColor(hex: 0xC0EDB4)
        
        pauseButton.position = CGPoint(x:-500, y:900)
        
        cameraNode.addChild(pauseButton)
        
        let defaults = UserDefaults()
        
        if let score = Optional(defaults.integer(forKey: defaultsKeys.highScoreKey)) {
            highScore = score
        } else {
            defaults.setValue(highScore, forKey: defaultsKeys.highScoreKey)
            defaults.synchronize()
        }
        
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            if gameLayer.isPaused == false {
                let location = touch.location(in:self)
                playerCurrentTarget = location
                if touchOngoing == false {
                    gameLayer.addChild(targetLine)
                    touchOngoing = true
                }
            } else {
                
            }
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for touch: AnyObject in touches {
            let location = touch.location(in:self)
            playerCurrentTarget = location
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        playerCurrentTarget = nil
        for touch: AnyObject in touches {
            
            var approx = CGFloat(80)
            let location = touch.location(in:self)
            let locationOnScreen = cameraNode.convert(location, from: self)
            
            if gameLayer.isPaused == false {
                for bubble in bubbles {
                
                    if (bubble.position.x-approx < location.x && location.x < bubble.position.x+approx && bubble.position.y-approx < location.y && location.y < bubble.position.y+approx) {
                    
                        var direction = CGFloat(0)
                    
                        if (bubble.position.x < player.position.x) {
                            direction = CGFloat(-1)
                        } else {
                            direction = CGFloat(1)
                        }
                    
                        let slopeY = bubble.position.y - player.position.y
                        let slopeX = bubble.position.x - player.position.x
                    
                        let slope = slopeY / slopeX
                    
                        player.physicsBody?.velocity.dx = playerSpeed / (abs(slope) + 1) * direction
                        player.physicsBody?.velocity.dy = slope * (player.physicsBody?.velocity.dx)!

                    }
                }

            } else {
                if (resetCords.x-approx < locationOnScreen.x && locationOnScreen.x < resetCords.x+approx && resetCords.y-approx < locationOnScreen.y && locationOnScreen.y < resetCords.y+approx) {
                    resumegame()
                    dieAndRestart()
                }
                
            }
            
            approx = CGFloat(100)
            if (pauseButton.position.x-approx < locationOnScreen.x && locationOnScreen.x < pauseButton.position.x+approx && pauseButton.position.y-approx < locationOnScreen.y && locationOnScreen.y < pauseButton.position.y+approx) {
                if gameLayer.isPaused == false {
                    targetLine.removeFromParent()
                    touchOngoing = false
                    pauseGame()
                } else {
                    resumegame()
                }
            }

        }
    }
    
    override func update(_ currentTime: TimeInterval) {
        if gameLayer.isPaused == false {
            let despawnRange = CGFloat(1600)
        
            if let path = playerCurrentTarget{
                let targetPath = CGMutablePath()
                targetPath.move(to: CGPoint(x: player.position.x, y: player.position.y))
                targetPath.addLine(to: path)
                targetLine.path = targetPath
            
                targetLine.strokeColor = SKColor(hex: 0xC0EDB4)
                targetLine.lineWidth = 10
            } else {
                targetLine.removeFromParent()
                touchOngoing = false
            }
        
            scoreLabel.text = String(score)
        
            cameraNode.position.y = player.position.y
            cameraNode.position.x = player.position.x
        
        
            for bubble in bubbles {
                if (Swift.abs(bubble.position.x-player.position.x) > despawnRange || Swift.abs(bubble.position.y-player.position.y) > despawnRange) {
                    bubble.removeFromParent()
                    bubbles.remove(at: bubbles.index(of: bubble)!)
//                    Small work around
                    addBubble(gameGoing: false)
                }
                
            }
        
            for spike in spikes {
                if (Swift.abs(spike.position.x-player.position.x) > despawnRange || Swift.abs(spike.position.y-player.position.y) > despawnRange) {
                    spike.removeFromParent()
                    spikes.remove(at: spikes.index(of: spike)!)
                    addSpike(gameGoing: true)
                }
            
            }
        } else {
            
        }

    }
    
    func setupScene() {
//      Player Setup
        setupPlayer()
        renderAdditionalNodes(20)
        setUpGraphicMenu()

    }
    
    func renderAdditionalNodes(_ amount: Int) {
        for _ in 1...amount {
            addBubble(gameGoing: false)
        }
        
        for _ in 1...amount-5 {
            addSpike(gameGoing: false)
        }
        
        while checkIfBubble() == false {
            bubbles[0].removeFromParent()
            bubbles.remove(at: 0)
            addBubble(gameGoing: false)
        }
    }
    
    func setupPlayer() {
        let playerBody = SKPhysicsBody(circleOfRadius: 140)
        playerBody.categoryBitMask = PhysicsCategory.Player
        playerBody.collisionBitMask = 0
        playerBody.affectedByGravity = false
        player.physicsBody = playerBody
        
        let playerMainShape = SKShapeNode(circleOfRadius: 150)
        playerMainShape.fillColor = SKColor(hex: 0xC8E3FF)
        playerMainShape.strokeColor = SKColor(hex: 0xB5CFEB)
        playerMainShape.lineWidth = 10
        
        let playerReflectionShape = SKShapeNode(circleOfRadius: 30)
        playerReflectionShape.fillColor = SKColor(hex: 0xFFFFFF)
        playerReflectionShape.strokeColor = SKColor(hex: 0xFFFFFF)
        playerReflectionShape.position = CGPoint(x:65, y: 70)
        
        player.addChild(playerMainShape)
        player.addChild(playerReflectionShape)
        
        scoreLabel.position = CGPoint(x: 0, y: 0)
        scoreLabel.fontColor = SKColor(hex: 0xB5CFEB)
        scoreLabel.fontSize = 150
        scoreLabel.text = String(score)
        scoreLabel.text = String(score)
        scoreLabel.position = CGPoint(x:0, y: -50)
    
        player.addChild(scoreLabel)
        
        player.position = CGPoint(x: size.width/2, y: size.height/2)
        player.name = "player"
        gameLayer.addChild(player)
    }
    
    func addBubble(gameGoing: Bool) {
        let bubble = SKNode()
            
        let bubbleForm = SKShapeNode(circleOfRadius: 35)
        bubbleForm.fillColor = SKColor(hex: 0xFCFFAD)
        bubbleForm.strokeColor = SKColor(hex: 0xEFF3A5)
        bubbleForm.lineWidth = 5
        bubble.addChild(bubbleForm)
        
        let bubbleBody = SKPhysicsBody(circleOfRadius: 30)
        bubbleBody.categoryBitMask = PhysicsCategory.Bubble
        bubbleBody.collisionBitMask = 0
        bubbleBody.contactTestBitMask = PhysicsCategory.Player
        bubbleBody.affectedByGravity = false
        bubble.physicsBody = bubbleBody
        
        let bubblePosition = generateCords(gameGoing: gameGoing)
        bubble.position = bubblePosition
        
        bubble.name = "bubble"
        
        bubbles.append(bubble)
        
        gameLayer.addChild(bubble)
    
        
        
    }
    
    func addSpike(gameGoing: Bool) {
        
        let rotationFactor = CGFloat(M_PI_2)
        let spikePosition = generateCords(gameGoing: gameGoing)
        
        let spike = SKNode()
        spike.position = spikePosition
        
        for i in 1...4 {
            
            let spikePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 25, height: 10),
                                     cornerRadius: 20)
            let spikeLine = SKShapeNode(path: spikePath.cgPath)
            
            spikeLine.fillColor = SKColor(hex: 0xFFB7B3)
            spikeLine.strokeColor = SKColor(hex: 0xFFB7B3)
            
            spikeLine.zRotation = rotationFactor * CGFloat(i)
            spike.addChild(spikeLine)
        }
        
        let spikeCenter = SKShapeNode(circleOfRadius: 5)
        spikeCenter.fillColor = SKColor(hex: 0xFFB7B3)
        spikeCenter.strokeColor = SKColor(hex: 0xFFB7B3)
        
        spike.addChild(spikeCenter)
        
        let spikeBody = SKPhysicsBody(circleOfRadius: 35)
        spikeBody.categoryBitMask = PhysicsCategory.Spike
        spikeBody.collisionBitMask = 0
        spikeBody.contactTestBitMask = PhysicsCategory.Player
        spikeBody.affectedByGravity = false
        spike.physicsBody = spikeBody
        
        spike.name = "spike"
        
        spikes.append(spike)

        gameLayer.addChild(spike)
        
    }
    
    func caughtBubble(_ bubbleIndex: Int) {
        score += 1
        playerSpeed *= 1.1
        let soundChoice = arc4random_uniform(3)
        if soundChoice == 1 {
            run(SKAction.playSoundFileNamed("caught1.wav", waitForCompletion: false))
        } else if soundChoice == 2 {
            run(SKAction.playSoundFileNamed("caught2.wav", waitForCompletion: false))
        } else {
            run(SKAction.playSoundFileNamed("caught3.aiff", waitForCompletion: false))
        }
        
        bubbles[bubbleIndex].removeFromParent()
        bubbles.remove(at: bubbleIndex)
        addBubble(gameGoing: true)
        
    }
    
    func testCords(_ nodeX: CGFloat, nodeY: CGFloat, gameGoing: Bool) -> Bool {
        
        //       Radius of player is 150 so at least has to be >150
        let playerSpacing: CGFloat = 250
        
        if (nodeX < player.position.x+playerSpacing && nodeX > player.position.x-playerSpacing) && (nodeY < player.position.y+playerSpacing && nodeY > player.position.y-playerSpacing) {
            return false
        }
        
        let addSpacing = CGFloat(25)
        
        for testBubble in bubbles {
            if (nodeX < testBubble.position.x+addSpacing && nodeX > testBubble.position.x-addSpacing) {
                return false
            } else if (nodeY < testBubble.position.y+addSpacing && nodeY > testBubble.position.y-addSpacing) {
                return false
            }
        }
        
        for testSpike in spikes {
            if (nodeX < testSpike.position.x+(addSpacing) && nodeX > testSpike.position.x-(addSpacing)) {
                return false
            } else if (nodeY < testSpike.position.y+(addSpacing) && nodeY > testSpike.position.y-(addSpacing)) {
                return false
            }
        }
        
        return true
    }

    
    func generateCords(gameGoing: Bool) -> CGPoint {
        var nodeX: CGFloat = 0
        var nodeY: CGFloat = 0
        var cordsAreGood = false
        
        if gameGoing == true {
            while cordsAreGood == false {
                
                let buffer = CGFloat(250)
                let topLeft = convert(CGPoint(x: 0-size.width/2, y: 0-size.height/2), from: cameraNode)
                let topRight = convert(CGPoint(x: 0+size.width/2, y: 0-size.height/2), from: cameraNode)
                let bottomLeft = convert(CGPoint(x: 0-size.width/2, y: 0-size.height/2), from: cameraNode)
                let bottomRight = convert(CGPoint(x: 0-size.width/2, y: 0+size.height/2), from: cameraNode)
                var nodePoint = CGPoint(x: 0,y: 0)
            
                let extraX = CGFloat(arc4random_uniform(UInt32(buffer)))
                let extraY = CGFloat(arc4random_uniform(UInt32(buffer)))
            
                if (arc4random_uniform(UInt32(2))) == 1 {
                    nodePoint.x = topLeft.x + extraX
                    if (arc4random_uniform(UInt32(2))) == 1 {
                        nodePoint.y = bottomLeft.y + extraY
                    } else {
                        nodePoint.y = topLeft.y - extraY
                    }
                } else {
                    nodePoint.x = topRight.x - extraX
                    if (arc4random_uniform(UInt32(2))) == 1 {
                        nodePoint.y = bottomLeft.y + extraY
                    } else {
                        nodePoint.y = topLeft.y - extraY
                    }
                }
                nodeX = nodePoint.x
                nodeY = nodePoint.y
            
                
                cordsAreGood = testCords(nodeX, nodeY: nodeY, gameGoing: gameGoing)
        
            }
            
            return CGPoint(x: nodeX, y: nodeY)
            
        } else {
            let bufferX: CGFloat = size.width + 250
            let bufferY: CGFloat = size.height + 250
        
            let maxX = player.position.x + bufferX
            let minX = player.position.x - bufferX
            let difX = maxX - minX
        
            let maxY = player.position.y + bufferY
            let minY = player.position.y - bufferY
            let difY = maxY - minY
        

        
            while cordsAreGood == false {
                nodeX = CGFloat(arc4random_uniform(UInt32(difX))) + minX
                nodeY = CGFloat(arc4random_uniform(UInt32(difY))) + minY
                cordsAreGood = testCords(nodeX, nodeY: nodeY, gameGoing: gameGoing)
            
            }
            return CGPoint(x: nodeX, y: nodeY)
        
        }

    }
    
    func dieAndRestart() {
        player.position = CGPoint(x: 0, y: 0)
        player.physicsBody?.velocity.dy = 0
        player.physicsBody?.velocity.dx = 0
        playerSpeed = 400
        
        run(SKAction.playSoundFileNamed("death.wav", waitForCompletion: false))
        let defaults = UserDefaults()
        
        let oldScore = defaults.integer(forKey: defaultsKeys.highScoreKey)
        
        if oldScore < score {
            defaults.setValue(score, forKey: defaultsKeys.highScoreKey)
            highScore = score
            defaults.synchronize()
        }
        
    

        
        score = 0
        
        for bubble in bubbles {
            bubble.removeFromParent()
            bubbles.remove(at: bubbles.index(of: bubble)!)
        }
        for spike in spikes {
            spike.removeFromParent()
            spikes.remove(at: spikes.index(of: spike)!)
        }
        
        cameraNode.position = CGPoint(x: size.width/2, y: size.height/2)
        
        renderAdditionalNodes(13)
        
    }
    
    func checkIfBubble() -> Bool{
        for bubble in bubbles {
            if bubble.position.x > 100 && bubble.position.x < size.width - 100{
                if bubble.position.y > 100 && bubble.position.y < size.height - 100 {
                    return true
                }
            }
        }
        return false
    }
    
    func pauseGame() {
        gameLayer.isPaused = true
        physicsWorld.speed = 0
        addChild(pauseLayer)
        setUpPauseMenu()
    }
    
    func resumegame() {
        pauseLayer.removeAllChildren()
        pauseLayer.removeFromParent()
        menu.removeFromParent()
        
        gameLayer.addChild(player)
        physicsWorld.speed = 1
        gameLayer.isPaused = false
        
        pauseButton.removeAllChildren()
        
        let pausePath = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 15, height: 75),
                                     cornerRadius: 20)
        let pauseLine = SKShapeNode(path: pausePath.cgPath)
        let pauseLine2 = SKShapeNode(path: pausePath.cgPath)
        pauseLine2.position.x += 25
        
        pauseButton.addChild(pauseLine)
        pauseButton.addChild(pauseLine2)
        
        pauseLine.fillColor = SKColor(hex: 0xC0EDB4)
        pauseLine.strokeColor = SKColor(hex: 0xC0EDB4)
        pauseLine2.fillColor = SKColor(hex: 0xC0EDB4)
        pauseLine2.strokeColor = SKColor(hex: 0xC0EDB4)
        
        
        
    }
    
    func setUpPauseMenu() {
        pauseButton.removeAllChildren()
        player.removeFromParent()
        
        let pausePath = UIBezierPath()
        pausePath.move(to: CGPoint(x: 0, y: 0))
        pausePath.addLine(to: CGPoint(x: 80, y: 38))
        pausePath.addLine(to: CGPoint(x: 0, y: 75))
        pausePath.addLine(to: CGPoint(x: 0, y: 0))
        
        let unpauseFill = SKShapeNode(path: pausePath.cgPath)
        unpauseFill.fillColor = SKColor(hex: 0xC0EDB4)
        unpauseFill.strokeColor = SKColor(hex: 0xC0EDB4)
        pauseButton.addChild(unpauseFill)
        
        menuCurrentScore.text = "Now: \(score)"
        menuHighScore.text = "Best: \(highScore)"
        
        
        
        cameraNode.addChild(menu)
    }
    
    func setUpGraphicMenu() {
        let pauseBGForm = UIBezierPath(roundedRect: CGRect(x: 0, y: 0, width: 750, height: 175),
                                       cornerRadius: 50)
        let pauseBG = SKShapeNode(path: pauseBGForm.cgPath)
        pauseBG.fillColor = SKColor(hex: 0xEBF2FF)
        pauseBG.strokeColor = SKColor(hex: 0xEBF2FF)
        pauseBG.position = CGPoint(x: 0, y: 0)
        menu.addChild(pauseBG)
        
        let restartTexture = SKTexture(imageNamed: "restart")
        let reset = SKSpriteNode(texture: restartTexture)

        menuHighScore.fontColor =  SKColor(hex: 0xB5CFEB)
        menuCurrentScore.fontColor = SKColor(hex: 0xB5CFEB)
        menuHighScore.fontSize = 80
        menuCurrentScore.fontSize = 80

        
        menuCurrentScore.position = CGPoint(x: 490, y: 100)
        menuHighScore.position = CGPoint(x: 500, y: 32)
        
        reset.position = CGPoint(x: 150, y: 95)
        
        menu.addChild(menuHighScore)
        menu.addChild(menuCurrentScore)
        menu.addChild(reset)

        
        
//        placeholder
        
        menuCurrentScore.text = "Now: \(score)"
        menuHighScore.text = "Best: \(highScore)"
        
        menu.position = CGPoint(x: -375, y: -100)
        
        resetCords = cameraNode.convert(reset.position, from: menu)
    }
    
}

extension GameScene: SKPhysicsContactDelegate {
    func didBegin(_ contact: SKPhysicsContact) {
        if let nodeA = contact.bodyA.node as SKNode?, let nodeB = contact.bodyB.node as SKNode? {
            if nodeB.name == "bubble" {
                if let i = bubbles.index(of: nodeB) {
                    caughtBubble(i)
                }
            } else if nodeB.name == "spike" {
                
                print(nodeA.position)
                print(nodeB.position)
                print("player died")
                dieAndRestart()
            }
            
        }
    }
}
