RED='\033[0;31m'
NC='\033[0m' # No Color
CTL=./controlFile/categorychange.ctl
TODAY=`date +%m-%d-%Y`
ARCH=/data/hnpcen/category/201705/

echo $TODAY 
for file in $GAIA/RECEIVED/*.csv
do
    FILENAME=`basename $file`
    cat $CTL | sed "s/:FILEDATA/$FILENAME/g" > $FILENAME.ctl 

    echo -e "${RED}Processing Third Party inventory file ...... ["$FILENAME"]${NC}"
    sqlldr USERID=hnucen/hnucen log=logs/$FILENAME.log BAD=logs/$FILENAME.bad  DIRECT=YES DATA=$file SKIP=1 CONTROL=$FILENAME.ctl ERRORS=100000 READSIZE=60000000 BINDSIZE=60000000
    echo -e "${RED}["$FILENAME"] ........ DONE.${NC}"
    
    echo -e "${RED}Processing the category change files integrated  .....${NC}"
    sqlplus -s hnucen/hnucen @sql/processiCategoryFile.sql $FILENAME
    echo -e "${RED}Category change files integrated  " $FILENAME ".....${NC}"

    rm $FILENAME.ctl 
    mv $file $ARCH
done

# psifa98p psifa98p $USERID numInv date language num
# psifa98p psifa98p $USERID -1 `date "+%d/%m/%y"` HN 1 
