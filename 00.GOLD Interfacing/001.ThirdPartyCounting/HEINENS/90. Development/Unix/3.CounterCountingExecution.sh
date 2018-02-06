RED='\033[0;31m'
NC='\033[0m' # No Color
rm -r *.txt 
dt=`date '+%d/%m/%y %H:%M'`
export dt

echo -e "${RED}\n^[[1m--- GOLD COUNTER ADJUSTING COUNTING integration psifa98p  ---^[[0m\n${NC}"
echo -e started at ${dt}


sqlplus -s hncustom/hncustom @$HOME/bin/shell/thirdpartyinventory/sql/getCounterCountingListToIntegrate.sql   

echo -e "Counting list generated."
chmod 777 $HOME/bin/shell/thirdpartyinventory/countingAdjustList.txt 
sed '/^$/d' $HOME/bin/shell/thirdpartyinventory/countingAdjustList.txt > $HOME/bin/shell/thirdpartyinventory/countingAdjustListOut.txt
echo -e "GOLD batch execution PSIFA98P..."

myfile="$HOME/bin/shell/thirdpartyinventory/countingAdjustListOut.txt"

count=0
while read line; 
do
	echo -e "Counting: $line"
	./adjustInventory.sh $line
	count=`expr $count + 1`
done <"$myfile"

echo -e "${RED}GOLD counter counting generation completed -  $count counts.${NC}"

./2.executeGOLDcountingIntegration.sh

