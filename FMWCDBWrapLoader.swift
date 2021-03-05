//
//  FXWCDBWrapStore.swift
//  meme
//
//  Created by imMac on 2021/3/4.
//
import WCDBSwift
import Foundation

class FMWCDBWrapLoader: NSObject {
    
    /** 单例 */
    static let share = FMWCDBWrapLoader()
    
    /** 数据库实例 */
   fileprivate let dbInstance = FMWCDBBaseOperation()
    
    override init() {
        super.init()
        self.openSwitchDB(dbName: "commom")
    }
    
    //MARK: 需要设置dbName
    func openSwitchDB(dbName: String?) {
        dbInstance.openSwitchDB(dbName: dbName)
    }
    
    //MARK: 插入数据用类名,传表名会使用表名,不传使用tableName()(已经存在会更新)
    @discardableResult
    func insertToDb<T: FMDBStorageProtocol>(object: T, table: String? = nil) -> Bool {
        guard let toTable = table ?? object.tableName() else { return false }
        return dbInstance.insertToDb(object: object, intoTable: toTable)
    }
    
    //MARK: 插入数据用类名,传表名会使用表名,不传使用tableName()(已经存在会更新)
    @discardableResult
    func insertToDbArray<T: FMDBStorageProtocol>(objects: [T], table: String? = nil) -> Bool {
        guard let object = objects.first else { return false }
        guard let toTable = table ?? object.tableName() else { return false }
        return dbInstance.insertArrayToDb(objects: objects, intoTable: toTable)
    }
    
    //MARK: 删除数据 where *.Properties.*.is
    @discardableResult
    func deleteFromDb<T: FMDBStorageProtocol>(ttype: T.Type = T.self, table: String? = nil, where condition: Condition? = nil) -> Bool {
        guard let toTable = table ?? ttype.tableName() else { return false }
        return dbInstance.deleteFromDb(table: toTable, where: condition)
    }
    
    //MARK: 删除数据 where *.Properties.*.is
    @discardableResult
    func deleteFromDb(table: String, where condition: Condition? = nil) -> Bool {
        dbInstance.deleteFromDb(table: table, where: condition)
    }
    
    //MARK: 删除全部数据
    @discardableResult
    func deleteAllFromDb<T: FMDBStorageProtocol>( ttype: T.Type = T.self, table: String? = nil, where condition: Condition? = nil) -> Bool {
        guard let toTable = table ?? ttype.tableName() else { return false }
        return dbInstance.deleteFromDb(table: toTable)
    }

    //MARK: 查询单个数据 condition查询条件 orderList排序
    @discardableResult
    func qureyFromDb<T: FMDBStorageProtocol>( ttype: T.Type,  table: String? = nil,  where condition: Condition? = nil) -> T? {
        guard let toTable = table ?? ttype.tableName() else { return nil }
        return dbInstance.qureyFromDb(table: toTable, cls: ttype, where: condition)
    }

    //MARK: 查询多个数据  *.Properties.*.asOrder(by: .ascending升序/descending降序)
    @discardableResult
    func qureyFromDb<T: FMDBStorageProtocol>(
        ttype: T.Type,
        table: String? = nil,
        where condition: Condition? = nil,
        orderBy orderList: [OrderBy]? = nil,
        limit: Limit? = nil,  /* 个数 */
        offset: Offset? = nil /* 从第几个开始 */) -> [T]? {

        guard let toTable = table ?? ttype.tableName() else { return nil }
        return dbInstance.qureyFromDbArray(
            table: toTable,
            cls: ttype,
            where: condition,
            orderBy: orderList,
            limit: limit,
            offset: offset
        )
    }
    
}
