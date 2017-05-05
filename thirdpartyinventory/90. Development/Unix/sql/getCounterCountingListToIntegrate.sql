set termout off
set feed off
set head off
set echo off

spool $HOME/bin/shell/thirdpartyinventory/countingAdjustList.txt

select distinct cntfile from thirdparty_counting, intinv where ivffich=cntfile and ivflgfi=cntlgfi and ivftrt = 1 and trunc(ivfdinv)=trunc(sysdate);

spool off;

exit success
