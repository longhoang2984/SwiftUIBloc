/// Represents a change from one state to another
public struct Change<State> {
    public let currentState: State
    public let nextState: State
    
    public init(currentState: State, nextState: State) {
        self.currentState = currentState
        self.nextState = nextState
    }
}

extension Change: CustomStringConvertible {
    public var description: String {
        return "Change { currentState: \(currentState), nextState: \(nextState) }"
    }
}