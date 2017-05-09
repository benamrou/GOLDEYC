set termout off
set feed off
set head off
set echo off

spool $HOME/bin/shell/categorychange/categorychangeList.txt   

select distinct irautil from intartrac where iratrt = 0 and trunc(iradcre)=trunc(sysdate);

spool off;

exit success
