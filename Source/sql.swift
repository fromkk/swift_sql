#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS)
    import Darwin
#elseif os(Linux)
    import Glibc
#endif

internal protocol SQLSelectQueryBuilder : class {
    var _table :String { get set }
    var _columns :[String] { get set }
    var _where :[SQLQueryWhere] { get set }
    var _groupBy :[String] { get set }
    var _limit :Int? { get set }
    var _offset :Int { get set }
    init(table :String, columns :[String])
    func limitQuery() -> String
    func escape(string :String) -> String
}

internal protocol SQLQueryWhere {}
internal struct SQLQueryAndWhere :SQLQueryWhere
{
    var value :String
}
internal struct SQLQueryOrWhere :SQLQueryWhere
{
    var value :String
}
internal struct SQLQueryAndWhereOpen :SQLQueryWhere {}
internal struct SQLQueryAndWhereClose :SQLQueryWhere {}
internal struct SQLQueryOrWhereOpen :SQLQueryWhere {}
internal struct SQLQueryOrWhereClose :SQLQueryWhere {}

internal extension SQLSelectQueryBuilder
{
    static func select(table :String, columns :[String] = []) -> Self
    {
        return Self(table :table, columns :columns)
    }

    func andWhere<T>(key :String, value :T) -> Self
    {
        var sql :String = ""
        if value is Int || value is Float || value is Double
        {
            sql = "\(key) = \(value)"
        } else if let string :String = value as? String
        {
            sql = "\(key) = \"\(self.escape(string: string))\""
        }
        if 0 != sql.characters.count
        {
            self._where.append(SQLQueryAndWhere(value :sql))
        }

        return self
    }

    func orWhere<T>(key :String, value :T) -> Self
    {
        var sql :String = ""
        if value is Int || value is Float || value is Double
        {
            sql = "\(key) = \(value)"
        } else if let string :String = value as? String
        {
            sql = "\(key) = \"\(self.escape(string: string))\""
        }
        if 0 != sql.characters.count
        {
            self._where.append(SQLQueryOrWhere(value :sql))
        }
        return self
    }

    func andWhereOpen() -> Self
    {
        self._where.append(SQLQueryAndWhereOpen())
        return self
    }

    func andWhereClose() -> Self
    {
        self._where.append(SQLQueryAndWhereClose())
        return self
    }

    func orWhereOpen() -> Self
    {
        self._where.append(SQLQueryOrWhereOpen())
        return self
    }

    func orWhereClose() -> Self
    {
        self._where.append(SQLQueryOrWhereClose())
        return self
    }

    func groupBy(values :[String]) -> Self
    {
        self._groupBy = values
        return self
    }

    func offset(offset :Int) -> Self
    {
        self._offset = offset
        return self
    }

    func limit(limit :Int) -> Self
    {
        self._limit = limit
        return self
    }

    func query() -> String
    {
        let columns :String = 0 == self._columns.count ? "*" : self._columns.joined(separator : ",")
        var sql :String = "SELECT \(columns) FROM \(self._table)"

        var whereString :String = ""
        var didOpen :Bool = false
        self._where.forEach {
            if let item :SQLQueryAndWhere = $0 as? SQLQueryAndWhere
            {
                if 0 != whereString.characters.count && false == didOpen { whereString += " AND " }
                whereString += item.value
                didOpen = false
            } else if let item :SQLQueryOrWhere = $0 as? SQLQueryOrWhere
            {
                if 0 != whereString.characters.count && false == didOpen { whereString += " OR " }
                whereString += item.value
                didOpen = false
            } else if let _ = $0 as? SQLQueryAndWhereOpen
            {
                if 0 != whereString.characters.count && false == didOpen { whereString += " AND " }
                whereString += "("
                didOpen = true
            } else if let _ = $0 as? SQLQueryAndWhereClose
            {
                whereString += ")"
                didOpen = false
            }
            else if let _ = $0 as? SQLQueryOrWhereOpen
           {
               if 0 != whereString.characters.count && false == didOpen { whereString += " OR " }
               whereString += "("
               didOpen = true
           } else if let _ = $0 as? SQLQueryOrWhereClose
           {
               whereString += ")"
               didOpen = false
           }
        }
        if 0 != whereString.characters.count
        {
            sql += " WHERE \(whereString)"
        }
        if 0 != self._groupBy.count
        {
            sql += " GROUP BY \(self._groupBy.joined(separator :", "))"
        }

        sql += self.limitQuery()

        return sql
    }
    func generalEscape(string :String) -> String
    {
        //http://php.net/manual/ja/function.mysql-real-escape-string.php#101248
        let escapes :[String] = ["\\", "\"", "'", "\0", "\n", "\r"]
        var result :String = string
        escapes.forEach {
            result = result.stringByReplacingOccurrencesOfString($0, withString:"\\\($0)")
        }
        result = result.stringByReplacingOccurrencesOfString("\\x1a", withString: "\\Z")
        return result
    }
}
