#PARAMETERS
PARAM_PATH="/database/param.txt"
GIT_REPO_PREFIX=$(sh param.sh $PARAM_PATH origin)
GIT_REPO_URL=$(sh param.sh $PARAM_PATH url)

SOURCE_CODE_PATH='/database/exec'
INSTALL_FILE="install.run"
#PARAMETERS
GIT_PROD_REPOSITORY="database-deployment"

TEMP_FOLDER=$1
BRANCH_NAME=$2
DB_FOLDER=$3
BUILD_ID=$4
NOTIFICATION_USERS=$5

COMMIT_TEXT=$BRANCH_NAME/$DB_FOLDER/$BUILD_ID

bash update_repo.sh $GIT_REPO_PREFIX $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master"
if [ $? -ne 0 ]; then
  bash failed_message.sh
  exit 1
fi
#------------------------------------------------
EXEC_PATH=$SOURCE_CODE_PATH/$GIT_PROD_REPOSITORY/$BRANCH_NAME/$DB_FOLDER
mkdir $EXEC_PATH -p
echo "$BUILD_ID.sql" > $EXEC_PATH/install.run
mv $TEMP_FOLDER/$BUILD_ID.sql $EXEC_PATH/$BUILD_ID.sql
#------------------------------------------------
echo "--------------------------------------------"
bash push_changes.sh $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master" $COMMIT_TEXT
bash urlDeployment.sh $SOURCE_CODE_PATH $GIT_PROD_REPOSITORY "master" $GIT_REPO_URL
 
echo "--------------------------------------------"
echo "RUTA para EJECUTAR SCRIPT EN PROD"
echo "https://jenkins.utec.edu.pe/job/database/job/database-prod/parambuild/?BRANCH_NAME=$BRANCH_NAME&DB_QA=$DB_FOLDER&NOTIFICATION_USERS=$NOTIFICATION_USERS"


 