select me3donord "Code entrepot",
       me3datexp "Date mvt",
       decode(me3typol, 1, 'Retour', 'Expedition') "Type Mvt",
       me3numcde "Num commande",
       me3codcli "Code magasin",
       clilibl "Nom magasin",
       pkparpostes.get_postlibl(999, 0, 502, dcdetat, 'FR') "Etat commande",
       me3nseqbl "Num BL",
       me3ctourn "Num tournee",
       me3cproin "Code article",
       me3ilogis "VL",
       tsobdesc "Libelle",
       me3qteexp "Qte",
       me3pdsexp "Poids",
       nvl((select SUM (NVL(storeai,0) + NVL(storeal,0) - NVL(storeav,0) + NVL(storeae,0) + NVL(storeac,0) - NVL(storear,0)) CINR from stocouch where stosite = me3donord and stocinr = artcinr), 0) "Stock dispo UVC CENTRAL"
  from n3_mvtex e, artrac, tra_strucobj, clidgene, cdedetcde
 where me3cproin = artcexr
   and tsobcint = artcinr
   and langue = 'FR'
   and me3codcli = clincli
   and me3numcde = dcdcexcde
   and me3nolign = dcdnolign
   and exists (select 1
          from tmc_n3_mvtex h
         where e.me3numcde = h.me3numcde
           and e.me3nolign = h.me3nolign
           and e.me3nseqbl = h.me3nseqbl
           and h.TMC_OPERATION = 'INS'
           and h.TMC_datetime < sysdate - 1 / (24))
order by me3datexp, me3numcde, me3nolign, me3cproin