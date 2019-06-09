/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import UIKit
import SceneKit
import ARKit
import MultipeerConnectivity

class ViewController: UIViewController {
    // MARK: - IBOutlets

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet weak var sizeStepper: UIStepper!
    @IBOutlet weak var rotationSlider: UISlider!
    @IBOutlet weak var rotationXSlider: UISlider!
    @IBOutlet weak var leftArrowButton: UIButton!
    @IBOutlet weak var rightArrowButton: UIButton!
    @IBOutlet weak var modeSegment: UISegmentedControl!
    
    @IBOutlet weak var worldMapStateLabel: UILabel!
    @IBOutlet weak var sendWorldMapButton: UIButton!
    
    var peerID: MCPeerID!
    var mcSession: MCSession!
    var mcADAssistant: MCAdvertiserAssistant!
    
    var mpMode: MPMode = .none {
        didSet {
            DispatchQueue.main.async {
                self.worldMapStateLabel.isHidden = self.mpMode != .host
                self.sendWorldMapButton.isHidden = self.mpMode != .host
            }
        }
    }
    
    var pointerView: PointerView!
    
    lazy var airSoundPlayer: AVAudioPlayer = {
        guard let url = Bundle.main.url(forResource: "air", withExtension: "m4a") else { fatalError() }
        guard let player = try? AVAudioPlayer(contentsOf: url) else { fatalError() }
        player.numberOfLoops = -1
        return player
    }()
    
    var planeIsAdded: Bool = false
    
    var mpHostSession: MPHostSession?
    var mpClientSession: MPClientSession?
    
    var editMode : EditMode = .placeMode {
        didSet {
            selectedValvola = nil
            self.sizeStepper.isHidden = (editMode != .editSettingsMode)
            self.rotationSlider.isHidden = (editMode != .editSettingsMode)
            self.rotationXSlider.isHidden = (editMode != .editSettingsMode)
            self.leftArrowButton.isHidden = (editMode != .editSettingsMode)
            self.rightArrowButton.isHidden = (editMode != .editSettingsMode)
            
            if editMode == .circuitMode {
                airSoundPlayer.play()
            } else {
                airSoundPlayer.pause()
            }
        }
    }
    
    var handsMode: HandsMode = .normal {
        didSet {
            self.modeSegment?.isHidden = handsMode == HandsMode.handsFree
            self.pointerView?.isHidden = handsMode != HandsMode.handsFree
        }
    }
    
    var virtualObjects : [ValvolaConformance] = []
    var lines: [Line] = []
    var selectedValvola: ValvolaConformance? { didSet { highlight(node: selectedValvola?.objectNode) }  }
    var selectedType: ValvolaConformance.Type?
    
    var firstSelectedIO: InputOutput? { didSet { highlight(node: firstSelectedIO?.ioNode) } }
    var secondSelectedIO: InputOutput? { didSet { highlight(node: secondSelectedIO?.ioNode) } }
    
    var tableView: UITableView!
    var dataSource: UITableViewDataSource!
    
    var needToRedraw: Bool = false
    
    var movableEdit: MovableEdit!
    
    // MARK: - View Life Cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.sizeStepper.isHidden = true
        
        let scene = SCNScene(named: "Assets.scnassets/ship.scn")
        self.sceneView.scene = scene!
        self.sceneView.isPlaying = true
        
        self.tableView = UITableView()
        self.tableView.register(BoldCell.self, forCellReuseIdentifier: "boldCell")
        self.tableView.backgroundColor = .clear
        self.tableView.separatorStyle = .none
        self.tableView.tableFooterView = UIView()
        self.tableView.delegate = self
        
