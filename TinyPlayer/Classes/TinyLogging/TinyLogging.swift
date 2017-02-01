//
//  TinyLogging.swift
//  TinyPlayerDemo
//
//  Created by Kevin Chen on 07/12/2016.
//  Copyright © 2016 Xi Chen. All rights reserved.
//

import Foundation


public enum TinyLoggingLevel: Int {
    case verbose = 0
    case info = 1
    case warning = 2
    case error = 3
    case none = 4
}


public protocol TinyLogging {
    
    var loggingLevel: TinyLoggingLevel { get set }
}


public extension TinyLogging {

    func verboseLog(_ msg: String, file: String = #file, level: TinyLoggingLevel = .verbose) {
        
        generalLog(msg, file: file, level: level)
    }

    func infoLog(_ msg: String, file: String = #file, level: TinyLoggingLevel = .info) {
        
        generalLog(msg, file: file, level: level)
    }

    func warningLog(_ msg: String, file: String = #file, level: TinyLoggingLevel = .warning) {
        
        generalLog(msg, file: file, level: level)
    }

    func errorLog(_ msg: String, file: String = #file, level: TinyLoggingLevel = .error) {
        
        generalLog(msg, file: file, level: level)
    }

    func generalLog(_ msg: String, file: String, level: TinyLoggingLevel) {
        
        if self.loggingLevel.rawValue <= level.rawValue {
            
            let levelStringRepresentation: String
            
            switch level {
            case .verbose:
                levelStringRepresentation = "[verbose]"
            case .info:
                levelStringRepresentation = "[info]"
            case .warning:
                levelStringRepresentation = "[warning]"
            case .error:
                levelStringRepresentation = "[error]"
            default:
                levelStringRepresentation = ""
            }
            
            var fileName: String = ""
            if let prefix = file.components(separatedBy: ".swift").first,
               let postfix = prefix.components(separatedBy: "/").last {
                    fileName = postfix
            }
            
            print("[" + fileName + "]" + levelStringRepresentation + msg)
        }
    }
}
