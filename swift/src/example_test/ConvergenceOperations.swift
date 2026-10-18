// ============================================================
// ConvergenceOperations.swift
// 収束演算のSwift実装
// 不動点反復、勾配降下法、ニュートン法、汎用収束フレームワーク
// ============================================================

import Foundation

// MARK: - エラー型

enum ConvergenceError: Error {
    case maxIterationsExceeded(maxIterations: Int)
    case diverged(lastValue: Double)
    case invalidInitialValue
    case invalidTolerance(tolerance: Double)
}

// MARK: - 収束結果

struct ConvergenceResult<T> {
    let value: T
    let iterations: Int
    let finalError: Double
    let history: [T]
    let converged: Bool

    func summary() -> String {
        return """
        === 収束結果 ===
        反復回数: \(iterations)
        最終誤差: \(String(format: "%.6e", finalError))
        収束判定: \(converged ? "収束" : "未収束")
        """
    }
}

// MARK: - 収束条件プロトコル

/// 収束判定を行うプロトコル
protocol ConvergenceCriterion {
    func shouldStop(current: Double, previous: Double, iteration: Int) -> Bool
    func errorMeasure(current: Double, previous: Double) -> Double
}

// MARK: - 具体的な収束条件

/// 絶対誤差による収束判定
struct AbsoluteTolerance: ConvergenceCriterion {
    let tolerance: Double

    init(tolerance: Double) {
        self.tolerance = tolerance
    }

    func shouldStop(current: Double, previous: Double, iteration: Int) -> Bool {
        return abs(current - previous) < tolerance
    }

    func errorMeasure(current: Double, previous: Double) -> Double {
        return abs(current - previous)
    }
}

/// 相対誤差による収束判定
struct RelativeTolerance: ConvergenceCriterion {
    let tolerance: Double

    init(tolerance: Double) {
        self.tolerance = tolerance
    }

    func shouldStop(current: Double, previous: Double, iteration: Int) -> Bool {
        let denom = abs(previous)
        if denom < .ulpOfOne { return abs(current - previous) < tolerance }
        return abs(current - previous) / denom < tolerance
    }

    func errorMeasure(current: Double, previous: Double) -> Double {
        let denom = abs(previous)
        if denom < .ulpOfOne { return abs(current - previous) }
        return abs(current - previous) / denom
    }
}

/// 複合収束判定（絶対誤差 OR 相対誤差）
struct CompositeTolerance: ConvergenceCriterion {
    let absoluteTol: Double
    let relativeTol: Double

    func shouldStop(current: Double, previous: Double, iteration: Int) -> Bool {
        let absDiff = abs(current - previous)
        if absDiff < absoluteTol { return true }
        let denom = abs(previous)
        if denom < .ulpOfOne { return false }
        return absDiff / denom < relativeTol
    }

    func errorMeasure(current: Double, previous: Double) -> Double {
        return abs(current - previous)
    }
}

/// 残差ノルムによる収束判定（形方程式など）
struct ResidualTolerance: ConvergenceCriterion {
    let tolerance: Double
    let computeResidual: (Double) -> Double

    func shouldStop(current: Double, previous: Double, iteration: Int) -> Bool {
        return abs(computeResidual(current)) < tolerance
    }

    func errorMeasure(current: Double, previous: Double) -> Double {
        return abs(computeResidual(current))
    }
}

// MARK: - 不動点反復（FPI）

/// 不動点反復: x_{n+1} = f(x_n)
/// 数学的収束保証: f が縮小写像（Lipschitz L < 1）ならバナッハの定理より収束
struct FixedPointIteration {
    let maxIterations: Int
    let criterion: ConvergenceCriterion
    let recordHistory: Bool

    init(maxIterations: Int = 1000,
         criterion: ConvergenceCriterion = AbsoluteTolerance(tolerance: 1e-10),
         recordHistory: Bool = false) {
        self.maxIterations = maxIterations
        self.criterion = criterion
        self.recordHistory = recordHistory
    }

    /// 不動点を求める
    /// - Parameters:
    ///   - f: 反復関数
    ///   - initialGuess: 初期値
    /// - Returns: 収束結果
    func solve(f: (Double) -> Double, initialGuess: Double) throws -> ConvergenceResult<Double> {
        var x = initialGuess
        var history: [Double] = recordHistory ? [x] : []

        for iteration in 1...maxIterations {
            let xNext = f(x)
            let error = criterion.errorMeasure(current: xNext, previous: x)

            if recordHistory { history.append(xNext) }

            if criterion.shouldStop(current: xNext, previous: x, iteration: iteration) {
                return ConvergenceResult(
                    value: xNext,
                    iterations: iteration,
                    finalError: error,
                    history: history,
                    converged: true
                )
            }

            // 発散チェック
            if xNext.isInfinite || xNext.isNaN {
                throw ConvergenceError.diverged(lastValue: x)
            }

            x = xNext
        }

        throw ConvergenceError.maxIterationsExceeded(maxIterations: maxIterations)
    }
}

// MARK: - 勾配降下法

