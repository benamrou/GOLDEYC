LOAD DATA
APPEND
INTO TABLE ITEMMHLINK FIELDS TERMINATED BY ","
TRAILING NULLCOLS
(
CATCODE		CHAR,
CATCAT		CHAR,
CATDATE		SYSDATE,
CATFILE		CONSTANT ":FILEDATA",
CATLGFI 	RECNUM,
CATDCRE		SYSDATE,
CATDMAJ		SYSDATE,	
CATUTIL		CONSTANT "CATEGORY"
)
