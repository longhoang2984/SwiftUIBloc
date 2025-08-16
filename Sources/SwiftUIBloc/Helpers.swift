import SwiftUI
import Combine

// MARK: - Context Extensions

extension View {
    /// Read a bloc from the environment
    public func readBloc<BlocType: BlocBase<State>, State>(_ type: BlocType.Type) -> BlocType {
        // This would typically be implemented with Environment values
        // For now, we'll use EnvironmentObject approach
        fatalError("Use @EnvironmentObject or BlocProvider instead")
    }
}

// MARK: - Equatable State Support

/// Protocol for states that can be compared for changes
public protocol EquatableState: Equatable {}

/// Enhanced Cubit that only emits when state actually changes
open class EquatableCubit<State: EquatableState>: Cubit<State> {
    
    public override func emit(_ newState: State) {
        if newState != state {
            super.emit(newState)
        }
    }
}

/// Enhanced Bloc that only emits when state actually changes
open class EquatableBloc<Event, State: EquatableState>: Bloc<Event, State> {
    
    public override func emit(_ newState: State) {
        if newState != state {
            super.emit(newState)
        }
    }
}
