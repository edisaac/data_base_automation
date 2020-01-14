#!/bin/bash
#source /root/.bash_profile

GIT_REPO_PREFIX=$1
SOURCE_CODE_PATH=$2
GIT_REPOSITORY_NAME=$3
BRANCH_NAME=$4

WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

	  echo ">>>>"
		echo "DOWNLOAD APP SOURCE CODE        "$GIT_REPOSITORY_NAME

		mkdir $SOURCE_CODE_PATH/$GIT_REPOSITORY_NAME -p
		cd $SOURCE_CODE_PATH/$GIT_REPOSITORY_NAME
		cd .git
		if [ $? -eq 0 ]; then
			echo "Repo was found, just update it!!"
			cd $SOURCE_CODE_PATH/$GIT_REPOSITORY_NAME
			(
				git reset --hard -q
				git clean -d -x -f -q
				git fetch -q
				git checkout master -q
				git checkout $BRANCH_NAME -q
				git pull origin $BRANCH_NAME -q
			)

			if [ $? -ne 0 ]; then
				exit 1
			fi

		else
			echo "Repo was not found, clone it!!"
			cd $WORK_DIR
			sh ./download.sh $SOURCE_CODE_PATH/ "git clone $GIT_REPO_PREFIX/$GIT_REPOSITORY_NAME.git -b $BRANCH_NAME -q"

			if [ $? -ne 0 ]; then
				exit 1
			fi

		fi
