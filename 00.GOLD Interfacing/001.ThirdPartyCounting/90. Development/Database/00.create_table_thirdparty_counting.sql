-------------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                      --
-- Created by Ahmed  Benamrouche on 5/5/2017, 13:13:21 13:13:21  --
-------------------------------------------------------------------

set define off
spool thridpartytable.log

prompt
prompt Creating table THIRDPARTY_COUNTING
prompt ==================================
prompt
@@sql/thirdparty_counting_table.sql

spool off
