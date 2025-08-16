import SwiftUI
import Combine

/// SwiftUI view that rebuilds when bloc state changes (with optional buildWhen condition)
public struct BlocView<BlocType: BlocBase<BlocState>, BlocState, Content: View>: View {
    @ObservedObject private var bloc: BlocType
    private let buildWhen: BlocBuilderCondition<BlocState>?
    private let listener: ((BlocState) -> Void)?
    private let listenerWhen: BlocListenerCondition<BlocState>?
    private let content: (BlocState) -> Content
    
    public init(
        bloc: BlocType,
        buildWhen: BlocBuilderCondition<BlocState>? = nil,
        listener: ((BlocState) -> Void)? = nil,
        listenerWhen: BlocListenerCondition<BlocState>? = nil,
        @ViewBuilder content: @escaping (BlocState) -> Content
    ) {
        self.bloc = bloc
        self.buildWhen = buildWhen
        self.listener = listener
        self.listenerWhen = listenerWhen
        self.content = content
    }
    
    public var body: some View {
        ConditionalBlocContent(
            bloc: bloc,
            buildWhen: buildWhen,
            listener: listener,
            listenerWhen: listenerWhen,
            content: content
        )
    }
}

/// Internal view that handles conditional building and listening
private struct ConditionalBlocContent<BlocType: BlocBase<BlocState>, BlocState, Content: View>: View {
    @ObservedObject var bloc: BlocType
    let buildWhen: BlocBuilderCondition<BlocState>?
    let listener: ((BlocState) -> Void)?
    let listenerWhen: BlocListenerCondition<BlocState>?
    let content: (BlocState) -> Content
    
    @State private var displayState: BlocState
    @State private var hasInitialized = false
    
    init(
        bloc: BlocType,
        buildWhen: BlocBuilderCondition<BlocState>?,
        listener: ((BlocState) -> Void)?,
        listenerWhen: BlocListenerCondition<BlocState>?,
        content: @escaping (BlocState) -> Content
    ) {
        self.bloc = bloc
        self.buildWhen = buildWhen
        self.listener = listener
        self.listenerWhen = listenerWhen
        self.content = content
        self._displayState = State(initialValue: bloc.state)
    }
    
    var body: some View {
        content(displayState)
            .onReceive(bloc.$state) { newState in
                handleStateChange(newState)
            }
            .onAppear {
                if !hasInitialized {
                    displayState = bloc.state
                    hasInitialized = true
                }
            }
    }
    
    private func handleStateChange(_ newState: BlocState) {
        let previousState = bloc.previousState ?? displayState
        
        // Handle listener
        if let listener = listener {
            let shouldListen: Bool
            if let listenerWhen = listenerWhen {
                shouldListen = listenerWhen(previousState, newState)
            } else {
                shouldListen = hasInitialized // Don't trigger on initial state
            }
            
            if shouldListen {
                listener(newState)
            }
        }
        
        // Handle rebuild condition
        let shouldRebuild: Bool
        if let buildWhen = buildWhen {
            shouldRebuild = buildWhen(previousState, newState)
        } else {
            shouldRebuild = true
        }
        
        if shouldRebuild {
            displayState = newState
        }
    }
}
