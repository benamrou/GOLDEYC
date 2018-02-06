
SELECT DISTINCT to_char(lissite) "Store id", soclmag "Store desc", to_char(SYSDATE, 'DAY') || ' ' || TRUNC(SYSDATE) "Order day",
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdsite=lissite AND trunc(ecddenvoi)=TRUNC(SYSDATE) AND ecdetat IN (3,5,7)) "Nb. Colis",
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdsite=lissite AND trunc(ecddenvoi)=TRUNC(SYSDATE-7) AND ecdetat IN (3,5,7)) "Nb. Colis week-7",
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdsite=lissite AND trunc(ecddenvoi)=TRUNC(SYSDATE-14) AND ecdetat IN (3,5,7)) "Nb. Colis week-14",
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdsite=lissite AND trunc(ecddenvoi)=TRUNC(SYSDATE-21) AND ecdetat IN (3,5,7)) "Nb. Colis week-21"
FROM lienserv, sitdgene
WHERE lissite=socsite 
AND soccmag=10
AND liscfin=781
AND ((to_char(SYSDATE, 'D')=1 AND liscddi=1) OR 
(to_char(SYSDATE, 'D')=2 AND liscdlu=1) OR 
(to_char(SYSDATE, 'D')=3 AND liscdma=1) OR 
(to_char(SYSDATE, 'D')=4 AND liscdme=1) OR 
(to_char(SYSDATE, 'D')=5 AND liscdje=1) OR 
(to_char(SYSDATE, 'D')=6 AND liscdve=1) OR 
(to_char(SYSDATE, 'D')=7 AND liscdsa=1) )
AND TRUNC(SYSDATE) BETWEEN lisddeb AND lisdfin
UNION 
SELECT '', '', 'TOTAL',
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdcfin=781 AND trunc(ecddenvoi)=TRUNC(SYSDATE) AND ecdetat IN (3,5,7)),
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdcfin=781 AND trunc(ecddenvoi)=TRUNC(SYSDATE-7) AND ecdetat IN (3,5,7)),
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdcfin=781 AND trunc(ecddenvoi)=TRUNC(SYSDATE-14) AND ecdetat IN (3,5,7)),
       (SELECT SUM (dcdcoli) 
        FROM cdedetcde, cdeentcde WHERE ecdcincde=dcdcincde AND ecdcfin=781 AND trunc(ecddenvoi)=TRUNC(SYSDATE-21) AND ecdetat IN (3,5,7))
FROM dual
ORDER BY 2 ASC


/*SELECT to_date(SYSDATE-4, 'D') FROM dual
L M M J V S D
2 3 4 5 6 7 1*/
