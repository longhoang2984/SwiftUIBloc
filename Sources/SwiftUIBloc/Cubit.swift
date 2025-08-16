/// Function-based state management
open class Cubit<State>: BlocBase<State> {
    
    public override init(initialState: State) {
        super.init(initialState: initialState)
    }
    
    /// Emit a new state (public interface for Cubit)
    public override func emit(_ newState: State) {
        super.emit(newState)
    }
}
