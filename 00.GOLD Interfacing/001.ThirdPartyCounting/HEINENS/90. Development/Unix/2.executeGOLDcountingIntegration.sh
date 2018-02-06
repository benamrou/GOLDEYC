RED='\033[0;31m'
NC='\033[0m' # No Color
rm -r *.txt 
dt=`date '+%d/%m/%y %H:%M'`
export dt

echo -e "${RED}\n^[[1m--- GOLD COUNTING integration psifa98p  ---^[[0m\n${NC}"
echo -e started at ${dt}


sqlplus -s hncustom/hncustom @$HOME/bin/shell/thirdpartyinventory/sql/getCountingListToIntegrate.sql   

echo -e "Counting list generated."
chmod 777 $HOME/bin/shell/thirdpartyinventory/countingList.txt 
sed '/^$/d' $HOME/bin/shell/thirdpartyinventory/countingList.txt > $HOME/bin/shell/thirdpartyinventory/countingListOut.txt
echo -e "GOLD batch execution PSIFA98P..."

myfile="$HOME/bin/shell/thirdpartyinventory/countingListOut.txt"

count=0
while read line; 
do
	echo -e "Counting: $line"
	nohup psifa98p psifa98p $USERID $line `date "+%d/%m/%y"` HN 1 &     
	count=`expr $count + 1`
done <"$myfile"

echo -e "${RED}GOLD counting execution completed -  $count counts.${NC}"
