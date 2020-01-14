SQL_CONNECTION=$1
SCHEMAS_EXCLUDED=$2
BRANCH_NAME=$3
HOURS=$4
GIT_REPO_PREFIX=$5
SOURCE_CODE_PATH=$6
COMMIT_TEXT=$7"..."$HOURS
EXECDATE=$8

GIT_REPOSITORY_NAME="database-history"
empty=""
REPO_PATH=$SOURCE_CODE_PATH/$GIT_REPOSITORY_NAME
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

bash update_repo.sh $GIT_REPO_PREFIX $SOURCE_CODE_PATH $GIT_REPOSITORY_NAME $BRANCH_NAME
if [ $? -ne 0 ]; then
  exit 1
fi

echo ">>>>"
echo "VERSIONANDO "$BRANCH_NAME


sqlplus64 -S  $SQL_CONNECTION  << EOF
exit;
EOF

if [ $? -ne 0 ]; then
  exit 1
fi

SQL_SET="set pagesize 50000  HEADING OFF   FEEDBACK OFF   long 10000000  ECHO   OFF linesize 32767   "

if [ "$HOURS" = "0" ]; then
  echo "BORRANDO "$REPO_PATH/
  find $REPO_PATH/ -type f -name '*.sql' -delete
fi

if [ "$HOURS" = "25" ]; then
    echo ">>>Searching objects to delete..."
    SQL_OBJECT="select '$REPO_PATH/'||owner||'/'||"
    SQL_OBJECT=$SQL_OBJECT"case when object_type like  'PACKAGE%' then 'PACKAGE' else  object_type end ||'/'||"
    SQL_OBJECT=$SQL_OBJECT"case when object_type = 'PACKAGE BODY' then object_name||'_BODY' else   object_name end ||'.sql'"
    SQL_OBJECT=$SQL_OBJECT" from all_objects where owner not in ($SCHEMAS_EXCLUDED)"
    SQL_OBJECT=$SQL_OBJECT"and object_type !='TYPE' "
    SQL_OBJECT=$SQL_OBJECT"order by owner,object_type,object_name;"
    sqlplus64 -S  $SQL_CONNECTION   >$REPO_PATH/bd.del  << EOF
$SQL_SET
$SQL_OBJECT
exit;    
EOF
    
    find $REPO_PATH -name \*.sql -print | sort -d > $REPO_PATH/arc.del
    sort -d $REPO_PATH/bd.del > $REPO_PATH/bd2.del
    
    diff $REPO_PATH/bd2.del $REPO_PATH/arc.del | grep ">" | sed -e "s/^>//" > $REPO_PATH/fin.del
    for word in `sed '/^$/d' $REPO_PATH/fin.del`; do      
      delete_file="${word/$REPO_PATH/$empty}"
      echo "Delete " $delete_file
      rm $word
    done
    find $REPO_PATH/ -type f -name '*.del' -delete    
fi

if [ -z "$EXECDATE" ]; then
  last_ddl_time=" and ($HOURS=0 or last_ddl_time >=sysdate-($HOURS/24))"
else
  last_ddl_time=" and last_ddl_time >=TO_DATE('$EXECDATE','DD/MM/YYYY:HH24:MI:SS')"
fi

 echo ">>>Searching objects to modify..."$EXECDATE
#PACKAGE_SPEC', some_package instead) (there is similar with PACKAGE_BODY
SQL_SENTENCE="select  case when object_type = 'PACKAGE' then 'PACKAGE_SPEC' when object_type = 'PACKAGE BODY' then 'PACKAGE_BODY' else object_type end   ||','|| "
SQL_SENTENCE=$SQL_SENTENCE"object_name||','|| owner ||','||"
SQL_SENTENCE=$SQL_SENTENCE"case when object_type like  'PACKAGE%' then 'PACKAGE' else  object_type end ||','||"
SQL_SENTENCE=$SQL_SENTENCE"case when object_type = 'PACKAGE BODY' then object_name||'_BODY' else   object_name end ||'|' "
SQL_SENTENCE=$SQL_SENTENCE" from all_objects where owner not in ($SCHEMAS_EXCLUDED)"
SQL_SENTENCE=$SQL_SENTENCE" and object_type !='TYPE' "
SQL_SENTENCE=$SQL_SENTENCE$last_ddl_time
SQL_SENTENCE=$SQL_SENTENCE" order by owner,object_type,object_name;"

OBJETOS_MODIFICADOS=`sqlplus64 -S  $SQL_CONNECTION  << EOF
$SQL_SET
$SQL_SENTENCE
exit;
EOF`

if [ -z "$OBJETOS_MODIFICADOS" ]; then
  echo "No objects modify returned from database"  
else

    IFS='|' read -ra ARR_OBJETOS <<<  $OBJETOS_MODIFICADOS

    for OBJETO in "${ARR_OBJETOS[@]}"; do
      IFS=',' read -ra ELEMENTOS <<<  $OBJETO
       object_type=${ELEMENTOS[0]}
       object_name=${ELEMENTOS[1]}
       owner=${ELEMENTOS[2]}
       type_path=${ELEMENTOS[3]}
       object_file=${ELEMENTOS[4]}

       PATH_DDL=$REPO_PATH/$owner/$type_path

       mkdir $PATH_DDL -p
       SQL_SENTENCE="select DBMS_METADATA.GET_DDL('$object_type','$object_name','$owner') as ddl from DUAL;"
       echo "Modify /"$owner/$type_path/$object_file.sql
export NLS_LANG='LATIN AMERICAN SPANISH_AMERICA.WE8ISO8859P1'
sqlplus64 -S  $SQL_CONNECTION > $PATH_DDL/$object_file.temp  << EOF
$SQL_SET
column ddl format A50000
$SQL_SENTENCE
exit;
EOF
    sed "1,2d" $PATH_DDL/$object_file.temp > $PATH_DDL/$object_file.temp2

    iconv -f iso8859-1 -t utf-8  $PATH_DDL/$object_file.temp2 > $PATH_DDL/$object_file.sql
    
    rm $PATH_DDL/$object_file.temp*
    done

fi

echo "==="
echo "PUSH DDL CHANGES"
echo "==="

bash push_changes.sh $SOURCE_CODE_PATH $GIT_REPOSITORY_NAME $BRANCH_NAME $COMMIT_TEXT
if [ $? -ne 0 ]; then
  exit 1
fi

exit  0