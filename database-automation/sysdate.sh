SQL_CONNECTION=$1
RUN_FOLDER=$2

SQL_SET="set pagesize 50000  HEADING OFF   FEEDBACK OFF   long 10000000  ECHO   OFF linesize 32767   "

sqlplus64 -S  $SQL_CONNECTION   > $RUN_FOLDER/execdate.temp  << EOF
$SQL_SET
select to_char(sysdate,'DD/MM/YYYY:HH24:MI:SS') from dual;
exit;
EOF
grep . $RUN_FOLDER/execdate.temp > $RUN_FOLDER/execdate.log 
rm  $RUN_FOLDER/execdate.temp