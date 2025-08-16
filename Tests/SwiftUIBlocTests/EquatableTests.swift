//
//  EquatableTests.swift
//  SwiftBlocTests
//
//  Created by Cửu Long Hoàng on 15/8/25.
//

import Testing
@preconcurrency import Combine
@testable import SwiftUIBloc

// MARK: - Test Models for Equatable Tests

struct CounterState: EquatableState {
    let count: Int
    let isLoading: Bool
    
    init(count: Int, isLoading: Bool = false) {
        self.count = count
        self.isLoading = isLoading
    }
}

enum CounterStateEvent {
    case increment
    case decrement
    case startLoading
    case stopLoading
    case setCount(Int)
}

class EquatableCounterCubit: EquatableCubit<CounterState> {
    init() {
        super.init(initialState: CounterState(count: 0))
    }
    
    func increment() {
        emit(CounterState(count: state.count + 1, isLoading: state.isLoading))
    }
    
    func decrement() {
        emit(CounterState(count: state.count - 1, isLoading: state.isLoading))
    }
    
    func startLoading() {
        emit(CounterState(count: state.count, isLoading: true))
    }
    
    func stopLoading() {
        emit(CounterState(count: state.count, isLoading: false))
    }
    
    func setCount(_ count: Int) {
        emit(CounterState(count: count, isLoading: state.isLoading))
    }
}

class EquatableCounterBloc: EquatableBloc<CounterStateEvent, CounterState> {
    init() {
        super.init(initialState: CounterState(count: 0))
    }
    
    override func mapEventToState(event: CounterStateEvent) throws -> CounterState {
        switch event {
        case .increment:
            return CounterState(count: state.count + 1, isLoading: state.isLoading)
        case .decrement:
            return CounterState(count: state.count - 1, isLoading: state.isLoading)
        case .startLoading:
            return CounterState(count: state.count, isLoading: true)
        case .stopLoading:
            return CounterState(count: state.count, isLoading: false)
        case .setCount(let count):
            return CounterState(count: count, isLoading: state.isLoading)
        }
    }
}

// MARK: - Equatable Tests

struct EquatableTests {
    
    // MARK: - EquatableCubit Tests
    
    @Test func testEquatableCubitOnlyEmitsWhenStateChanges() async throws {
        let cubit = await EquatableCounterCubit()
        var stateChanges: [CounterState] = []
        
        let cancellable = await cubit.$state.sink { state in
            stateChanges.append(state)
        }
        
        // This should emit
        await cubit.increment()
        
        // This should emit (state actually changed)
        await cubit.startLoading()
        
        // This should NOT emit (same state)
        await cubit.setCount(1) // count is already 1
        
        // This should NOT emit (isLoading is already true)
        await cubit.startLoading()
        
        // This should emit (state changed)
        await cubit.stopLoading()
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Initial state + 3 actual changes (not 5)
        #expect(stateChanges.count == 4) // initial + increment + startLoading + stopLoading
        
        let finalState = stateChanges.last!
        #expect(finalState.count == 1)
        #expect(finalState.isLoading == false)
        
        cancellable.cancel()
    }
    
    @Test func testEquatableCubitPreventsIdenticalStateEmissions() async throws {
        let cubit = await EquatableCounterCubit()
        var emissionCount = 0
        
        let cancellable = await cubit.$state.dropFirst().sink { _ in
            emissionCount += 1
        }
        
        let initialState = await cubit.state
        
        // Emit the same state multiple times
        await cubit.setCount(0) // Same count
        await cubit.stopLoading() // Same loading state
        await cubit.setCount(0) // Same count again
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // No emissions should occur since state hasn't actually changed
        #expect(emissionCount == 0)
        #expect(await cubit.state == initialState)
        
        cancellable.cancel()
    }
    
    // MARK: - EquatableBloc Tests
    
