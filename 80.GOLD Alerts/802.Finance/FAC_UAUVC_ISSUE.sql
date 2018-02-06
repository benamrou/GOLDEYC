SELECT dffcexfac "Invoice #", effsite "Site #", artcexr  "Item code", pkstrucobj.get_desc(1,dffcinr,'FR') "Description", 
       effdatf "Invoice date", dffuaut "UAUT", dffuauvc "UAUVC", dffuapp "UAPP" 
FROM facentfac,facdetfac, artrac
WHERE dffuapp=1
AND dffuaut != dffuauvc
AND dffcinr=artcinr
AND effcinfac=dffcinfac
UNION 
SELECT 'Script to run to fix issue > ',NULL,NULL, '
UPDATE facdetfac set dffuauvc=dffuaut, dffdmaj=sysdate, dffutil=''sql_fixuauvc'' 
where dffuapp=1
AND dffuaut != dffuauvc;',  NULL,NULL,  NULL,NULL
FROM dual

