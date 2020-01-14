set +e
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $WORK_DIR

#CONSTANTS
PARAM_PATH="/database/param.txt"
SOURCE_CODE_PATH='/database/repo'
INSTALL_FILE="install.run"
GIT_PROD_REPOSITORY="database-deployment"
TIPO='ADD'

#PARAMETERS
BRANCH_NAME=$1
DB_NAME=$2
DB_FOLDER=$3
if [ -z "$4" ]; then
  BUILD_ID='P'.$(date '+%Y%m%d_%H%M%S')
else
  BUILD_ID='P'.$4
fi

#FILE PARAMETERS
GIT_REPO_PREFIX=$(sh param.sh $PARAM_PATH origin)
GIT_REPO_URL=$(sh param.sh $PARAM_PATH url)
DB_PASSWORD=$(sh param.sh $PARAM_PATH prod_db_password)
SQL_CONNECTION=$(sh param.sh $PARAM_PATH $DB_NAME)
SCHEMAS_EXCLUDED="$(cat schemas_excluded.txt)"

bash update_repo.sh $GIT_REPO_PREFIX $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master"
if [ $? -ne 0 ]; then
  bash failed_message.sh
  exit 1
fi

#------------------------------------------------
REPO_DIR=$SOURCE_CODE_PATH/$GIT_PROD_REPOSITORY/$BRANCH_NAME/$DB_FOLDER
RUN_FOLDER=$SOURCE_CODE_PATH/$GIT_PROD_REPOSITORY/$BRANCH_NAME

COMMIT_TEXT=$BRANCH_NAME/$DB_NAME/$BUILD_ID
bash splitter.sh $REPO_DIR $INSTALL_FILE $SQL_CONNECTION $SCHEMAS_EXCLUDED $DB_NAME $BUILD_ID $RUN_FOLDER $TIPO
if [ $? -ne 0 ]; then
  mv $REPO_DIR/$INSTALL_FILE $REPO_DIR/'install_'$(date '+%Y%m%d_%H%M%S').err
  STATUS="FAIL"
else
  cat $REPO_DIR/$INSTALL_FILE>>$REPO_DIR/"final_executed.log"
  rm $REPO_DIR/$INSTALL_FILE
  STATUS="SUCCESS"
fi
echo ">>>>"
echo "PUSH DEPLOYMENT"
COMMIT_TEXT=$COMMIT_TEXT/$STATUS
bash push_changes.sh $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master" $COMMIT_TEXT
bash urlDeployment.sh $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master" $GIT_REPO_URL
if [ $? -ne 0 ]; then
   echo "FALLO EN GUARDAR DEPLOYMENT , REVISAR LOS ARCHIVOS DE PROD"
  bash failed_message.sh
  exit 3
fi
EXECDATE="$(cat  $RUN_FOLDER/execdate.log)"
rm  $RUN_FOLDER/execdate.log
HOUR="."
#------------------------------------------------
bash ddl_versioner.sh $SQL_CONNECTION $SCHEMAS_EXCLUDED $DB_NAME $HOUR $GIT_REPO_PREFIX $SOURCE_CODE_PATH $COMMIT_TEXT $EXECDATE
if [ $? -ne 0 ]; then
  echo "FALLO EN EL VERSIONAMIENTO DE OBJETOS, REVISAR LOS ARCHIVOS de HISTORY"
  bash failed_message.sh
  exit 2
fi

if [[ $STATUS == "FAIL" ]]; then
  bash failed_message.sh
  exit 1
fi


bash success_message.sh
exit 0
