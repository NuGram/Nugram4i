import Foundation
import Postbox
import SwiftSignalKit
import TelegramApi
import MtProtoKit

private let nugramGhostModeUserDefaultsKey = "nugram_ghost_mode_enabled"

private final class NugramGhostModeState {
    let lock = NSLock()
    var readRequestBypass = 0
    var presenceRequestBypass = 0
}

private let nugramGhostModeState = NugramGhostModeState()

public func nugramGhostModeEnabled() -> Bool {
    return UserDefaults.standard.bool(forKey: nugramGhostModeUserDefaultsKey)
}

public func nugramGhostModePersistEnabled(_ enabled: Bool) {
    UserDefaults.standard.set(enabled, forKey: nugramGhostModeUserDefaultsKey)
}

public func nugramGhostModeSetEnabled(_ enabled: Bool, network: Network?) {
    nugramGhostModePersistEnabled(enabled)
    guard let network else {
        return
    }
    if enabled {
        nugramGhostModeSendOfflineNow(network: network)
    } else {
        nugramGhostModeSendOnlineNow(network: network)
    }
}

public func nugramGhostModeShouldSendTypingActivities() -> Bool {
    return !nugramGhostModeEnabled()
}

public func nugramGhostModeShouldSendReadReceipts() -> Bool {
    guard nugramGhostModeEnabled() else {
        return true
    }
    return nugramGhostModeConsumeReadBypass()
}

public func nugramGhostModeShouldSendStoryReadReceipts() -> Bool {
    return !nugramGhostModeEnabled()
}

public func nugramGhostModeEffectivePresenceIsOnline(_ isOnline: Bool) -> Bool {
    guard nugramGhostModeEnabled() else {
        return isOnline
    }
    if nugramGhostModeConsumePresenceBypass() {
        return isOnline
    }
    return false
}

public func nugramGhostModeHandleOutgoingAction(network: Network, postbox: Postbox, stateManager: AccountStateManager, peerId: PeerId, maxReadId: Int32?) -> Signal<Void, NoError> {
    let enabled = nugramGhostModeEnabled()
    guard enabled else {
        return .complete()
    }
    return nugramGhostModeMarkPeerRead(network: network, postbox: postbox, stateManager: stateManager, peerId: peerId, maxReadId: maxReadId)
    |> then(.single(Void()))
    |> beforeNext { _ in
        nugramGhostModeSendOfflineNow(network: network)
    }
}

public func nugramGhostModeSendOfflineNow(network: Network) {
    nugramGhostModeAllowNextPresenceRequest()
    let _ = (network.request(Api.functions.account.updateStatus(offline: .boolTrue))
    |> `catch` { _ -> Signal<Api.Bool, NoError> in
        return .single(.boolFalse)
    }).start()
}

public func nugramGhostModeSendOnlineNow(network: Network) {
    nugramGhostModeAllowNextPresenceRequest()
    let _ = (network.request(Api.functions.account.updateStatus(offline: .boolFalse))
    |> `catch` { _ -> Signal<Api.Bool, NoError> in
        return .single(.boolFalse)
    }).start()
}

public func nugramGhostModeAllowNextReadRequest() {
    nugramGhostModeState.lock.lock()
    nugramGhostModeState.readRequestBypass += 1
    nugramGhostModeState.lock.unlock()
}

public func nugramGhostModeAllowNextPresenceRequest() {
    nugramGhostModeState.lock.lock()
    nugramGhostModeState.presenceRequestBypass += 1
    nugramGhostModeState.lock.unlock()
}

private func nugramGhostModeConsumeReadBypass() -> Bool {
    nugramGhostModeState.lock.lock()
    defer {
        nugramGhostModeState.lock.unlock()
    }
    guard nugramGhostModeState.readRequestBypass > 0 else {
        return false
    }
    nugramGhostModeState.readRequestBypass -= 1
    return true
}

private func nugramGhostModeConsumePresenceBypass() -> Bool {
    nugramGhostModeState.lock.lock()
    defer {
        nugramGhostModeState.lock.unlock()
    }
    guard nugramGhostModeState.presenceRequestBypass > 0 else {
        return false
    }
    nugramGhostModeState.presenceRequestBypass -= 1
    return true
}

private func nugramGhostModeMarkPeerRead(network: Network, postbox: Postbox, stateManager: AccountStateManager, peerId: PeerId, maxReadId: Int32?) -> Signal<Void, NoError> {
    guard peerId.namespace != Namespaces.Peer.SecretChat else {
        return .complete()
    }
    let effectiveMaxReadId = maxReadId ?? (Int32.max - 1)
    return postbox.transaction { transaction -> (Api.InputPeer, Api.InputChannel?)? in
        guard let peer = transaction.getPeer(peerId), let inputPeer = apiInputPeer(peer) else {
            return nil
        }
        if case let .inputPeerChannel(data) = inputPeer {
            return (inputPeer, .inputChannel(.init(channelId: data.channelId, accessHash: data.accessHash)))
        } else {
            return (inputPeer, nil)
        }
    }
    |> mapToSignal { inputData -> Signal<Void, NoError> in
        guard let (inputPeer, inputChannel) = inputData else {
            return .complete()
        }
        nugramGhostModeAllowNextReadRequest()
        if let inputChannel {
            return network.request(Api.functions.channels.readHistory(channel: inputChannel, maxId: effectiveMaxReadId))
            |> `catch` { _ -> Signal<Api.Bool, NoError> in
                return .single(.boolFalse)
            }
            |> mapToSignal { _ -> Signal<Void, NoError> in
                return .complete()
            }
        } else {
            return network.request(Api.functions.messages.readHistory(peer: inputPeer, maxId: effectiveMaxReadId))
            |> map(Optional.init)
            |> `catch` { _ -> Signal<Api.messages.AffectedMessages?, NoError> in
                return .single(nil)
            }
            |> mapToSignal { result -> Signal<Void, NoError> in
                if let result {
                    switch result {
                    case let .affectedMessages(data):
                        stateManager.addUpdateGroups([.updatePts(pts: data.pts, ptsCount: data.ptsCount)])
                    }
                }
                return .complete()
            }
        }
    }
}
