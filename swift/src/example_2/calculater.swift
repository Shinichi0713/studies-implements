import SwiftUI
import Combine

class CalculatorViewModel: ObservableObject {
    @Published var displayValue: String = "0"
    
    private var currentInput: String = ""
    private var previousValue: Double? = nil
    private var currentOperation: Operation? = nil
    private var shouldResetInput: Bool = false
    
    enum Operation {
        case add, subtract, multiply, divide
        
        func calculate(_ a: Double, _ b: Double) -> Double {
            switch self {
            case .add: return a + b
            case .subtract: return a - b
            case .multiply: return a * b
            case .divide: return b == 0 ? 0 : a / b
            }
        }
        
        var symbol: String {
            switch self {
            case .add: return "+"
            case .subtract: return "−"
            case .multiply: return "×"
            case .divide: return "÷"
            }
        }
    }
    
    func buttonTapped(_ button: CalculatorButton) {
        switch button {
        case .number(let digit):
            inputNumber(digit)
        case .decimal:
            inputDecimal()
        case .operation(let op):
            selectOperation(op)
        case .equals:
            calculateResult()
        case .clear:
            clear()
        case .plusMinus:
            togglePlusMinus()
        case .percent:
            applyPercent()
        }
    }
    
    private func inputNumber(_ digit: Int) {
        if shouldResetInput {
            currentInput = String(digit)
            shouldResetInput = false
        } else {
            if currentInput == "0" {
                currentInput = String(digit)
            } else {
                currentInput.append(String(digit))
            }
        }
        updateDisplay()
    }
    
    private func inputDecimal() {
        if shouldResetInput {
            currentInput = "0."
            shouldResetInput = false
        } else if !currentInput.contains(".") {
            currentInput.append(".")
        }
        updateDisplay()
    }
    
    private func selectOperation(_ op: Operation) {
        guard let currentValue = Double(currentInput) else { return }
        
        if let prev = previousValue, let currentOp = currentOperation, !shouldResetInput {
            let result = currentOp.calculate(prev, currentValue)
            previousValue = result
            currentInput = formatResult(result)
        } else {
            previousValue = currentValue
        }
        
        currentOperation = op
        shouldResetInput = true
        updateDisplay()
    }
    
    private func calculateResult() {
        guard let prev = previousValue,
              let op = currentOperation,
              let current = Double(currentInput) else { return }
        
        let result = op.calculate(prev, current)
        currentInput = formatResult(result)
        previousValue = nil
        currentOperation = nil
        shouldResetInput = true
        updateDisplay()
    }
    
    private func clear() {
        currentInput = "0"
        previousValue = nil
        currentOperation = nil
        shouldResetInput = false
        updateDisplay()
    }
    
    private func togglePlusMinus() {
        if let value = Double(currentInput) {
            currentInput = formatResult(-value)
            updateDisplay()
        }
    }
    
    private func applyPercent() {
        if let value = Double(currentInput) {
            currentInput = formatResult(value / 100)
            updateDisplay()
        }
    }
    
    private func formatResult(_ value: Double) -> String {
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f", value)
        } else {
            return String(value)
        }
    }
    
    private func updateDisplay() {
        displayValue = currentInput
    }
}

import SwiftUI

struct CalculatorView: View {
    @StateObject private var viewModel = CalculatorViewModel()
    
    let buttons: [[CalculatorButton]] = [
        [.clear, .plusMinus, .percent, .operation(.divide)],
        [.number(7), .number(8), .number(9), .operation(.multiply)],
        [.number(4), .number(5), .number(6), .operation(.subtract)],
        [.number(1), .number(2), .number(3), .operation(.add)],
        [.number(0), .decimal, .equals]
    ]
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 12) {
                Spacer()
                
                // ディスプレイ
                HStack {
                    Spacer()
                    Text(viewModel.displayValue)
                        .font(.system(size: 80, weight: .light))
                        .foregroundColor(.white)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                .padding()
                
                // ボタン
                ForEach(buttons, id: \.self) { row in
                    HStack(spacing: 12) {
                        ForEach(row, id: \.self) { button in
                            CalculatorButtonView(button: button) {
                                viewModel.buttonTapped(button)
                            }
                        }
                    }
                }
            }
            .padding(.bottom)
        }
    }
}

struct CalculatorButtonView: View {
    let button: CalculatorButton
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(button.title)
                .font(.system(size: 32))
                .frame(
                    width: buttonWidth(),
                    height: 80
                )
                .background(button.backgroundColor)
                .foregroundColor(button.foregroundColor)
                .cornerRadius(40)
        }
    }
    
    private func buttonWidth() -> CGFloat {
        if case .number(0) = button {
            return 80 * 2 + 12
        }
        return 80
    }
}

struct ContentView: View {
    var body: some View {
        CalculatorView()
    }
}
