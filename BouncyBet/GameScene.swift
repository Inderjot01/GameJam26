//
//  GameScene.swift
//  BouncyBet
//
//  This is the heart of the game. It is an SKScene that
//  handles all physics, rendering, and game logic.
//

import SpriteKit

class GameScene: SKScene, SKPhysicsContactDelegate {
    
    // MARK: - Properties
    
    /// A weak reference back to the ViewModel for communication.
    weak var viewModel: GameViewModel?
    
    private var isRoundActive = false
    private var currentRoundScore = 0 {
        didSet {
            // Notify the ViewModel every time the score changes
            viewModel?.scoreDidChange(newScore: currentRoundScore)
        }
    }
    
    private var projectileNode: SKSpriteNode?
    private var launcherNode: SKSpriteNode!
    private var aimLine: SKShapeNode?
    private var powerLabel: SKLabelNode?
    
    private var placedObjects: [SKSpriteNode] = []
    
    // Drag gesture properties
    private var startTouch: CGPoint?
    private var currentTouch: CGPoint?
    private var isDragging = false
    
    // Trail effect
    private var trailNode: SKEmitterNode?
    
    // MARK: - Scene Lifecycle
    
    override func didMove(to view: SKView) {
        super.didMove(to: view)
        
        backgroundColor = UIColor(red: 0.1, green: 0.1, blue: 0.2, alpha: 1.0)
        
        // 1. Set up the physics world - NO GRAVITY!
        physicsWorld.gravity = CGVector(dx: 0, dy: 0)  // Zero gravity
        physicsWorld.contactDelegate = self
        
        // 2. Create the world boundary
        let boundaryBody = SKPhysicsBody(edgeLoopFrom: self.frame)
        boundaryBody.categoryBitMask = PhysicsCategory.worldBoundary
        boundaryBody.restitution = 0.8 // Good bounce off walls
        self.physicsBody = boundaryBody
        
        // 3. Create the launcher (bigger and more visible)
        launcherNode = SKSpriteNode(color: .cyan, size: CGSize(width: 60, height: 60))
        launcherNode.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 100)
        launcherNode.zPosition = 10
        
        // Add a circular outline to the launcher
        let circle = SKShapeNode(circleOfRadius: 35)
        circle.strokeColor = .white
        circle.lineWidth = 3
        circle.fillColor = .clear
        circle.glowWidth = 2
        launcherNode.addChild(circle)
        
        addChild(launcherNode)
        
        // 4. Create power label
        powerLabel = SKLabelNode(fontNamed: "Helvetica-Bold")
        powerLabel?.fontSize = 20
        powerLabel?.fontColor = .yellow
        powerLabel?.position = CGPoint(x: self.frame.midX, y: self.frame.minY + 180)
        powerLabel?.zPosition = 15
        powerLabel?.isHidden = true
        addChild(powerLabel!)
        
