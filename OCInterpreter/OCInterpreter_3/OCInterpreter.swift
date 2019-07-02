//
//  OCInterpreter.swift
//  HTN
//
//  Created by DaiMing on 2018/6/5.
//

import Foundation

public enum OCValue {
    case none
    case number(OCNumber)
    case boolean(Bool)
    case string(String)
}

public enum OCConstant {
    case integer(Int)
    case float(Float)
    case boolean(Bool)
    case string(String)
}

public enum OCOperation {
    case plus
    case minus
    case mult
    case intDiv
}

public enum OCDirection {
    case left
    case right
}

public enum OCToken {
    case constant(OCConstant)
    case operation(OCOperation)
    case paren(OCDirection)
    case eof
    case whiteSpaceAndNewLine
}

extension OCConstant: Equatable {
    public static func == (lhs: OCConstant, rhs: OCConstant) -> Bool {
        switch (lhs, rhs) {
        case let (.integer(left), .integer(right)):
            return left == right
        case let (.float(left), .float(right)):
            return left == right
        case let (.boolean(left), .boolean(right)):
            return left == right
        case let (.string(left), .string(right)):
            return left == right
        default:
            return false
        }
    }
}

extension OCOperation: Equatable {
    public static func == (lhs: OCOperation, rhs: OCOperation) -> Bool {
        switch (lhs, rhs) {
        case (.plus, .plus):
            return true
        case (.minus, .minus):
            return true
        case (.mult, .mult):
            return true
        case (.intDiv, .intDiv):
            return true
        default:
            return false
        }
    }
}

extension OCDirection: Equatable {
    public static func == (lhs: OCDirection, rhs: OCDirection) -> Bool {
        switch (lhs, rhs) {
        case (.left, .left):
            return true
        case (.right, .right):
            return true
        default:
            return false
        }
    }
}

extension OCToken: Equatable {
    public static func == (lhs: OCToken, rhs: OCToken) -> Bool {
        switch (lhs, rhs) {
        case let (.constant(left), .constant(right)):
            return left == right
        case let (.operation(left), .operation(right)):
            return left == right
        case (.eof, .eof):
            return true
        case (.whiteSpaceAndNewLine, .whiteSpaceAndNewLine):
            return true
        case let (.paren(left), .paren(right)):
            return left == right
        default:
            return false
        }
    }
}

public class OCLexer {
    private let text: String
    private var currentIndex: Int
    private var currentCharacter: Character?
    
    public init(_ input: String) {
        if input.count == 0 {
            fatalError("Error! input can't be empty")
        }
        self.text = input
        currentIndex = 0
        currentCharacter = text[text.startIndex]
    }
    
    // 流程函数
    func nextTk() -> OCToken {
        if currentIndex > self.text.count - 1 {
            return .eof
        }
        
        if CharacterSet.whitespacesAndNewlines.contains((currentCharacter?.unicodeScalars.first!)!) {
            skipWhiteSpaceAndNewLines()
            return .whiteSpaceAndNewLine
        }
        
        if CharacterSet.decimalDigits.contains((currentCharacter?.unicodeScalars.first!)!) {
            return number()
        }
        
        if currentCharacter == "+" {
            advance()
            return .operation(.plus)
        }
        if currentCharacter == "-" {
            advance()
            return .operation(.minus)
        }
        if currentCharacter == "*" {
            advance()
            return .operation(.mult)
        }
        if currentCharacter == "/" {
            advance()
            return .operation(.intDiv)
        }
        if currentCharacter == "(" {
            advance()
            return .paren(.left)
        }
        if currentCharacter == ")" {
            advance()
            return .paren(.right)
        }
        advance()
        return .eof
    }
    // 数字处理
    private func number() -> OCToken {
        var numStr = ""
        while let character = currentCharacter,  CharacterSet.decimalDigits.contains((character.unicodeScalars.first!)) {
            numStr += String(character)
            advance()
        }
        
        return .constant(.integer(Int(numStr)!))
    }
    
