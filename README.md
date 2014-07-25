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
	variables.result = new select('*').from('token').execute();
	writedump(var=variables.result,abort=1);

With Datasource Usage Example:
================================
	variables.datasource = "whatever";
	variables.result = new select('*').from('token').withDatasource(variables.datasource).execute();
	writedump(var=variables.result,abort=1);

Additional usage:
=================
	variables.params = { 'id' = { value=5, type="int" }};
	variables.result = new select('id').from('tablename').where('id = :id',variables.param).execute();
	writedump(var=variables.result,abort=1);

More complex usage with filtering system:
=========================================
	variables.filter = "username";
	variables.value = "webRat";
	variables.columns = ['array','of','columns'];
	variables.dbtable = "tablename";

	var _query = new select(variables.columns).from(variables.dbtable);
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