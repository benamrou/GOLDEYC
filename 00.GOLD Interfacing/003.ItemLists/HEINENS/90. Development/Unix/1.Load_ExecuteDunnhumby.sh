RED='\033[0;31m'
NC='\033[0m' # No Color
CTL=./controlFile/dunnhumby_pgroup.ctl
TODAY=`date +%m-%d-%Y`
ARCH=/data/hnpcen/dunnhumby/

echo $TODAY 
for file in $GAIA/RECEIVED/DUNN*.*
do
    FILENAME=`basename $file`
    cat $CTL | sed "s/:FILEDATA/$FILENAME/g" > $FILENAME.ctl 

    echo -e "${RED}Processing Dunnhumby file ...... ["$FILENAME"]${NC}"
    # sqlldr USERID=hncustom/hncustom log=logs/$FILENAME.log BAD=logs/$FILENAME.bad  DIRECT=YES DATA=$file SKIP=1 CONTROL=$FILENAME.ctl ERRORS=100000 READSIZE=60000000 BINDSIZE=60000000
    echo -e "${RED}["$FILENAME"] ........ DONE.${NC}"
    
    echo -e "${RED}Processing the Dunnhumby files integrated  .....${NC}"
    sqlplus -s hncustom/hncustom @sql/processDunnhumbyFile.sql $FILENAME
    echo -e "${RED}Dunnhumby files integrated  " $FILENAME ".....${NC}"

    rm $FILENAME.ctl 
    mv $file $ARCH
done

# psifa98p psifa98p $USERID numInv date language num
# psifa98p psifa98p $USERID -1 `date "+%d/%m/%y"` HN 1 
