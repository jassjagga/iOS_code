import SwiftUI
import SpriteKit

struct ContentView: View {
    var body: some View {
        NavigationView {
            VStack {
                Text("Parking Puzzle")
                    .font(.largeTitle)
                    .padding()

                SpriteView(scene: ParkingPuzzleScene(size: UIScreen.main.bounds.size))
                    .edgesIgnoringSafeArea(.all)
            }
        }
    }
}

class ParkingPuzzleScene: SKScene {
    private let gridSize = 6 // 6x6 grid
    private var blocks: [SKSpriteNode] = []
    private var targetBlock: SKSpriteNode!
    private let cellSize: CGFloat = 80
    private let targetRow = 2 // Row where the exit is located
    private let exitColumn = 5 // Exit is at the far-right of targetRow

    override func didMove(to view: SKView) {
        backgroundColor = .white
        setupGrid()
        setupBlocks()
    }

    private func setupGrid() {
        for row in 0..<gridSize {
            for col in 0..<gridSize {
                let cell = SKShapeNode(rectOf: CGSize(width: cellSize, height: cellSize))
                cell.strokeColor = .gray
                cell.position = CGPoint(
                    x: CGFloat(col) * cellSize - CGFloat(gridSize / 2) * cellSize + cellSize / 2,
                    y: CGFloat(row) * cellSize - CGFloat(gridSize / 2) * cellSize + cellSize / 2
                )
                addChild(cell)
            }
        }
    }

    private func setupBlocks() {
        // Add a "target block"
        targetBlock = createBlock(color: .red, size: CGSize(width: cellSize * 2, height: cellSize))
        targetBlock.position = CGPoint(x: -cellSize / 2, y: CGFloat(targetRow) * cellSize - CGFloat(gridSize / 2) * cellSize + cellSize / 2)
        targetBlock.name = "target"
        addChild(targetBlock)

        // Add other blocks
        for _ in 0..<5 {
            let block = createBlock(color: randomColor(), size: CGSize(width: cellSize, height: cellSize * 2))
            block.position = randomPosition()
            blocks.append(block)
            addChild(block)
        }
    }

    private func createBlock(color: UIColor, size: CGSize) -> SKSpriteNode {
        let block = SKSpriteNode(color: color, size: size)
        block.physicsBody = SKPhysicsBody(rectangleOf: size)
        block.physicsBody?.isDynamic = false
        return block
    }

    private func randomColor() -> UIColor {
        return UIColor(
            red: CGFloat.random(in: 0.5...1),
            green: CGFloat.random(in: 0.5...1),
            blue: CGFloat.random(in: 0.5...1),
            alpha: 1
        )
    }

    private func randomPosition() -> CGPoint {
        let row = Int.random(in: 0..<gridSize)
        let col = Int.random(in: 0..<gridSize)
        return CGPoint(
            x: CGFloat(col) * cellSize - CGFloat(gridSize / 2) * cellSize + cellSize / 2,
            y: CGFloat(row) * cellSize - CGFloat(gridSize / 2) * cellSize + cellSize / 2
        )
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            let location = touch.location(in: self)
            let previousLocation = touch.previousLocation(in: self)
            
            // Check which block is being touched
            for block in [targetBlock] + blocks {
                if block.contains(previousLocation) {
                    let delta = CGVector(dx: location.x - previousLocation.x, dy: location.y - previousLocation.y)
                    block.position = CGPoint(x: block.position.x + delta.dx, y: block.position.y + delta.dy)

                    // Check if the target block has reached the exit
                    if block == targetBlock && hasReachedExit(block) {
                        showWinMessage()
                    }
                    break
                }
            }
        }
    }

    private func hasReachedExit(_ block: SKSpriteNode) -> Bool {
        let targetX = CGFloat(exitColumn) * cellSize - CGFloat(gridSize / 2) * cellSize + cellSize / 2
        let targetY = CGFloat(targetRow) * cellSize - CGFloat(gridSize / 2) * cellSize + cellSize / 2
        return abs(block.position.x - targetX) < cellSize / 2 && abs(block.position.y - targetY) < cellSize / 2
    }

    private func showWinMessage() {
        let label = SKLabelNode(text: "You Win!")
        label.fontSize = 50
        label.fontColor = .green
        label.position = CGPoint(x: 0, y: 0)
        addChild(label)
        isUserInteractionEnabled = false // Disable further interaction
    }
}

