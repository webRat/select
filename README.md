select
======
Basic query helper for ColdFusion

Supported thus far:
* Basic SELECT
* Basic INNER JOIN

Needs to be done still:
* Unit Tests
* Dummy Proofing

Use at your own risk. Apache 2 license.

Basic Usage:
============
	{{ assuming you have this.datasource in your Application.cfc }}
	variables.select = new select();
	variables.result = select('id').from('tablename').orderBy('id').execute();
	writedump(var=variables.result,abort=1);

With Datasource Usage Example 1:
================================
	variables.datasource = "whatever";
	variables.select = new select().withDatasource(variables.datasource);
	variables.result = select('id').from('tablename').orderBy('id').execute();
	writedump(var=variables.result,abort=1);

With Datasource Usage Example 2:
================================
	variables.datasource = "whatever";
	variables.select = new select();
	variables.result = select('id').from('tablename').orderBy('id').withDatasource(variables.datasource).execute();
	writedump(var=variables.result,abort=1);

Additional usage:
=================
	variables.select = new select();
	var params = { 'id' = { value=5, type="int" }};
	variables.result = select('id').from('tablename').where('id = :id',params).execute();
	writedump(var=variables.result,abort=1);

More complex usage:
===================
	variables.filter = "username";
	variables.value = "webRat";
	variables.columns = ['array','of','columns'];
	variables.dbtable = "tablename";

	var _query = select(variables.columns).from(variables.dbtable);
	var params = {};

	switch(variables.filter){
		case "accountGUID":
			params = { 'create_guid' = { value = variables.value, type = "char" } };
			_query.where('create_guid = :create_guid AND active = 1 AND deleted = 0',params);
		break;
		case 'usernameOrEmail':
			params = { 'username' = { value = variables.value, type = "varchar" } };
			_query.where('(username = :username OR email = :username) AND active = 1 AND deleted = 0',params);
		break;
		case "username":
			params = { 'username' = { value = variables.value, type = "varchar" } };
			_query.where('username = :username AND active = 1 AND deleted = 0',params);
		break;
		default:
			params = { 'account_id' = { value = variables.id, type = "int" } };
			_query.where('account_id = :account_id and deleted = 0',params);
		break;
	}
	writedump(var= _query.execute(), abort=1);

Debugging:
===========
writedump(var=_query.debug(),abort=1);