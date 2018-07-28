part of query;

/// Select SQL statement builder.
class Find implements Statement {
  final _column = <SelColumn>[];

  final TableName from;

  final _joins = <JoinedTable>[];

  JoinedTable _curJoin;

  Expression _where = new And();

  final List<OrderBy> _orderBy = [];

  final List<String> _groupBy = [];

  int _limit;

  int _offset;

  Find(String tableName, {String alias, Expression where})
      : from = new TableName(tableName, alias) {
    if(where != null) this.where(where);
    _immutable = new ImmutableFindStatement(this);
  }

  /// Adds a 'join' clause to the select statement
  Find addJoin(JoinedTable join) {
    if (join == null) throw new Exception('Join cannot be null!');

    _curJoin = join;
    _joins.add(_curJoin);
    return this;
  }

  /// Adds a 'inner join' clause to the select statement.
  Find innerJoin(String tableName, [String alias]) {
    _curJoin = new JoinedTable.innerJoin(tableName, alias);
    _joins.add(_curJoin);
    return this;
  }

  /// Adds a 'left join' clause to the select statement.
  Find leftJoin(String tableName, [String alias]) {
    _curJoin = new JoinedTable.leftJoin(tableName, alias);
    _joins.add(_curJoin);
    return this;
  }

  /// Adds a 'right join' clause to the select statement.
  Find rightJoin(String tableName, [String alias]) {
    _curJoin = new JoinedTable.rightJoin(tableName, alias);
    _joins.add(_curJoin);
    return this;
  }

  /// Adds a 'full join' clause to the select statement.
  Find fullJoin(String tableName, [String alias]) {
    _curJoin = new JoinedTable.fullJoin(tableName, alias);
    _joins.add(_curJoin);
    return this;
  }

  /// Adds 'cross join' clause to the select statement.
  Find crossJoin(String tableName, [String alias]) {
    _curJoin = new JoinedTable.crossJoin(tableName, alias);
    _joins.add(_curJoin);
    return this;
  }

  /// Adds the condition with which to perform joins.
  Find joinOn(Expression exp) {
    if (_curJoin == null) throw new Exception('No joins in the join stack!');

    _curJoin.joinOn(exp);
    return this;
  }

  /// Selects a [column] to be fetched. Use [alias] to alias the column name.
  Find sel(String column, [String alias]) {
    _column.add(new SelColumn(column, alias));
    return this;
  }

  /// Selects a [column] to be fetched. Use [alias] to alias the column name.
  Find selAll() {
    _column.add(new SelColumn('*'));
    return this;
  }

  /// Selects a [column] to be fetched. Use [alias] to alias the column name.
  Find selAllFromTable(String table) {
    _column.add(new SelColumn('$table.*'));
    return this;
  }

  /// Selects many [columns] to be fetched. Use [alias] to alias the column name.
  Find selMany(Iterable<String> columns, [String alias]) {
    for (String columnName in columns) {
      final String name = columnName;
      _column.add(new SelColumn(name));
    }
    return this;
  }

  /// Selects a [column] to be fetched from the [table]. Use [alias] to alias
  /// the column name.
  Find selIn(String table, String column, [String alias]) {
    final String name = table + '.' + column;
    _column.add(new SelColumn(name, alias));
    return this;
  }

  /// Selects many [columns] to be fetched in the given [table]. Use [alias] to
  /// alias the column name.
  Find selManyIn(String table, List<String> columns) {
    for (String columnName in columns) {
      final String name = table + '.' + columnName;
      _column.add(new SelColumn(name));
    }
    return this;
  }

  Find count(String column, {String alias, bool isDistinct: false}) {
    _column
        .add(new CountSelColumn(column, alias: alias, isDistinct: isDistinct));
    return this;
  }

  /// Adds an 'or' [expression] to 'where' clause.
  Find or(Expression expression) {
    _where = _where.or(expression);
    return this;
  }

