
BRANCH_NAME="PR-2017-031-SNAPSHOT"
DB_NAME="coredev2"

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $WORK_DIR
#TIPO="RESET"
TIPO="ADD"
VERSIONAR="true" 
BUILD_ID='D'.$(date '+%Y%m%d_%H%M%S')
bash mainDev.sh $TIPO $BRANCH_NAME $DB_NAME $BUILD_ID $VERSIONAR
