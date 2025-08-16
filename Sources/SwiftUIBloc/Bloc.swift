import Combine

/// Event-based state management
open class Bloc<Event, State>: BlocBase<State> {
    
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var eventCancellables = Set<AnyCancellable>()
    
    public override init(initialState: State) {
        super.init(initialState: initialState)
        setupEventHandling()
    }
    
    private func setupEventHandling() {
        eventSubject
            .sink { [weak self] event in
                Task { @MainActor in
                    await self?.handleEvent(event)
                }
            }
            .store(in: &eventCancellables)
    }
    
    private func handleEvent(_ event: Event) async {
        let currentState = state
        
        do {
            let nextState = try mapEventToState(event: event)
            
            // Create transition object
            let transition = Transition(
                currentState: currentState,
                event: event,
                nextState: nextState
            )
            
            // Call onTransition hook
            onTransition(transition)
            
            // Notify observer
            BlocObserver.shared.onTransition(transition)
            
            // Emit new state
            emit(nextState)
            
        } catch {
            onError(error)
        }
    }
    
    /// Add an event to the bloc
    public func add(event: Event) {
        eventSubject.send(event)
    }
    
    /// Map an event to a new state - override this method
    open func mapEventToState(event: Event) throws -> State {
        fatalError("mapEventToState must be overridden by subclasses")
    }
    
    /// Override this method to react to state transitions
    open func onTransition(_ transition: Transition<Event, State>) {
        // Override in subclasses
    }
}