    @Test func testEquatableBlocOnlyEmitsWhenStateChanges() async throws {
        let bloc = await EquatableCounterBloc()
        var stateChanges: [CounterState] = []
        
        let cancellable = await bloc.$state.sink { state in
            stateChanges.append(state)
        }
        
        // This should emit
        await bloc.add(event: .increment)
        
        // This should emit
        await bloc.add(event: .startLoading)
        
        // This should NOT emit (same state)
        await bloc.add(event: .setCount(1)) // count is already 1
        
        // This should NOT emit (isLoading is already true)
        await bloc.add(event: .startLoading)
        
        // This should emit
        await bloc.add(event: .stopLoading)
        
        try await Task.sleep(nanoseconds: 200_000_000) // Allow event processing
        
        // Initial state + 3 actual changes
        #expect(stateChanges.count == 4)
        
        let finalState = stateChanges.last!
        #expect(finalState.count == 1)
        #expect(finalState.isLoading == false)
        
        cancellable.cancel()
    }
    
    @Test func testEquatableBlocPreventsIdenticalStateEmissions() async throws {
        let bloc = await EquatableCounterBloc()
        var emissionCount = 0
        
        let cancellable = await bloc.$state.dropFirst().sink { _ in
            emissionCount += 1
        }
        
        let initialState = await bloc.state
        
        // Add events that would produce the same state
        await bloc.add(event: .setCount(0)) // Same count
        await bloc.add(event: .stopLoading) // Same loading state
        await bloc.add(event: .setCount(0)) // Same count again
        
        try await Task.sleep(nanoseconds: 200_000_000)
        
        // No emissions should occur since state hasn't actually changed
        #expect(emissionCount == 0)
        #expect(await bloc.state == initialState)
        
        cancellable.cancel()
    }
    
    // MARK: - Comparison with Regular Bloc/Cubit
    
    @Test func testEquatableCubitVsRegularCubit() async throws {
        let regularCubit = await CounterCubit()
        let equatableCubit = await EquatableCounterCubit()
        
        var regularEmissions = 0
        var equatableEmissions = 0
        
        let regularCancellable = await regularCubit.$state.dropFirst().sink { _ in
            regularEmissions += 1
        }
        
        let equatableCancellable = await equatableCubit.$state.dropFirst().sink { _ in
            equatableEmissions += 1
        }
        
        // Perform similar operations
        await regularCubit.emit(0) // Same as initial
        await regularCubit.emit(0) // Same again
        await regularCubit.emit(1) // Different
        
        await equatableCubit.setCount(0) // Same as initial
        await equatableCubit.setCount(0) // Same again
        await equatableCubit.setCount(1) // Different
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Regular cubit emits every time
        #expect(regularEmissions == 3)
        
        // Equatable cubit only emits when state actually changes
        #expect(equatableEmissions == 1)
        
        regularCancellable.cancel()
        equatableCancellable.cancel()
    }
    
    // MARK: - Complex State Tests
    
    @Test func testEquatableWithComplexStateChanges() async throws {
        let cubit = await EquatableCounterCubit()
        var stateHistory: [CounterState] = []
        
        let cancellable = await cubit.$state.sink { state in
            stateHistory.append(state)
        }
        
        // Series of operations with some duplicates
        await cubit.increment() // 0 -> 1
        await cubit.increment() // 1 -> 2
        await cubit.setCount(2) // 2 -> 2 (no change)
        await cubit.startLoading() // loading: false -> true
        await cubit.startLoading() // loading: true -> true (no change)
        await cubit.decrement() // count: 2 -> 1
        await cubit.stopLoading() // loading: true -> false
        await cubit.stopLoading() // loading: false -> false (no change)
        
        try await Task.sleep(nanoseconds: 100_000_000)
        
        // Should have: initial + increment + increment + startLoading + decrement + stopLoading = 6
        #expect(stateHistory.count == 6)
        
        let finalState = stateHistory.last!
        #expect(finalState.count == 1)
        #expect(finalState.isLoading == false)
        
        cancellable.cancel()
    }
}
