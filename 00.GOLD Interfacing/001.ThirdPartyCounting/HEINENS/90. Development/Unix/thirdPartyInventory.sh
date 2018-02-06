RED='\033[0;31m'
NC='\033[0m' # No Color
CTL=./controlFile/thirdparty_counting.ctl
TODAY=`date +%m-%d-%Y`

echo $TODAY 
for file in $GAIA/RECEIVED/*.csv
do
    FILENAME=`basename $file`
    cat $CTL | sed "s/:FILEDATA/$FILENAME/g" > $FILENAME.ctl 

    echo -e "${RED}Processing Third Party inventory file ...... ["$FILENAME"]${NC}"
    # sqlldr USERID=$USERID log=logs/$FILENAME.log BAD=logs/$FILENAME.bad  DIRECT=YES DATA=$file SKIP=1 CONTROL=$FILENAME.ctl ERRORS=100000 READSIZE=60000000 BINDSIZE=60000000
    echo -e "${RED}["$FILENAME"] ........ DONE.${NC}"
    
    echo -e "${RED}Processing the inventory files integrated  .....${NC}"
    sqlplus -s $USERID @processInventoryFile.sql $FILENAME
    echo -e "${RED}Inventory files integrated  " $FILENAME ".....${NC}"

    rm $FILENAME.ctl 
done

# psifa98p psifa98p $USERID numInv date language num
# psifa98p psifa98p $USERID -1 `date "+%d/%m/%y"` HN 1 
