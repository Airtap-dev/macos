//
//  WebRTCService.swift
//  Airtap
//
//  Created by Aleksandr Litreev on 28.02.2021.
//  Copyright © 2021 Airtap OÜ. All rights reserved.
//

import Foundation
import WebRTC
import Combine

enum WebRTCServiceEvent {
    case receiveCandidate(String, Int32, String?)
}

class WebRTCService: NSObject {
    
    private var peerConnection: RTCPeerConnection!
    private var mediaConstraints: RTCMediaConstraints!
    
    private(set) var eventSubject = PassthroughSubject<WebRTCServiceEvent, Never>()
    
    override init() {
        super.init()
        
        let rtcPeerConnectionFactory = RTCPeerConnectionFactory()
        let rtcConfig = RTCConfiguration()
        
        rtcConfig.iceServers = [
            RTCIceServer(
                urlStrings: [
                    Config.rtcEndpoint
                ],
                username: "ninefingers",
                credential: "youhavetoberealistic"
            )
        ]
    
        mediaConstraints = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        peerConnection = rtcPeerConnectionFactory.peerConnection(
            with: rtcConfig,
            constraints: mediaConstraints,
            delegate: self
        )
    }
    
    func createOffer(completion: @escaping (String?) -> Void) {
        peerConnection.offer(for: mediaConstraints) { [weak self] sessionDescription, error in
            self?.peerConnection.setLocalDescription(sessionDescription!, completionHandler: { _ in
                completion(sessionDescription?.sdp)
            })
        }
    }
    
    func setOffer(_ sdp: String, completion: @escaping () -> Void) {
        let sessionDescription = RTCSessionDescription(type: .offer, sdp: sdp)
        peerConnection.setRemoteDescription(sessionDescription, completionHandler: { _ in
            completion()
        })
    }
    
    func createAnswer(completion: @escaping (String?) -> Void) {
        peerConnection.answer(for: mediaConstraints) { [weak self] sessionDescription, error in
            self?.peerConnection.setLocalDescription(sessionDescription!, completionHandler: { _ in
                completion(sessionDescription?.sdp)
            })
        }
    }
    
    func setAnswer(_ sdp: String, completion: @escaping () -> Void) {
        let sessionDescription = RTCSessionDescription(type: .answer, sdp: sdp)
        peerConnection.setRemoteDescription(sessionDescription, completionHandler: { _ in
            completion()
        })
    }
    
    func setCandidate(_ sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        peerConnection.add(RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid))
    }
}

extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        self.eventSubject.send(.receiveCandidate(candidate.sdp, candidate.sdpMLineIndex, candidate.sdpMid))
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        //no-op
    }
}
