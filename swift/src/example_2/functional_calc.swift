import Foundation

final class CalculatorEngine {
    enum Token: Equatable {
        case number(Double)
        case operatorSymbol(String, Int, Associativity) // symbol, precedence, associativity
        case function(String, Int) // name, argumentCount
        case constant(String, Double)
        case leftParen
        case rightParen
        case postfixOperator(String, Int) // like !
        
        enum Associativity { case left, right }
    }
    
    var isDegree: Bool = true
    var lastAnswer: Double = 0
    
    private let operators: [String: (precedence: Int, assoc: Token.Associativity, unary: Bool)] = [
        "+": (1, .left, false), "-": (1, .left, false),
        "*": (2, .left, false), "/": (2, .left, false), "%": (2, .left, false),
        "^": (3, .right, false), "_": (4, .right, true) // _ is unary minus
    ]
    
    private let functions: [String: Int] = [
        "sin": 1, "cos": 1, "tan": 1,
        "asin": 1, "acos": 1, "atan": 1,
        "ln": 1, "log": 1, "sqrt": 1,
        "abs": 1
    ]
    
    private let constants: [String: Double] = [
        "pi": Double.pi, "e": exp(1.0)
    ]
    
    func evaluate(_ expression: String) throws -> Double {
        let tokens = try tokenize(expression)
        let rpn = try shuntingYard(tokens)
        return try evaluateRPN(rpn)
    }
    
    // MARK: - Tokenizer
    
    private func tokenize(_ input: String) throws -> [Token] {
        var tokens: [Token] = []
        var i = input.startIndex
        
        while i < input.endIndex {
            let ch = input[i]
            
            if ch.isWhitespace {
                i = input.index(after: i)
                continue
            }
            
            if ch.isNumber || ch == "." {
                var numStr = ""
                while i < input.endIndex && (input[i].isNumber || input[i] == ".") {
                    numStr.append(input[i])
                    i = input.index(after: i)
                }
                if let val = Double(numStr) {
                    tokens.append(.number(val))
                } else {
                    throw CalcError.invalidNumber(numStr)
                }
                continue
            }
            
            if ch.isLetter {
                var word = ""
                while i < input.endIndex && input[i].isLetter {
                    word.append(input[i])
                    i = input.index(after: i)
                }
                let lower = word.lowercased()
                if let argCount = functions[lower] {
                    tokens.append(.function(lower, argCount))
                } else if let val = constants[lower] {
                    tokens.append(.constant(lower, val))
                } else {
                    throw CalcError.unknownFunction(word)
                }
                continue
            }
            
            if ch == "!" {
                tokens.append(.postfixOperator("!", 5))
            } else if ch == "(" {
                tokens.append(.leftParen)
            } else if ch == ")" {
                tokens.append(.rightParen)
            } else {
                var opStr = String(ch)
                // Handle two-char operators if needed; here simple single char
                if let op = operators[opStr] {
                    // Unary minus detection
                    if opStr == "-" {
                        let needUnary = tokens.isEmpty ||
                            (if case .operatorSymbol = tokens.last { true } else { false }) ||
                            (if case .leftParen = tokens.last { true } else { false }) ||
                            (if case .function = tokens.last { true } else { false })
                        if needUnary {
                            opStr = "_" // internal unary minus
                        }
                    }
                    let info = operators[opStr]!
                    tokens.append(.operatorSymbol(opStr, info.precedence, info.assoc))
                } else {
                    throw CalcError.invalidOperator(opStr)
                }
            }
            
            i = input.index(after: i)
        }
        
        return tokens
    }
    
    // MARK: - Shunting Yard
    
