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

enum WebRTCServiceEvent: Equatable {
    case ready
    case receiveCandidate(Int, String, Int32, String?)
}

protocol WebRTCServing {
    var eventSubject: PassthroughSubject<WebRTCServiceEvent, Never> { get }
    
    func setServerList(_ servers: [Server])
    
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
    private let authProvider: AuthProviding
    
    private let rtcMediaConstraints: RTCMediaConstraints = RTCMediaConstraints(
        mandatoryConstraints: [
            kRTCMediaConstraintsOfferToReceiveAudio: kRTCMediaConstraintsValueTrue
        ],
        optionalConstraints: nil
    )
    private let rtcConfig = RTCConfiguration()
    private var peerConnections: [Int: RTCPeerConnection] = [:]
    private var peerConnectionFactories: [Int: RTCPeerConnectionFactory] = [:]
    
    private(set) var eventSubject = PassthroughSubject<WebRTCServiceEvent, Never>()
    private var cancellables = Set<AnyCancellable>()
    
    init(authProvider: AuthProviding) {
        self.authProvider = authProvider
        super.init()
        
        self.authProvider.eventSubject
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                if case .signedOut = event {
                    self?.peerConnections.forEach {
                        $0.value.close()
                    }
                    self?.peerConnections = [:]
                    self?.rtcConfig.iceServers = []
                }
            }
            .store(in: &cancellables)
    }
    
    func setServerList(_ servers: [Server]) {
        rtcConfig.disableIPV6 = true
        rtcConfig.sdpSemantics = .unifiedPlan
        rtcConfig.iceServers = servers.map { server in
            RTCIceServer(
                urlStrings: [
                    server.url
                ],
                username: server.username,
                credential: server.password,
                tlsCertPolicy: .insecureNoCheck
            )
        }
        
        eventSubject.send(.ready)
    }
    
    func muteAudio(id: Int) {
        self.setAudioEnabled(id: id, isEnabled: false)
    }
    
    func unmuteAudio(id: Int) {
        self.setAudioEnabled(id: id, isEnabled: true)
    }
    
    func createConnection(id: Int) {
        let factory = RTCPeerConnectionFactory()
        peerConnectionFactories[id] = factory
        
        let peerConnection = factory.peerConnection(
            with: rtcConfig,
            constraints: rtcMediaConstraints,
            delegate: self
        )
        
        let audioTrack = self.createAudioTrack(id: id)
        peerConnection.add(audioTrack, streamIds: ["stream_\(id)"])
        
        let stream = factory.mediaStream(withStreamId: "stream_\(id)")
        stream.addAudioTrack(audioTrack)
    
        peerConnections[id] = peerConnection
        muteAudio(id: id)
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
        peerConnections[id] = nil
        createConnection(id: id)
        
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
        guard let factory = peerConnectionFactories[id] else { fatalError() }
        let audioConstrains = RTCMediaConstraints(mandatoryConstraints: nil, optionalConstraints: nil)
        let audioSource = factory.audioSource(with: audioConstrains)
        let audioTrack = factory.audioTrack(with: audioSource, trackId: "audio_\(id)")
        return audioTrack
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

extension WebRTCService: RTCPeerConnectionDelegate {
    func peerConnectionShouldNegotiate(_ peerConnection: RTCPeerConnection) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange stateChanged: RTCSignalingState) {
        //no-op
        if stateChanged == .closed, let id = peerConnections.keyForValue(peerConnection) {
            peerConnections.removeValue(forKey: id)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didAdd stream: RTCMediaStream) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove stream: RTCMediaStream) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceConnectionState) {
        if newState == .disconnected, let id = peerConnections.keyForValue(peerConnection) {
            self.closeConnection(id: id)
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didChange newState: RTCIceGatheringState) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didGenerate candidate: RTCIceCandidate) {
        if let id = peerConnections.keyForValue(peerConnection) {
            self.eventSubject.send(.receiveCandidate(id, candidate.sdp, candidate.sdpMLineIndex, candidate.sdpMid))
        }
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didRemove candidates: [RTCIceCandidate]) {
        //no-op
    }
    
    func peerConnection(_ peerConnection: RTCPeerConnection, didOpen dataChannel: RTCDataChannel) {
        //no-op
    }
}
