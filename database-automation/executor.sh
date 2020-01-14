WORK_DIR=$1
RUN_DIR=$2
SQL_CONNECTION=$3
DB_NAME=$4
TIPO=$5
BUILD_ID=$6
RESET="RESET"
SEPARATOR="--SPLIT--"
BUILD_PATH=$WORK_DIR/$DB_NAME/$BUILD_ID
FINAL_FILE=$WORK_DIR/$DB_NAME/"install.run"

if [ "$TIPO" == "$RESET" ]; then
  rm $FINAL_FILE
fi

LAST_FILE=""

for sqlfile in "$RUN_DIR"/*
do
  if [ -f "$sqlfile" ];then
    echo -e "______________________________"

    blank=''
    sqlfilename="${sqlfile/$RUN_DIR'/'/$blank}"

    echo -e $sqlfilename' \t running...'

    sqlstring="$(cat $sqlfile | tr -d '[:space:]' | grep -v -e '^$' )"    
    if [ -z "$sqlstring" ]; then
      log_string='Empty lines... continue to next split'
      echo $log_string> $sqlfile.log
    else
export NLS_LANG='LATIN AMERICAN SPANISH_AMERICA.WE8ISO8859P1'
sqlplus64 -S  $SQL_CONNECTION   > $sqlfile.log  << EOF
@$sqlfile
exit;
EOF

    log_string="$(cat $sqlfile.log)"
    Error1=`grep -rnw $sqlfile.log -e 'ERROR'`
    Error2=`grep -rnw $sqlfile.log -e 'SP2'`
    Error3=`grep -rnw $sqlfile.log -e 'created with compilation errors'`
    Error4=`grep -rnw $sqlfile.log -e 'Advertencia:'`
    
    fi


    if [ -z "$Error1" ] && [ -z "$Error2" ] && [ -z "$Error3" ]  && [ -z "$Error4" ] && [ ! -z "$log_string" -a "$log_string" != " " ]; then
        echo -e "\t\t\t"$log_string

        sqlfilename=${sqlfilename:4:-3}

        iconv -f iso8859-1 -t utf-8 $sqlfile >> $BUILD_PATH.$sqlfilename
        echo $SEPARATOR>>$BUILD_PATH.$sqlfilename


        if [ "$LAST_FILE" != "$sqlfilename" ]; then
          LAST_FILE=$sqlfilename

          echo $BUILD_ID.$sqlfilename>>$FINAL_FILE
          echo '-->File:'$sqlfilename>>$BUILD_PATH.log

        fi
        sed '/^$/d' $sqlfile.log>>$BUILD_PATH.log
        temp="$(wc -l  $BUILD_PATH.$sqlfilename | awk '{ print $1 }')"
        echo '---->last line:'$temp>>$BUILD_PATH.log

        echo -e '\t\t last line:'$temp
        echo -e "\t\t\t(SUCCESS)"
    else
      echo $sqlfilename>>$BUILD_PATH.err
      if [ -z "$log_string" ]; then
        log_string="SCRIPT LOG IS EMPTY,REVIEW: Only comments between Split's, no  '/' for PLSQL befor split  OR 'serveroutput on' with no output"
        echo $log_string
        echo $log_string>>$BUILD_PATH.err
      else
        cat $sqlfile.log
        cat $sqlfile.log>>$BUILD_PATH.err
      fi

      echo ""
      echo ""
      echo -e "\t\t\t(FAILED)"
  	  echo ""
  	  echo ""

      exit 1
    fi
   fi
done
exit 0
