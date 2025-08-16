import SwiftUI

/// Provides bloc instances to the SwiftUI view hierarchy
public struct BlocProvider<BlocType: BlocBase<State>, State, Content: View>: View {
    private let bloc: BlocType
    private let content: Content
    
    public init(
        create: () -> BlocType,
        @ViewBuilder child: () -> Content
    ) {
        self.bloc = create()
        self.content = child()
    }
    
    public init(
        value: BlocType,
        @ViewBuilder child: () -> Content
    ) {
        self.bloc = value
        self.content = child()
    }
    
    public var body: some View {
        content
            .environmentObject(bloc)
    }
}
