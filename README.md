# SwiftUIBloc

A predictable state management library for SwiftUI applications, inspired by the BLoC pattern from Flutter. SwiftUIBloc helps you manage application state in a predictable, testable, and scalable way using reactive programming principles.

## Features

- **🎯 Predictable State Management**: Clear separation between business logic and UI
- **🔄 Reactive**: Built on Combine framework for reactive state updates
- **🧪 Testable**: Easy to unit test business logic independently from UI
- **🎨 SwiftUI Integration**: Native SwiftUI components for seamless integration
- **📱 Multi-Platform**: Supports iOS 15+ and macOS 12+
- **🔍 Observable**: Built-in state change monitoring and debugging support
- **⚡ Performance**: Efficient state updates with conditional rebuilding

## Installation

### Swift Package Manager

Add SwiftUIBloc to your project using Xcode:

1. Open your project in Xcode
2. Go to File → Add Package Dependencies
3. Enter the repository URL: `https://github.com/longhoang2984/SwiftUIBloc.git`
4. Choose the version you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/longhoang2984/SwiftUIBloc.git", from: "1.0.0")
]
```

## Core Concepts

### Bloc vs Cubit

SwiftUIBloc provides two ways to manage state:

**Cubit**: Function-based state management (simpler)
```swift
class CounterCubit: Cubit<Int> {
    init() {
        super.init(initialState: 0)
    }
    
    func increment() {
        emit(state + 1)
    }
    
    func decrement() {
        emit(state - 1)
    }
}
```

**Bloc**: Event-based state management (more powerful)
```swift
enum CounterEvent {
    case increment
    case decrement
    case reset
}

class CounterBloc: Bloc<CounterEvent, Int> {
    init() {
        super.init(initialState: 0)
    }
    
    override func mapEventToState(event: CounterEvent) throws -> Int {
        switch event {
        case .increment:
            return state + 1
        case .decrement:
            return state - 1
        case .reset:
            return 0
        }
    }
}
```

## Basic Usage

### 1. Create a Cubit or Bloc

```swift
import SwiftUIBloc

class CounterCubit: Cubit<Int> {
    init() {
        super.init(initialState: 0)
    }
    
    func increment() {
        emit(state + 1)
    }
    
    func decrement() {
        emit(state - 1)
    }
}
```

### 2. Provide the Bloc to your View

```swift
import SwiftUI
import SwiftUIBloc

struct ContentView: View {
    var body: some View {
        BlocProvider(create: { CounterCubit() }) {
            CounterView()
        }
    }
}
```

### 3. Build UI that reacts to state changes

```swift
struct CounterView: View {
    var body: some View {
        BlocBuilder<CounterCubit, Int> { state in
            VStack {
                Text("Count: \(state)")
                    .font(.largeTitle)
                
                HStack {
                    Button("Decrement") {
                        // Access the cubit through environment
                    }
                    .environmentObject(/* cubit */)
                    
                    Button("Increment") {
                        // Access the cubit through environment
                    }
                    .environmentObject(/* cubit */)
                }
            }
        }
    }
}
```

### 4. Complete Example with BlocConsumer

```swift
struct CounterView: View {
    @EnvironmentObject var cubit: CounterCubit
    
