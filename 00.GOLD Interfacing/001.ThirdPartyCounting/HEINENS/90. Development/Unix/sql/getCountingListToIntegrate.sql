set termout off
set feed off
set head off
set echo off

spool $HOME/bin/shell/thirdpartyinventory/countingList.txt   

select distinct ivfcexinv from intinv where ivftrt = 0 and trunc(ivfdinv)=trunc(sysdate);

spool off;

exit success
