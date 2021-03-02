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
    case receiveCandidate(Int, String, Int32, String?)
}

protocol WebRTCServing {
    var eventSubject: PassthroughSubject<WebRTCServiceEvent, Never> { get }
    
    func createConnection(id: Int)
    func closeConnection(id: Int)
    func createOffer(for id: Int, completion: @escaping (String?) -> Void)
    func setOffer(for id: Int, sdp: String, completion: @escaping () -> Void)
    func createAnswer(for id: Int, completion: @escaping (String?) -> Void)
    func setAnswer(for id: Int, sdp: String, completion: @escaping () -> Void)
    func setCandidate(for id: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?)
    
}

class WebRTCService: NSObject, WebRTCServing {
    
    private let rtcPeerConnectionFactory = RTCPeerConnectionFactory()
    private let rtcMediaConstraints: RTCMediaConstraints = RTCMediaConstraints(
        mandatoryConstraints: [
            "OfferToReceiveAudio": "true"
        ],
        optionalConstraints: nil
    )
    private let rtcConfig = RTCConfiguration()
    
    private var peerConnections: [Int: RTCPeerConnection] = [:]
    
    private(set) var eventSubject = PassthroughSubject<WebRTCServiceEvent, Never>()
    
    override init() {
        super.init()

        rtcConfig.iceServers = [
            RTCIceServer(
                urlStrings: [
                    Config.rtcEndpoint
                ],
                username: "ninefingers",
                credential: "youhavetoberealistic",
                tlsCertPolicy: .insecureNoCheck
            )
        ]
        rtcConfig.sdpSemantics = .unifiedPlan
    }
    
    func createConnection(id: Int) {
        let peerConnection = rtcPeerConnectionFactory.peerConnection(
            with: rtcConfig,
            constraints: rtcMediaConstraints,
            delegate: self
        )
        
        let trans = peerConnection.addTransceiver(of: .audio)
        trans.direction = .sendRecv
        trans.receiver.delegate = self
        
        let mediaStream = rtcPeerConnectionFactory.mediaStream(withStreamId: "1")
        let audioSource = rtcPeerConnectionFactory.audioSource(with: rtcMediaConstraints)
        let audioTrack = rtcPeerConnectionFactory.audioTrack(with: audioSource, trackId: "1")

        peerConnection.add(audioTrack, streamIds: ["1"])
   
        peerConnections[id] = peerConnection
    }
    
    func closeConnection(id: Int) {
        peerConnections[id]?.close()
        peerConnections.removeValue(forKey: id)
    }
    
    func createOffer(for id: Int, completion: @escaping (String?) -> Void) {
        guard let peerConnection = peerConnections[id] else { return }
        
        peerConnection.offer(for: rtcMediaConstraints) { sessionDescription, error in
            peerConnection.setLocalDescription(sessionDescription!, completionHandler: { _ in
                completion(sessionDescription?.sdp)
            })
        }
    }
    
    func setOffer(for id: Int, sdp: String, completion: @escaping () -> Void) {
        if peerConnections[id]?.localDescription != nil {
            peerConnections[id]?.close()
            createConnection(id: id)
        }
        
        guard let peerConnection = peerConnections[id] else { return }
        
        let sessionDescription = RTCSessionDescription(type: .offer, sdp: sdp)
        peerConnection.setRemoteDescription(sessionDescription, completionHandler: { err in
            completion()
        })
    }
    
    func createAnswer(for id: Int, completion: @escaping (String?) -> Void) {
        guard let peerConnection = peerConnections[id] else { return }
        
        peerConnection.answer(for: rtcMediaConstraints) { sessionDescription, error in
            peerConnection.setLocalDescription(sessionDescription!, completionHandler: { _ in
                completion(sessionDescription?.sdp)
            })
        }
    }
    
    func setAnswer(for id: Int, sdp: String, completion: @escaping () -> Void) {
        guard let peerConnection = peerConnections[id] else { return }
        
        let sessionDescription = RTCSessionDescription(type: .answer, sdp: sdp)
        peerConnection.setRemoteDescription(sessionDescription, completionHandler: { _ in
            completion()
        })
    }
    
    func setCandidate(for id: Int, sdp: String, sdpMLineIndex: Int32, sdpMid: String?) {
        guard let peerConnection = peerConnections[id] else { return }
        
        peerConnection.add(RTCIceCandidate(sdp: sdp, sdpMLineIndex: sdpMLineIndex, sdpMid: sdpMid))
    }
}

extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //no-op
        print("RTC: \(stateChanged)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        //no-op
        print("RTC: \(stream)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        //no-op
        print("RTC: \(stream)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        //no-op
        print("RTC: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //no-op
        print("RTC: \(newState)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if let id = peerConnections.keyForValue(peerConnection) {
            self.eventSubject.send(.receiveCandidate(id, candidate.sdp, candidate.sdpMLineIndex, candidate.sdpMid))
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //no-op
        print("RTC: \(candidates)")
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        //no-op
        print("RTC: \(dataChannel)")
    }
}

extension WebRTCService: RTCRtpReceiverDelegate {
    func rtpReceiver(_ rtpReceiver: RTCRtpReceiver, didReceiveFirstPacketFor mediaType: RTCRtpMediaType) {
        print("RTC: \(mediaType)")
    }
}
