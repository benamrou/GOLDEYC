-------------------------------------------------------------------
-- Export file for user HNUCEN@HN_UAT510                         --
-- Created by Ahmed  Benamrouche on 5/9/2017, 10:59:28 10:59:28  --
-------------------------------------------------------------------

set define off
spool itemmhlink_table.log

prompt
prompt Creating table ITEMMHLINK
prompt =========================
prompt
@@sql/itemmhlink.table.creation.sql

spool off
