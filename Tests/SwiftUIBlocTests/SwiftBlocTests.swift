//
//  SwiftBlocTests.swift
//  SwiftBlocTests
//
//  Created by Cửu Long Hoàng on 15/8/25.
//

import Testing
@preconcurrency import Combine
@testable import SwiftUIBloc

// MARK: - Test Models

enum CounterEvent {
    case increment
    case decrement
    case incrementBy(Int)
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
        case .incrementBy(let value):
            if value < 0 {
                throw TestError.invalidValue
            }
            return state + value
        }
    }
}

class CounterCubit: Cubit<Int> {
    init() {
        super.init(initialState: 0)
    }
    
    func increment() {
        transform { $0 + 1 }
    }
    
    func decrement() {
        transform { $0 - 1 }
    }
    
    func reset() {
        emit(0)
    }
}

enum TestError: Error, Equatable {
    case invalidValue
    case networkError
}

// MARK: - Test Observer

@MainActor
class TestBlocObserver {
    var changes: [String] = []
    var transitions: [String] = []
    var errors: [(Error, String)] = []
    
    func onChange<State>(_ change: Change<State>) {
        changes.append("Change: \(change.currentState) -> \(change.nextState)")
    }
    
    func onTransition<Event, State>(_ transition: Transition<Event, State>) {
        transitions.append("Transition: \(transition.currentState) -> \(transition.nextState) via \(transition.event)")
    }
    
    func onError<State>(_ error: Error, bloc: BlocBase<State>) {
        errors.append((error, String(describing: type(of: bloc))))
    }
    
    func reset() {
        changes.removeAll()
        transitions.removeAll()
        errors.removeAll()
    }
}

// MARK: - Core Tests

struct SwiftBlocTests {
    
    // MARK: - BlocBase Tests
    
    @Test func testBlocBaseInitialState() async throws {
        let cubit = await CounterCubit()
        #expect(await cubit.state == 0)
        #expect(await cubit.previousState == nil)
    }
    
    @Test func testBlocBaseStateEmission() async throws {
        let cubit = await CounterCubit()
        let expectation = AsyncPublisher(await cubit.stream)
        
        await cubit.increment()
        
        #expect(await cubit.state == 1)
        #expect(await cubit.previousState == 0)
        
        let states = await expectation.collect(2)
        #expect(states == [0, 1])
    }
    
    @Test func testBlocBaseMultipleEmissions() async throws {
        let cubit = await CounterCubit()
        
        await cubit.increment()
        await cubit.increment()
        await cubit.decrement()
        
        #expect(await cubit.state == 1)
        #expect(await cubit.previousState == 2)
    }
    
    // MARK: - Cubit Tests
    
    @Test func testCubitEmit() async throws {
        let cubit = await CounterCubit()
        
        await cubit.increment()
        #expect(await cubit.state == 1)
        
        await cubit.decrement()
        #expect(await cubit.state == 0)
        
        await cubit.reset()
        #expect(await cubit.state == 0)
    }
    
    @Test func testCubitStateStream() async throws {
        let cubit = await CounterCubit()
        var receivedStates: [Int] = []
        let cancellable = await cubit.stream.sink { state in
            receivedStates.append(state)
        }
        
        await cubit.increment()
        await cubit.increment()
        await cubit.decrement()
        
        // Allow some time for async operations
        try await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        
        #expect(receivedStates.count >= 4) // initial + 3 emissions
        #expect(receivedStates.first == 0) // initial state
        #expect(receivedStates.last == 1) // final state
        
        cancellable.cancel()
    }
    
    // MARK: - Bloc Tests
    
    @Test func testBlocInitialState() async throws {
        let bloc = await CounterBloc()
        #expect(await bloc.state == 0)
        #expect(await bloc.previousState == nil)
    }
    
    @Test func testBlocEventHandling() async throws {
        let bloc = await CounterBloc()
        
        await bloc.add(event: CounterEvent.increment)
        try await Task.sleep(nanoseconds: 100_000_000) // Allow event processing
        #expect(await bloc.state == 1)
        
        await bloc.add(event: CounterEvent.decrement)
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await bloc.state == 0)
        
