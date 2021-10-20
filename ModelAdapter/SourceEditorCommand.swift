//
//  SourceEditorCommand.swift
//  ModelAdapter
//
//  Created by tony on 2021/9/14.
//

import Foundation
import XcodeKit

class SourceEditorCommand: NSObject, XCSourceEditorCommand {
    
    func perform(with invocation: XCSourceEditorCommandInvocation, completionHandler: @escaping (Error?) -> Void ) -> Void {
        //var name: calss?
        //var anchors = ""
        let originLines = invocation.buffer.lines.copy() as! [String]
        var classArray = [String]()
        for (index, line) in originLines.enumerated() {
            if line.hasPrefix("struct") == true || line.hasPrefix("class") == true {
                var classDefines = line
                if line.contains(":") {
                    classDefines = classDefines.replacingOccurrences(of: " {", with: ", ModelAdapterModel {")
                }else {
                    classDefines = classDefines.replacingOccurrences(of: " {", with: ": ModelAdapterModel {")
                }
                invocation.buffer.lines.replaceObject(at: index, with: classDefines)
                if line.hasPrefix("struct") == true {
                    classArray.append("struct")
                }else {
                    classArray.append("class")
                }
            }
        }
        
        let originCount = originLines.count
        var isLastProperty: Bool = true
        var isLastImport: Bool = true
        for (reversedIndex, line) in originLines.reversed().enumerated() {
            let index = originCount - 1 - reversedIndex
            let hasPropertyPrefix = line.contains("let") || line.contains("var")
            let isProperty = hasPropertyPrefix && (line.contains(":") || line.contains("="))
            if isProperty {
                if isLastProperty {
                    isLastProperty = false
                    let classDefine = classArray.removeLast()
                    let isClass = classDefine == "class"
                    let initFuncString = """
                        \(isClass ? "required " : "")init() {
                            initFieldExpressions()
                        }
                    """
                    invocation.buffer.lines.insert(initFuncString, at: index + 1)
                }
                let scanner = Scanner(string: line)
                scanner.charactersToBeSkipped = nil
                let spaces = scanner.scanCharacters(from: CharacterSet.whitespacesAndNewlines)
                _ = scanner.scanUpToString(":")
                _ = scanner.scanString(":")
                scanner.charactersToBeSkipped = CharacterSet.whitespacesAndNewlines
                //scan class name
                _ = scanner.scanCharacters(from: CharacterSet.letters)
                let questionMark = scanner.scanString("?")
                let isOptional = questionMark != nil
                invocation.buffer.lines.insert("\(spaces ?? "")@Field\(isOptional ? "Optional" : "")", at: index)
            }else {
                if line.hasPrefix("struct") == true || line.hasPrefix("class") == true {
                    isLastProperty = true
                }
                if line.hasPrefix("import") == true && isLastImport {
                    isLastImport = false
                    invocation.buffer.lines.insert("import ModelAdapter", at: index + 1)
                }
            }
        }
        
        completionHandler(nil)
    }
    
}
