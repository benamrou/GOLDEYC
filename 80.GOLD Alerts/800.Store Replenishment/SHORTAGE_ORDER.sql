WITH DETAIL_SHORTAGE AS (
SELECT to_char(ecdsite) storeid, soclmag storelib, 
       SUM(cclqtec/DECODE(ccluvup,0,1,ccluvup)) storecolis, 
       SUM(cclqtep/DECODE(ccluvup,0,1,ccluvup))  storeprep 
FROM ccldetccl, cdeentcde, sitdgene
WHERE cclcexcde=ecdcexcde
AND socsite=ecdsite
AND trunc(ecddenvoi)=TRUNC(SYSDATE-1)
GROUP BY ecdsite, soclmag
UNION
SELECT to_char(ecdsite), soclmag, SUM(cclqtec/DECODE(ccluvup,0,1,ccluvup)), SUM(DECODE(ccluvup,0,1,ccluvup))
FROM hccldetccl, cdeentcde, sitdgene
WHERE cclcexcde=ecdcexcde
AND socsite=ecdsite
AND trunc(ecddenvoi)=TRUNC(SYSDATE-1)
GROUP BY ecdsite, soclmag
ORDER BY storelib ASC
) 
SELECT storeid "Store #",
        storelib "Description",
				SUM(storecolis) "Nb colis ordered",
				SUM(storeprep) "Nb colis to be prepared"
 FROM DETAIL_SHORTAGE
 GROUP BY storeid, storelib
 
 UNION
 SELECT '', ' TOTAL', SUM(storecolis), SUM(storeprep)
FROM DETAIL_SHORTAGE
ORDER BY 2 ASC

	
