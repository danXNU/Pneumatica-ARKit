/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Main view controller for the AR experience.
 */

import UIKit
import SceneKit
import ARKit

enum EditMode : String {
    case moveMode = "Move"
    case editSettingsMode = "Edit"
    case placeMode = "Place"
    case circuitMode = "Circuit"
    case saveMode = "Save"
    case loadMode = "Load"
}

class ViewController: UIViewController {
    // MARK: - IBOutlets

    @IBOutlet weak var sceneView: ARSCNView!
    @IBOutlet var editModesButtons: [UIButton]!
    @IBOutlet weak var sizeStepper: UIStepper!
    
    var editMode : EditMode = .placeMode {
        didSet {
            guard let modesButton = self.editModesButtons else { return }
            for button in modesButton {
                if button.currentTitle == editMode.rawValue {
                    button.titleLabel?.backgroundColor = .green
                } else {
                    button.titleLabel?.backgroundColor = .yellow
                }
            }
            self.sizeStepper.isHidden = (editMode != .editSettingsMode)
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
        
        let holdGesture = UILongPressGestureRecognizer(target: self, action: #selector(didHold(_:)))
        self.view.addGestureRecognizer(holdGesture)
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
    
    @IBAction func moveButtonTapped(_ sender: UIButton) {
        editMode = .moveMode
    }
    
    @IBAction func placeButtonTapped(_ sender: UIButton) {
        editMode = .placeMode
    }
    
    @IBAction func editButtonTapped(_ sender: UIButton) {
        editMode = .editSettingsMode
    }
    
    @IBAction func circuitButtonTapped(_ sender: UIButton) {
        editMode = .circuitMode
    }
    
    @IBAction func saveButtonPressed(_ sender: UIButton) {
        editMode = .saveMode
    }
    
    @IBAction func loadButtonPressed(_ sender: UIButton) {
        editMode = .loadMode
    }
    
    @objc func didHold(_ gestureRecognizer: UILongPressGestureRecognizer) {
        showTableView()
    }
    
    @IBAction func stpperTapped(_ sender: UIStepper) {
        guard let valvola = selectedValvola else { return }
        let value = Float(sender.value / 100.0)
        valvola.objectNode.scale = SCNVector3(value, value, value)
    }
    
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: sceneView)
        
        switch editMode {
        case .moveMode:
            let results = sceneView.hitTest(touchLocation, options: nil)
            guard let res = results.first else { break }
            guard let selectedObject = getValvola(from: res.node) else { break }
            self.selectedValvola = selectedObject
        case .placeMode:
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
            if let hitResult = result.last {
                let transform = SCNMatrix4.init(hitResult.worldTransform)
                let hitPositionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
                
                if let type = self.selectedType {
                    place(valvola: type, at: hitPositionVector)
                }
            }
        case .editSettingsMode:
            let results = sceneView.hitTest(touchLocation, options: nil)
            guard let res = results.first else { break }
            guard let selectedObject = getValvola(from: res.node) else { break }
            self.selectedValvola = selectedObject
            sizeStepper.value = Double(selectedObject.objectNode.scale.y * 100)
            
            //also, set the edit view
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
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
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
                try saver.save(to: "test")
                print("Salvato")
            } catch {
                print("\(error)")
            }

        case .loadMode:
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
            guard let hitResult = result.last else { return }
            
            let transform = SCNMatrix4.init(hitResult.worldTransform)
            let hitPositionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
            
            let box = SCNBox(width: 0.01, height: 0.01, length: 0.01, chamferRadius: 0)
            box.firstMaterial?.transparency = 0.2
            let loaderNode = SCNNode(geometry: box)
            loaderNode.position = hitPositionVector
            
            self.sceneView.scene.rootNode.addChildNode(loaderNode)
            
            do {
                let loader = try Loader(fileName: "test", loaderNode: loaderNode)
                loader.load(sceneRootNode: self.sceneView.scene.rootNode) { (valvole, wires) in
                    self.virtualObjects = valvole
                    for wire in wires {
                        self.createLine(from: wire.0, to: wire.1)
                    }
                    print("Caricato")
                }
            } catch {
                print("\(error)")
            }
            
        }
        hideTableView()
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let touchLocation = touch.location(in: sceneView)
        
        switch editMode {
        case .moveMode:
            let result = sceneView.hitTest(touchLocation, types: ARHitTestResult.ResultType.existingPlaneUsingExtent)
            if let hitResult = result.last {
                let transform = SCNMatrix4.init(hitResult.worldTransform)
                let positionVector = SCNVector3Make(transform.m41, transform.m42, transform.m43)
                
                if let selectedVal = selectedValvola {
                    move(valvola: selectedVal, at: positionVector)
                }
            }
        default:
            break
        }
    }
    
    func place(valvola: ValvolaConformance.Type, at position: SCNVector3) {
        if let virtualObject = valvola.init() {
            virtualObject.objectNode.scale = SCNVector3(0.1, 0.1, 0.1)
            virtualObject.objectNode.position = position
            self.virtualObjects.append(virtualObject)
            sceneView.scene.rootNode.addChildNode(virtualObject.objectNode)
        }
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
    
}

extension ViewController: ARSCNViewDelegate {

    // MARK: - Circuit logic
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
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
    
    /// - Tag: PlaceARContent
    func renderer(_ renderer: SCNSceneRenderer, didAdd node: SCNNode, for anchor: ARAnchor) {
        // Place content only for anchors found by plane detection.
        guard let planeAnchor = anchor as? ARPlaneAnchor else { return }
        
        // Create a custom object to visualize the plane geometry and extent.
        let plane = Plane(anchor: planeAnchor, in: sceneView)
        
        // Add the visualization to the ARKit-managed node so that it tracks
        // changes in the plane anchor as plane estimation continues.
        node.addChildNode(plane)
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
    
    // MARK: - Private methods
        
    private func resetTracking() {
        let configuration = ARWorldTrackingConfiguration()
        configuration.planeDetection = [.horizontal, .vertical]
        sceneView.session.run(configuration, options: [.resetTracking, .removeExistingAnchors])
    }
}
