-------------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                      --
-- Created by Ahmed  Benamrouche on 5/5/2017, 13:12:41 13:12:41  --
-------------------------------------------------------------------

set define off
spool pkthirdpartycounting.log

prompt
prompt Creating package PKTHIRDPARTY_COUNTING
prompt ======================================
prompt
@@sql/pkthirdparty_counting.pck

spool off
