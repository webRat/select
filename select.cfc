component accessors="true" {
	property name="q" type="any";
	property name="sql" type="string";
	// settable props
	property name="select" type="any";
	property name="from" type="string";
	property name="innerJoin" type="array";
	property name="where" type="string";
	property name="orderBy" type="string";
	property name="limit" type="string";
	property name="params" type="struct";
	property name="cachedWithinMinutes" type="numeric";
	property name="Datasource" type="string";
	// Internals
	property name="hasPrepared" type="boolean" default=false;
	property name="hasSelect" type="boolean" default=false;
	property name="hasOrderBy" type="boolean" default=false;
	property name="hasCachedWithinMinutes" type="boolean" default=false;
	property name="hasParams" type="boolean" default=false;
	property name="hasLimit" type="boolean" default=false;
	property name="hasJoins" type="boolean" default=false;
	property name="hasDatasource" type="boolean" default=false;
	property name="hasQ" type="boolean" default=false;

	public select function init(){
		// If we have arguments, kick off select()
		if( arrayLen(arguments) ){
			if( structKeyExists(arguments,'datasource') && len(trim(arguments.datasource)) || structKeyExists(arguments,'dsn') && len(trim(arguments.dsn)) ) withDatasource(dsn=arguments[structKeyExists(arguments,'datasource') ? 'datasource':'dsn']);

			_select(argumentCollection=arguments);
		}
		
		return this;
	}
	private select function _select(required any columns){
		setSelect(arguments.columns);
		setHasSelect(true);
		return this;
	}
	public select function from(required any table){
		setFrom(arguments.table);
		return this;
	}
	public select function innerJoin(required any join){
		var joins = isArray(getInnerJoin()) && arrayLen( getInnerJoin() ) ? getInnerJoin() : [];
		arrayAppend(joins,arguments.join);
		setInnerJoin(joins);
		setHasJoins(true);
		return this;
	}
	public select function where(required string statement, struct params){
		setWhere(arguments.statement);
		if(structKeyExists(arguments,'params') && !structIsEmpty(arguments.params)) withParams(arguments.params);
		return this;
	}
	public select function orderBy(required string sorting){
		setOrderBy(arguments.sorting);
		setHasOrderBy(true);
		return this;
	}
	public select function limit(required numeric x){
		setLimit(arguments.x);
		setHasLimit(true);
		return this;
	}
	public select function withDatasource(required string dsn){
		setDatasource(arguments.dsn);
		setHasDatasource(true);
		return this;	
	}
	public select function withParams(required struct params){
		setParams(arguments.params);
		setHasParams(true);
		return this;
	}
	public select function cacheFor(required numeric minutes){
		setCachedWithinMinutes(arguments.minutes);
		setHasCachedWithinMinutes(true);
		return this;
	}
	public select function prepare(){

		var qArray = [];
		if( getHasSelect() ){
			var columns = getSelect();
			if( isArray(columns) ) columns = arrayToList(columns);
			arrayAppend(qArray,"SELECT #columns#");
		}
		if( len(trim( getFrom() )) ) arrayAppend(qArray,"FROM #getFrom()#");
		if( getHasJoins() ){
			var joins = getInnerJoin();
			for(var j in joins) arrayAppend(qArray,"INNER JOIN #j#");
		}
		if( len(trim( getWhere() )) ) arrayAppend(qArray,"WHERE #getWhere()#");
		if( getHasOrderBy() ) arrayAppend(qArray,"ORDER BY #getOrderBy()#");
		if( getHasLimit() ) arrayAppend(qArray,"LIMIT #getLimit()#");

		var queryArguments = {};
		queryArguments.sql = trim(arrayToList(qArray,' '));

		//if(structKeyExists(request,'foo')) writedump(var=queryArguments.sql,abort=1);

		setSQL(queryArguments.sql);
		queryArguments.name = '_' & hash(queryArguments.sql);
		if(getHasDatasource()) queryArguments.datasource = getDatasource();
		if(getHasCachedWithinMinutes()) queryArguments.cachedWithin = CreateTimeSpan(0, 0, getCachedWithinMinutes(), 0);

		var q = getQueryObject(argumentCollection=queryArguments);

		if( getHasParams() ){
			var params = getParams();
			for(var p in params){
				var assembled = {
					'name'=p
					,'value'=params[p].value
					,'cfsqltype'=mapDBTypeToCFType(params[p].type)
				}
				q.addParam(argumentCollection=assembled);
			}
		}

		setQ(q);
		setHasQ(true);
		setHasPrepared(true);

		return this;
	}
	public any function debug()
	{
		if(!getHasPrepared()) prepare();	
		return getSQL();
	}
	public any function execute()
	{
		if(!getHasPrepared()) prepare();
		return getHasQ() ? getQ().execute().getResult() : "ERROR -- Did you forget to setup the query?";
	}
	private function getQueryObject()
	{
		return new Query(argumentCollection=arguments);
	}
	private string function mapDBTypeToCFType(required string dbtype)
	{
		var toReturn = "";

		switch(lcase(arguments.dbtype))
		{
			case 'bigint':
				toReturn = 'CF_SQL_BIGINT';
			break;
			case 'bit':
				toReturn = 'CF_SQL_BIT';
			break;
			case 'char':
				toReturn = 'CF_SQL_CHAR';
			break;
			case 'blob':
				toReturn = 'CF_SQL_BLOB';
			break;
			case 'clob':
				toReturn = 'CF_SQL_CLOB';
			break;
			case 'date':
				toReturn = 'CF_SQL_DATE';
			break;
			case 'decimal':
				toReturn = 'CF_SQL_DECIMAL';
			break;
			case 'double':
				toReturn = 'CF_SQL_DOUBLE';
			break;
			case 'float':
				toReturn = 'CF_SQL_FLOAT';
			break;
			case 'idstamp':
				toReturn = 'CF_SQL_IDSTAMP';
			break;
			case 'int':
			case 'integer':
				toReturn = 'CF_SQL_INTEGER';
			break;
			case 'longvarchar':
				toReturn = 'CF_SQL_LONGVARCHAR';
			break;
			case 'money':
				toReturn = 'CF_SQL_MONEY';
			break;
			case 'money4':
				toReturn = 'CF_SQL_MONEY4';
			break;
			case 'number':
			case 'numeric':
				toReturn = 'CF_SQL_NUMERIC';
			break;
			case 'real':
				toReturn = 'CF_SQL_REAL';
			break;
			case 'refcursor':
				toReturn = 'CF_SQL_REFCURSOR';
			break;
			case 'smallint':
			case 'smallinteger':
				toReturn = 'CF_SQL_SMALLINT';
			break;
			case 'time':
				toReturn = 'CF_SQL_TIME';
			break;
			case 'datetime':
			case 'timestamp':
				toReturn = 'CF_SQL_TIMESTAMP';
			break;
			case 'tinyint':
				toReturn = 'CF_SQL_TINYINT';
			break;
			case 'varchar':
				toReturn = 'CF_SQL_VARCHAR';
			break;
			default:
				toReturn = 'CF_SQL_VARCHAR';
			break;
		}

		return toReturn;
	}
}