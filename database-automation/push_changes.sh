SOURCE_CODE_PATH=$1
GIT_REPOSITORY_NAME=$2
BRANCH_NAME=$3
COMMIT_TEXT=$4

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $SOURCE_CODE_PATH/$GIT_REPOSITORY_NAME
(
  git add -A 
  git commit -m $COMMIT_TEXT -q
  git push origin $BRANCH_NAME  -q

  if [ $? -ne 0 ]; then
    cd $WORK_DIR
    exit 1
  fi
  cd $WORK_DIR
)
