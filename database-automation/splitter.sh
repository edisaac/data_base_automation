REPO_DIR=$1
INSTALL_FILE=$2
SQL_CONNECTION=$3
SCHEMAS_EXCLUDED=$4
BUILD_ID=$6
DB_NAME=$5
RUN_FOLDER=$7
TIPO=$8

RUN_PATH=$DB_NAME"/"$BUILD_ID
COMPILE_DIR=$RUN_FOLDER/$RUN_PATH/"compile"
RUN_DIR=$RUN_FOLDER/$RUN_PATH/"run"
mkdir $RUN_DIR  -p
mkdir $COMPILE_DIR  -p

COUNTER=0
PAD=3
SEPARATOR="\-\-SPLIT\-\-"
SEPARATORW="--SPLIT--"

echo ""
echo "############################"
echo "### BEGIN SQL EXECUTING  ###"
echo "############################"
echo ""
if [ ! -f $REPO_DIR/$INSTALL_FILE ]; then
    echo "$REPO_DIR/$INSTALL_FILE not found!(FAILED)"
    exit 1
fi
echo "$REPO_DIR/$INSTALL_FILE found!"

echo ""
echo "( 1 ) SPLIT <<<<<<<<<<<<<<<<<<<<<<<<<<<<<"
echo ""
for word in `sed '/^$/d' $REPO_DIR/$INSTALL_FILE`; do
  SPLIT_PREFIX=$(printf "%0*d\n" $PAD $COUNTER).$word

  if [ -f $REPO_DIR/$word ]; then
    lastline="$(tail -n 1 $REPO_DIR/$word | tr -d '[:space:]' | grep -v -e '^$' )"
    if [[ $lastline != $SEPARATORW ]]; then
      echo -e "\n"$SEPARATORW>>$REPO_DIR/$word  
    fi   
    csplit --prefix=$RUN_DIR/$SPLIT_PREFIX $REPO_DIR/$word "/$SEPARATOR/+1" "{*}" --elide-empty-files --silent --digits=$PAD  
    echo -e $SPLIT_PREFIX "\t\t  done"
    COUNTER=$[$COUNTER +1]
  else
    echo -e $SPLIT_PREFIX "\t\t  (FAILED)" 
    echo -e "\n\t($word) IN  install.run REVIEW IF EXIST \n\n"
    exit 1
  fi 
done

#AGREGAR EXIT A ARCHIVOS GENERADOS
for sqlfile in "$RUN_DIR"/*
do
  if [ -f "$sqlfile" ];then
   sed -i".bak" '$d' $sqlfile
   rm $sqlfile.bak
   #echo -e "\n exit;" >> $sqlfile
   #echo $sqlfile >> $RUN_DIR/$INSTALL_FILE
    if $( file -i "${sqlfile}"|grep -q us-ascii ); then
      iconv -f us-ascii -t iso8859-1 "$sqlfile" > "${sqlfile}.enc"
      rm $sqlfile
      mv $sqlfile.enc  $sqlfile
    fi
    if $( file -i "${sqlfile}"|grep -q utf-8 ); then
      iconv -f utf-8 -t iso8859-1 "$sqlfile" > "${sqlfile}.enc"
      rm $sqlfile
      mv $sqlfile.enc  $sqlfile
    fi
  fi
done

echo ""
echo "( 2 ) INITIAL COMPILING <<<<<<<<<<<<<<<<<"
echo ""
bash compile.sh $COMPILE_DIR $SQL_CONNECTION $SCHEMAS_EXCLUDED
bash search_invalid.sh $COMPILE_DIR $SQL_CONNECTION $SCHEMAS_EXCLUDED "begin"

echo ""
echo "( 3 ) RUNNING SCRIPTS <<<<<<<<<<<<<<<<<<<"
echo ""
bash sysdate.sh $SQL_CONNECTION $RUN_FOLDER
echo "<BEGIN>"
bash executor.sh $RUN_FOLDER $RUN_DIR $SQL_CONNECTION $DB_NAME $TIPO $BUILD_ID
if [ $? -ne 0 ]; then
  echo "<END>"
  rm $RUN_DIR -R
  exit 1
else
  echo "<END>"
  rm $RUN_DIR -R
fi

echo ""
echo "( 4 ) FINAL COMPILING <<<<<<<<<<<<<<<<<<<"
echo ""
bash compile.sh $COMPILE_DIR $SQL_CONNECTION $SCHEMAS_EXCLUDED
bash search_invalid.sh $COMPILE_DIR $SQL_CONNECTION $SCHEMAS_EXCLUDED "end"

echo ""
echo "( 5 ) NEW INVALID OBJECTS <<<<<<<<<<<<<<<"
echo ""
bash show_compile_errors.sh $COMPILE_DIR  "begin" "end"
if [ $? -ne 0 ]; then
  rm $COMPILE_DIR -R
  exit 1
else
  rm $COMPILE_DIR -R
fi
echo ""
echo "############################"
echo "#### END SQL EXECUTING  ####"
echo "############################"
echo ""