        let x: Int = Int(self.view.frame.width / 4.0)
        let y: Int = Int(self.view.frame.height / 5) * 2
        self.movableEdit = MovableEdit(frame: CGRect(x: x,
                                                     y: y,
                                                     width: x * 2,
                                                     height: y / 2))
        self.view.addSubview(movableEdit.editView)
        
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(didHold(_:)))
        self.view.addGestureRecognizer(holdGesture)
        
        pointerView = PointerView(frame: .init(origin: .zero, size: .init(width: 50, height: 50)))
        self.view.addSubview(pointerView)
        pointerView.center = self.view.center
        
        setUpConnectivity()
        
        airSoundPlayer.prepareToPlay()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.vertical]
        sceneView.session.run(configuration)
        
        sceneView.session.delegate = self
        sceneView.delegate = self
        
        UIApplication.shared.isIdleTimerDisabled = true
        
        sceneView.showsStatistics = true
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        sceneView.session.pause()
    }
    
    // MARK: - IBActions
    
    @IBAction func segmentChanged(_ sender: UISegmentedControl) {
        switch sender.selectedSegmentIndex {
        case 0: editMode = .placeMode
        case 1: editMode = .moveMode
        case 2: editMode = .editSettingsMode
        case 3: editMode = .circuitMode
        case 4: editMode = .saveMode
        case 5: editMode = .loadMode
        case 6: editMode = .load2DMode
        default: break
        }
    }
    
    @IBAction func stpperTapped(_ sender: UIStepper) {
        let value = Float(sender.value / 100.0)
        if let valvola = selectedValvola {
            valvola.objectNode.scale = SCNVector3(value, value, value)
        } else {
            for valvola in self.virtualObjects {
                valvola.objectNode.scale = SCNVector3(value, value, value)
            }
        }
    }
    
    @IBAction func zAheadButtonPressed(_ sender: UIButton) {
        if let valvola = selectedValvola {
            let node = valvola.objectNode
            node.position.z += 0.1
        } else {
            for valvola in self.virtualObjects {
                let node = valvola.objectNode
                node.position.z += 0.1
            }
        }
        needToRedraw = true
    }
    
    @IBAction func zBehindButtonPressed(_ sender: UIButton) {
        if let valvola = selectedValvola {
            let node = valvola.objectNode
            node.position.z -= 0.1
        } else {
            for valvola in self.virtualObjects {
                let node = valvola.objectNode
                node.position.z -= 0.1
            }
        }
        needToRedraw = true
    }
    
    @IBAction func rotationSliderMoved(_ sender: UISlider) {
        if let valvola = selectedValvola {
            valvola.objectNode.eulerAngles.y = sender.value.degreesToRadians
        } else {
            for valvola in self.virtualObjects {
                valvola.objectNode.eulerAngles.y = sender.value.degreesToRadians
            }
        }
    }
    
    @IBAction func rotationXsliderMoved(_ sender: UISlider) {
        if let valvola = selectedValvola {
            valvola.objectNode.eulerAngles.x = sender.value.degreesToRadians
        } else {
            for valvola in self.virtualObjects {
                valvola.objectNode.eulerAngles.x = sender.value.degreesToRadians
            }
        }
    }
    
    
    @IBAction func leftArrowPressed(_ sender: UIButton) {
        for valvola in self.virtualObjects {
            valvola.objectNode.position.x -= 0.1
        }
    }
    
    @IBAction func rightArrowPressed(_ sender: UIButton) {
        for valvola in self.virtualObjects {
            valvola.objectNode.position.x += 0.1
        }
    }
    
    @IBAction func holderModeTouched(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 1 {
            self.handsMode = .handsFree
        } else {
            self.handsMode = .normal
        }
    }
    
    @IBAction func multiplayerSgmentTouched(_ sender: UISegmentedControl) {
        if sender.selectedSegmentIndex == 0 {
            self.mpHostSession = MPHostSession(receivedDataHandler: receivedData)
            self.mpMode = .host
        } else {
            self.mpClientSession = MPClientSession(receivedDataHandler: receivedData)
            let mcBrowser = MCBrowserViewController(serviceType: MPClientSession.serviceType, session: self.mpClientSession!.session)
            mcBrowser.delegate = self
            self.present(mcBrowser, animated: true)
            self.mpMode = .client
        }
    }
    
    @IBAction func sendWorldMapTapped(_ sender: UIButton) {
        sceneView.session.getCurrentWorldMap { (worldMap, error) in
            guard let map = worldMap else { print("\(error!)"); return }
            guard let data = try? NSKeyedArchiver.archivedData(withRootObject: map, requiringSecureCoding: true)
                else { fatalError("Can't encode worldMap") }
            self.mpHostSession?.sendToAllPeers(data)
        }
    }
    
    
    // MARK: - Touches functions
    
    var removingObject : ValvolaConformance?
    
    @objc func didHold(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state != .began { return }
        let touchLocation = gestureRecognizer.location(in: self.view)
        
        switch editMode {
        case .placeMode:
            let hitResults = sceneView.hitTest(touchLocation, options: nil)
            if let res = hitResults.first, let selectedObject = getValvola(from: res.node) {
                if removingObject?.objectNode == selectedObject.objectNode { break }
                removeObject(selectedObject)
                
                sendRemoveCommand(selectedObject)
                
            } else {
                showTableView()
            }
        case .editSettingsMode:
            if self.movableEdit.isActive {
                self.movableEdit.reset()
            } else {
                let results = sceneView.hitTest(touchLocation, options: nil)
                guard let res = results.first else { break }
                guard let selectedObject = getValvola(from: res.node) as? AcceptsMovableInput else { break }
                print("Premuto un AcceptsMovableInput. Ora seleziona il MovableInput")
                movableEdit.editView.isHidden = false
                movableEdit.selectedValvolaWithMovableInput = selectedObject
                self.movableEdit.isActive = true
                self.movableEdit.isSelectingFinecorsa = true
            }
        default:
            showTableView()
        }
    }
    
    fileprivate func simulateTouch(in touchLocation: CGPoint) {
        switch editMode {
        case .moveMode:
            if handsMode == .handsFree, let currValvola = self.selectedValvola {
                let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlane)
                guard let hitResult = result.last else { return }
                let transform = SCNMatrix4.init(hitResult.worldTransform)
                var positionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
                
                positionVector.z = currValvola.objectNode.position.z
                move(valvola: currValvola, at: positionVector)
                self.selectedValvola = nil
            } else {
                let results = sceneView.hitTest(touchLocation, options: nil)
                guard let res = results.first else { break }
                guard let selectedObject = getValvola(from: res.node) else { selectedValvola = nil; break }
                self.selectedValvola = selectedObject
            }
        case .placeMode:
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlane)
            if let hitResult = result.last {
                let transform = SCNMatrix4.init(hitResult.worldTransform)
                let hitPositionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
                
                if let type = self.selectedType, let valvola = type.init() {
                    self.virtualObjects.append(valvola)
                    place(node: valvola.objectNode, at: hitPositionVector)
                    
                    sendAddCommand(valvola, hitPositionVector)
                }
            }
        case .editSettingsMode:
            let results = sceneView.hitTest(touchLocation, options: nil)
            
            if self.movableEdit.isActive {
                guard let res = results.first else { return }
                guard let selectedObject = getValvola(from: res.node) as? Movable else { break }
                if var valvolaThatAcceptsMovableInput = movableEdit.selectedValvolaWithMovableInput {
                    valvolaThatAcceptsMovableInput.movableInput = selectedObject
                    valvolaThatAcceptsMovableInput.listenValue = movableEdit.editView.sliderValue
                    movableEdit.reset()
                }
            } else {
                guard let res = results.first else { return }
                guard let selectedObject = getValvola(from: res.node) else { selectedValvola = nil; break }
                self.selectedValvola = selectedObject
                sizeStepper.value = Double(selectedObject.objectNode.scale.y * 100)
                rotationSlider.value = selectedObject.objectNode.eulerAngles.y.radiansToDegrees
            }
            
        case .circuitMode:
            let results = sceneView.hitTest(touchLocation, options: nil)
            guard let res = results.first else { break }
            guard let selectedIO = getInputOutput(from: res.node) else { break }
            if let tappableIO = selectedIO as? Tappable {
                tappableIO.tapped()
                break
            } else if let normalIO = selectedIO as? InputOutput {
                if firstSelectedIO == nil { firstSelectedIO = normalIO }
                else if secondSelectedIO == nil { secondSelectedIO = normalIO }
                
                if let firstIO = firstSelectedIO, let secondIO = secondSelectedIO {
                    if firstIO.inputsConnected.contains(secondIO) && secondIO.inputsConnected.contains(firstIO) {
                        removeLine(from: firstIO, to: secondIO)
                    } else {
                        createLine(from: firstIO, to: secondIO)
                    }
                    firstSelectedIO = nil
                    secondSelectedIO = nil
                }
            }
        case .saveMode:
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlane)
            guard let hitResult = result.last else { return }
            
            let transform = SCNMatrix4.init(hitResult.worldTransform)
            let hitPositionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
            
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.transparency = 0.2
            let saverNode = SCNNode(geometry: box)
            saverNode.position = hitPositionVector
            
            self.sceneView.scene.rootNode.addChildNode(saverNode)
            let saver = Saver(circuitName: "test", nodes: self.virtualObjects, nodeSaver: saverNode)
            do {
                try saver.save(to: "circuit3D.json")
                print("Salvato")
            } catch {
                print("\(error)")
            }
            
        case .loadMode, .load2DMode:
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlane)
            guard let hitResult = result.last else { return }
            
            let transform = SCNMatrix4.init(hitResult.worldTransform)
            let hitPositionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
            
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.transparency = 0.2
            let loaderNode = SCNNode(geometry: box)
            loaderNode.position = hitPositionVector
            loaderNode.name = "Loader"
            
            self.sceneView.scene.rootNode.addChildNode(loaderNode)
        
            do {
                var loader: Loader
                
                if editMode == .load2DMode {
                    let converter = Converter(fileName: "circuit2D.json")
                    converter.convert()
                    loader = try Loader(fileName: "circuit2D-3D.json", loaderNode: loaderNode)
                } else {
                    loader = try Loader(fileName: "circuit3D.json", loaderNode: loaderNode)
                }
                
                loader.load() { (valvole, wires) in
                    self.virtualObjects.append(contentsOf: valvole)
                    for valvola in valvole {
                        place(node: valvola.objectNode)
                    }
                    for wire in wires {
                        self.createLine(from: wire.0, to: wire.1)
                    }
                    print("Caricato")
                }
            } catch {
                self.showMessage("\(error)", duration: 3)
                print("\(error)")
            }
        }
        hideTableView()
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if handsMode == .normal {
            guard let touch = touches.first else { return }
            let touchLocation = touch.location(in: sceneView)
            
            simulateTouch(in: touchLocation)
        } else {
            simulateTouch(in: pointerView.center)
        }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: sceneView)
        
        switch editMode {
        case .moveMode:
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlane)
            if let hitResult = result.last {
                let transform = SCNMatrix4.init(hitResult.worldTransform)
                var positionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
                
                if let selectedVal = selectedValvola {
                    positionVector.z = selectedVal.objectNode.position.z
                    move(valvola: selectedVal, at: positionVector)
                }
            }
        default:
            break
        }
    }
    
    // MARK: - Generic functions
    
    func receivedData(_ data: Data, from peer: MCPeerID) {
        
        
            if let worldMap = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARWorldMap.self, from: data) {
                // Run the session with the received world map.
                let configuration = ARWorldTrackingConfiguration()
                configuration.planeDetection = .vertical
                configuration.initialWorldMap = worldMap
                sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])

                print("Received World Map! YEAHHHH")
            }
            else if let anchor = try? NSKeyedUnarchiver.unarchivedObject(ofClass: ARAnchor.self, from: data) {
                    // Add anchor to the session, ARSCNView delegate adds visible content.
                    sceneView.session.add(anchor: anchor)
            }
            else if let command = try? JSONDecoder().decode(AddCommand.self, from: data) {
                var objectType: ValvolaConformance.Type
                switch command.objectType {
                case .and: objectType = ValvolaAnd.self
                case .or: objectType = ValvolaOR.self
                case .pulsante: objectType = Pulsante.self
                case .treDueMS: objectType = TreDueMonostabileNC.self
                case .treDueBS: objectType = TreDueBistabile.self
                case .cinqueDueMS: objectType = CinqueDueMonostabile.self
                case .cinqueDueBS: objectType = CinqueDueBistabile.self
                case .timer: objectType = TimerObject.self
                case .frl: objectType = GruppoFRL.self
                case .cilindro: objectType = CilindroDoppioEffetto.self
                case .finecorsa: objectType = Finecorsa.self
                }
                
                if var valvola = objectType.init() {
                    valvola.id = command.newID
                    valvola.objectNode.eulerAngles = SCNVector3(cvector: command.eulerAngles)
                    self.virtualObjects.append(valvola)
                    self.place(node: valvola.objectNode, at: SCNVector3(cvector: command.position))
                }
            }
            else if let command = try? JSONDecoder().decode(MoveCommand.self, from: data) {
                
            }
            else if let command = try? JSONDecoder().decode(RotateCommand.self, from: data) {
                
            }
            else if let command = try? JSONDecoder().decode(RemoveCommand.self, from: data) {
                let valvole = virtualObjects.filter { command.objectIDs.contains($0.id) }
                valvole.forEach { removeObject( $0 ) }
            }
            else {
                    print("unknown data recieved from \(peer)")
            }
        
    }
    
    fileprivate func removeObject(_ selectedObject: ValvolaConformance) {
        removingObject = selectedObject
        let source = SCNAudioSource(fileNamed: "chargerUp.wav")!
        let playSoundAction = SCNAction.playAudio(source, waitForCompletion: false)
        let moveAction = SCNAction.moveBy(x: 0, y: 3, z: 0, duration: 2)
        
        let movementAction = SCNAction.group([playSoundAction, moveAction])
        
        let removeAction = SCNAction.removeFromParentNode()
        let waitAction = SCNAction.wait(duration: 1)
        
        let finishAction = SCNAction.run { (_) in
            self.removingObject = nil
            self.virtualObjects.removeAll(where: { $0.objectNode == selectedObject.objectNode })
        }
        let fullAction = SCNAction.sequence([waitAction, movementAction, removeAction, finishAction])
        
        
        let fire = SCNParticleSystem(named: "fire.scnp", inDirectory: nil)!
        fire.particleSize = 0.01
        selectedObject.objectNode.addParticleSystem(fire)
        
        selectedObject.objectNode.runAction(fullAction)
    }
    
    func place(node: SCNNode, at position: SCNVector3? = nil) {
        guard let currentFrame = self.sceneView.session.currentFrame else { return }
        let cameraTransform = SCNMatrix4.init(currentFrame.camera.transform)
        let cameraPosition = SCNVector3Make(cameraTransform.m41, cameraTransform.m42, cameraTransform.m43)
        
        node.scale = SCNVector3(0.1, 0.1, 0.1)
        if let positionGiven = position {
            node.position = positionGiven
            node.position.z += 0.02
        }
        node.look(at: cameraPosition)
//        node.eulerAngles.y += Float(180.0).degreesToRadians
        node.eulerAngles.y = currentFrame.camera.eulerAngles.y + Float(180.0).degreesToRadians
        node.eulerAngles.x = Float(180.0).degreesToRadians
        
        sceneView.scene.rootNode.addChildNode(node)
    }
    
    func move(valvola: ValvolaConformance, at location: SCNVector3) {
        valvola.objectNode.position = location
        needToRedraw = true
    }
    
    func showTableView() {
        let width = self.view.frame.size.width / 2
        let height = self.view.frame.size.height
        
        let rect = CGRect(origin: .zero, size: .init(width: width, height: height))
        self.tableView.frame = rect
        self.view?.addSubview(self.tableView)
        self.dataSource = ObjectCreationDataSource()
        tableView.dataSource = self.dataSource
        tableView.reloadData()
    }
    
    func hideTableView() {
        self.tableView.removeFromSuperview()
    }
    
    func getValvola(from node: SCNNode) -> ValvolaConformance? {
        for object in self.virtualObjects {
            if object.objectNode == node {
                return object
            }
        }
        return nil
    }
    
    func getInputOutput(from node: SCNNode) -> IOConformance? {
        for object in self.virtualObjects {
            for io in object.ios {
                if io.ioNode == node {
                    return io
                }
            }
        }
        return nil
    }
    
    func highlight(node: SCNNode?) {
        guard let realNode = node else { return }
        let material = realNode.geometry?.firstMaterial
        
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        
        SCNTransaction.completionBlock = {
            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.5
            
            material?.emission.contents = UIColor.black
            
            SCNTransaction.commit()
        }
        
        material?.emission.contents = UIColor.red
        
        SCNTransaction.commit()
    }
    
    func createLine(from firstIO: InputOutput, to secondIO: InputOutput) {
        let line = Line(from: firstIO, to: secondIO)
        line.draw()
        
        self.lines.append(line)
        sceneView.scene.rootNode.addChildNode(line.lineNode)
        
        firstIO.addWire(to: secondIO)
    }
    
    func removeLine(from firstIO: InputOutput, to secondIO: InputOutput) {
        let line = lines.first { (line) -> Bool in
            if line.firstIO == firstIO && line.secondIO == secondIO {
                return true
            } else if line.firstIO == secondIO && line.secondIO == firstIO {
                return true
            } else {
                return false
            }
        }
        
        if let lineSelected = line {
            self.lines.removeAll { (lineInArray) -> Bool in
                return lineSelected == lineInArray
            }
            firstIO.removeWire(secondIO)
            
            let removeAction = SCNAction.removeFromParentNode()
            
            lineSelected.lineNode.runAction(removeAction)
        }
    }
    
    func pointerTouched() {
        DispatchQueue.main.async {
            self.simulateTouch(in: self.pointerView.center)
        }
    }
    
    func setUpConnectivity() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
        
        if mcSession.connectedPeers.count <= 0 {
            self.mcADAssistant = MCAdvertiserAssistant(serviceType: "ARPneumatica", discoveryInfo: nil, session: mcSession)
            self.mcADAssistant.start()
        }
    }
    
    fileprivate func sendAddCommand(_ valvola: ValvolaConformance, _ hitPositionVector: SCNVector3) {
        let command = AddCommand(newID: valvola.id,
                                 objectType: valvola.objectType,
                                 position: Vector3(vector: hitPositionVector),
                                 eulerAngles: Vector3(vector: valvola.objectNode.eulerAngles))
        if let data = CustomEncoder.encode(object: command) {
            mpHostSession?.sendToAllPeers(data)
            mpClientSession?.sendToAllPeers(data)
        }
    }
    
    fileprivate func sendRemoveCommand(_ selectedObject: ValvolaConformance) {
        let command = RemoveCommand(objectIDs: [selectedObject.id],
                                    removeCommand: "remove-command")
        if let data = CustomEncoder.encode(object: command) {
            self.mpHostSession?.sendToAllPeers(data)
            self.mpClientSession?.sendToAllPeers(data)
        }
    }
}

