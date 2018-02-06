-----------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                    --
-- Created by Ahmed  Benamrouche on 2/6/2018, 8:54:01 8:54:01  --
-----------------------------------------------------------------

set define off
spool dunnpricegroup_table.log

prompt
prompt Creating table DUNN_PRICEGROUP
prompt ==============================
prompt
create table DUNN_PRICEGROUP
(
  dnndept   VARCHAR2(80),
  dnnssdept VARCHAR2(80),
  dnncat    VARCHAR2(80),
  dnnsscat  VARCHAR2(80),
  dnncode   VARCHAR2(20),
  dnnupc    VARCHAR2(20),
  dnnlv     VARCHAR2(3),
  dnndesc   VARCHAR2(80),
  dnnbrand  VARCHAR2(80),
  dnnpgrp   VARCHAR2(80),
  dnnfile   VARCHAR2(80),
  dnnlgfi   NUMBER(7),
  dnndcre   DATE default SYSDATE,
  dnndmaj   DATE default SYSDATE,
  dnnutil   VARCHAR2(50) default 'DUNNHUMBY',
  dnnnerr   NUMBER(6),
  dnnmess   VARCHAR2(100),
  dnntrt    NUMBER(1) default 0,
  dnnglst   VARCHAR2(50)
)
;
comment on table DUNN_PRICEGROUP
  is 'Dunnhumby inventory THIRDPARTY_COUNTING table';
comment on column DUNN_PRICEGROUP.dnndept
  is 'Department';
comment on column DUNN_PRICEGROUP.dnnssdept
  is 'Sub-Department';
comment on column DUNN_PRICEGROUP.dnncat
  is 'Category';
comment on column DUNN_PRICEGROUP.dnnsscat
  is 'Sub-Category';
comment on column DUNN_PRICEGROUP.dnncode
  is 'Item code';
comment on column DUNN_PRICEGROUP.dnnupc
  is 'EAN/UPC code';
comment on column DUNN_PRICEGROUP.dnnlv
  is 'LV code';
comment on column DUNN_PRICEGROUP.dnndesc
  is 'Item description';
comment on column DUNN_PRICEGROUP.dnnbrand
  is 'Item brand';
comment on column DUNN_PRICEGROUP.dnnpgrp
  is 'Item price group';
comment on column DUNN_PRICEGROUP.dnnfile
  is 'Filename';
comment on column DUNN_PRICEGROUP.dnnlgfi
  is 'Line number in the file';
comment on column DUNN_PRICEGROUP.dnndcre
  is 'Creation date';
comment on column DUNN_PRICEGROUP.dnndmaj
  is 'Update date';
comment on column DUNN_PRICEGROUP.dnnutil
  is 'Last user';
comment on column DUNN_PRICEGROUP.dnnnerr
  is 'Error number';
comment on column DUNN_PRICEGROUP.dnnmess
  is 'Message error';
comment on column DUNN_PRICEGROUP.dnntrt
  is 'Treatment flag (0: To be processed, 1: Success, 2: Failure)';
comment on column DUNN_PRICEGROUP.dnnglst
  is 'GOLD item list associated';
create index DUNN_PRICEGROUP_I01 on DUNN_PRICEGROUP (DNNFILE, DNNLGFI);


spool off
