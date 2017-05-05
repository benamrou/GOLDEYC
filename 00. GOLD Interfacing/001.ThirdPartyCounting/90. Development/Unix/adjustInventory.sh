RED='\033[0;31m'
NC='\033[0m' # No Color
TODAY=`date +%m-%d-%Y`

echo $TODAY 
FILENAME=`basename $1`

echo -e "${RED}Adjusting Inventory files " $FILENAME " with in-between operations.....${NC}"    
sqlplus -s hncustom/hncustom @sql/adjustInventory.sql $FILENAME
echo -e "${RED}Inventory files integrated  " $FILENAME ".....${NC}"

# psifa98p psifa98p $USERID numInv date language num
# psifa98p psifa98p $USERID -1 `date "+%d/%m/%y"` HN 1 
