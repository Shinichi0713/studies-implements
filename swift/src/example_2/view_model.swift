import SwiftUI
import Combine

final class ScientificCalculatorViewModel: ObservableObject {
    @Published var expression: String = "0"
    @Published var displayResult: String = ""
    @Published var isDegree: Bool = true
    @Published var is2nd: Bool = false
    @Published var history: [(expression: String, result: String)] = []
    
    private let engine = CalculatorEngine()
    private var isResultDisplayed: Bool = false
    
    func toggleAngleMode() {
        isDegree.toggle()
        engine.isDegree = isDegree
        recalculate()
    }
    
    func toggle2nd() {
        is2nd.toggle()
    }
    
    func input(_ token: String) {
        if isResultDisplayed {
            expression = token
            isResultDisplayed = false
        } else {
            if expression == "0" && !isOperator(token) {
                expression = token
            } else {
                expression.append(token)
            }
        }
        recalculate()
    }
    
    func insertFunction(_ name: String) {
        if isResultDisplayed {
            expression = name + "("
            isResultDisplayed = false
        } else {
            expression.append(name + "(")
        }
        recalculate()
    }
    
    func insertConstant(_ value: String) {
        input(value)
    }
    
    func clear() {
        expression = "0"
        displayResult = ""
        isResultDisplayed = false
    }
    
    func deleteLast() {
        if expression.count <= 1 {
            expression = "0"
        } else {
            expression.removeLast()
            // Simple cleanup for multi-char functions could be added here
        }
        recalculate()
    }
    
    func calculate() {
        do {
            let result = try engine.evaluate(expression)
            let formatted = format(result)
            displayResult = "= " + formatted
            history.insert((expression, formatted), at: 0)
            expression = formatted
            isResultDisplayed = true
        } catch {
            displayResult = "Error"
        }
    }
    
    func useHistoryItem(_ item: (expression: String, result: String)) {
        expression = item.result
        isResultDisplayed = false
        recalculate()
    }
    
    private func recalculate() {
        guard !expression.isEmpty else { return }
        do {
            let result = try engine.evaluate(expression)
            displayResult = "= " + format(result)
        } catch {
            displayResult = ""
        }
    }
    
    private func format(_ value: Double) -> String {
        if value.isNaN { return "Error" }
        if value.isInfinite { return "Error" }
        let intVal = Int64(value)
        if Double(intVal) == value {
            return String(intVal)
        }
        return String(format: "%.10g", value)
    }
    
    private func isOperator(_ token: String) -> Bool {
        return ["+", "−", "-", "×", "*", "÷", "/", "%", "^"].contains(token)
    }
}