    var body: some View {
        BlocConsumer<CounterCubit, Int> { state in
            // Listener: Handle side effects
            if state == 10 {
                print("Reached maximum count!")
            }
        } builder: { state in
            // Builder: Build UI based on state
            VStack(spacing: 20) {
                Text("Count: \(state)")
                    .font(.largeTitle)
                    .foregroundColor(state > 5 ? .red : .blue)
                
                HStack(spacing: 16) {
                    Button("−") {
                        cubit.decrement()
                    }
                    .buttonStyle(.bordered)
                    
                    Button("+") {
                        cubit.increment()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .padding()
        }
    }
}
```

## SwiftUI Components

### BlocProvider
Provides a bloc instance to the widget tree:

```swift
BlocProvider(create: { CounterCubit() }) {
    CounterView()
}

// Or with an existing instance
BlocProvider(value: existingCubit) {
    CounterView()
}
```

### BlocBuilder
Builds UI in response to state changes:

```swift
BlocBuilder<CounterCubit, Int> { state in
    Text("Count: \(state)")
}

// With conditional rebuilding
BlocBuilder<CounterCubit, Int>(
    buildWhen: { previous, current in
        // Only rebuild if count changed by more than 1
        abs(previous - current) > 1
    }
) { state in
    Text("Count: \(state)")
}
```

### BlocListener
Executes code in response to state changes without rebuilding:

```swift
BlocListener<CounterCubit, Int>(
    listener: { state in
        if state < 0 {
            print("Count went negative!")
        }
    }
) {
    SomeChildView()
}

// With conditional listening
BlocListener<CounterCubit, Int>(
    listener: { state in
        print("Even number: \(state)")
    },
    listenerWhen: { previous, current in
        current.isMultiple(of: 2)
    }
) {
    SomeChildView()
}
```

### BlocConsumer
Combines BlocBuilder and BlocListener:

```swift
BlocConsumer<CounterCubit, Int>(
    listener: { state in
        // Handle side effects
        if state == 0 {
            print("Reset to zero!")
        }
    },
    buildWhen: { previous, current in
        // Control when to rebuild
        previous != current
    }
) { state in
    // Build UI
    Text("Count: \(state)")
}
```

## Advanced Features

### State Transitions (Bloc only)
Override `onTransition` to monitor state transitions:

```swift
class CounterBloc: Bloc<CounterEvent, Int> {
    // ... initialization ...
    
    override func onTransition(_ transition: Transition<CounterEvent, Int>) {
        print("Transition: \(transition.currentState) -> \(transition.nextState) via \(transition.event)")
    }
}
```

### Error Handling
Handle errors in your bloc:

```swift
enum CounterEvent {
    case increment
    case divide(by: Int)
}

class CounterBloc: Bloc<CounterEvent, Int> {
    // ... initialization ...
    
    override func mapEventToState(event: CounterEvent) throws -> Int {
        switch event {
        case .increment:
            return state + 1
        case .divide(let divisor):
            guard divisor != 0 else {
                throw CounterError.divisionByZero
            }
            return state / divisor
        }
    }
    
    override func onError(_ error: Error) {
        print("Counter error: \(error)")
    }
}
```

### Global State Monitoring
Use BlocObserver to monitor all blocs globally:

```swift
class AppBlocObserver: BlocObserver {
    override func onChange<State>(_ change: Change<State>) {
        print("State changed: \(change.currentState) -> \(change.nextState)")
    }
    
    override func onTransition<Event, State>(_ transition: Transition<Event, State>) {
        print("Transition: \(transition)")
    }
    
    override func onError<State>(_ error: Error, bloc: BlocBase<State>) {
        print("Bloc error: \(error)")
    }
}

// Set the observer
BlocObserver.shared = AppBlocObserver()
```

## Testing

SwiftUIBloc makes testing easy by separating business logic from UI:

```swift
import Testing
@testable import SwiftUIBloc

@Test func testCounterIncrement() {
    let cubit = CounterCubit()
    
    cubit.increment()
    
    #expect(cubit.state == 1)
}

@Test func testCounterBlocEvents() async {
    let bloc = CounterBloc()
    
    bloc.add(event: .increment)
    bloc.add(event: .increment)
    
    // Wait for async event processing
    try await Task.sleep(nanoseconds: 100_000)
    
    #expect(bloc.state == 2)
}
```

## Requirements

- iOS 15.0+ / macOS 12.0+
- Swift 6.0+
- Xcode 15.0+

## Architecture Benefits

- **Separation of Concerns**: Business logic is separate from UI
- **Testability**: Easy to unit test state management logic
- **Reusability**: Blocs can be shared across different UI components
- **Predictability**: Unidirectional data flow makes state changes predictable
- **Scalability**: Well-structured pattern that scales with app complexity

## Documentation

For more detailed documentation and examples, visit our [documentation site](https://github.com/longhoang2984/SwiftUIBloc/wiki).

## Contributing

We welcome contributions! Please see our [Contributing Guide](CONTRIBUTING.md) for details.

## License

SwiftUIBloc is available under the MIT license. See [LICENSE](LICENSE) for details.

## Acknowledgments

This library is inspired by the [bloc library](https://bloclibrary.dev/) for Flutter, adapted for SwiftUI and Swift's unique features.
