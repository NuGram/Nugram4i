import Foundation
import UIKit
import Display
import SwiftSignalKit
import TelegramCore
import TelegramPresentationData
import TelegramUIPreferences
import ItemListUI
import AccountContext

private final class NugramSettingsControllerArguments {
    let openGeneral: () -> Void
    let openAppearance: () -> Void
    let updateGhostMode: (Bool) -> Void
    let updateZalgoRemover: (Bool) -> Void
    let updateRestrictedForward: (Bool) -> Void
    
    init(openGeneral: @escaping () -> Void, openAppearance: @escaping () -> Void, updateGhostMode: @escaping (Bool) -> Void, updateZalgoRemover: @escaping (Bool) -> Void, updateRestrictedForward: @escaping (Bool) -> Void) {
        self.openGeneral = openGeneral
        self.openAppearance = openAppearance
        self.updateGhostMode = updateGhostMode
        self.updateZalgoRemover = updateZalgoRemover
        self.updateRestrictedForward = updateRestrictedForward
    }
}

private enum NugramSettingsSection: Int32 {
    case categories
    case general
}

private enum NugramSettingsControllerEntry: ItemListNodeEntry {
    case general
    case appearance
    case supportInfo
    case comingSoon
    case ghostMode(Bool)
    case ghostModeInfo
    case zalgoRemover(Bool)
    case zalgoRemoverInfo
    case restrictedForward(Bool)
    case restrictedForwardInfo
    
    var section: ItemListSectionId {
        switch self {
        case .general, .appearance, .supportInfo:
            return NugramSettingsSection.categories.rawValue
        case .comingSoon, .ghostMode, .ghostModeInfo, .zalgoRemover, .zalgoRemoverInfo, .restrictedForward, .restrictedForwardInfo:
            return NugramSettingsSection.general.rawValue
        }
    }
    
    var stableId: Int32 {
        switch self {
        case .general:
            return 0
        case .appearance:
            return 1
        case .supportInfo:
            return 2
        case .comingSoon:
            return 3
        case .ghostMode:
            return 4
        case .ghostModeInfo:
            return 5
        case .zalgoRemover:
            return 6
        case .zalgoRemoverInfo:
            return 7
        case .restrictedForward:
            return 8
        case .restrictedForwardInfo:
            return 9
        }
    }
    
    static func <(lhs: NugramSettingsControllerEntry, rhs: NugramSettingsControllerEntry) -> Bool {
        return lhs.stableId < rhs.stableId
    }
    
    func item(presentationData: ItemListPresentationData, arguments: Any) -> ListViewItem {
        let arguments = arguments as! NugramSettingsControllerArguments
        switch self {
        case .general:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Nugram_General, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openGeneral()
            })
        case .appearance:
            return ItemListDisclosureItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Nugram_Appearance, label: "", sectionId: self.section, style: .blocks, action: {
                arguments.openAppearance()
            })
        case .supportInfo:
            return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.Nugram_SupportPrompt), sectionId: self.section)
        case .comingSoon:
            return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.Nugram_ComingSoon), sectionId: self.section, textAlignment: .center)
        case let .ghostMode(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Nugram_GhostMode, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateGhostMode(value)
            })
        case .ghostModeInfo:
            return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.Nugram_GhostModeInfo), sectionId: self.section)
        case let .zalgoRemover(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Nugram_ZalgoRemover, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateZalgoRemover(value)
            })
        case .zalgoRemoverInfo:
            return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.Nugram_ZalgoRemoverInfo), sectionId: self.section)
        case let .restrictedForward(value):
            return ItemListSwitchItem(presentationData: presentationData, systemStyle: .glass, title: presentationData.strings.Nugram_RestrictedForward, value: value, sectionId: self.section, style: .blocks, updated: { value in
                arguments.updateRestrictedForward(value)
            })
        case .restrictedForwardInfo:
            return ItemListTextItem(presentationData: presentationData, text: .plain(presentationData.strings.Nugram_RestrictedForwardInfo), sectionId: self.section)
        }
    }
}

private enum NugramSettingsMode {
    case root
    case general
    case appearance
}

private func nugramSettingsControllerEntries(mode: NugramSettingsMode, settings: ExperimentalUISettings) -> [NugramSettingsControllerEntry] {
    switch mode {
    case .root:
        return [
            .general,
            .appearance,
            .supportInfo
        ]
    case .general:
        return [
            .ghostMode(settings.nugramGhostMode),
            .ghostModeInfo,
            .zalgoRemover(settings.nugramZalgoRemover),
            .zalgoRemoverInfo,
            .restrictedForward(settings.nugramRestrictedForward),
            .restrictedForwardInfo
        ]
    case .appearance:
        return [
            .comingSoon
        ]
    }
}

private func nugramSettingsController(context: AccountContext, mode: NugramSettingsMode) -> ViewController {
    var pushControllerImpl: ((ViewController) -> Void)?
    
    let arguments = NugramSettingsControllerArguments(
        openGeneral: {
            pushControllerImpl?(nugramSettingsController(context: context, mode: .general))
        },
        openAppearance: {
            pushControllerImpl?(nugramSettingsController(context: context, mode: .appearance))
        },
        updateGhostMode: { value in
            nugramGhostModeSetEnabled(value, network: context.account.network)
            let _ = updateExperimentalUISettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                settings.nugramGhostMode = value
                return settings
            }).start()
        },
        updateZalgoRemover: { value in
            let _ = updateExperimentalUISettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                settings.nugramZalgoRemover = value
                return settings
            }).start()
        },
        updateRestrictedForward: { value in
            let _ = updateExperimentalUISettingsInteractively(accountManager: context.sharedContext.accountManager, { settings in
                var settings = settings
                settings.nugramRestrictedForward = value
                return settings
            }).start()
        }
    )
    
    let signal = combineLatest(queue: .mainQueue(),
        context.sharedContext.presentationData,
        context.sharedContext.accountManager.sharedData(keys: [ApplicationSpecificSharedDataKeys.experimentalUISettings])
    )
    |> map { presentationData, sharedData -> (ItemListControllerState, (ItemListNodeState, Any)) in
        let settings = sharedData.entries[ApplicationSpecificSharedDataKeys.experimentalUISettings]?.get(ExperimentalUISettings.self) ?? .defaultSettings
        let title: String
        switch mode {
        case .root:
            title = presentationData.strings.Nugram_Title
        case .general:
            title = presentationData.strings.Nugram_General
        case .appearance:
            title = presentationData.strings.Nugram_Appearance
        }
        let controllerState = ItemListControllerState(presentationData: ItemListPresentationData(presentationData), title: .text(title), leftNavigationButton: nil, rightNavigationButton: nil, backNavigationButton: ItemListBackButton(title: presentationData.strings.Common_Back))
        let listState = ItemListNodeState(presentationData: ItemListPresentationData(presentationData), entries: nugramSettingsControllerEntries(mode: mode, settings: settings), style: .blocks, animateChanges: true)
        
        return (controllerState, (listState, arguments))
    }
    
    let controller = ItemListController(context: context, state: signal)
    controller.navigationPresentation = .modal
    pushControllerImpl = { [weak controller] c in
        controller?.push(c)
    }
    return controller
}

public func nugramSettingsController(context: AccountContext) -> ViewController {
    return nugramSettingsController(context: context, mode: .root)
}
