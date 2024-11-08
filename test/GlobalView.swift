//
//  GlobalView.swift
//  test
//
//  Created by Courtois Kevin on 03/09/2024.
//

import SwiftUI

/// View that renders scrollable content beneath a header that
/// automatically collapses when the user scrolls down.
struct GlobalView: View {
    let model = ViewModel()

    @State var value = 0

    var body: some View {
        Button(action: {
            model.updateValue(value + 1)
        }, label: {
            Text("Val: \(value)")
        })
        .task {
            guard let stateStream = await model.actor.stateStream else {
                return
            }
            for await state in stateStream {
                value = state
            }
        }
    }
}

struct GlobalView_Previews: PreviewProvider {
    static var previews: some View {
        GlobalView()
    }
}

final class ViewModel: Sendable {
    let actor = StateActor()

    func updateValue(_ newValue: Int) {
        Task {
            await actor.updateValue(newValue)
        }
    }
}

actor StateActor {
    var stateStream: AsyncStream<Int>?
    private var stateContinuation: AsyncStream<Int>.Continuation?

    init() {
        Task { [weak self] in
            await self?.initStateStream()
        }
    }

    func initStateStream() {
        self.stateStream = AsyncStream { [weak self] continuation in
            Task { [continuation] in
                await self?.updateContinuation(continuation: continuation)
            }
        }
    }

    func updateValue(_ newValue: Int) {
        stateContinuation?.yield(newValue)
    }

    func updateContinuation(continuation: AsyncStream<Int>.Continuation?) {
        self.stateContinuation = continuation
    }
}