        await bloc.add(event: CounterEvent.incrementBy(5))
        try await Task.sleep(nanoseconds: 100_000_000)
        #expect(await bloc.state == 5)
    }
    
    @Test func testBlocErrorHandling() async throws {
        _ = await CounterBloc()
        _ = TestBlocObserver()
        
        // Store original observer and replace it
        _ = BlocObserver.shared
        _ = Mirror(reflecting: BlocObserver.shared)
        // We need to test error handling by overriding onError in the bloc itself
        
        actor ErrorCapture {
            private(set) var capturedError: Error?
            
            func capture(_ error: Error) {
                capturedError = error
            }
        }
        
        let errorCapture = ErrorCapture()
        
        @MainActor
        class TestCounterBloc: CounterBloc {
            var onErrorCallback: ((Error) -> Void)?
            
            override func onError(_ error: Error) {
                onErrorCallback?(error)
                super.onError(error)
            }
        }
        
        let testBloc = await TestCounterBloc()
        await MainActor.run {
            testBloc.onErrorCallback = { @Sendable error in
                Task {
                    await errorCapture.capture(error)
                }
            }
        }
        
        await testBloc.add(event: CounterEvent.incrementBy(-1)) // This should trigger an error
        try await Task.sleep(nanoseconds: 100_000_000)
        
        let capturedError = await errorCapture.capturedError
        #expect(capturedError != nil)
        if let error = capturedError as? TestError {
            #expect(error == .invalidValue)
        }
    }
    
    // MARK: - Data Structure Tests
    
    @Test func testChangeStructure() async throws {
        let change = Change(currentState: 0, nextState: 1)
        
        #expect(change.currentState == 0)
        #expect(change.nextState == 1)
        #expect(change.description.contains("0"))
        #expect(change.description.contains("1"))
    }
    
    @Test func testTransitionStructure() async throws {
        let transition = Transition(currentState: 0, event: CounterEvent.increment, nextState: 1)
        
        #expect(transition.currentState == 0)
        #expect(transition.nextState == 1)
        
        switch transition.event {
        case .increment:
            break // Expected
        default:
            Issue.record("Expected increment event")
        }
        
        #expect(transition.description.contains("0"))
        #expect(transition.description.contains("1"))
        #expect(transition.description.contains("increment"))
    }
    
    // MARK: - Observer Tests
    
    @Test func testBlocObserverSingleton() async throws {
        let observer1 = BlocObserver.shared
        let observer2 = BlocObserver.shared
        
        #expect(observer1 === observer2)
    }
    
    // MARK: - Integration Tests
    
    @Test func testBlocIntegrationWithObserver() async throws {
        _ = await CounterCubit()
        let testObserver =    TestBlocObserver()
        
        // We'll test by creating a custom cubit that calls our test observer
        @MainActor
        class TestCubit: CounterCubit {
            let testObserver: TestBlocObserver
            
            init(testObserver: TestBlocObserver) {
                self.testObserver = testObserver
                super.init()
            }
            
            override func onChange(_ change: Change<Int>) {
                testObserver.onChange(change)
                super.onChange(change)
            }
        }
        
        let testCubit = await TestCubit(testObserver: testObserver)
        
        await testCubit.increment()
        await testCubit.increment()
        await testCubit.decrement()
        
        await MainActor.run {
            #expect(testObserver.changes.count == 3)
            #expect(testObserver.changes[0].contains("0 -> 1"))
            #expect(testObserver.changes[1].contains("1 -> 2"))
            #expect(testObserver.changes[2].contains("2 -> 1"))
        }
    }
    
    @Test func testBlocTransitionWithObserver() async throws {
        _ = await CounterBloc()
        let testObserver =  TestBlocObserver()
        
        @MainActor
        class TestBloc: CounterBloc {
            let testObserver: TestBlocObserver
            
            init(testObserver: TestBlocObserver) {
                self.testObserver = testObserver
                super.init()
            }
            
            override func onTransition(_ transition: Transition<CounterEvent, Int>) {
                testObserver.onTransition(transition)
                super.onTransition(transition)
            }
        }
        
        let testBloc = await TestBloc(testObserver: testObserver)
        
        await testBloc.add(event: CounterEvent.increment)
        await testBloc.add(event: CounterEvent.incrementBy(3))
        
        try await Task.sleep(nanoseconds: 200_000_000) // Allow processing
        
        await MainActor.run {
            #expect(testObserver.transitions.count >= 2)
            #expect(testObserver.transitions.first?.contains("0 -> 1") == true)
        }
    }
    
    // MARK: - Async Behavior Tests
    
    @Test func testConcurrentStateChanges() async throws {
        let cubit = await CounterCubit()
        
        await withTaskGroup(of: Void.self) { group in
            for _ in 0..<10 {
                group.addTask {
                    await cubit.increment()
                }
            }
        }
        
        #expect(await cubit.state == 10)
    }
    
    @Test func testStreamSubscription() async throws {
        let cubit = await CounterCubit()
        var collectedStates: [Int] = []
        let cancellable = await cubit.$state.sink { state in
            collectedStates.append(state)
        }
        
        await cubit.increment()
        await cubit.increment()
        await cubit.decrement()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(collectedStates.count >= 4) // initial + changes
        #expect(collectedStates.contains(0))
        #expect(collectedStates.contains(1))
        #expect(collectedStates.contains(2))
        #expect(collectedStates.contains(1)) // final state after decrement
        
        cancellable.cancel()
    }
}

// MARK: - Helper Classes for Async Testing

class AsyncPublisher<T> {
    private let publisher: AnyPublisher<T, Never>
    private var values: [T] = []
    private var cancellable: AnyCancellable?
    
    init<P: Publisher>(_ publisher: P) where P.Output == T, P.Failure == Never {
        self.publisher = publisher.eraseToAnyPublisher()
        self.cancellable = self.publisher.sink { value in
            self.values.append(value)
        }
    }
    
    func collect(_ count: Int) async -> [T] {
        while values.count < count {
            try? await Task.sleep(nanoseconds: 10_000_000) // 0.01 seconds
        }
        return Array(values.prefix(count))
    }
    
    deinit {
        cancellable?.cancel()
    }
}