extension ViewController: ARSCNViewDelegate {

    // MARK: - Circuit logic
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        if editMode != .circuitMode { return }
        for object in self.virtualObjects {
            object.ios.forEach { $0.update() }
            object.update()
        }
        
        for line in self.lines {
            line.update()
        }
        
        if needToRedraw {
            for line in self.lines {
                line.draw()
            }
            needToRedraw = false
        }
    }
}

extension ViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if let source = dataSource as? ObjectCreationDataSource {
            self.selectedType = source.getType(at: indexPath.row)
        }
        hideTableView()
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
}



extension ViewController: ARSessionDelegate {
    // MARK: - ARSCNViewDelegate
    
    func session(_ session: ARSession, didUpdate frame: ARFrame) {
        switch frame.worldMappingStatus {
        case .mapped:
            worldMapStateLabel.text = "MAPPATA"
            sendWorldMapButton.isEnabled = true
        default:
            worldMapStateLabel.text = "Non mappata"
            sendWorldMapButton.isEnabled = false
        }
    }
    
    /// - Tag: PlaceARContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        if !self.planeIsAdded && self.mpMode != .client {
            let plane = SCNPlane(width: 3, height: 4)
            let texture = #imageLiteral(resourceName: "dark")
            plane.firstMaterial?.diffuse.contents = texture
            plane.firstMaterial?.transparency = 0.5
            
