
BRANCH_NAME="PR-2017-031-SNAPSHOT"
DB_NAME="coredev1"

DB_FOLDER="coredev2"

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $WORK_DIR

bash mainProd.sh  $BRANCH_NAME  $DB_NAME $DB_FOLDER
