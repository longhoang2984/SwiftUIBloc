import SwiftUI

/// Combines BlocBuilder and BlocListener with optional conditions
public struct BlocConsumer<BlocType: BlocBase<State>, State, Content: View>: View {
    @EnvironmentObject private var bloc: BlocType
    private let listener: (State) -> Void
    private let listenerWhen: BlocListenerCondition<State>?
    private let buildWhen: BlocBuilderCondition<State>?
    private let content: (State) -> Content
    
    public init(
        listener: @escaping (State) -> Void,
        listenerWhen: BlocListenerCondition<State>? = nil,
        buildWhen: BlocBuilderCondition<State>? = nil,
        @ViewBuilder builder: @escaping (State) -> Content
    ) {
        self.listener = listener
        self.listenerWhen = listenerWhen
        self.buildWhen = buildWhen
        self.content = builder
    }
    
    public var body: some View {
        BlocView(
            bloc: bloc,
            buildWhen: buildWhen,
            listener: listener,
            listenerWhen: listenerWhen,
            content: content
        )
    }
}
