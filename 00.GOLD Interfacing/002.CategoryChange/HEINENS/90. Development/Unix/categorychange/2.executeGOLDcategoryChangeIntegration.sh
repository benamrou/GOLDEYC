RED='\033[0;31m'
NC='\033[0m' # No Color
rm -f *.txt 
dt=`date '+%d/%m/%y %H:%M'`
export dt

echo -e "${RED}\n^[[1m--- GOLD Category Change integration psifa05p  ---^[[0m\n${NC}"
echo -e started at ${dt}


sqlplus -s hnucen/hnucen @$HOME/bin/shell/categorychange/sql/getCategoryChangeListToIntegrate.sql   

echo -e "Category Change list generated."
chmod 777 $HOME/bin/shell/categorychange/categorychangeList.txt 
sed '/^$/d' $HOME/bin/shell/categorychange/categorychangeList.txt > $HOME/bin/shell/categorychange/categorychangeListOut.txt
echo -e "GOLD batch execution PSIFA05P..."

myfile="$HOME/bin/shell/categorychange/categorychangeListOut.txt"

count=0
while read line; 
do
	echo -e "Category change: $line"
	nohup psifa05p psifa05p $USERID `date "+%d/%m/%y"` 1 -u$line HN 1 &     
	count=`expr $count + 1`
done <"$myfile"

# prog prog u/p date initial_loading [-sSite][-uUSER] language Log
echo -e "${RED}GOLD category change execution completed -  $count counts.${NC}"
