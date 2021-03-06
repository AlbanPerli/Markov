//
//  valueIterator.swift
//  Markov
//
//  Created by Robert Bigelow on 11/18/18.
//  Copyright © 2018 Robert Bigelow. All rights reserved.
//

/// A value iterator finds an optimal policy by incrementally building an estimate of the
/// state-value function V(s) by using the action-value function Q(s, a).
class ValueIterator<TModel: MarkovDecisionProcess> {
    
    let mdp: TModel
    let gamma: Double
    
    var iterations: Int = 0
    
    init(mdp: TModel, gamma: Double) {
        assert(gamma >= 0.0 && gamma < 1.0)
        self.mdp = mdp
        self.gamma = gamma
    }
    
    /// Outputs an improved policy using value iteration.
    func getPolicy(withTolerance tolerance: Double) -> StochasticPolicy<TModel> {
        iterations = 0
        var estimates: Dictionary<TModel.State, Reward> = Dictionary()
        var delta: Double
        let states = mdp.states
        var chosenActions: Dictionary<TModel.State, [TModel.Action]> = Dictionary()
        repeat {
            delta = 0.0
            chosenActions.removeAll()
            for state in states {
                if let actions = mdp.getActions(forState: state) {
                    let oldEstimate = estimates[state] ?? 0.0
                    let actionValues = actions.map({ ($0, getActionValue(forState: state, withAction: $0, mdp: mdp, discount: gamma, v: { estimates[$0] ?? 0.0 })) })
                    if let maxActionValue = actionValues.max(by: { $0.1 < $1.1 }) {
                        let stateValue = maxActionValue.1
                        let stateAction = maxActionValue.0
                        var currentChoices = chosenActions[state] ?? []
                        estimates[state] = stateValue
                        currentChoices.append(stateAction)
                        chosenActions[state] = currentChoices
                        delta = max(delta, abs(oldEstimate - stateValue))
                    }
                }
            }
            iterations += 1
        } while delta > tolerance
        return StochasticPolicy<TModel>(actionMap: chosenActions)
    }
    
    /// Finds an optimal policy by using value iteration.
    static func getOptimalPolicy(forModel mdp:TModel, withTolerance epsilon: Double, withDiscount gamma: Double) -> (StochasticPolicy<TModel>, Int) {
        let valueIterator = ValueIterator(mdp: mdp, gamma: gamma)
        return (valueIterator.getPolicy(withTolerance: epsilon), valueIterator.iterations)
    }
}
