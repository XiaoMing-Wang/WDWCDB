////
////  FXWCDBBaseStore.swift
////  IM_Client_Swift
////
////  Created by wq on 2020/6/1.
////  Copyright © 2020 wq. All rights reserved.
////
//
import UIKit
import WCDBSwift

class FMWCDBBaseOperation: NSObject {

    /** 用户id用来切换数据库 nil则会关闭数据库 */
    private var dbName: String?
    private var dataBase: Database?

    // MARK: 获取当前数据库
    var currentDB: Database? {
        get {
            if existdbName() == false {
                closeDatabase()
                return nil
            }

            if dataBase?.path != getUserFolders() && dataBase?.path != nil {
                closeDatabase()
                debugPrint("切换用户数据库: \(getUserFolders())")
            }
            
            /** 重新创建数据库对象 */
            if dataBase == nil { dataBase = createDataBase() }
            debugPrint("数据库: \(getUserFolders())")
            return dataBase
        }
    }

    // MARK: 打开或切换数据库 nil关闭数据库
    func openSwitchDB(dbName: String?) {
        self.dbName = dbName
        self.createDefaultTable()
    }

    /** 创建一个默认表 wcdb没有表不创建db文件 */
    fileprivate func createDefaultTable() {
        guard existdbName() else { return }
        createTable(table: "emptytable", of: EmptyTable.self)
    }

    //MARK: 插入数据(已经存在会更新)
    func insertToDb<T: TableCodable>(object: T, intoTable table: String) -> Bool {
        insertArrayToDb(objects: [object], intoTable: table)
    }
    
    /// 插入数据(已经存在会更新)
    /// - Parameters:
    ///   - objects: objects
    ///   - table: table
    /// - Returns: 成功与否
    func insertArrayToDb<T: TableCodable>(objects: [T], intoTable table: String) -> Bool {
        guard existdbName() else { return false }
        guard objects.count > 0 else { return false }

        //MARK: 插入数据前先建表(存在表也要先建 新增字段)
        let object = objects.first!
        guard createTable(table: table, of: type(of: object)) else { return false }

        do {
            try currentDB?.run(transaction: {
                try currentDB?.insertOrReplace(objects: objects, intoTable: table)
            })
            return true
        } catch let error {
            debugPrint("insert obj error \(error.localizedDescription)")
            return false
        }
    }

    //MARK: 修改数据(一般直接用添加修改就行) propertys代表只部分插入 传空全属性插入表中
    func updateToDb<T: TableCodable>(
        object: T,
        foTable table: String,
        on propertys: [PropertyConvertible],
        where condition: Condition? = nil) -> Bool {

        guard existdbName() else { return false }
        guard createTable(table: table, of: type(of: object)) else { return false }

        do {
            try currentDB?.update(table: table, on: propertys, with: object, where: condition)
            return true
        } catch let error {
            debugPrint("update obj error \(error.localizedDescription)")
            return false
        }
    }

    //MARK: 删除数据
    func deleteFromDb(table: String, where condition: Condition? = nil) -> Bool {
        guard existdbName() else { return false }
        guard existTable(table) else { return false }

        do {
            try currentDB?.delete(fromTable: table, where: condition)
            return true
        } catch let error {
            debugPrint("delete error \(error.localizedDescription)")
            return false
        }
    }

    //MARK: 查询数据 单个多个
    func qureyFromDb<T: TableCodable>(
        table: String,
        cls: T.Type,
        where condition: Condition? = nil) -> T? {

        qureyFromDbArray(table: table, cls: cls, where: condition, orderBy: nil)?.first
    }

    
    /// 查询数据多个
    /// - Parameters:
    ///   - table: <#table description#>
    ///   - cls: <#cls description#>
    ///   - condition: <#condition description#>
    ///   - orderList: <#orderList description#>
    ///   - limit: <#limit description#>
    ///   - offset: <#offset description#>
    /// - Returns: <#description#>
    func qureyFromDbArray<T: TableCodable>(
        table: String,
        cls: T.Type,
        where condition: Condition? = nil,
        orderBy orderList: [OrderBy]? = nil,
        limit: Limit? = nil, /* 个数15 */
        offset: Offset? = nil /* 从第几个开始 */) -> [T]? {

        guard existdbName() else { return nil }
        guard createTable(table: table, of: cls) else { return nil }

        do {
            return try currentDB?.getObjects(
                fromTable: table,
                where: condition,
                orderBy: orderList,
                limit: limit,
                offset: offset
            )
        } catch let error {
            debugPrint("no data find \(error.localizedDescription)")
            return nil
        }
    }
}

/// 表操作
extension FMWCDBBaseOperation {
    
    //MARK:创建表 表可以重复创建内部有判断
    @discardableResult
    fileprivate func createTable<T: TableCodable>(
        table: String,
        of ttype: T.Type) -> Bool {
        guard existdbName() else { return false }

        do {
            try currentDB?.create(table: table, of: ttype)
            return true
        } catch let error {
            debugPrint("create table error \(error.localizedDescription)")
            return false
        }
    }
    
    //MARK:删除表
    fileprivate func dropTable(table: String) -> Bool {
        guard existdbName() else { return false }
        
        do {
            try currentDB?.drop(table: table)
            return true
        } catch let error {
            debugPrint("drop table error \(error)")
            return false
        }
    }
    
    //MARK: 判断表是否存在
    fileprivate func existTable(_ table: String) -> Bool {
        guard existdbName() else { return false }

        do {
            return try currentDB?.isTableExists(table) ?? false
        } catch let error {
            debugPrint("no data find \(error.localizedDescription)")
            return false
        }
    }

    //MARK:删库 跑路那种
    fileprivate func removeDbFile() -> Void {
        guard existdbName() else { return }

        do {
            try currentDB?.close(onClosed: {
                try currentDB?.removeFiles()
            })
        } catch let error {
            debugPrint("not close db \(error)")
        }
    }

}

/// 数据库操作
extension FMWCDBBaseOperation {
                 
    /// 创建DB(WCDB在表为空的时候是不会创建db文件的 创建一张表)
    fileprivate func createDataBase() ->Database? {
        if dbName == nil { return nil }
        return Database(withPath: getUserFolders())
    }

    /// 关闭数据库
    fileprivate func closeDatabase() {
        if dataBase != nil {
            dataBase?.close()
            dataBase = nil
            kLogPrint("关闭数据库")
        }
    }

    /// 是否存在
    fileprivate func existdbName() -> Bool {
        return (dbName == nil) ? false : (dbName!.count > 0)
    }

    /// 获取用户文件夹
    fileprivate func getUserFolders() -> String {
        return (libraryMemePrefix + dbName! + ".db")
    }

}

/**< 创建空表打开wcdb */
class EmptyTable: TableCodable {
    var emptyTableKey: String? = nil
    enum CodingKeys: String, CodingTableKey {
        typealias Root = EmptyTable
        static let objectRelationalMapping = TableBinding(CodingKeys.self)
        case emptyTableKey

        static var columnConstraintBindings: [CodingKeys: ColumnConstraintBinding]? {
            return [emptyTableKey: ColumnConstraintBinding(isPrimary: true)]
        }
    }
}