/// 勾配降下法
/// 数学的収束保証: F が L-smooth で学習率 η ≤ 1/L なら収束
struct GradientDescent {
    let learningRate: Double
    let maxIterations: Int
    let criterion: ConvergenceCriterion
    let recordHistory: Bool

    init(learningRate: Double,
         maxIterations: Int = 10000,
         criterion: ConvergenceCriterion = AbsoluteTolerance(tolerance: 1e-8),
         recordHistory: Bool = false) {
        self.learningRate = learningRate
        self.maxIterations = maxIterations
        self.criterion = criterion
        self.recordHistory = recordHistory
    }

    /// 勾配降下法で最小化
    /// - Parameters:
    ///   - gradient: 勾配関数 ∇F(x)
    ///   - initialGuess: 初期値
    /// - Returns: 収束結果
    func minimize(gradient: (Double) -> Double, initialGuess: Double) throws -> ConvergenceResult<Double> {
        var x = initialGuess
        var history: [Double] = recordHistory ? [x] : []

        for iteration in 1...maxIterations {
            let grad = gradient(x)
            let xNext = x - learningRate * grad
            let error = criterion.errorMeasure(current: xNext, previous: x)

            if recordHistory { history.append(xNext) }

            if criterion.shouldStop(current: xNext, previous: x, iteration: iteration) {
                return ConvergenceResult(
                    value: xNext,
                    iterations: iteration,
                    finalError: error,
                    history: history,
                    converged: true
                )
            }

            if xNext.isInfinite || xNext.isNaN {
                throw ConvergenceError.diverged(lastValue: x)
            }

            x = xNext
        }

        throw ConvergenceError.maxIterationsExceeded(maxIterations: maxIterations)
    }

    /// 損失関数と勾配の両方を使った版（Armijo条件付き）
    func minimizeWithArmijo(
        loss: (Double) -> Double,
        gradient: (Double) -> Double,
        initialGuess: Double,
        armijoC: Double = 0.5,
        armijoRho: Double = 0.5
    ) throws -> ConvergenceResult<Double> {
        var x = initialGuess
        var history: [Double] = recordHistory ? [x] : []

        for iteration in 1...maxIterations {
            let grad = gradient(x)
            let direction = -grad

            // Armijo線探索
            var alpha = learningRate
            let fx = loss(x)
            let lhs = loss(x + alpha * direction)
            let rhs = fx + armijoC * alpha * grad * direction

            var armijoSteps = 0
            while lhs > rhs && armijoSteps < 20 {
                alpha *= armijoRho
                let newLhs = loss(x + alpha * direction)
                let newRhs = fx + armijoC * alpha * grad * direction
                if newLhs <= newRhs { break }
                armijoSteps += 1
            }

            let xNext = x + alpha * direction
            let error = criterion.errorMeasure(current: xNext, previous: x)

            if recordHistory { history.append(xNext) }

            if criterion.shouldStop(current: xNext, previous: x, iteration: iteration) {
                return ConvergenceResult(
                    value: xNext,
                    iterations: iteration,
                    finalError: error,
                    history: history,
                    converged: true
                )
            }

            x = xNext
        }

        throw ConvergenceError.maxIterationsExceeded(maxIterations: maxIterations)
    }
}

// MARK: - ニュートン法

/// ニュートン法
/// 数学的収束保証: f が2回微分可能で f'(x*) ≠ 0 なら初期値が近ければ2次収束
struct NewtonMethod {
    let maxIterations: Int
    let tolerance: Double
    let recordHistory: Bool

    init(maxIterations: Int = 50, tolerance: Double = 1e-12, recordHistory: Bool = false) {
        self.maxIterations = maxIterations
        self.tolerance = tolerance
        self.recordHistory = recordHistory
    }

    /// 方程式 f(x) = 0 を解く
    /// - Parameters:
    ///   - f: 関数
    ///   - df: 導関数
    ///   - initialGuess: 初期値
    /// - Returns: 収束結果
    func solve(f: (Double) -> Double, df: (Double) -> Double, initialGuess: Double) throws -> ConvergenceResult<Double> {
        var x = initialGuess
        var history: [Double] = recordHistory ? [x] : []

        for iteration in 1...maxIterations {
            let fx = f(x)
            let dfx = df(x)

            if abs(dfx) < .ulpOfOne {
                throw ConvergenceError.invalidInitialValue
            }

            let xNext = x - fx / dfx
            let error = abs(xNext - x)

            if recordHistory { history.append(xNext) }

            if error < tolerance {
                return ConvergenceResult(
                    value: xNext,
                    iterations: iteration,
                    finalError: error,
                    history: history,
                    converged: true
                )
            }

            if xNext.isInfinite || xNext.isNaN {
                throw ConvergenceError.diverged(lastValue: x)
            }

            x = xNext
        }

        throw ConvergenceError.maxIterationsExceeded(maxIterations: maxIterations)
    }

    /// 平方根計算専用（x^2 - a = 0）
    func sqrt(_ a: Double, initialGuess: Double? = nil) throws -> ConvergenceResult<Double> {
        let x0 = initialGuess ?? a / 2.0
        return try solve(
            f: { x in x * x - a },
            df: { x in 2 * x },
            initialGuess: x0
        )
    }
}

