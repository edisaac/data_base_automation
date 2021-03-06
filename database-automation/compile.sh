COMPILE_DIR=$1
SQL_CONNECTION=$2
SCHEMAS_EXCLUDED=$3
SQL_FILE=$COMPILE_DIR/"compile.sql"
SQL_SENTENCE="BEGIN \n"
SQL_SENTENCE=$SQL_SENTENCE"FOR rec IN (select owner from all_objects where owner not in ($SCHEMAS_EXCLUDED)"
SQL_SENTENCE=$SQL_SENTENCE" and status='INVALID' group by owner)\n"
SQL_SENTENCE=$SQL_SENTENCE" loop\n"
SQL_SENTENCE=$SQL_SENTENCE" DBMS_UTILITY.COMPILE_SCHEMA(rec.owner,FALSE); \n"
SQL_SENTENCE=$SQL_SENTENCE" END LOOP;\n"
SQL_SENTENCE=$SQL_SENTENCE"end;\n/\nexit"
echo -e $SQL_SENTENCE>$SQL_FILE

echo -e "COMPILING DATABASE SCHEMAS"
sqlplus64 -S $SQL_CONNECTION  @$SQL_FILE
rm $SQL_FILE
