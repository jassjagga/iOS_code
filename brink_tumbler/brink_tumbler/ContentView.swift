import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        VStack {
            Text("Brick Tumble")
                .font(.largeTitle)
                .fontWeight(.bold)
                .padding()

            SpriteView(scene: BrickTumbleGameScene(size: UIScreen.main.bounds.size))
                .edgesIgnoringSafeArea(.all)
        }
    }
}

class BrickTumbleGameScene: SKScene {
    private let brickWidth: CGFloat = 100
    private let brickHeight: CGFloat = 30
    private var scoreLabel: SKLabelNode!
    private var score: Int = 0 {
        didSet {
            scoreLabel.text = "Score: \(score)"
        }
    }
    
    override func didMove(to view: SKView) {
        backgroundColor = .white
        setupBricks()
        setupScoreLabel()
    }
    
    private func setupBricks() {
        let startY = size.height / 2
        let numBricks = 10
        for i in 0..<numBricks {
            let brick = SKSpriteNode(color: randomColor(), size: CGSize(width: brickWidth, height: brickHeight))
            brick.position = CGPoint(x: size.width / 2, y: startY + CGFloat(i) * brickHeight)
            brick.name = "brick"
            brick.physicsBody = SKPhysicsBody(rectangleOf: brick.size)
            brick.physicsBody?.isDynamic = false // Initially static
            addChild(brick)
        }
    }
    
    private func setupScoreLabel() {
        scoreLabel = SKLabelNode(text: "Score: 0")
        scoreLabel.fontSize = 24
        scoreLabel.fontColor = .black
        scoreLabel.position = CGPoint(x: size.width / 2, y: size.height - 50)
        scoreLabel.horizontalAlignmentMode = .center
        addChild(scoreLabel)
    }
    
    private func randomColor() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0.5...1),
            green: CGFloat.random(in: 0.5...1),
            blue: CGFloat.random(in: 0.5...1),
            alpha: 1
        )
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let nodesAtPoint = nodes(at: location)
            
            for node in nodesAtPoint {
                if node.name == "brick" {
                    node.removeFromParent() // Remove the brick
                    score += 10
                }
            }
        }
    }
}

