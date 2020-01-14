COMPILE_DIR=$1
INVALID_BEGIN=$COMPILE_DIR/"invalid."$2
INVALID_END=$COMPILE_DIR/"invalid."$3
INVALID_DIFF=$COMPILE_DIR/"invalid.diff"
diff $INVALID_BEGIN $INVALID_END | grep ">" | sed -e "s/^>//" > $INVALID_DIFF

Error1=`grep -rnw $INVALID_DIFF -e 'ERRORS'`

if [ -z "$Error1" ]; then
    echo -e "COMPILE ERRORS\t NONE"
    exit 0
else
  echo $INVALID_DIFF
  echo $Error1
  exit 1
fi
