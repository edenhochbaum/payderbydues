#!/usr/bin/env node

/*
 * call like:
 * 	> node validate_schema.js /home/ec2-user/payderbydues/schema/rds_schema_schema.json /home/ec2-user/payderbydues/schema/rds_schema.json
 *
 * */

var argv = require('minimist')(process.argv);

var schemajsonfilename = argv['_'][2];
var objectjsonfilename = argv['_'][3];

var fs = require('fs');

fs.readFile(schemajsonfilename, 'utf8', function (schemajsonerr, schemajsondata) {
	if (schemajsonerr) {
		return console.log(schemajsonerr);
	}

	fs.readFile(objectjsonfilename, 'utf8', function (objectjsonerr, objectjsondata) {
		if (objectjsonerr) {
			return console.log(objectjsonerr);
		}

		var Validator = require('jsonschema').Validator;
		var v = new Validator();

		console.log(v.validate(JSON.parse(objectjsondata), JSON.parse(schemajsondata)));
	});
});
