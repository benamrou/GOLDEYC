-----------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                    --
-- Created by Ahmed  Benamrouche on 2/6/2018, 8:52:38 8:52:38  --
-----------------------------------------------------------------

set define off
spool seqdnnlist.log

prompt
prompt Creating sequence SEQDNNLIST
prompt ============================
prompt
create sequence SEQDNNLIST
minvalue 1
maxvalue 999999
start with 6507
increment by 1
cache 5;


spool off
