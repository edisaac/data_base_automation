REPO_DIR=$1
RUN_FOLDER=$2
BRANCH_NAME=$3
GIT_REPO_URL=$4
GIT_DEV_REPOSITORY=$5

mkdir -p $RUN_FOLDER
COMMIT_FILE=$RUN_FOLDER/"commit.log"

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $REPO_DIR
(
  COMMIT_ID=`git rev-parse $BRANCH_NAME`
  Error1=`grep -rnw $COMMIT_FILE -e $COMMIT_ID`

  echo ">>>>"
  echo "ORIGIN"
  echo $GIT_REPO_URL"/"$GIT_DEV_REPOSITORY"/src/"$COMMIT_ID"/install.run?at="$BRANCH_NAME
  echo ">>>>"
  if [ -z "$Error1" ]; then
    echo "COMMIT_ID (OK)"
    echo $COMMIT_ID>>$COMMIT_FILE
    cd $WORK_DIR
    exit 0
  else
    echo "COMMIT_ID $COMMIT_ID FOUND IN commit.log"
    echo "change your files and make another commit"
    cd $WORK_DIR
    exit 1
  fi

)
