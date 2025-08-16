public final class BlocObserver: Sendable {
    public static let shared = BlocObserver()
    
    private init() {}
    
    /// Called whenever a Cubit's state changes
    public func onChange<State>(_ change: Change<State>) {
        // Override this method to handle state changes globally
        print("[BlocObserver] onChange: \(change)")
    }
    
    /// Called whenever a Bloc's state transitions
    public func onTransition<Event, State>(_ transition: Transition<Event, State>) {
        // Override this method to handle state transitions globally
        print("[BlocObserver] onTransition: \(transition)")
    }
    
    /// Called when an error occurs in a bloc/cubit
    public func onError<State>(_ error: Error, bloc: BlocBase<State>) {
        print("[BlocObserver] onError: \(error) in \(type(of: bloc))")
    }
}