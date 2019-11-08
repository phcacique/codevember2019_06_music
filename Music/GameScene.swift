//
//  GameScene.swift
//  Sound
//
//  Created by Pedro Cacique on 05/11/19.
//  Copyright © 2019 Pedro Cacique. All rights reserved.
//

import SpriteKit
import GameplayKit
import AVFoundation
import SwiftGameOfLife

class GameScene: SKScene {
    
    let gridWidth:Int = 10
    let gridHeight:Int = 16
    let border:CGFloat = 50
    var shapeSize:CGFloat = 10
    var nodes:[SKShapeNode] = []
    var minDim:Int = 0
    var space:CGFloat = 0
    let container:SKNode = SKNode()
    var duration:TimeInterval = 3.4
    var barShape:SKShapeNode = SKShapeNode()
    var currentColumn:Int = -1
    
    let swipeRight = UISwipeGestureRecognizer()
    let swipeLeft = UISwipeGestureRecognizer()
    let tapRec3 = UITapGestureRecognizer()
    
    var grid:Grid = Grid()
    
    var isPlaying:Bool = false
    
    let shapeColor:UIColor = UIColor(red:200/255, green:214/255, blue:229/255, alpha: 1)
    let barColor:UIColor = UIColor(red:238/255, green:82/255, blue:83/255, alpha: 1)
    let bgColor:UIColor = UIColor(red:34/255, green:47/255, blue:62/255, alpha: 1)
    
