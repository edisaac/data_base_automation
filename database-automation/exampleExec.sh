
BRANCH_NAME="FIX-MDA-BBBB"
DB_FOLDER="exec"
BUILD_ID='E'.$(date '+%Y%m%d_%H%M%S')

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $WORK_DIR

SCRIPT="PRUEBA\nAAAA"
NOTIFICATION_USERS="emejia@utec.edu.pe"

bash mainExec.sh $BRANCH_NAME $DB_FOLDER $BUILD_ID $NOTIFICATION_USERS $SCRIPT
