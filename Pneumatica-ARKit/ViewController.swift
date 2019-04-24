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
    var selectedValvola: ValvolaConformance? { didSet { highlight(valvola: selectedValvola) }  }
    var selectedType: ValvolaConformance.Type?
    
    var tableView: UITableView!
    var dataSource: UITableViewDataSource!
    
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
        case .placeMode:
            break
        case .editSettingsMode:
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
    
    func highlight(valvola: ValvolaConformance?) {
        guard let val = valvola else { return }
        let material = val.objectNode.geometry?.firstMaterial
        
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
    
}

extension ViewController: ARSCNViewDelegate {

    // MARK: - Circuit logic
    func renderer(_ renderer: SCNSceneRenderer, updateAtTime time: TimeInterval) {
        
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