        // 5. Start with a fresh field
        prepareNewRound()
    }
    
    // MARK: - Game Loop
    
    /// Called by the ViewModel to set up the field for a new round.
    func prepareNewRound() {
        // 1. Clear old objects
        for obj in placedObjects {
            obj.removeFromParent()
        }
        placedObjects.removeAll()
        
        // 2. Generate new field
        generateField(objectCount: 35)
        
        // 3. Reset state
        isRoundActive = false
        currentRoundScore = 0
    }
    
    /// Starts the 10-second round timer.
    private func startRoundTimer() {
        guard !isRoundActive else { return }
        
        isRoundActive = true
        
        let waitAction = SKAction.wait(forDuration: GameConfig.projectileLifespan)
        let endRoundAction = SKAction.run { [weak self] in
            self?.endRound()
        }
        
        let sequence = SKAction.sequence([waitAction, endRoundAction])
        self.run(sequence, withKey: "roundTimer")
    }
    
    /// Called by the timer when the round is over.
    private func endRound() {
        isRoundActive = false
        self.removeAction(forKey: "roundTimer")
        
        trailNode?.removeFromParent()
        trailNode = nil
        projectileNode?.removeFromParent()
        projectileNode = nil
        
        // Report final score back to ViewModel
        viewModel?.roundDidEnd(score: currentRoundScore)
    }
    
    // MARK: - Drag and Shoot Mechanics
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, !isRoundActive else { return }
        
        let location = touch.location(in: self)
        
        // Check if touch is near the launcher
        let distance = hypot(location.x - launcherNode.position.x,
                           location.y - launcherNode.position.y)
        
        if distance < 100 {
            isDragging = true
            startTouch = launcherNode.position
            currentTouch = location
            
            // Create aim line
            aimLine = SKShapeNode()
            aimLine?.strokeColor = UIColor(white: 1, alpha: 0.5)
            aimLine?.lineWidth = 3
            aimLine?.zPosition = 5
            addChild(aimLine!)
            
            // Show power label
            powerLabel?.isHidden = false
            
            updateAimLine()
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first, isDragging else { return }
        
        currentTouch = touch.location(in: self)
        updateAimLine()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard isDragging, let start = startTouch, let current = currentTouch else { return }
        
        isDragging = false
        
        // Remove aim line
        aimLine?.removeFromParent()
        aimLine = nil
        powerLabel?.isHidden = true
        
        // Calculate pull vector (opposite direction)
        let pullVector = CGVector(dx: start.x - current.x,
                                 dy: start.y - current.y)
        
        // Limit maximum power
        let maxPower: CGFloat = 15.0
        let power = min(sqrt(pullVector.dx * pullVector.dx + pullVector.dy * pullVector.dy) / 10, maxPower)
        
        // Only shoot if pulled back enough
        if power > 1 {
            shootProjectile(direction: pullVector, power: power)
        }
        
        startTouch = nil
        currentTouch = nil
    }
    
    private func updateAimLine() {
        guard let start = startTouch, let current = currentTouch, let aimLine = aimLine else { return }
        
        // Create path for aim line
        let path = CGMutablePath()
        
        // Calculate trajectory preview
        let pullVector = CGVector(dx: start.x - current.x,
                                 dy: start.y - current.y)
        
        // Show preview line in shooting direction
        let previewEnd = CGPoint(x: start.x + pullVector.dx * 2,
                                y: start.y + pullVector.dy * 2)
        
        path.move(to: start)
        path.addLine(to: previewEnd)
        aimLine.path = path
        
        // Update power label
        let power = min(sqrt(pullVector.dx * pullVector.dx + pullVector.dy * pullVector.dy) / 10, 15)
        powerLabel?.text = String(format: "Power: %.0f%%", power * 100 / 15)
    }
    
    private func shootProjectile(direction: CGVector, power: CGFloat) {
        // 1. Create the projectile
        projectileNode = SKSpriteNode(color: .white, size: CGSize(width: 12, height: 12))
        projectileNode?.position = launcherNode.position
        projectileNode?.zPosition = 8
        
        // Make it glow
        projectileNode?.physicsBody?.fieldBitMask = 1
        
        // 2. Create trail effect
        if let trail = SKEmitterNode(fileNamed: "Trail") {
            trailNode = trail
            projectileNode?.addChild(trail)
            trail.targetNode = self
        } else {
            // Fallback: Create trail programmatically
            let trail = SKEmitterNode()
            trail.particleTexture = SKTexture(imageNamed: "spark")
            trail.particleLifetime = 0.5
            trail.particleLifetimeRange = 0.2
            trail.particleScale = 0.2
            trail.particleScaleRange = 0.1
            trail.particleAlpha = 0.8
            trail.particleAlphaSpeed = -2
            trail.particleColor = .cyan
            trail.particleColorBlendFactor = 1
            trail.particleBlendMode = .add
            trail.particleBirthRate = 100
            trail.emissionAngle = .pi
            trail.particleSpeed = 50
            trail.particleSpeedRange = 20
            trail.targetNode = self
            trail.zPosition = 7
            
            trailNode = trail
            projectileNode?.addChild(trail)
        }
        
        // 3. Create physics body
        let body = SKPhysicsBody(circleOfRadius: 6)
        body.isDynamic = true
        body.categoryBitMask = PhysicsCategory.projectile
        body.collisionBitMask = PhysicsCategory.obstacle | PhysicsCategory.worldBoundary
        body.contactTestBitMask = PhysicsCategory.obstacle | PhysicsCategory.reward | PhysicsCategory.hazard
        
        // Physics properties for no-gravity environment
        body.restitution = 0.95  // Very bouncy
        body.linearDamping = 0.02  // Very low damping (keeps moving)
        body.angularDamping = 0.1
        body.friction = 0
        body.mass = 0.05
        body.usesPreciseCollisionDetection = true
        body.affectedByGravity = false  // Explicitly no gravity
        
        projectileNode?.physicsBody = body
        addChild(projectileNode!)
        
        // 4. Apply velocity based on drag
        let velocity = CGVector(dx: direction.dx * power,
                               dy: direction.dy * power)
        body.velocity = velocity
        
        // 5. Start timer
        startRoundTimer()
    }
    
    // MARK: - Object Generation
    
    private func generateField(objectCount: Int) {
        let playableRect = self.frame.inset(by: UIEdgeInsets(top: 150, left: 30, bottom: 250, right: 30))
        
        for _ in 0..<objectCount {
            let data = ObjectData.createRandom()
            let node = createNode(from: data)
            
            var attempts = 0
            while attempts < 100 {
                let randomX = CGFloat.random(in: playableRect.minX...playableRect.maxX)
                let randomY = CGFloat.random(in: playableRect.minY...playableRect.maxY)
                node.position = CGPoint(x: randomX, y: randomY)
                
                var intersects = false
                for existingNode in placedObjects {
                    if node.intersects(existingNode) {
                        intersects = true
                        break
                    }
                }
                
                if !intersects {
                    break
                }
                attempts += 1
            }
            
            // Add glow effect
            node.physicsBody?.fieldBitMask = 1
            
            addChild(node)
            placedObjects.append(node)
        }
    }
    
    private func createNode(from data: ObjectData) -> SKSpriteNode {
        let size: CGSize
        let color: SKColor
        let category: UInt32
        
        switch data.type {
        case .obstacle:
            size = CGSize(width: 25, height: 25)
            color = UIColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
            category = PhysicsCategory.obstacle
        case .reward:
            size = CGSize(width: 30, height: 30)
            color = UIColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 1.0)
            category = PhysicsCategory.reward
        case .hazard:
            size = CGSize(width: 20, height: 20)
            color = UIColor(red: 1.0, green: 0.3, blue: 0.3, alpha: 1.0)
            category = PhysicsCategory.hazard
        }
        
        let node = SKSpriteNode(color: color, size: size)
        node.name = data.id.uuidString
        
        // Add visual effects based on type
        if data.type == .reward {
            // Add pulsing animation to rewards
            let scaleUp = SKAction.scale(to: 1.2, duration: 0.5)
            let scaleDown = SKAction.scale(to: 1.0, duration: 0.5)
            let pulse = SKAction.sequence([scaleUp, scaleDown])
            node.run(SKAction.repeatForever(pulse))
        } else if data.type == .hazard {
            // Add rotation to hazards
            let rotate = SKAction.rotate(byAngle: .pi * 2, duration: 3)
            node.run(SKAction.repeatForever(rotate))
        }
        
        node.userData = ["points": data.points]
        
        let body = SKPhysicsBody(circleOfRadius: size.width / 2)
        body.isDynamic = false
        body.categoryBitMask = category
        body.affectedByGravity = false
        
        if data.type == .obstacle {
            body.restitution = 1.0
        }
        
        node.physicsBody = body
        return node
    }
    
    // MARK: - Collision Handling
    
    func didBegin(_ contact: SKPhysicsContact) {
        let bodyA: SKPhysicsBody
        let bodyB: SKPhysicsBody
        if contact.bodyA.categoryBitMask < contact.bodyB.categoryBitMask {
            bodyA = contact.bodyA
            bodyB = contact.bodyB
        } else {
            bodyA = contact.bodyB
            bodyB = contact.bodyA
        }

        guard bodyA.categoryBitMask == PhysicsCategory.projectile else { return }
        
        let otherNode = bodyB.node
        
        if let points = otherNode?.userData?["points"] as? Int {
            currentRoundScore += points
            
            // Visual feedback for scoring
            if let node = otherNode {
                let flash = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.1),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.1)
                ])
                node.run(flash)
            }
        }
        
        if bodyB.categoryBitMask == PhysicsCategory.reward || bodyB.categoryBitMask == PhysicsCategory.hazard {
            otherNode?.removeFromParent()
        }
    }
}
