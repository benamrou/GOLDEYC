select mr3donord as "Code entrepot",
       mr3datmvt as "Date mvt",
       decode(mr3typOR, 1, 'Reception', 'Retour') as "Type Mvt",
       mr3ncdefo as "Num commande",
       (select TPARLIBL from cdeentcde, tra_parpostes where tparcmag = 0 and tpartabl = 502 and tparpost = ecdetat and langue = 'FR' and ecdcexcde = mr3ncdefo) as "Etat commande",
       mr3numroc as "Num OR",
       nvl((select TPARLIBL from stoentre, cfdendoc, cfdenfac, tra_parpostes where tparcmag = 0 and tpartabl = 224 and tparpost = efaetat and langue = 'FR' and lpad(sernusr,7,'0') = lpad(to_char(mr3numroc),7,'0') and edccexcde = sercexcde and edcndoc = sercinrec and edcrfou = efarfou and rownum = 1 ), 'Non receptionee') as "Etat BRV",
       mr3cproin as "Code article",
       mr3ilogis as "VL",
       tsobdesc as "Libelle",
       mr3uvcrec as "Qte en reception",
       MR3PDSREC as "Poids en reception",
       nvl((select SUM (NVL(storeai,0) + NVL(storeal,0) - NVL(storeav,0) + NVL(storeae,0) + NVL(storeac,0) - NVL(storear,0)) CINR from stocouch where stosite = mr3donord and stocinr = artcinr), 0) as "Stock dispo UVC CENTRAL"
  from n3_mvtre e, artrac, tra_strucobj
 where mr3cproin = artcexr
   and tsobcint = artcinr
   and langue = 'FR'
   and exists (select 1
          from tmc_n3_mvtre h
         where e.mr3ncdefo = h.mr3ncdefo
           and e.mr3nolign = h.mr3nolign
           and e.mr3bdlfou = h.mr3bdlfou
           and h.TMC_OPERATION = 'INS'
           and h.TMC_datetime < sysdate - 1 / (24))
order by mr3datmvt, mr3ncdefo, mr3nolign, mr3cproin