            let newNode = SCNNode(geometry: plane)
            newNode.name = "background-plane"
            
            let transform = SCNMatrix4.init(planeAnchor.transform)
            let hitPositionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
            newNode.position = hitPositionVector
            
            sceneView.scene.rootNode.addChildNode(newNode)
        }
        
        self.planeIsAdded = true
        print("Trovato un plane! Ora fai quel cazzo che ti pare")
    }
    
    /// - Tag: UpdateARContent
    func renderer(_ renderer: SCNSceneRenderer, didUpdate node: SCNNode, for anchor: ARAnchor) {
        // Update only anchors and nodes set up by `renderer(_:didAdd:for:)`.
        guard let planeAnchor = anchor as? ARPlaneAnchor,
            let plane = node.childNodes.first as? Plane
            else { return }
        
        // Update ARSCNPlaneGeometry to the anchor's new estimated shape.
        if let planeGeometry = plane.meshNode.geometry as? ARSCNPlaneGeometry {
            planeGeometry.update(from: planeAnchor.geometry)
        }
        
        // Update extent visualization to the anchor's new bounding rectangle.
        if let extentGeometry = plane.extentNode.geometry as? SCNPlane {
            extentGeometry.width = CGFloat(planeAnchor.extent.x)
            extentGeometry.height = CGFloat(planeAnchor.extent.z)
            plane.extentNode.simdPosition = planeAnchor.center
        }
        
        // Update the plane's classification and the text position
        if #available(iOS 12.0, *),
            let classificationNode = plane.classificationNode,
            let classificationGeometry = classificationNode.geometry as? SCNText {
            let currentClassification = planeAnchor.classification.description
            if let oldClassification = classificationGeometry.string as? String, oldClassification != currentClassification {
                classificationGeometry.string = currentClassification
                classificationNode.centerAlign()
            }
        }
        
    }
    
    // MARK: - ARSessionObserver
    
    func sessionWasInterrupted(_ session: ARSession) {
        print("Session was interrupted")
    }
    
    func sessionInterruptionEnded(_ session: ARSession) {
        print("Session interruption ended")
        resetTracking()
    }
    
    func session(_ session: ARSession, didFailWithError error: Error) {
        print("Session failed: \(error.localizedDescription)")
        guard error is ARError else { return }
        
        let errorWithInfo = error as NSError
        let messages = [
            errorWithInfo.localizedDescription,
            errorWithInfo.localizedFailureReason,
            errorWithInfo.localizedRecoverySuggestion
        ]
        
        // Remove optional error messages.
        let errorMessage = messages.compactMap({ $0 }).joined(separator: "\n")
        
        DispatchQueue.main.async {
            // Present an alert informing about the error that has occurred.
            let alertController = UIAlertController(title: "The AR session failed.", message: errorMessage, preferredStyle: .alert)
            let restartAction = UIAlertAction(title: "Restart Session", style: .default) { _ in
                alertController.dismiss(animated: true, completion: nil)
                self.resetTracking()
            }
            alertController.addAction(restartAction)
            self.present(alertController, animated: true, completion: nil)
        }
    }
        
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}