// MARK: - ベクトル版（多次元）

/// 多次元ベクトル（簡易実装）
typealias Vector = [Double]

extension Vector {
    func norm() -> Double {
        return sqrt(self.reduce(0) { $0 + $1 * $1 })
    }

    static func -(lhs: Vector, rhs: Vector) -> Vector {
        return zip(lhs, rhs).map(-)
    }
}

/// 多次元勾配降下法
struct VectorGradientDescent {
    let learningRate: Double
    let maxIterations: Int
    let tolerance: Double

    func minimize(
        gradient: (Vector) -> Vector,
        initialGuess: Vector
    ) throws -> ConvergenceResult<Vector> {
        var x = initialGuess
        let dim = x.count

        for iteration in 1...maxIterations {
            let grad = gradient(x)
            let xNext = zip(x, grad).map { $0 - learningRate * $1 }
            let diff = zip(xNext, x).map(-)
            let error = sqrt(diff.reduce(0) { $0 + $1 * $1 })

            if error < tolerance {
                return ConvergenceResult(
                    value: xNext,
                    iterations: iteration,
                    finalError: error,
                    history: [],
                    converged: true
                )
            }

            x = xNext
        }

        throw ConvergenceError.maxIterationsExceeded(maxIterations: maxIterations)
    }
}

// MARK: - 使用例

func runExamples() {
    print("=" .repeat(60))
    print("【例1】不動点反復: x = cos(x)")
    print("=" .repeat(60))

    let fpi = FixedPointIteration(
        maxIterations: 100,
        criterion: AbsoluteTolerance(tolerance: 1e-10),
        recordHistory: true
    )

    do {
        let result = try fpi.solve(f: cos, initialGuess: 0.5)
        print(result.summary())
        print("不動点の値: \(String(format: "%.10f", result.value))")
        print("履歴（最初8ステップ）:")
        for (i, v) in result.history.prefix(8).enumerated() {
            print("  n=\(i): \(String(format: "%.10f", v))")
        }
    } catch {
        print("エラー: \(error)")
    }

    print()
    print("=" .repeat(60))
    print("【例2】勾配降下法: F(x) = 0.5*x^2 + 0.25*x^4")
    print("=" .repeat(60))

    let gd = GradientDescent(
        learningRate: 0.1,
        maxIterations: 1000,
        criterion: AbsoluteTolerance(tolerance: 1e-8),
        recordHistory: false
    )

    do {
        let result = try gd.minimize(
            gradient: { x in x + x * x * x },
            initialGuess: 2.0
        )
        print(result.summary())
        print("最適解: \(String(format: "%.10f", result.value))")
    } catch {
        print("エラー: \(error)")
    }

    print()
    print("=" .repeat(60))
    print("【例3】勾配降下法 + Armijo線探索")
    print("=" .repeat(60))

    do {
        let result = try gd.minimizeWithArmijo(
            loss: { x in 0.5 * x * x + 0.25 * x * x * x * x },
            gradient: { x in x + x * x * x },
            initialGuess: 2.0
        )
        print(result.summary())
        print("最適解: \(String(format: "%.10f", result.value))")
    } catch {
        print("エラー: \(error)")
    }

    print()
    print("=" .repeat(60))
    print("【例4】ニュートン法: x^2 - 2 = 0")
    print("=" .repeat(60))

    let newton = NewtonMethod(maxIterations: 20, tolerance: 1e-14, recordHistory: true)

    do {
        let result = try newton.sqrt(2.0)
        print(result.summary())
        print("√2 ≈ \(String(format: "%.15f", result.value))")
        print("真の値: \(String(format: "%.15f", sqrt(2)))")
        print("履歴:")
        for (i, v) in result.history.enumerated() {
            let err = abs(v - sqrt(2))
            print("  n=\(i): \(String(format: "%.15f", v)), 誤差=\(String(format: "%.2e", err))")
        }
    } catch {
        print("エラー: \(error)")
    }

    print()
    print("=" .repeat(60))
    print("【例5】残差ノルムによる収束判定")
    print("=" .repeat(60))

    // 1次元線形方程式 ax = b の残差 |ax - b| で停止判定
    let a = 3.0
    let b = 6.0
    let residualCriterion = ResidualTolerance(tolerance: 1e-12) { x in
        return a * x - b  // 残差 r = ax - b
    }
    let fpiResidual = FixedPointIteration(
        maxIterations: 1000,
        criterion: residualCriterion,
        recordHistory: false
    )

    do {
        // Richardson反復: x = x - ω(ax - b) = (1 - ωa)x + ωb
        let omega = 0.1
        let result = try fpiResidual.solve(
            f: { x in (1 - omega * a) * x + omega * b },
            initialGuess: 0.0
        )
        print(result.summary())
        print("解: \(String(format: "%.10f", result.value)) (真の解: \(b/a))")
    } catch {
        print("エラー: \(error)")
    }
}

// String extension for repeat
extension String {
    func repeat(_ count: Int) -> String {
        return String(repeating: self, count: count)
    }
}

// 実行
runExamples()
