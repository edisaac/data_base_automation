PARAM_PATH=$1
PARAM_NAME=$2
PARAM_VALUE=$(awk -F "=>" '/'$PARAM_NAME'/ {print $2}' $PARAM_PATH)
PARAM_VALUE="$(echo "${PARAM_VALUE}" | tr -d '[:space:]')"
echo "$PARAM_VALUE"