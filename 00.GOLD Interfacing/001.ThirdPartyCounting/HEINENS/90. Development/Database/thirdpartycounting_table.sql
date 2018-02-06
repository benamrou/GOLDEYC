-----------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                    --
-- Created by Ahmed  Benamrouche on 2/6/2018, 8:53:09 8:53:09  --
-----------------------------------------------------------------

set define off
spool thirdpartycounting_table.log

prompt
prompt Creating table THIRDPARTY_COUNTING
prompt ==================================
prompt
create table THIRDPARTY_COUNTING
(
  cntupc      VARCHAR2(20),
  cntdesc     VARCHAR2(50),
  cntcat      VARCHAR2(20),
  cntcost     VARCHAR2(10),
  cntcode1    VARCHAR2(20),
  cntcode2    VARCHAR2(20),
  cntloc      VARCHAR2(10),
  cntdept     VARCHAR2(10),
  cntcode3    VARCHAR2(20),
  cntcost2    VARCHAR2(10),
  cntqty      VARCHAR2(10),
  cntextcost  VARCHAR2(10),
  cntcnuf     VARCHAR2(10),
  cntcode4    VARCHAR2(20),
  cntcode5    VARCHAR2(20),
  cntdeptdesc VARCHAR2(20),
  cnt500      VARCHAR2(20),
  cntfile     VARCHAR2(80),
  cntlgfi     NUMBER(7),
  cntdcre     DATE default SYSDATE,
  cntdmaj     DATE default SYSDATE,
  cntutil     VARCHAR2(50) default 'THIRDPARTY_COUNTING',
  cntnerr     NUMBER(6),
  cntmess     VARCHAR2(100),
  cnttrt      NUMBER(1) default 0,
  cntcompany  VARCHAR2(50)
)
tablespace USERS
  pctfree 10
  initrans 1
  maxtrans 255
  storage
  (
    initial 6M
    next 1M
    minextents 1
    maxextents unlimited
  );
comment on table THIRDPARTY_COUNTING
  is 'THIRDPARTY_COUNTING inventory THIRDPARTY_COUNTING table';
comment on column THIRDPARTY_COUNTING.cntupc
  is 'Item UPC code';
comment on column THIRDPARTY_COUNTING.cntdesc
  is 'Item description';
comment on column THIRDPARTY_COUNTING.cntcat
  is 'Item category';
comment on column THIRDPARTY_COUNTING.cntcost
  is 'Cost 1';
comment on column THIRDPARTY_COUNTING.cntcode1
  is 'Code 1';
comment on column THIRDPARTY_COUNTING.cntcode2
  is 'Code 2';
comment on column THIRDPARTY_COUNTING.cntloc
  is 'Location number';
comment on column THIRDPARTY_COUNTING.cntdept
  is 'Department number';
comment on column THIRDPARTY_COUNTING.cntcode3
  is 'Code 3';
comment on column THIRDPARTY_COUNTING.cntcost2
  is 'Cost 2';
comment on column THIRDPARTY_COUNTING.cntqty
  is 'Quantity counted';
comment on column THIRDPARTY_COUNTING.cntextcost
  is 'Ext. cost';
comment on column THIRDPARTY_COUNTING.cntcnuf
  is 'Vendor code';
comment on column THIRDPARTY_COUNTING.cntcode4
  is 'Code 4';
comment on column THIRDPARTY_COUNTING.cntcode5
  is 'Code 5';
comment on column THIRDPARTY_COUNTING.cntdeptdesc
  is 'Department description';
comment on column THIRDPARTY_COUNTING.cnt500
  is '500 Department number';
comment on column THIRDPARTY_COUNTING.cntfile
  is 'Filename';
comment on column THIRDPARTY_COUNTING.cntlgfi
  is 'File line number';
comment on column THIRDPARTY_COUNTING.cntdcre
  is 'Creation date';
comment on column THIRDPARTY_COUNTING.cntdmaj
  is 'Modification date';
comment on column THIRDPARTY_COUNTING.cntutil
  is 'Last user';
comment on column THIRDPARTY_COUNTING.cntnerr
  is 'Error number';
comment on column THIRDPARTY_COUNTING.cntmess
  is 'Error message description';
comment on column THIRDPARTY_COUNTING.cnttrt
  is 'Integration flag (0: to be integrated, 1: Send to GOLD, 2: Error finding item)';
comment on column THIRDPARTY_COUNTING.cntcompany
  is 'Third Party company name';
create index THIRDPARTY_COUNTING_I01 on THIRDPARTY_COUNTING (CNTFILE, CNTLGFI)
  tablespace USERS
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 64K
    next 1M
    minextents 1
    maxextents unlimited
  );


spool off
