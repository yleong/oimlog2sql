BEGIN{
	YEAR="2016"
	FS="\\] \\["
	RS=("\n^\\[" YEAR) #no lookahead in awk :-(
	print "set define off;"
}

#SQL string literal has a limit of 4000 chars
#So we split a long string into concats of clobs
#i.e. to_clob(' ... ') || to_clob(' ...') || ...
function longStr2ClobConcat(longstr){
	THRESHOLD=3800
	output = "to_clob('" longstr "')";
	if(length(longstr) > THRESHOLD){
		#str is too long, have to split into a few clob concats
		output="to_clob('" substr(longstr, 0, THRESHOLD) "')"
		for(k = THRESHOLD+1; k <= length(longstr); k+=THRESHOLD){
			currpart = substr(longstr, k, THRESHOLD)
			output = output " || to_clob('" currpart "')"
		}
	}
	return output
}

{
	date = gensub("T", " ", 1, $1)
	date = gensub("+", " +", 1, date)
	if (NR == 1) {
		#since first record doesn't have RS 
		date = gensub("^\\[", "", 1, date)
	}  else {
		#have to replace the chopped off 2016
		date = (YEAR date)
	}

	#escape literal single quotes
	server = gensub("'", "''", "g", $2)
	level = gensub("'", "''", "g", $3)
	errcode = gensub("'", "''", "g", $4)
	scope = gensub("'", "''", "g", $5)

	#remove column names and escape literal '
	tid = gensub("^tid: ", "", 1, $6)
	tid = gensub("'", "''", "g", tid)
	uid = gensub("^userId: ", "", "g", $7)
	uid = gensub("'", "''", "g", uid)
	ecid = gensub("^ecid: ", "", "g", $8)
	ecid = gensub("'", "''", "g", ecid)

	if (length(ecid) > 100){
		#some ecids can be incorrectly split as

		#'e66498a210ff2c9a:-2180a804:153611bfc40:-8000-00000000000180db,0]
		#incident flood controlled with Problem Key "DFW-99998
		#[java.lang.NullPointerException
		#][oracle.security.jps.ee.http.JpsAbsFilter$1.run][idmspe]"' 

		#we want to split into 2 strings, the part before the first ] and the
		#part after the first ]
		myind = index(ecid, "]")
		if(myind != 0){
			first = substr(ecid, 1, myind-1)
			second = substr(ecid, myind+1)
			ecid = first
			$9 = (second $9)
		}
	}

	#Construct the logmsg from the remaining columns
	$9 = gensub("'", "''", "g", $9)
	$9 = longStr2ClobConcat($9)
	logmsg = $9;
	for(j=10; j<=NF; j++){
		$j = gensub("'", "''", "g", $j)
		$j = longStr2ClobConcat($j)
		logmsg = logmsg" || " $j;
	}
	#logmsgs can sometimes be multi-line, have to escape \n to chr(10)
	logmsg = gensub("\n", "')|| to_clob(chr(10)) || to_clob('", "g", logmsg)

	#optional: perform some analysis on logmsg to determine the user and the target if any
	#finally print the generated SQL
	print "insert into LOGLINE (LOGLINE_DATE, LOGLINE_SERVER, LOGLINE_LEVEL, LOGLINE_ERRCODE, LOGLINE_SCOPE, LOGLINE_TID, LOGLINE_UID, LOGLINE_ECID, LOGLINE_MESSAGES) values (to_timestamp_tz('"date"', 'yyyy-mm-dd hh24:mi:ss.ff3 tzh:tzm'), '"server"', '"level"', '"errcode"', '"scope"', '"tid"', '"uid"', '"ecid"', "logmsg");"
}
