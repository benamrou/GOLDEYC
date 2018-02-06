-----------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                    --
-- Created by Ahmed  Benamrouche on 2/6/2018, 8:51:48 8:51:48  --
-----------------------------------------------------------------

set define off
spool pkdunnhumby.log

prompt
prompt Creating package body PK_DUNNHUMBY
prompt ==================================
prompt
CREATE OR REPLACE PACKAGE BODY "PK_DUNNHUMBY" AS

v_progname ERREURPRG.ERRPROG%TYPE := 'DUNNHUMBY';
--@(#) PK_DUNNHUMBY_h.sql /main/centr_dev/centr_maint510/HNE01/2 1/16/2018;

-- Processing Dunnhumby data approach
-- Step 1. Insert all the dunnhumby price group data in the dunnhumby interface table
-- Step 2. Update dunnhumby data if incorrect data are in the file (UPC code, item code, Store #, Qty)
-- Step 3. Run the dunnhumby data using unix batch (psifaxxp).

-- Requirement:
--     Dunnhumby price group  data are uploaded in table DUNN_PRICE_GRP
--
-- General parameter : Not needed
-- 
PROCEDURE ProcessDunnhumby (in_num_log IN NUMBER, in_filename IN VARCHAR2,o_return OUT NUMBER) IS

    i_dnncode DUNN_PRICEGROUP.DNNCODE%TYPE;
    i_dnnlv DUNN_PRICEGROUP.DNNLV%TYPE;
    i_dnnupc DUNN_PRICEGROUP.DNNUPC%TYPE;
    i_dnnbrand DUNN_PRICEGROUP.DNNBRAND%TYPE;
    i_dnnpgrp DUNN_PRICEGROUP.DNNPGRP%TYPE;
    i_dnnglst DUNN_PRICEGROUP.DNNGLST%TYPE;
    i_dnnfile DUNN_PRICEGROUP.DNNFILE%TYPE;
    i_dnnlgfi DUNN_PRICEGROUP.DNNLGFI%TYPE;

    v_flagLine NUMBER;
		v_pricegroup DUNN_PRICEGROUP.DNNBRAND%TYPE;
    v_count NUMBER;
    v_count_commit NUMBER;
    v_listid NUMBER;
		i_existList NUMBER;
		i_existDetailList NUMBER;
		v_retour NUMBER;
		
		v_elinlis ARTENTLIST.ELINLIS%TYPE;
		v_elilibl ARTENTLIST.ELILIBL%TYPE;
    v_errtrid ERREURPRG.ERRTRID%TYPE;
		v_eliusage ARTENTLIST.ELIUSAGE%TYPE;
		
		v_dlicinv ARTDETLIST.DLICINV%TYPE;

    CURSOR C_DUNN_PRICEGROUP IS
    SELECT  DNNCODE, DNNLV, DNNUPC, DNNBRAND, DNNPGRP, DNNGLST, DNNFILE, DNNLGFI
    FROM DUNN_PRICEGROUP
    WHERE DNNFILE = in_filename
    AND NVL(DNNTRT,0) = 0
		AND length(DNNPGRP) > 1
		AND DNNPGRP != ' '
    ORDER BY DNNPGRP, DNNCODE, DNNLV, DNNFILE, DNNLGFI ASC;

BEGIN
  v_count := 0;
  v_count_commit :=200;
  v_errtrid := 22215;

   BEGIN
    o_return := 0;
		i_existList := 0;
		v_eliusage := 6; -- pt_2234
    v_listid := SEQDNNLIST.NEXTVAL; -- New store => new interface inventory code

    INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
    VALUES (in_num_log, v_progname, 2, v_errtrid, 1,'Starting Dunnhumby load inventory ' || in_filename || '...',
            SYSDATE,v_Progname);

    BEGIN
      OPEN C_DUNN_PRICEGROUP;
      LOOP
          FETCH C_DUNN_PRICEGROUP
          INTO i_DNNCODE, i_DNNLV, i_DNNUPC, i_DNNBRAND, i_DNNPGRP, i_DNNGLST, i_DNNFILE, i_DNNLGFI;

          IF C_DUNN_PRICEGROUP%NOTFOUND THEN
						  COMMIT;
              EXIT;
          END IF;

          v_count := v_count + 1;
          IF v_count = v_count_commit THEN
            COMMIT;
            v_count := 1;
          END IF;

          IF (LENGTH(i_DNNPGRP) = 1) THEN
						v_flagLine := flagLine(in_num_log, 103, i_dnnfile, i_dnnlgfi);
						CONTINUE;
			    END IF;
					
          -- Partial commit by stores
          IF v_pricegroup != i_DNNPGRP THEN
            COMMIT;
						i_existList := 0;
            v_listid := SEQDNNLIST.NEXTVAL; -- New price group => new interface list id
          END IF;
					
					v_pricegroup := i_DNNPGRP;
					
          -- STEP 1: Test if the Price group already exists  is known
          -- STEP 2: Test if item already in Price group 
					--         if already in price group then next
					--         else add it to the price group
          i_existList := 0;
          BEGIN
            SELECT ELINLIS, ELILIBL, 1
             INTO v_elinlis, v_elilibl, i_existList
             FROM ARTENTLIST
             WHERE elilibl LIKE  '%' || TRIM(upper(i_DNNPGRP)) || '%'
             AND ROWNUM = 1;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               i_existList := 0;
           END;
					 
					 IF (i_existList != 1) THEN
						  v_elinlis := 'DNN' || LPAD(v_listid,5,'0');
              --v_elilibl := 'DUNNHUMBY-PRICE GROUP' || '- ' || TRIM(upper(REPLACE(i_DNNPGRP,Chr(39), Chr(34))));
              v_elilibl := 'DUNNHUMBY-PRICE GROUP' || '- ' || upper(i_DNNPGRP);
							--v_elilibl := 'DUNNHUMBY';
							BEGIN 
								pklisteart.insert_artEntList(1, v_elinlis, v_elilibl,
																						 NULL, -- iv_eliidstr
																						 NULL, -- in_elistrcint
																						 NULL, -- in_elicfin
																						 NULL, -- in_elinfilf
																						 NULL, -- in_eliccin
																						 NULL, -- iv_elicoll
																						 NULL, -- in_eligest
																						 NULL, -- iv_elistat
																						 NULL, -- iv_eliniel
																						 NULL, -- in_eli1pri
																						 NULL, -- in_eliqual
																						 NULL, -- in_eliperm
																						 NULL, -- iv_elincat
																						 to_char(SYSDATE,'DD/MM/RR'), -- iv_eliddeb
																						 0, -- in_elispst
																						 NULL, -- iv_eliextyp
																						 NULL, -- iv_eliexdeb
																						 NULL, -- iv_eliexfin
																						 NULL, -- in_elexgrs
																						 NULL, -- in_eliutif
																						 0, -- in_eliauto
																						 NULL, -- in_elicfinc
																						 NULL, -- in_elinfilfc
																						 NULL, -- in_eliccinc
																						 NULL, -- in_elietat
																						 'DUNN', --  iv_eliutil
																						 0, -- in_elinass
																						 0, -- in_elitlst
																						 NULL, -- in_elitypp
																						 NULL, -- in_elinops
																						 0, -- in_elitrace
																						 v_eliusage, -- in_eliusage
																						 NULL, -- in_elisite
																						 0, -- in_eliprofil
																						 NULL, -- in_elictatt
																						 NULL, -- in_elictattuv
																						 v_retour);
							     COMMIT;
								 EXCEPTION
									 WHEN NO_DATA_FOUND THEN
										 i_existList := 0;
						     END;
					 END IF;


					 
          i_existDetailList := 0;
					v_flagLine := 0;
          BEGIN
            SELECT arvcinv
             INTO v_dlicinv
             FROM  ARTUV, ARTVL, artul
						 WHERE arlcexr = i_dnncode
						  AND arlcexvl = i_dnnlv
							AND aruseqvl = arlseqvl
							AND arvcinv = pkartstock.RecupCinlUVC(1,arucinl)
							AND arutypul = 81 -- From Pallet retrieve Sale Variant
             AND ROWNUM = 1;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               v_flagLine := 1;
           END;
					
					IF (v_flagLine != 0 ) THEN
					   v_flagLine := flagLine(in_num_log, 100, i_dnnfile, i_dnnlgfi);
						 CONTINUE;
					END IF;
					
          i_existDetailList := 0;
          BEGIN
            SELECT elinlis, 1
             INTO v_elinlis, i_existList
             FROM ARTENTLIST, ARTDETLIST
						 WHERE trim(elilibl) LIKE  '%' || trim(upper(i_DNNPGRP)) || '%'
							AND dlinlis = elinlis
							AND dlicinv = v_dlicinv
             AND ROWNUM = 1;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               i_existDetailList := 0;
           END;
					 
					 -- Item doesn't exists in the list, let's add it
					 IF (i_existDetailList != 0) THEN
						 v_flagLine := flagLine(in_num_log, 101, i_dnnfile, i_dnnlgfi);
						 CONTINUE;
					 END IF;
						 pklisteart.insert_artDetList(1, v_elinlis, v_dlicinv,
                                          NULL, -- iv_dliddeb
                                          NULL, -- iv_dlidfin
                                          0, -- in_dlitrt
                                          0, -- in_dliorig
                                          'DUNN', -- iv_dliutil
																					v_retour); 
						 
						/*INSERT
								INTO artdetlist
										 (dlinlis,
											dlicinv,
											dliddeb,
											dlidfin,
											dlitrt,
											dlidcre,
											dlidmaj,
											dliorig,
											dliutil,
											dlinmod )
								VALUES
											(v_elinlis,
											 v_dlicinv,
											 TO_DATE(CURRENT_DATE,'DD/MM/RR'),
											 TO_DATE('31/12/49','DD/MM/RR'),
											 0 ,
											 CURRENT_DATE,
											 CURRENT_DATE,
											 0,
											 'DUNN',
											 0 );*/
						 v_flagLine := flagLine(in_num_log, 102, i_dnnfile, i_dnnlgfi);
						 COMMIT;
    END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        v_flagLine := flagLine(in_num_log, 900, i_dnnfile, i_dnnlgfi);
        PKERREURS.fc_erreur(in_num_log, v_Progname, substr('3. Error: ' || i_dnnupc || ' ' || i_dnncode || ' ' || SQLCODE || SQLERRM, 1, 254) );
    END;

  INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
  VALUES (in_num_log, v_progname, 8, v_errtrid, 99999,'End PK_DUNNHUMBY ' || in_filename || '...',
          SYSDATE,v_Progname);
  END;
END ProcessDunnhumby;


/**
 * This function flag the line in error with a CODE ERROR and MESSAGE
 * TRT = 1 -- Line process successfully
 * TRT = 2 -- Failure during the line mapping (too many references for the code)
 * TRT = 3 -- Unknown item from THIRD PARTY (Generic item code)
*/
FUNCTION flagLine (in_num_log IN NUMBER, in_errorNumber IN NUMBER, in_filename IN VARCHAR2, in_lineNumber IN VARCHAR2) RETURN NUMBER IS

 v_errorMessage DUNN_PRICEGROUP.DNNMESS%TYPE;
 v_trt DUNN_PRICEGROUP.DNNTRT%TYPE;
 v_errorNumber DUNN_PRICEGROUP.DNNNERR%TYPE;
BEGIN
  CASE in_errorNumber
    WHEN 0 THEN
      v_errorMessage := NULL;
      v_errorNumber := NULL;
      v_trt := 1;
    WHEN 100 THEN
      v_errorMessage := v_progname || ' couldn''t retrieve the item/LV code.';
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    WHEN 101 THEN
      v_errorMessage := v_progname || ' item already exist in the item list';
      v_errorNumber := in_errorNumber;
      v_trt := 1;
    WHEN 102 THEN
      v_errorMessage := v_progname || ' added item to the item list';
      v_errorNumber := in_errorNumber;
      v_trt := 1;
    WHEN 103 THEN
      v_errorMessage := v_progname || ' - No price group';
      v_errorNumber := in_errorNumber;
      v_trt := 1;
    WHEN 900 THEN
      v_errorMessage := substr(SQLCODE || SQLERRM, 1, 254);
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    ELSE v_errorMessage := 'No error message for this error number.';
  END CASE;

  BEGIN
    UPDATE DUNN_PRICEGROUP
    SET DNNTRT=v_trt, DNNNERR=v_errorNumber, DNNMESS= v_errorMessage, DNNDMAJ=SYSDATE
    WHERE DNNFILE = in_filename AND DNNLGFI= in_lineNumber;
  EXCEPTION
    WHEN OTHERS THEN
      PKERREURS.fc_erreur(in_num_log, v_Progname,'3. Error updating line item  ' || in_filename || ' ' || in_lineNumber || ' ' || SQLCODE || SQLERRM );
      RETURN -1;
  END;
  RETURN 1;
END flagLine;

END PK_DUNNHUMBY;
/


spool off
