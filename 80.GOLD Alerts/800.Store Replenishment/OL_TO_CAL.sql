
SELECT iolcodc "Item code",iolcexvlc "LV code", pkartvl.get_vldesc(1,arlseqvl,'GB') "Description", SUM(iolqteip) "Qty to be prepared (Colis)", 
       SUM(iolqtec) "Qty to be prepared (SKU)"
FROM tmc_icsdeol, artvl WHERE TRUNC(ioldcre)=trunc(SYSDATE) 
AND ioliurg=0 AND tmc_operation IN ( 'DEL') 
AND to_char(ioldcre,'HH24')='20'
AND arlcexvl=iolcexvlc
AND iolcodc=arlcexr
GROUP BY iolcodc, iolcexvlc, pkartvl.get_vldesc(1,arlseqvl,'GB')
UNION 
SELECT 'TOTAL', NULL, ' ',  SUM(iolqteip), SUM(iolqtec)
FROM tmc_icsdeol, artvl WHERE TRUNC(ioldcre)=trunc(SYSDATE) 
AND ioliurg=0 AND tmc_operation IN ( 'DEL') 
AND to_char(ioldcre,'HH24')='20'
AND arlcexvl=iolcexvlc
AND iolcodc=arlcexr
