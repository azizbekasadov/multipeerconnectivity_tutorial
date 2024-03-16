//
//  ViewController.swift
//  MCChat
//
//  Created by Azizbek Asadov on 16/03/24.
//

import UIKit
import MultipeerConnectivity

class ViewController: UIViewController {

    @IBOutlet private weak var textView: UITextView!
    @IBOutlet private weak var sendButton: UIButton!
    @IBOutlet private weak var messageTextField: UITextField!
    
    private var peerID: MCPeerID!
    private var mcSession: MCSession!
    private var mcAdAssistant: MCAdvertiserAssistant!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupPeer()
    }

    private func setupPeer() {
        peerID = MCPeerID(displayName: UIDevice.current.name)
        mcSession = MCSession(peer: peerID, securityIdentity: nil, encryptionPreference: .required)
        mcSession.delegate = self
    }
    
    @IBAction private func handleSendButtonPressed(_ sender: UIButton) {
        guard let message = messageTextField.text, !message.isEmpty else {
            return
        }
        
        send(message)
        messageTextField.text = nil
    }
    
    @IBAction private func browseForPeers(_ sender: UIButton) {
        let mcBrowser = MCBrowserViewController(serviceType: "chat", session: mcSession)
        mcBrowser.delegate = self
        present(mcBrowser, animated: true)
    }
    
    private func send(_ message: String) {
        if mcSession.connectedPeers.count > 0 {
            do {
                guard let data = message.data(using: .utf8) else {
                    throw NSError(domain: "Message", code: -122)
                }
                try mcSession.send(data, toPeers: mcSession.connectedPeers, with: .reliable)
                textView.text.append("You: \(message)")
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}

extension ViewController: MCSessionDelegate {
    func session(_ session: MCSession, didReceive data: Data, fromPeer peerID: MCPeerID) {
        let workItem = DispatchWorkItem {
            if let message = String(data: data, encoding: .utf8) {
                self.textView.text.append(message)
            }
        }
        
        DispatchQueue.main.async(execute: workItem)
    }
    
    func session(_ session: MCSession, peer peerID: MCPeerID, didChange state: MCSessionState) {
        let workItem = DispatchWorkItem {
            switch state {
            case .notConnected:
                self.textView.text.append("\(peerID.displayName) not connected.")
            case .connecting:
                break
            case .connected:
                self.textView.text.append("\(peerID.displayName) connected.")
            @unknown default:
                break
            }
            
            
        }
    }
}

extension ViewController: MCBrowserViewControllerDelegate {
    func browserViewControllerDidFinish(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
    
    func browserViewControllerWasCancelled(_ browserViewController: MCBrowserViewController) {
        browserViewController.dismiss(animated: true)
    }
}
