import Combine
import SwiftUI

/// Abstract base class for Bloc and Cubit
@MainActor
open class BlocBase<State>: ObservableObject {
    @Published public private(set) var state: State
    
    /// Previous state for buildWhen/listenerWhen comparisons
    public private(set) var previousState: State?
    
    private let stateSubject: CurrentValueSubject<State, Never>
    private var cancellables = Set<AnyCancellable>()
    
    public var stream: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }
    
    public init(initialState: State) {
        self.state = initialState
        self.previousState = nil
        self.stateSubject = CurrentValueSubject<State, Never>(initialState)
        
        // Sync the published state with the subject
        $state
            .sink { [weak self] newState in
                self?.stateSubject.send(newState)
            }
            .store(in: &cancellables)
    }
    
    /// Emit a new state
    public func emit(_ newState: State) {
        performEmit(newState)
    }
    
    private func performEmit(_ newState: State) {
        let currentState = state
        
        // Store previous state before updating
        previousState = currentState
        
        // Create change object
        let change = Change(currentState: currentState, nextState: newState)
        
        // Call onChange hook
        onChange(change)
        
        // Notify observer
        BlocObserver.shared.onChange(change)
        
        // Update state
        state = newState
    }
    
    /// Thread-safe state transformation
    public func transform(_ transformation: (State) -> State) {
        let newState = transformation(state)
        performEmit(newState)
    }
    
    /// Override this method to react to state changes
    open func onChange(_ change: Change<State>) {
        // Override in subclasses
    }
    
    /// Override this method to handle errors
    open func onError(_ error: Error) {
        BlocObserver.shared.onError(error, bloc: self)
    }
    
    deinit {
        // Note: We can't safely access MainActor-isolated properties from deinit
        // The stateSubject will be deallocated naturally with the object
        // Subscribers should handle completion gracefully when the publisher is deallocated
    }
}
