WORK_DIR=$1
COMPILE_DIR=$1
SQL_CONNECTION=$2
SCHEMAS_EXCLUDED=$3
TYPE=$4
INVALID_FILE=$COMPILE_DIR/"invalid."$TYPE
SQL_FILE=$COMPILE_DIR/"invalid.sql"

mkdir $COMPILE_DIR  -p
SQL_SENTENCE="set pagesize 8000 \n"
SQL_SENTENCE=$SQL_SENTENCE"SET HEADING OFF \n"
SQL_SENTENCE=$SQL_SENTENCE"SET FEEDBACK OFF \n"
SQL_SENTENCE=$SQL_SENTENCE"select 'SHOW ERRORS '|| OBJECT_TYPE||' '||owner||'.'||OBJECT_name||';' from all_objects"
SQL_SENTENCE=$SQL_SENTENCE" where owner not in ($SCHEMAS_EXCLUDED)"
SQL_SENTENCE=$SQL_SENTENCE" and status='INVALID' order by 1 asc; \nexit"

echo -e $SQL_SENTENCE>$SQL_FILE

sqlplus64 -S $SQL_CONNECTION  @$SQL_FILE >>$INVALID_FILE
rm $SQL_FILE

LOG=$(cat $INVALID_FILE)
LASTLOG=$LOG
LOG="$(echo -e "${LOG}" | tr -d '[:space:]')"

if [ -z "$LOG" ]; then
  echo -e "NO INVALID OBJECTS at \t "$TYPE
else
  echo -e "INVALID OBJECTS at \t "$TYPE
  echo ""
  echo $LASTLOG
fi
