component accessors="true" {
	property name="q" type="any";
	property name="sql" type="string";
	// settable props
	property name="select" type="any";
	property name="from" type="string";
	property name="innerJoin" type="array";
	property name="where" type="string" default="";
	property name="orderBy" type="string";
	property name="rowcount" type="numeric";
	property name="offset" type="numeric";
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
	property name="hasRowcount" type="boolean" default=false;
	property name="hasOffset" type="boolean" default=false;
	property name="hasJoins" type="boolean" default=false;
	property name="hasDatasource" type="boolean" default=false;
	property name="hasQ" type="boolean" default=false;

	public select function init(){
		variables.params = {};
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
	public select function innerJoin(required any join, struct params){
		var joins = isArray(getInnerJoin()) && arrayLen( getInnerJoin() ) ? getInnerJoin() : [];
		arrayAppend(joins,arguments.join);
		setInnerJoin(joins);
		setHasJoins(true);

		if(structKeyExists(arguments,'params') && !structIsEmpty(arguments.params)) withParams(arguments.params);

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
	public select function limit(required numeric rowcount=0, required numeric offset=0){
		if(isNumeric(arguments.rowcount) AND arguments.rowcount > 0){
			setRowcount(arguments.rowcount);
			setHasRowcount(true);
			setHasLimit(true);
		}
		if(isNumeric(arguments.offset) AND arguments.offset > 0){
			setOffset(arguments.offset);
			setHasOffset(true);
			setHasLimit(true);
		}
		return this;
	}
	public select function offset(required numeric offset=0){
		if(isNumeric(arguments.offset) AND arguments.offset > 0){
			setOffset(arguments.offset);
			setHasOffset(true);
			// Just using offset alone should not trigger a limit.
			//setHasLimit(true);
		}
		return this;
	}
	public select function withDatasource(required string dsn){
		setDatasource(arguments.dsn);
		setHasDatasource(true);
		return this;	
	}
	public select function withParams(required struct params){
		if(structKeyExists(arguments,'params') && !structIsEmpty(arguments.params)){
			var pStruct = getParams();
			if(structIsEmpty(pStruct)) pStruct = {};
			structAppend(pStruct, arguments.params,'yes');
			setParams(pStruct);
			setHasParams(true);
		}
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
		if( getHasLimit() ){
			var _limit = "LIMIT ";
			if( getHasRowcount() & getRowcount() > 0 ) _limit = _limit & getRowcount();
			if( getHasOffset() & getOffset() > 0 ) _limit = _limit & " OFFSET #getOffset()#";
			arrayAppend(qArray,_limit);
		}

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
		switch(lcase(arguments.dbtype))
		{
			case 'bigint':
			case 'CF_SQL_BIGINT':			
				return 'CF_SQL_BIGINT';
			break;
			case 'bit':
			case 'CF_SQL_BIT':
				return 'CF_SQL_BIT';
			break;
			case 'char':
			case 'CF_SQL_CHAR':
				return 'CF_SQL_CHAR';
			break;
			case 'blob':
			case 'CF_SQL_BLOB':
				return 'CF_SQL_BLOB';
			break;
			case 'clob':
			case 'CF_SQL_CLOB':
				return 'CF_SQL_CLOB';
			break;
			case 'date':
			case 'CF_SQL_DATE':
				return 'CF_SQL_DATE';
			break;
			case 'decimal':
			case 'CF_SQL_DECIMAL':
				return 'CF_SQL_DECIMAL';
			break;
			case 'double':
			case 'CF_SQL_DOUBLE':
				return 'CF_SQL_DOUBLE';
			break;
			case 'float':
			case 'CF_SQL_FLOAT':
				return 'CF_SQL_FLOAT';
			break;
			case 'idstamp':
			case 'CF_SQL_IDSTAMP':
				return 'CF_SQL_IDSTAMP';
			break;
			case 'int':
			case 'integer':
			case 'CF_SQL_INTEGER':
				return 'CF_SQL_INTEGER';
			break;
			case 'longvarchar':
			case 'CF_SQL_LONGVARCHAR':
				return 'CF_SQL_LONGVARCHAR';
			break;

			case 'money':
			case 'CF_SQL_MONEY':
				return 'CF_SQL_MONEY';
			break;
			case 'money4':
			case 'CF_SQL_MONEY4':
				return 'CF_SQL_MONEY4';
			break;
			case 'number':
			case 'numeric':
			case 'CF_SQL_NUMERIC':
				return 'CF_SQL_NUMERIC';
			break;
			case 'real':
			case 'CF_SQL_REAL':			
				return 'CF_SQL_REAL';
			break;
			case 'refcursor':
			case 'CF_SQL_REFCURSOR':
				return 'CF_SQL_REFCURSOR';
			break;
			case 'smallint':
			case 'smallinteger':
			case 'CF_SQL_SMALLINT':
				return 'CF_SQL_SMALLINT';
			break;
			case 'time':
			case 'CF_SQL_TIME':
				return 'CF_SQL_TIME';
			break;
			case 'datetime':
			case 'timestamp':
			case 'CF_SQL_TIMESTAMP':			
				return 'CF_SQL_TIMESTAMP';
			break;
			case 'tinyint':
			case 'CF_SQL_TINYINT':
				return 'CF_SQL_TINYINT';
			break;
			case 'varchar':
			case 'CF_SQL_VARCHAR':
				return 'CF_SQL_VARCHAR';
			break;
			default:
				return 'CF_SQL_VARCHAR';
			break;
		}
	}
}