import SwiftUI

/// Convenience view builder for blocs with optional buildWhen condition
public struct BlocBuilder<BlocType: BlocBase<State>, State, Content: View>: View {
    @EnvironmentObject private var bloc: BlocType
    private let buildWhen: BlocBuilderCondition<State>?
    private let content: (State) -> Content
    
    public init(
        buildWhen: BlocBuilderCondition<State>? = nil,
        @ViewBuilder builder: @escaping (State) -> Content
    ) {
        self.buildWhen = buildWhen
        self.content = builder
    }
    
    public var body: some View {
        BlocView(
            bloc: bloc,
            buildWhen: buildWhen,
            content: content
        )
    }
}
