--LOCAL
select 'LOCAL' "Invoice type", sclsite "Code Magasin", effncli "Code client", clilibl "Nom mag",   
       foucnuf "Code fournisseur", foulibl "Libelle Fournisseur",
       effcexfac "Num invoice AR", sum(pffbase) "Montant AR", effdatf "Date Facture AR",
       epfrfou "Num Invoice AP", SUM(gfamtht) "Montant AP", efadatf "Date facture AP",
       (sum(gfamtht) - sum(pffbase)) ecart, GFATTVA "Taux TVA"
from facentfac, facentpro, facpiedfac, cfdgbfac, cfdenfac, cliadres, fouadres, clidgene, sitclirel, foudgene
where 1 = 1
and effcinfac = epfcinfac
AND efarfou=gfarfou
AND sclncli=clincli
AND efacfin=foucfin
AND TRUNC(SYSDATE) BETWEEN sclddeb AND scldfin
and epfrfou = gfarfou
and REGEXP_SUBSTR(epfcomi1, '[^/]+', 1, 1) = pkfoudgene.get_CNUF(0, efacfin)
and gfacfin != 781
and gfacfin = efacfin
and gfacfin = fadcfin
and effncli = clincli
and effncli = adrncli
and adrpays = fadpays
and effcinfac = pffcinfac
and pffrubr = 4
and clisocju = 3
and gfamtht != 0
and gfamtht != pffbase
and abs(gfamtht - pffbase) > 1
and GFATTVA = pffvale
and trunc(gfadcre) >= trunc(sysdate - 10)
--and gfarfou != 'FA007628'
having abs(gfamtht - sum(pffbase)) > 1
group by effncli, effcexfac, effdatf, epfrfou, efadatf, gfamtht, sclsite, clincli, clilibl, foucnuf, foulibl, GFATTVA
UNION
--IEE
SELECT 'IEE' "Invoice type", sclsite "Code Magasin", effncli "Code client", clilibl "Nom mag", 
       foucnuf "Code fournisseur", foulibl "Libelle Fournisseur",
       effcexfac "Num invoice AR", sum(pffbase) "Montant AR", effdatf "Date Facture AR",
       epfrfou "Num Invoice AP", sum(gfamtht) "Montant AP", efadatf "Date facture AP",
       (sum(gfamtht) - sum(pffbase)) ecart, GFATTVA "Taux TVA"
from facentfac, facentpro, facpiedfac, cfdgbfac, cfdenfac, cliadres, fouadres, clidgene, sitclirel, foudgene 
where 1 = 1
and effcinfac = epfcinfac
and epfrfou = gfarfou
and REGEXP_SUBSTR(epfcomi1, '[^/]+', 1, 1) = pkfoudgene.get_CNUF(0, efacfin)
AND efacfin=foucfin
AND efarfou=gfarfou
and efacfin = gfacfin
AND sclncli=clincli
AND TRUNC(SYSDATE) BETWEEN sclddeb AND scldfin
and gfacfin != 781
and gfacfin = fadcfin
and effncli = clincli
and effncli = adrncli
and adrpays != fadpays
and clisocju = 3
and effcinfac = pffcinfac
and pffrubr = 4
and gfamtht != 0
and trunc(gfadcre) >= trunc(sysdate - 10)
--having gfamtht != sum(pffbase)
--and gfarfou != 'FA007628'
having abs(sum(gfamtht) - sum(pffbase)) > 1
--having (sum(gfamtht) - sum(pffbase))
group by effncli, effcexfac, effdatf, epfrfou, efadatf, gfamtht, sclsite, clincli, clilibl,  foucnuf, foulibl, GFATTVA
ORDER BY "Date facture AP" DESC