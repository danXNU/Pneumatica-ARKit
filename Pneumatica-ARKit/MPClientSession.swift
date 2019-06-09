//
//  MPClientSession.swift
//  Pneumatica-ARKit
//
//  Created by Dani Tox on 08/06/2019.
//  Copyright © 2019 Dani Tox. All rights reserved.
//

import MultipeerConnectivity

class MPClientSession: NSObject {
    static let serviceType = "MP-circuit"
    
    private let myPeerID = MCPeerID(displayName: UIDevice.current.name)
    public var session: MCSession!
    private var serviceAdvertiser: MCAdvertiserAssistant!
    //    private var serviceAdvertiser: MCNearbyServiceAdvertiser!
    //    private var serviceBrowser: MCNearbyServiceBrowser!
    
    private let receivedDataHandler: (Data, MCPeerID) -> Void
    
    
    /// - Tag: MultipeerSetup
    init(receivedDataHandler: @escaping (Data, MCPeerID) -> Void ) {
        self.receivedDataHandler = receivedDataHandler
        
        super.init()
        
        session = MCSession(peer: myPeerID, securityIdentity: nil, encryptionPreference: .required)
        session.delegate = self
        
    }
    
    func sendToAllPeers(_ data: Data) {
        do {
            try session.send(data, toPeers: session.connectedPeers, with: .reliable)
        } catch {
            print("CLIENT: error sending data to peers: \(error.localizedDescription)")
        }
    }
    
    var connectedPeers: [MCPeerID] {
        return session.connectedPeers
    }
}

extension MPClientSession: MCSessionDelegate {
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        // not used
    }
    
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        receivedDataHandler(data, peerID)
    }
    
    func session(_ session: MCSession, didReceive stream: InputStream, withName streamName: String, fromPeer peerID: MCPeerID) {
        fatalError("This service does not send/receive streams.")
    }
    
    func session(_ session: MCSession, didStartReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, with progress: Progress) {
        fatalError("This service does not send/receive resources.")
    }
    
    func session(_ session: MCSession, didFinishReceivingResourceWithName resourceName: String, fromPeer peerID: MCPeerID, at localURL: URL?, withError error: Error?) {
        fatalError("This service does not send/receive resources.")
    }
    
}