    // 辅助函数
    private func advance() {
        currentIndex += 1
        guard currentIndex < text.count else {
            currentCharacter = nil
            return
        }
        currentCharacter = text[text.index(text.startIndex, offsetBy: currentIndex)]
    }
    
    // 往前探一个字符，不改变当前字符
    private func peek() -> Character? {
        let peekIndex = currentIndex + 1
        guard peekIndex < text.count else {
            return nil
        }
        return text[text.index(text.startIndex, offsetBy: peekIndex)]
    }
    
    private func skipWhiteSpaceAndNewLines() {
        while let character = currentCharacter, CharacterSet.whitespacesAndNewlines.contains((character.unicodeScalars.first!)) {
            advance()
        }
    }
}

public class OCInterpreter {
    
    private var lexer: OCLexer
    private var currentTk: OCToken
    
    public init(_ input: String) {
        lexer = OCLexer(input)
        currentTk = lexer.nextTk()
    }
    
    // eval
    public func eval(node: OCAST) -> OCValue {
        switch node {
        case let number as OCNumber:
            return eval(number: number)
        case let unaryOperation as OCUnaryOperation:
            return eval(unaryOperation: unaryOperation)
        case let binOp as OCBinOp:
            return eval(binOp: binOp)
        default:
            return .none
        }
    }
    
    func eval(number: OCNumber) -> OCValue {
        return .number(number)
    }
    
    func eval(binOp: OCBinOp) -> OCValue {
        guard case let .number(leftResult) = eval(node: binOp.left), case let .number(rightResult) = eval(node: binOp.right) else {
            fatalError("Error! binOp is wrong")
        }
        
        switch binOp.operation {
        case .plus:
            return .number(leftResult + rightResult)
        case .minus:
            return .number(leftResult - rightResult)
        case .mult:
            return .number(leftResult * rightResult)
        case .intDiv:
            return .number(leftResult / rightResult)
        }
    }
    
    func eval(unaryOperation: OCUnaryOperation) -> OCValue {
        guard case let .number(result) = eval(node: unaryOperation.operand) else {
            fatalError("Error: eval unaryOperation")
        }
        switch unaryOperation.operation {
        case .plus:
            return .number(+result)
        case .minus:
            return .number(-result)
        }
    }
    
    public func expr() -> OCAST {
        var node = term()
        
        while [.operation(.plus), .operation(.minus)].contains(currentTk) {
            let tk = currentTk
            eat(currentTk)
            if tk == .operation(.plus) {
                node = OCBinOp(left: node, operation: .plus, right: term())
            } else if tk == .operation(.minus) {
                node = OCBinOp(left: node, operation: .minus, right: term())
            }
        }
        return node
    }
    
    // 语法解析中对数字的处理
    private func term() -> OCAST {
        var node = factor()
        
        while [.operation(.mult), .operation(.intDiv)].contains(currentTk) {
            let tk = currentTk
            eat(currentTk)
            if tk == .operation(.mult) {
                node = OCBinOp(left: node, operation: .mult, right: factor())
            } else if tk == .operation(.intDiv) {
                node = OCBinOp(left: node, operation: .intDiv, right: factor())
            }
        }
        return node
    }
    
    private func factor() -> OCAST {
        let tk = currentTk
        switch tk {
        case .operation(.plus):
            eat(.operation(.plus))
            return OCUnaryOperation(operation: .plus, operand: factor())
        case .operation(.minus):
            eat(.operation(.minus))
            return OCUnaryOperation(operation: .minus, operand: factor())
        case let .constant(.integer(result)):
            eat(.constant(.integer(result)))
            return OCNumber.integer(result)
        case .paren(.left):
            eat(.paren(.left))
            let result = expr()
            eat(.paren(.right))
            return result
        default:
            return OCNumber.integer(0)
        }
    }
    
    private func eat(_ token: OCToken) {
        if  currentTk == token {
            currentTk = lexer.nextTk()
            if currentTk == OCToken.whiteSpaceAndNewLine {
                currentTk = lexer.nextTk()
            }
        } else {
            error()
        }
    }
    
    func error() {
        fatalError("Error!")
    }
    
    
}
