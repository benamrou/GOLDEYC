select null "Action ?",
       null MAGASIN, 
       null "Nom",
       --s.tfile "Type Fact",
       --s.reference,
       null "No PO",
       null "Nb colils",
       null "Facture",
       null "Date Facture",
       null "Mont TTC",
       null "Mont HT",
       null "Mont TVA",
       'SYigit@tomandco.be;JVanhollebeke@tomandco.com;Mvanparys@tomandco.be;gvanbelle@tomandco.be;KDevriese@tomandco.com;Mohamed.Mars@EYC.COM;Soufyane.Elharram@EYC.COM;EDubois@tomandco.com;Pascal.Potvliege@EYC.CO' "Description"
       from dual
Union
select 'OK/ToChekc' "Action ?",
       s.storelto MAGASIN, 
       pksitdgene.get_sitedescription(1, s.storelto) "Nom",
       --s.tfile "Type Fact",
       --s.reference,
       CEXCDE "No PO",
       round(NBRCOLIS, 3) "Nb colils",
       s.blnr "Facture",
       to_date(s.bldat, 'YYYYMMDD') "Date Facture",
       sum(s.wrbtr) "Mont TTC",
       sum(s.fwbas) "Mont HT",
       sum(s.wmwst) "Mont TVA",
       e.mess "Description"
  from tmc_sas_sap s,
       (select *
          from tmc_sas_sap t
         where trt = 2
           and t.nerr = 6) e, (select dffcexfac CEXFAC, dffcexcde CEXCDE, sum(dffqte/dffuauvc) NBRCOLIS from facdetfac group by dffcexfac, dffcexcde)facdetfac
 where s.tfile = e.tfile
   and s.reference = s.reference
   and s.blnr = e.blnr
   and NVL(s.LIFNR, '0') = NVL(e.LIFNR, '0')
   AND s.STORELTO = e.STORELTO
   --and s.blnr = '1801000209601'
   and CEXFAC = s.blnr
 group by s.storelto, s.reference, s.blnr, s.docid, s.bldat, e.mess, CEXCDE, NBRCOLIS
 order by 7 desc