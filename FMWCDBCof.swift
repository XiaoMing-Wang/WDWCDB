//
//  FMWCDBCof.swift
//  meme
//
//  Created by imMac on 2021/3/4.
//

import Foundation
import WCDBSwift

fileprivate let library = NSSearchPathForDirectoriesInDomains(.libraryDirectory, .allDomainsMask, true).first
public let libraryMemePrefix = library! + "/default/"

//MARK: 表名协议
typealias FMDBStorageProtocol = TableCodable & FMTableNameProtocol
protocol FMTableNameProtocol {
    func tableName() -> String?
    static func tableName() -> String?
}

class FMDBBaseModel: NSObject {

    //MARK: 以类名作为表名 需要修改重写该方法
    func tableName() -> String? {
        return String(describing: type(of: self))
    }

    //MARK: 以下属性不需要重写
    static func tableName() -> String? {
        let type = self
        return type.init().tableName()
    }

    required override init() {
        super.init()
    }
    
}