    let audioManager:AudioManager = AudioManager()
    
    
    override func didMove(to view: SKView) {
        swipeRight.addTarget(self, action:#selector(swipeRight(_:) ))
        swipeRight.direction = .right
        self.view!.addGestureRecognizer(swipeRight)
        
        swipeLeft.addTarget(self, action:#selector(swipeLeft(_:) ))
        swipeLeft.direction = .left
        self.view!.addGestureRecognizer(swipeLeft)
        
        tapRec3.addTarget(self, action:#selector(tappedView3(_:) ))
        tapRec3.numberOfTouchesRequired = 1
        tapRec3.numberOfTapsRequired = 3
        self.view!.addGestureRecognizer(tapRec3)
        
        restart()
    }
    
    
    
    @objc func tappedView3(_ sender:UITapGestureRecognizer) {
        
        restart()
        stop()
    }
    
    func restart(){
        backgroundColor = bgColor
        
        removeAllChildren()
        removeAllActions()
        
        nodes = []
        
        container.removeAllActions()
        container.removeAllChildren()
        
        addChild(container)
        
        setGrid()
        
        minDim = ( min(self.size.width, self.size.height) == self.size.width ) ? 0 : 1

        let shapeSizeW:CGFloat = ((self.size.width - 2 * border) - CGFloat(gridWidth) * space) / CGFloat(gridWidth)
        let shapeSizeH:CGFloat = ((self.size.height - 2 * border) - CGFloat(gridHeight) * space) / CGFloat(gridHeight)
        shapeSize = min(shapeSizeW, shapeSizeH)
        
        
        for i in 0..<gridWidth{
            for j in 0..<gridHeight{
                drawObject(CGPoint(x: border + CGFloat(i) * (shapeSize + space), y:border + CGFloat(j) * (shapeSize + space) ), "shape-\(i)-\(j)")
            }
        }
        
        let containerH:CGFloat = 2 * border + CGFloat(gridHeight) * (shapeSize + space)
        let hSpace:CGFloat = (self.size.height - containerH) / 2
        container.position.y = hSpace
        
        barShape = SKShapeNode(rect: CGRect(x: border - 10, y:container.position.y + border, width:5, height:CGFloat(gridHeight) * (shapeSize + space)))
        barShape.fillColor = barColor
        barShape.lineWidth = 0
        addChild(barShape)
    }
    
    @objc func swipeRight(_ sender:UITapGestureRecognizer) {
        play()
    }
    
    @objc func swipeLeft(_ sender:UITapGestureRecognizer) {
        stop()
    }
    
    func showGen(){
        for i in 0..<grid.width{
            for j in 0..<grid.height{
                if grid.cells[i][j].state == .alive {
                    nodes[j + i * grid.height].run(SKAction.fadeAlpha(to: 1, duration: 0.5))
                } else {
                    nodes[j + i * grid.height].run(SKAction.fadeAlpha(to: 0.1, duration: 0.5))
                }
            }
        }
    }
    
    func stop(){
        barShape.position.x = 0
        barShape.removeAllActions()
        currentColumn = -1
        isPlaying = false
        audioManager.player.stop()
    }
    
    func play(){
        isPlaying = true
        playAudioGen()
    }
    
    func setGrid(){
        grid = Grid(width: gridWidth, height: gridHeight)
        grid.addRule(CountRule(name: "Solitude", startState: .alive, endState: .dead, count: 2, type: .lessThan))
        grid.addRule(CountRule(name: "Survive2", startState: .alive, endState: .alive, count: 2, type: .equals))
        grid.addRule(CountRule(name: "Survive3", startState: .alive, endState: .alive, count: 3, type: .equals))
        grid.addRule(CountRule(name: "Overpopulation", startState: .alive, endState: .dead, count: 3, type: .greaterThan))
        grid.addRule(CountRule(name: "Birth", startState: .dead, endState: .alive, count: 3, type: .equals))
    }
    
    func drawObject(_ pos:CGPoint, _ name:String){
        let node:SKShapeNode = SKShapeNode(circleOfRadius: shapeSize/2)
        node.position = CGPoint(x:pos.x + shapeSize/2, y:pos.y + shapeSize/2)
        node.fillColor = shapeColor
        node.lineWidth = 0
        node.name = name
        node.alpha = 0
        node.run(SKAction.sequence([SKAction.wait(forDuration: Double.random(in: 0...0.5)),
                                    SKAction.fadeAlpha(to: 0.1, duration: 0.5)]))
        container.addChild(node)
        nodes.append(node)
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else {
            return
        }
        
        let location = touch.location(in: self)
        
        if let frontTouchedNode = atPoint(location).name {
            for node in nodes {
                if node.name == frontTouchedNode {
                    
                    let i:Int = Int(String(frontTouchedNode.split(separator: "-")[1])) ?? 0
                    let j:Int = Int(String(frontTouchedNode.split(separator: "-")[2])) ?? 0
                    if grid.cells[i][j].state == .dead {
                        grid.cells[i][j].state = .alive
                        node.run(SKAction.fadeAlpha(to: 1, duration: 0.5))
                        if !isPlaying {
                            
                            let temp:String = (j < 10) ? "0\(j)" : "\(j)"
                            audioManager.playAudio(AudioManager.getAudioURL(name: "sound\(temp)"))
                            
                        }
                    } else {
                        grid.cells[i][j].state = .dead
                        node.run(SKAction.fadeAlpha(to: 0.1, duration: 0.5))
                    }
                }
            }
        }
        showGen()
        
    }
    
    func playAudioGen(_ column:Int  = 0){
        if column == 0 {
            audioManager.urls = []
        }
        
        var audios:[URL] = []
        var countDead:Int  = 0
        for j in 0..<gridHeight{
            if grid.cells[column][j].state == .alive {
                let temp:String = (j < 10) ? "0\(j)" : "\(j)"
                audios.append(AudioManager.getAudioURL(name: "sound\(temp)"))
            } else {
                countDead += 1
            }
        }
        if countDead == gridHeight {
            audios.append(AudioManager.getAudioURL(name: "silence"))
        }
        
        audioManager.events.listenTo(eventName: AudioManager.TRACKS_MERGED, action: {information in
            let url = information as! URL
            self.audioManager.events.removeListeners(eventNameToRemoveOrNil: AudioManager.TRACKS_MERGED)
            self.audioManager.urls.append(url)
            if column < self.gridWidth - 1{
                self.playAudioGen(column + 1)
            } else {
                self.playMusic()
                self.barShape.run( SKAction.sequence([
                    SKAction.moveTo(x: self.size.width - 2 * self.border, duration: self.duration),
                    SKAction.moveTo(x: 0, duration: 0)
                ]))
            }
        })
        audioManager.mergeTracks(audios: audios)
    }
    
    func playMusic(){

            audioManager.events.listenTo(eventName: AudioManager.TRACKS_CONCATENATED, action: {information in
                self.audioManager.events.removeListeners(eventNameToRemoveOrNil: AudioManager.TRACKS_CONCATENATED)
                print(information as! URL)
                self.audioManager.playAudio(information as! URL)
            })
        audioManager.concatenateTracks(audios: audioManager.urls.reversed())
        
    }
    
    override func update(_ currentTime: TimeInterval) {
        if isPlaying {
            let w:CGFloat = self.size.width - 2 * border
            let step:CGFloat = w / CGFloat(gridWidth)
            
            if currentColumn != Int(barShape.position.x / step) {
                currentColumn =  Int(barShape.position.x / step)
                //playColumn(currentColumn)
                if currentColumn == gridWidth - 1 {
                    grid.applyRules()
                    showGen()
                    self.barShape.position.x = 0
                    barShape.removeAllActions()
                    playAudioGen()
                }
            }
            
        }
    }
}
