create table ITEMMHLINK
(
  catcode VARCHAR2(20),
  catcat  VARCHAR2(50),
  catdate DATE default SYSDATE,
  cattrt  NUMBER(1) default 0,
  catfile VARCHAR2(80),
  catlgfi NUMBER(7),
  catdcre DATE default SYSDATE,
  catdmaj DATE default SYSDATE,
  catutil VARCHAR2(50) default 'CATEGORY',
  catnerr NUMBER(6),
  catmess VARCHAR2(100)
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
comment on table ITEMMHLINK
  is 'ITEMLINKMH item Merchandise Hierarchy link change table';
comment on column ITEMMHLINK.catcode
  is 'Item code';
comment on column ITEMMHLINK.catcat
  is 'Category/Merchandise hierarchy external code';
comment on column ITEMMHLINK.cattrt
  is 'Integration flag (0: to be integrated, 1: Send to GOLD, 2: Error in processing)';
comment on column ITEMMHLINK.catfile
  is 'Filename';
comment on column ITEMMHLINK.catlgfi
  is 'File line number';
comment on column ITEMMHLINK.catdcre
  is 'Creation date';
comment on column ITEMMHLINK.catdmaj
  is 'Modification date';
comment on column ITEMMHLINK.catutil
  is 'Last user';
comment on column ITEMMHLINK.catnerr
  is 'Error number';
comment on column ITEMMHLINK.catmess
  is 'Error message description';
create index ITEMLINKMH_I01 on ITEMMHLINK (CATFILE, CATLGFI)
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

