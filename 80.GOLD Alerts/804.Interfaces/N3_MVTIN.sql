select mi3donord as "Code entrepot",
       mi3datmvt as "Date mvt",
       mi3codinv as "Code utilsateur",
       mi3codcli as "Code tier",
       mi3qteuvc as "Qte",
       mi3numorc as "Num mvt",
       mi3cproin as "Code article",
       mi3ilogis as "VL",
       tsobdesc as "Libelle",
       nvl((select TPARLIBL from stoentre, cfdendoc, cfdenfac, tra_parpostes where tparcmag = 0 and tpartabl = 224 and tparpost = efaetat and langue = 'FR' and lpad(sernusr,7,'0') = lpad(to_char(mi3numorc),7,'0') and edccexcde = sercexcde and edcndoc = sercinrec and edcrfou = efarfou and rownum = 1 ), 'Non receptionee ou article inexistant BRV') as "Etat BRV",
       nvl((select SUM (NVL(storeai,0) + NVL(storeal,0) - NVL(storeav,0) + NVL(storeae,0) + NVL(storeac,0) - NVL(storear,0)) CINR from stocouch where stosite = mi3donord and stocinr = artcinr), 0) as "Stock dispo UVC"
  from n3_mvtin e, artrac, tra_strucobj
 where mi3cproin = artcexr
   and tsobcint = artcinr
   and langue = 'FR'
   and exists (select 1
          from tmc_n3_mvtin h
         where e.mi3numorc = h.mi3numorc
           --and e.mi3nolign = h.mi3nolign
           --and e.mi3bdlfou = h.mi3bdlfou
           and e.mi3codcli = h.mi3codcli
           and e.mi3cproin = h.mi3cproin
           and e.mi3datmvt = h.mi3datmvt
           and h.tmc_OPERATION = 'INS'
           and h.tmc_datetime < sysdate - 1 / (24))
order by mi3datmvt, mi3numorc, mi3nolign, mi3cproin