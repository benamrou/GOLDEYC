-----------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                    --
-- Created by Ahmed  Benamrouche on 2/6/2018, 8:52:29 8:52:29  --
-----------------------------------------------------------------

set define off
spool seqcounting.log

prompt
prompt Creating sequence SEQCOUNTING
prompt =============================
prompt
create sequence SEQCOUNTING
minvalue 1
maxvalue 9999999
start with 2281
increment by 1
cache 20;


spool off