extension ViewController : MCSessionDelegate, MCBrowserViewControllerDelegate {
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        
        if session == self.mcSession {
            guard let packet = try? JSONDecoder().decode(Packet.self, from: data) else { return }
            print("New Packet: \(packet)")
            DispatchQueue.main.async {
                switch packet.comand {
                case .touch: self.pointerTouched()
                case .setPlaceMode: self.editMode = .placeMode; self.showMessage("Place Mode")
                case .setMoveMode: self.editMode = .moveMode; self.showMessage("Move Mode")
                case .setEditMode: self.editMode = .editSettingsMode; self.showMessage("Edit Mode")
                case .setCircuitMode: self.editMode = .circuitMode; self.showMessage("Circuit Mode")
                case .andObject:
                    self.selectedType = ValvolaAnd.self
                    self.showMessage("AND", color: .blue)
                case .orObject:
                    self.selectedType = ValvolaOR.self
                    self.showMessage("OR", color: .blue)
                case .pulsanteObject:
                    self.selectedType = Pulsante.self
                    self.showMessage("Pulsante", color: .blue)
                case .treDueMSObject:
                    self.selectedType = TreDueMonostabileNC.self
                    self.showMessage("3/2 MS", color: .blue)
                case .treDueBSObject:
                    self.selectedType = TreDueBistabile.self
                    self.showMessage("3/2 BS", color: .blue)
                case .cinqueDueMSObject:
                    self.selectedType = CinqueDueMonostabile.self
                    self.showMessage("5/2 MS", color: .blue)
                case .cinqueDueBSObject:
                    self.selectedType = CinqueDueBistabile.self
                    self.showMessage("5/2 BS", color: .blue)
                case .timerObject:
                    self.selectedType = TimerObject.self
                    self.showMessage("Timer", color: .blue)
                case .frlObject:
                    self.selectedType = GruppoFRL.self
                    self.showMessage("FRL", color: .blue)
                case .cilindroObject:
                    self.selectedType = CilindroDoppioEffetto.self
                    self.showMessage("Cilindro DE", color: .blue)
                case .finecorsaObject:
                    self.selectedType = Finecorsa.self
                    self.showMessage("Finecorsa", color: .blue)
                }
            }
        }
        
        
    }
    
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        switch state {
        case MCSessionState.connected:
            print("Connected to session: \(session)")
            
        case MCSessionState.connecting:
            print("Connecting to session: \(session)")
        default:
            print("Did not connect to session: \(session)")
        }
    }
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {}
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {}
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {}
}
