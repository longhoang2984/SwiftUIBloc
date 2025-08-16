/// Predicate function to determine when to rebuild views
public typealias BlocBuilderCondition<State> = (State, State) -> Bool

/// Predicate function to determine when to trigger listeners
public typealias BlocListenerCondition<State> = (State, State) -> Bool