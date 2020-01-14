set +e
WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $WORK_DIR

#CONSTANTS
SOURCE_CODE_PATH='/database/repoDev'
PARAM_PATH="/database/param.txt"

INSTALL_FILE="install.run"
GIT_DEV_REPOSITORY="database-scripts"
GIT_PROD_REPOSITORY="database-deployment"

#PARAMETERS
TIPO=$1
BRANCH_NAME=$2
DB_NAME=$3
if [ -z "$4" ]; then
  BUILD_ID='D'.$(date '+%Y%m%d_%H%M%S')
else
  BUILD_ID='D'.$4
fi
VERSIONAR=$5

#FILE PARAMETERS
GIT_REPO_PREFIX=$(sh param.sh $PARAM_PATH origin)
GIT_REPO_URL=$(sh param.sh $PARAM_PATH url)
SQL_CONNECTION=$(sh param.sh $PARAM_PATH db_$DB_NAME)
SCHEMAS_EXCLUDED="$(cat schemas_excluded.txt)"

bash update_repo.sh $GIT_REPO_PREFIX $SOURCE_CODE_PATH $GIT_DEV_REPOSITORY $BRANCH_NAME
if [ $? -ne 0 ]; then
  bash failed_message.sh
  exit 1
fi

bash update_repo.sh $GIT_REPO_PREFIX $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master"
if [ $? -ne 0 ]; then
  bash failed_message.sh
  exit 1
fi

#------------------------------------------------
REPO_DIR=$SOURCE_CODE_PATH/$GIT_DEV_REPOSITORY
RUN_FOLDER=$SOURCE_CODE_PATH/$GIT_PROD_REPOSITORY/$BRANCH_NAME

bash verificadorCommit.sh $REPO_DIR $RUN_FOLDER $BRANCH_NAME $GIT_REPO_URL $GIT_DEV_REPOSITORY
if [ $? -ne 0 ]; then
  bash failed_message.sh
  exit 1
fi

COMMIT_TEXT=$BRANCH_NAME/$DB_NAME/$BUILD_ID
bash splitter.sh $REPO_DIR $INSTALL_FILE $SQL_CONNECTION $SCHEMAS_EXCLUDED $DB_NAME $BUILD_ID $RUN_FOLDER $TIPO
if [ $? -ne 0 ]; then
  STATUS="FAIL"
else
  STATUS="SUCCESS"
fi
echo ">>>>"
echo "PUSH DEPLOYMENT"
COMMIT_TEXT=$COMMIT_TEXT/$STATUS
bash push_changes.sh $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master" $COMMIT_TEXT
bash urlDeployment.sh $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master" $GIT_REPO_URL
if [ $? -ne 0 ]; then
   echo "FALLO EN GUARDAR DEPLOYMENT , REVISAR LOS ARCHIVOS PARA PROD"
   bash failed_message.sh
   exit 3
fi
#------------------------------------------------ AQUI SE VERSIONA EL AMBIENTE DE PRUEBAS
EXECDATE="$(cat  $RUN_FOLDER/execdate.log)"
rm  $RUN_FOLDER/execdate.log
HOUR="."

if [[ $VERSIONAR == "true" ]]; then
  bash ddl_versioner.sh $SQL_CONNECTION $SCHEMAS_EXCLUDED $DB_NAME $HOUR $GIT_REPO_PREFIX $SOURCE_CODE_PATH $COMMIT_TEXT $EXECDATE
  if [ $? -ne 0 ]; then
   echo "FALLO EN EL VERSIONAMIENTO DE OBJETOS, REVISAR LOS ARCHIVOS de HISTORY"
   bash failed_message.sh
   exit 2
  fi
else
  echo ">>>>"
  echo "NO VERSIONING"
fi

if [[ $STATUS == "FAIL" ]]; then
  bash failed_message.sh
  exit 1
fi


bash success_message.sh
exit 0
