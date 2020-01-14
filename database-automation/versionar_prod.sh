WORK_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd $WORK_DIR

PARAM_PATH="/database/param.txt"
GIT_REPO_PREFIX=$(sh param.sh $PARAM_PATH origin)

DB_PASSWORD=$(sh param.sh $PARAM_PATH prod_db_password)
DB_USER=$(sh param.sh $PARAM_PATH prod_db_user)
DB_PORT=$(sh param.sh $PARAM_PATH prod_db_port)
DB_NAME=$(sh param.sh $PARAM_PATH prod_db_name)
DB_HOST=$(sh param.sh $PARAM_PATH prod_db_host)

SOURCE_CODE_PATH='/database/history/prod'
COMMIT_TEXT=$(date '+%Y_%m_%d')

if [ -z "$1" ]; then
  HORAS="25"
else
  HORAS=$1
fi
mkdir -p $SOURCE_CODE_PATH


SCHEMAS_EXCLUDED="$(cat schemas_excluded.txt)"

#PROD
SQL_CONNECTION=$DB_USER/$DB_PASSWORD@"(DESCRIPTION=(ADDRESS=(PROTOCOL=TCP)(HOST=$DB_HOST)(PORT=$DB_PORT))(CONNECT_DATA=(SID=$DB_NAME)))"
bash ddl_versioner.sh $SQL_CONNECTION $SCHEMAS_EXCLUDED $DB_NAME $HORAS $GIT_REPO_PREFIX $SOURCE_CODE_PATH $COMMIT_TEXT
echo $COMMIT_TEXT" "$DB_NAME>>/database/versionar.log
