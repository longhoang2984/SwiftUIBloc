import SwiftUI
import Combine

/// Listens to bloc state changes without rebuilding (with optional listenerWhen condition)
public struct BlocListener<BlocType: BlocBase<State>, State, Content: View>: View {
    @EnvironmentObject private var bloc: BlocType
    private let listener: (State) -> Void
    private let listenerWhen: BlocListenerCondition<State>?
    private let content: Content
    
    public init(
        listener: @escaping (State) -> Void,
        listenerWhen: BlocListenerCondition<State>? = nil,
        @ViewBuilder child: () -> Content
    ) {
        self.listener = listener
        self.listenerWhen = listenerWhen
        self.content = child()
    }
    
    public var body: some View {
        content
            .onReceive(bloc.$state) { newState in
                let previousState = bloc.previousState
                
                if let listenerWhen = listenerWhen {
                    if let prev = previousState, listenerWhen(prev, newState) {
                        listener(newState)
                    }
                } else {
                    listener(newState)
                }
            }
    }
}