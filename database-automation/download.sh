#!/bin/bash

folder_to_download=$1;
git_clone_cmd_string=$2;

# echo "cleaning.. " $folder_to_download

# rm -rf $folder_to_download
# mkdir $folder_to_download

cd $folder_to_download

export IFS=";"
for git_clone_cmd in $git_clone_cmd_string; do
    echo "downloading..." $git_clone_cmd
	
	eval "($git_clone_cmd)"
	STATUS=$?

	if [ $STATUS -eq 0 ]; then
		echo "success download \n\n"
	else
		echo "failed download \n\n"
		return 1
	fi	
done
