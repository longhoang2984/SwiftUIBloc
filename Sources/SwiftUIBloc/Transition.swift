/// Represents a transition triggered by an event
public struct Transition<Event, State> {
    public let currentState: State
    public let event: Event
    public let nextState: State
    
    public init(currentState: State, event: Event, nextState: State) {
        self.currentState = currentState
        self.event = event
        self.nextState = nextState
    }
}

extension Transition: CustomStringConvertible {
    public var description: String {
        return "Transition { currentState: \(currentState), event: \(event), nextState: \(nextState) }"
    }
}