  /// Adds an 'and' [expression] to 'where' clause.
  Find and(Expression exp) {
    _where = _where.and(exp);
    return this;
  }

  Find orMap<T>(Iterable<T> iterable, MappedExpression<T> func) {
    iterable.forEach((T v) {
      final Expression exp = func(v);
      if (exp != null) _where = _where.or(exp);
    });
    return this;
  }

  Find andMap<T>(Iterable<T> iterable, MappedExpression<T> func) {
    iterable.forEach((T v) {
      final Expression exp = func(v);
      if (exp != null) _where = _where.and(exp);
    });
    return this;
  }

  /// Adds an to 'where' [expression] clause.
  Find where(Expression expression) {
    _where = _where.and(expression);
    return this;
  }

  /// Adds an '=' [expression] to 'where' clause.
  Find eq<T>(String column, T val) => and(q.eq<T>(column, val));

  /// Adds an '<>' [expression] to 'where' clause.
  Find ne<T>(String column, T val) => and(q.ne<T>(column, val));

  /// Adds an '>' [expression] to 'where' clause.
  Find gt<T>(String column, T val) => and(q.gt<T>(column, val));

  /// Adds an '>=' [expression] to 'where' clause.
  Find gtEq<T>(String column, T val) => and(q.gtEq<T>(column, val));

  /// Adds an '<=' [expression] to 'where' clause.
  Find ltEq<T>(String column, T val) => and(q.ltEq<T>(column, val));

  /// Adds an '<' [expression] to 'where' clause.
  Find lt<T>(String column, T val) => and(q.lt<T>(column, val));

  /// Adds an '%' [expression] to 'where' clause.
  Find like(String column, String val) => and(q.like(column, val));

  /// Adds an 'between' [expression] to 'where' clause.
  Find between<T>(String column, T low, T high) =>
      and(q.between<T>(column, low, high));

  Find orderBy(String column, [bool ascending = false]) {
    _orderBy.add(new OrderBy(column, ascending));
    return this;
  }

  Find orderByMany(List<String> columns, [bool ascending = false]) {
    columns.forEach((String column) {
      _orderBy.add(new OrderBy(column, ascending));
    });
    return this;
  }

  Find limit(int val) {
    if (_limit != null) {
      throw new Exception('Already limited!');
    }
    _limit = val;
    return this;
  }

  Find offset(int val) {
    if (_offset != null) {
      throw new Exception('Cant use more than one offset!');
    }
    _offset = val;
    return this;
  }

  Find groupBy(String val) {
    _groupBy.add(val);
    return this;
  }

  Find groupByMany(List<String> columns) {
    _groupBy.addAll(columns);
    return this;
  }

  FindExecutor<ConnType> exec<ConnType>(Adapter<ConnType> adapter) =>
      new FindExecutor<ConnType>(adapter, this);

  ImmutableFindStatement _immutable;

  ImmutableFindStatement get asImmutable => _immutable;
}

class ImmutableFindStatement {
  Find _find;

  ImmutableFindStatement(this._find)
      : selects = new UnmodifiableListView<SelColumn>(_find._column),
        joins = new UnmodifiableListView<JoinedTable>(_find._joins),
        orderBy = new UnmodifiableListView<OrderBy>(_find._orderBy),
        groupBy = new UnmodifiableListView<String>(_find._groupBy);

  TableName get from => _find.from;

  final UnmodifiableListView<SelColumn> selects;

  final UnmodifiableListView<JoinedTable> joins;

  // TODO return immutable
  Expression get where => _find._where;

  final UnmodifiableListView<OrderBy> orderBy;

  final UnmodifiableListView<String> groupBy;

  int get limit => _find._limit;

  int get offset => _find._offset;
}

typedef MappedExpression<T> = Expression Function(T value);

class OrderBy {
  final String columnName;

  final bool ascending;

  const OrderBy(this.columnName, [this.ascending = false]);
}