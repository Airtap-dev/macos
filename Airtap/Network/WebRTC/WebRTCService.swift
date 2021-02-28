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
import AVFoundation

enum WebRTCServiceEvent {
    case receiveCandidate(Int, String, Int32, String?)
    case receiveData(Data)
}

protocol WebRTCServing {
    var eventSubject: PassthroughSubject<WebRTCServiceEvent, Never> { get }
    
    func muteAudio(id: Int)
    func unmuteAudio(id: Int)
    
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
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue
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
    
    func muteAudio(id: Int) {
        self.setAudioEnabled(id: id, isEnabled: false)
    }
    
    func unmuteAudio(id: Int) {
        self.setAudioEnabled(id: id, isEnabled: true)
    }
    
    func createConnection(id: Int) {
        let peerConnection = rtcPeerConnectionFactory.peerConnection(
            with: rtcConfig,
            constraints: rtcMediaConstraints,
            delegate: self
        )
        
        peerConnections[id] = peerConnection
        createMediaSenders(id: id)
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
    
    // MARK: - Private -
    
    private func createAudioTrack(id: Int) -> RTCAudioTrack {
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = rtcPeerConnectionFactory.audioSource(with: audioConstrains)
        let audioTrack = rtcPeerConnectionFactory.audioTrack(with: audioSource, trackId: "audio_\(id)")
        return audioTrack
    }
    
    private func createMediaSenders(id: Int) {
        let streamId = "stream_\(id)"
        
        // Audio
        let audioTrack = self.createAudioTrack(id: id)
        self.peerConnections[id]?.add(audioTrack, streamIds: [streamId])
    }
    
    private func setAudioEnabled(id: Int, isEnabled: Bool) {
        setTrackEnabled(RTCAudioTrack.self, id: id, isEnabled: isEnabled)
    }
}

extension WebRTCService {
    private func setTrackEnabled<T: RTCMediaStreamTrack>(_ type: T.Type, id: Int, isEnabled: Bool) {
        peerConnections[id]?.transceivers
            .compactMap { return $0.sender.track as? T }
            .forEach { $0.isEnabled = isEnabled }
    }
}

extension WebRTCService: RTCDataChannelDelegate {
    func dataChannelDidChangeState(_ dataChannel: RTCDataChannel) {
        debugPrint("dataChannel did change state: \(dataChannel.readyState)")
    }
    
    func dataChannel(_ dataChannel: RTCDataChannel, didReceiveMessageWith buffer: RTCDataBuffer) {
        eventSubject.send(.receiveData(buffer.data))
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
