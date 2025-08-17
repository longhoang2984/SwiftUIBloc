# SwiftUIBloc Examples

This directory contains comprehensive examples demonstrating the usage of SwiftUIBloc library.

## Examples Overview

### 1. Counter (Cubit Example) - `CounterCubit.swift`

A simple counter application demonstrating:
- Basic Cubit usage with direct state emission
- Synchronous and asynchronous state updates
- SwiftUI integration with `BlocProvider` and `BlocBuilder`
- Error handling and state management best practices

**Key Features:**
- ✅ Increment/Decrement counter
- ✅ Reset functionality
- ✅ Async operations with loading states
- ✅ State change logging with `onChange`

### 2. Todo List (Bloc Example) - `TodoBloc.swift`

A full-featured todo application showcasing:
- Event-driven architecture with `Bloc`
- Complex state management with multiple event types
- Business logic separation
- Advanced UI patterns with filtering and editing

**Key Features:**
- ✅ Add/Edit/Delete todos
- ✅ Toggle completion status
- ✅ Filter todos (All/Active/Completed)
- ✅ Bulk operations (Toggle All, Clear Completed)
- ✅ State transitions with `onTransition`

### 3. Main Examples App - `SwiftUIBlocExamples.swift`

A navigation-based app that showcases both examples with:
- Interactive example browser
- Feature comparison guide
- Documentation and usage examples
- Resource links

## Running the Examples

### Option 1: As a Standalone App

```swift
import SwiftUI
import SwiftUIBloc

@main
struct ExampleApp: App {
    var body: some Scene {
        WindowGroup {
            SwiftUIBlocExamples()
        }
    }
}
```

### Option 2: Individual Examples

```swift
// Counter Example
CounterView()

// Todo Example  
TodoView()
```

### Option 3: Integrate into Your App

```swift
NavigationLink("Counter Example") {
    CounterView()
}
```

## Code Structure

### Cubit Pattern (CounterCubit.swift)

```
State Definition → Cubit Class → Business Logic → UI Integration
     ↓                ↓              ↓              ↓
CounterState → CounterCubit → increment() → BlocBuilder
```

**Best For:**
- Simple state management
- Direct state updates  
- Limited business logic
- Quick prototyping

### Bloc Pattern (TodoBloc.swift)

```
Events → State → Bloc Class → Event Handlers → State Transitions
   ↓       ↓         ↓            ↓               ↓
TodoEvent → TodoState → TodoBloc → mapEventToState() → UI Updates
```

**Best For:**
- Complex business logic
- Event-driven architecture
- State transition tracking
- Scalable applications

## Key Concepts Demonstrated

### 1. State Management
- Immutable state objects
- State transitions
- Loading and error states

### 2. Business Logic Separation
- Pure functions for state updates
- Event-driven command pattern
- Error handling strategies

### 3. SwiftUI Integration
- Reactive UI updates
- Provider pattern for dependency injection
- Conditional rendering based on state

### 4. Testing Patterns
- Predictable state changes
- Event-driven testing approach
- Mockable architecture

## Usage Patterns

### Basic Cubit Usage

```swift
// 1. Define State
struct MyState: Equatable {
    let value: String
}

// 2. Create Cubit
class MyCubit: Cubit<MyState> {
    func updateValue(_ newValue: String) {
        emit(MyState(value: newValue))
    }
}

// 3. Use in UI
BlocProvider(create: { MyCubit() }) {
    BlocBuilder<MyCubit, MyState> { state in
        Text(state.value)
    }
}
```

### Basic Bloc Usage

```swift
// 1. Define Events & State
enum MyEvent {
    case updateValue(String)
}

struct MyState: Equatable {
    let value: String
}

// 2. Create Bloc
class MyBloc: Bloc<MyEvent, MyState> {
    override func mapEventToState(event: MyEvent) throws -> MyState {
        switch event {
        case .updateValue(let value):
            return MyState(value: value)
        }
    }
}

// 3. Use in UI
BlocProvider(create: { MyBloc() }) {
    BlocBuilder<MyBloc, MyState> { state in
        Text(state.value)
    }
}
```

## Next Steps

1. **Run the Examples**: Use the main `SwiftUIBlocExamples` view to explore both patterns
2. **Modify the Code**: Try adding new features to understand the patterns better
3. **Create Your Own**: Use these examples as templates for your own state management needs
4. **Explore Advanced Features**: Look into `BlocListener`, `BlocConsumer`, and custom observers

## Resources

- [SwiftUIBloc Documentation](../README.md)
- [Flutter BLoC Pattern](https://bloclibrary.dev/)
- [State Management Best Practices](https://developer.apple.com/documentation/swiftui/managing-model-data-in-your-app)