    private func shuntingYard(_ tokens: [Token]) throws -> [Token] {
        var output: [Token] = []
        var stack: [Token] = []
        
        for token in tokens {
            switch token {
            case .number, .constant:
                output.append(token)
                
            case .function:
                stack.append(token)
                
            case .postfixOperator:
                output.append(token)
                
            case .operatorSymbol(let op1, let p1, let assoc):
                while let top = stack.last {
                    if case .operatorSymbol(let op2, let p2, _) = top {
                        if (assoc == .left && p1 <= p2) || (assoc == .right && p1 < p2) {
                            output.append(stack.removeLast())
                            continue
                        }
                    }
                    break
                }
                stack.append(token)
                
            case .leftParen:
                stack.append(token)
                
            case .rightParen:
                while let top = stack.last, !isLeftParen(top) {
                    output.append(stack.removeLast())
                }
                if stack.isEmpty {
                    throw CalcError.mismatchedParentheses
                }
                stack.removeLast() // pop left paren
                if let top = stack.last, case .function = top {
                    output.append(stack.removeLast())
                }
            }
        }
        
        while let top = stack.last {
            if isLeftParen(top) || isRightParen(top) {
                throw CalcError.mismatchedParentheses
            }
            output.append(stack.removeLast())
        }
        
        return output
    }
    
    private func isLeftParen(_ token: Token) -> Bool {
        if case .leftParen = token { return true }
        return false
    }
    
    private func isRightParen(_ token: Token) -> Bool {
        if case .rightParen = token { return true }
        return false
    }
    
    // MARK: - RPN Evaluation
    
    private func evaluateRPN(_ tokens: [Token]) throws -> Double {
        var stack: [Double] = []
        
        for token in tokens {
            switch token {
            case .number(let val):
                stack.append(val)
            case .constant(_, let val):
                stack.append(val)
            case .operatorSymbol(let op, _, _):
                if op == "_" {
                    guard let a = stack.popLast() else { throw CalcError.insufficientOperands }
                    stack.append(-a)
                } else {
                    guard let b = stack.popLast(), let a = stack.popLast() else { throw CalcError.insufficientOperands }
                    let res: Double
                    switch op {
                    case "+": res = a + b
                    case "-": res = a - b
                    case "*": res = a * b
                    case "/": res = b == 0 ? Double.nan : a / b
                    case "%": res = a.truncatingRemainder(dividingBy: b)
                    case "^": res = pow(a, b)
                    default: throw CalcError.invalidOperator(op)
                    }
                    stack.append(res)
                }
            case .postfixOperator("!", _):
                guard let a = stack.popLast(), a >= 0, a == floor(a) else { throw CalcError.invalidFactorial }
                var res: Double = 1
                for i in 1...Int(a) { res *= Double(i) }
                stack.append(res)
            case .function(let name, let argCount):
                var args: [Double] = []
                for _ in 0..<argCount { args.insert(stack.popLast() ?? 0, at: 0) }
                let res = try applyFunction(name, args: args)
                stack.append(res)
            default:
                break
            }
        }
        
        guard stack.count == 1 else { throw CalcError.invalidExpression }
        return stack[0]
    }
    
    private func applyFunction(_ name: String, args: [Double]) throws -> Double {
        guard let x = args.first else { throw CalcError.insufficientOperands }
        let rad = isDegree ? x * Double.pi / 180 : x
        
        switch name {
        case "sin": return sin(rad)
        case "cos": return cos(rad)
        case "tan": return tan(rad)
        case "asin": let v = asin(x); return isDegree ? v * 180 / Double.pi : v
        case "acos": let v = acos(x); return isDegree ? v * 180 / Double.pi : v
        case "atan": let v = atan(x); return isDegree ? v * 180 / Double.pi : v
        case "ln": return log(x)
        case "log": return log10(x)
        case "sqrt": return sqrt(x)
        case "abs": return abs(x)
        default: throw CalcError.unknownFunction(name)
        }
    }
    
    enum CalcError: Error, LocalizedError {
        case invalidNumber(String)
        case invalidOperator(String)
        case unknownFunction(String)
        case mismatchedParentheses
        case insufficientOperands
        case invalidExpression
        case invalidFactorial
        
        var errorDescription: String? {
            switch self {
            case .invalidNumber(let s): return "Invalid number: \(s)"
            case .invalidOperator(let s): return "Invalid operator: \(s)"
            case .unknownFunction(let s): return "Unknown function: \(s)"
            case .mismatchedParentheses: return "Mismatched parentheses"
            case .insufficientOperands: return "Insufficient operands"
            case .invalidExpression: return "Invalid expression"
            case .invalidFactorial: return "Invalid factorial"
            }
        }
    }
}