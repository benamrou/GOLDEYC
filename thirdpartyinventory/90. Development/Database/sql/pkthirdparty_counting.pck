CREATE OR REPLACE PACKAGE "PKTHIRDPARTY_COUNTING" AS
--@(#) PKTHIRDPARTY_COUNTING_h.sql /main/centr_dev/centr_maint510/HNE01/2 4/4/2017;

-- Processing Third Party counting data approach
-- Step 1. Insert all the Counting data in the counting interface table
-- Step 2. Update Counting data if incorrect data are in the file (UPC code, item code, Store #, Qty)
-- Step 3. Run the integration using unix batch (psifa98p).

-- Requirement:
--     Counting data are uploaded in table THIRDPARTY_COUNTING
--     Counting type XX is setup in GOLD for all stores
-- General parameter 1074 entry 4: this entry allows you to differentiate the inventories created by interface.
-- General parameter 1309 entry 12: this entry allows you to define an inventory type by default for inventories
--                   by interface. The numerical value 1 of this entry includes the internal code of the inventory
--                   type by default.
-- Paraemter 1061 if inventory type not defined
PROCEDURE ProcessInventory (in_num_log IN NUMBER, in_filename IN VARCHAR2,o_return OUT NUMBER);
FUNCTION flagLine (in_num_log IN NUMBER, in_errorNumber IN NUMBER, in_filename IN VARCHAR2, in_lineNumber IN VARCHAR2) RETURN NUMBER;

-- This procedure is used when the inventory file is not integrated prior to the store movement.
-- In this case, the inventory file is integrated at the end of the follow-business days(s).
-- The NEW inventory quantity counted is :
-- The quantity counted by the 3rd party +/- all the operations from midnight to the new end of day integration.
PROCEDURE AdjustInventory (in_num_log IN NUMBER, in_filename IN VARCHAR2,o_return OUT NUMBER);

END PKTHIRDPARTY_COUNTING;
/

CREATE OR REPLACE PACKAGE BODY "PKTHIRDPARTY_COUNTING" AS

v_progname ERREURPRG.ERRPROG%TYPE := '3RDPARTY_CNT';
--@(#) PKTHIRDPARTY_COUNTING_h.sql /main/centr_dev/centr_maint510/HNE01/2 4/4/2017;

-- Processing Third Party counting data approach
-- Step 1. Insert all the Counting data in the counting interface table
-- Step 2. Update Counting data if incorrect data are in the file (UPC code, item code, Store #, Qty)
-- Step 3. Run the integration using unix batch (psifa98p).

-- Requirement:
--     Counting data are uploaded in table THIRDPARTY_COUNTING
--     Counting type XX is setup in GOLD for all stores
-- General parameter 1074 entry 4: this entry allows you to differentiate the inventories created by interface.
-- General parameter 1309 entry 12: this entry allows you to define an inventory type by default for inventories
--                   by interface. The numerical value 1 of this entry includes the internal code of the inventory
--                   type by default.
-- Paraemter 1061 if inventory type not defined
PROCEDURE ProcessInventory (in_num_log IN NUMBER, in_filename IN VARCHAR2,o_return OUT NUMBER) IS

    v_numCounting NUMBER;
    v_typeCounting INVENTTYP.ETICTYP%TYPE;

    i_cntloc THIRDPARTY_COUNTING.CNTLOC%TYPE;
    i_cntupc THIRDPARTY_COUNTING.CNTUPC%TYPE;
    i_cntcode1 THIRDPARTY_COUNTING.CNTCODE1%TYPE;
    i_cntcode2 THIRDPARTY_COUNTING.CNTCODE2%TYPE;
    i_cntqty THIRDPARTY_COUNTING.CNTQTY%TYPE;
    i_cntlgfi THIRDPARTY_COUNTING.CNTLGFI%TYPE;
    i_cntfile THIRDPARTY_COUNTING.CNTFILE%TYPE;
    i_cntcompany THIRDPARTY_COUNTING.CNTCOMPANY%TYPE;
    i_saleprice INTINV.IVFPV%TYPE;

    i_svcode ARTUV.ARVCEXV%TYPE; -- Variable used if UPC code/item code is not retrieved
    i_upctestSV NUMBER;
    v_flagLine NUMBER;
    v_store THIRDPARTY_COUNTING.CNTLOC%TYPE;
    v_inventoryName INTINV.IVFLIBL%TYPE;
    v_count NUMBER;
    v_count_commit NUMBER;
    v_errtrid ERREURPRG.ERRTRID%TYPE;

    CURSOR C_THIRDPARTY_COUNTING IS
    SELECT  CNTLOC, CNTUPC, NVL(CNTCODE1, SUBSTR(cntcode3,2,6)), CNTCODE2, CNTQTY, CNTLGFI,CNTFILE, NVL(CNTCOMPANY,'RGIS')
    FROM THIRDPARTY_COUNTING
    WHERE CNTFILE = in_filename
    AND NVL(CNTTRT,0) = 0
    ORDER BY CNTLOC, CNTFILE, CNTLGFI ASC;

BEGIN
  v_count := 0;
  v_count_commit :=200;
  v_errtrid := 22214;

   BEGIN
    v_numCounting := SEQCOUNTING.NEXTVAL;
    o_return := 0;

    INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
    VALUES (in_num_log, v_progname, 2, v_errtrid, 1,'Starting Third Party load inventory ' || in_filename || '...',
            SYSDATE,v_Progname);

    BEGIN
      OPEN C_THIRDPARTY_COUNTING;
      LOOP
          FETCH C_THIRDPARTY_COUNTING
          INTO i_cntloc, i_cntupc, i_cntcode1, i_cntcode2, i_cntqty, i_cntlgfi, i_cntfile, i_cntcompany ;

          IF C_THIRDPARTY_COUNTING%NOTFOUND THEN
              EXIT;
          END IF;

          v_count := v_count + 1;
          IF v_count = v_count_commit THEN
            COMMIT;
            v_count := 1;
          END IF;

          -- Partial commit by stores
          IF v_store != i_cntloc THEN
            COMMIT;
            v_numCounting := SEQCOUNTING.NEXTVAL; -- New store => new interface inventory code
          END IF;
           v_store := i_cntloc;
           v_inventoryName := to_char(SYSDATE-1,'RRRR/MM/DD') || ' STORE #' || v_store || ' - ' || i_cntcompany || ' CNT INVENTORY';

          -- Test on the store number
          IF i_cntloc IS NULL THEN
            v_flagLine := flagLine(in_num_log, 200, i_cntfile, i_cntlgfi);
            CONTINUE;
          END IF;

          -- Test on the qty
          IF i_cntqty IS NULL OR i_cntqty LIKE '%$%' THEN
            v_flagLine := flagLine(in_num_log, 300, i_cntfile, i_cntlgfi);
            CONTINUE;
          END IF;

    -- Treat the invalid date to the correct date
    /**
       UPDATE THIRDPARTY_COUNTING
           SET CNTcode2= to_char(trunc(SYSDATE),'MM/DD/RRRR')
           WHERE TO_CHAR(CNTCODE2,'YYYYMMDDHH24MISS') = '000000000000'
           AND CNTCODE2 IS NOT NULL
           AND CNTLOC IS NOT NULL
           AND CNTCODE1 IS NOT NULL
           AND CNTQTY IS NOT NULL;
    */
          -- Test if the UPC is known
          i_upctestSV := 0;
          BEGIN
            SELECT ARVCEXV, pkprixvente.get_prix_vente(1, arvcinv, i_cntloc, '1', trunc(SYSDATE))
             INTO i_upctestSV, i_saleprice
             FROM ARTCOCA, ARTUV
             WHERE ARVCINV = ARCCINV
             AND ARCCODE LIKE  '%' || i_cntupc || '_'
             AND i_cntupc IS NOT NULL
             AND ARVCEXR=i_cntcode1
             -- CNTCODE2 can contain incorrect date format
             -- AND to_date(CNTcode2,'MM/DD/RRRR') BETWEEN arcddeb AND arcdfin
             AND trunc(SYSDATE) BETWEEN arcddeb AND arcdfin
             AND ROWNUM = 1;
           EXCEPTION
             WHEN NO_DATA_FOUND THEN
               i_upctestSV := 0;
           END;
        IF (i_upctestSV != 0) THEN
            BEGIN
                INSERT INTO INTINV (
                  ivfcexinv,ivfsite,ivftinv,
                  ivflibl,ivfdinv,
                  ivftpos,ivfcode,ivfqter,ivfpdsinv,
                  ivfempl,ivfnordre,
                  ivforigcexinv,ivflgfi,ivftrt,
                  ivfdtrt,ivfdcre,ivfdmaj,
                  ivfutil,ivffich,ivfnlig,
                  ivfnerr,ivfmess,ivfcexv,
                  ivfcact, ivfpv) VALUES (
                  -- Insert using the UPC CODE
                  v_numCounting, i_cntloc,v_typeCounting, /* Inventory type blank  : using paramter 1061_101 */
                  v_inventoryName,trunc(SYSDATE), /* inventory date must be today or later */ --to_date(CNTcode2,'MM/DD/RRRR'),
                    0 /* tpos */, i_cntcode1, i_cntqty,i_cntqty,
                    NULL, i_cntlgfi, /* order number is mandatory */
                    NULL, i_cntlgfi, 0 /*trt */,
                    trunc(SYSDATE), SYSDATE,SYSDATE,
                    '3RDPARTY_CNT' /*util */, substr(i_cntfile,1,50), i_cntlgfi,
                    NULL, NULL,
                    i_upctestSV,
                     4, i_saleprice); /* IVFCACT */
                     /* field IVFCACT (action code) defines the actions that the programme has to carry out:
                           1 ¿ initialisation of the inventory
                           2 ¿ initialisation of and copy of the theoretical stock or only a copy of the stock if the inventory already exists
                           3 ¿ initialisation, copy of the theoretical stock and of the quantities in INVSAISIE or only copy of the quantities in INVSAISIE if the inventory already exists
                           4 ¿ initialisation + copy ofthe theoretical stock + input of the quantities + validation of the input + update of the stock
                           5 ¿ input of the quantities for an existing inventory
                           6 ¿ modification of an existing inventory 9 ¿ deletion of an existing inventory
                      */
              v_flagLine := flagLine(in_num_log, 101, i_cntfile, i_cntlgfi);
              EXCEPTION
                WHEN OTHERS THEN
                  v_flagLine := flagLine(in_num_log, 900, i_cntfile, i_cntlgfi);
                  PKERREURS.fc_erreur(in_num_log, v_Progname, substr('1. Error: ' || i_cntupc || ' ' || i_cntcode1 || ' ' || SQLCODE || SQLERRM, 1, 254) );
              END;
            ELSE
              -- Test #1 using UPC/item code failed
              -- Test #2 using the item code only
              i_svcode := NULL;
              BEGIN
               /* SELECT ARVCEXV, pkprixvente.get_prix_vente(1, arvcinv, 6, '1', trunc(SYSDATE))
                 INTO i_svcode, i_saleprice
                 FROM ARTUV, ARTSITE
                 WHERE arvcexr = i_cntcode1
                 AND i_cntcode1 IS NOT NULL
                 AND i_cntcode1 != '0'
								 AND arvcinv=sitcinv 
								 AND sitsite= i_cntloc
								 AND sitlien =1 
                 AND ROWNUM =1
                 GROUP BY ARVCEXV, arvcinv
                 ORDER BY ARVCEXV DESC; */
								 SELECT ARVCEXV, pkprixvente.get_prix_vente(1, arvcinv, i_cntloc, '1', trunc(SYSDATE))
                 INTO i_svcode, i_saleprice
                 FROM ARTUV
                 WHERE arvcexr = i_cntcode1
                 AND i_cntcode1 IS NOT NULL
                 AND i_cntcode1 != '0'
                 AND ROWNUM =1
                 GROUP BY ARVCEXV, arvcinv
                 ORDER BY ARVCEXV DESC; 
               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   i_svcode := NULL;
               END;

               IF (i_svcode IS NOT NULL) THEN
                  BEGIN
                      INSERT INTO INTINV (
                      ivfcexinv,ivfsite,ivftinv,
                      ivflibl,ivfdinv,
                      ivftpos,ivfcode,ivfqter,ivfpdsinv,
                      ivfpv, -- sale price required when only item code (saleable assortment potentially disabled)
                      ivfempl,ivfnordre,
                      ivforigcexinv,ivflgfi,ivftrt,
                      ivfdtrt,ivfdcre,ivfdmaj,
                      ivfutil,ivffich,ivfnlig,
                      ivfnerr,ivfmess,ivfcexv,
                      ivfcact) VALUES
                      (
                      -- Insert using the ITEM CODE last SV
                      v_numCounting, i_cntloc,v_typeCounting, /* Inventory type blank  : using paramter 1061_101 */
                      v_inventoryName,trunc(SYSDATE), /* inventory date must be today or later */ --to_date(CNTcode2,'MM/DD/RRRR'),
                      0 /* tpos */, i_cntcode1, i_cntqty,i_cntqty,
                      i_saleprice,
                      NULL, i_cntlgfi, /* order number is mandatory */
                      NULL, i_cntlgfi, 0 /*trt */,
                      trunc(SYSDATE), SYSDATE,SYSDATE,
                      '3RDPARTY_CNT' /*util */, substr(i_cntfile,1,50), i_cntlgfi,
                      NULL, NULL,
                      i_svcode,
                      4); /* IVFCACT */
                       /* field IVFCACT (action code) defines the actions that the programme has to carry out:
                             1 ¿ initialisation of the inventory
                             2 ¿ initialisation of and copy of the theoretical stock or only a copy of the stock if the inventory already exists
                             3 ¿ initialisation, copy of the theoretical stock and of the quantities in INVSAISIE or only copy of the quantities in INVSAISIE if the inventory already exists
                             4 ¿ initialisation + copy ofthe theoretical stock + input of the quantities + validation of the input + update of the stock
                             5 ¿ input of the quantities for an existing inventory
                             6 ¿ modification of an existing inventory 9 ¿ deletion of an existing inventory
                        */
                  v_flagLine := flagLine(in_num_log, 102, i_cntfile, i_cntlgfi);
                  EXCEPTION
                    WHEN OTHERS THEN
                      v_flagLine := flagLine(in_num_log, 900, i_cntfile, i_cntlgfi);
                      PKERREURS.fc_erreur(in_num_log, v_Progname, substr('2. Error: ' || i_cntupc || ' ' || i_cntcode1 || ' ' || SQLCODE || SQLERRM, 1,254) );
                  END;
                ELSE

              -- Test #1 using UPC/item code failed
              -- Test #2 using the item code only failed
              -- Test #3 using the UPC code only
              i_svcode := NULL;
              v_flagLine := 0;
              BEGIN
                SELECT MAX(ARVCEXV), arvcexr, pkprixvente.get_prix_vente(1, arvcinv, i_cntloc, '1', trunc(SYSDATE))
                 INTO i_svcode, i_cntcode1, i_saleprice
                 FROM ARTCOCA, ARTUV
                 WHERE arccode LIKE '%' || i_cntupc || '_'
                 AND ARVCINV=ARCCINV
                 AND trunc(SYSDATE) BETWEEN arcddeb AND arcdfin
								 AND rownum=1
                 GROUP BY arvcexr, arvcinv;

               EXCEPTION
                 WHEN NO_DATA_FOUND THEN
                   i_cntcode1 := NULL;
                   i_svcode := NULL;
                 WHEN OTHERS THEN
                    v_flagLine := flagLine(in_num_log, 104, i_cntfile, i_cntlgfi);
               END;

               IF (i_svcode IS  NULL) THEN
                 IF v_flagLine = 0 THEN -- If line not already flagged as ERROR
                   -- PICS company UNKNOWN CODE starts with 499
                   IF i_cntupc LIKE '499%' THEN
                     v_flagLine := flagLine(in_num_log, 105, i_cntfile, i_cntlgfi);
                   ELSE
                     v_flagLine := flagLine(in_num_log, 100, i_cntfile, i_cntlgfi);
                   END IF;
                 END IF;
               ELSE
                  BEGIN
                      INSERT INTO INTINV (
                      ivfcexinv,ivfsite,ivftinv,
                      ivflibl,ivfdinv,
                      ivftpos,ivfcode,ivfqter,ivfpdsinv,
                      ivfempl,ivfnordre,
                      ivforigcexinv,ivflgfi,ivftrt,
                      ivfdtrt,ivfdcre,ivfdmaj,
                      ivfutil,ivffich,ivfnlig,
                      ivfnerr,ivfmess,ivfcexv,
                      ivfcact, ivfpv) VALUES ( 
                      -- Insert using the ITEM CODE last SV
                      v_numCounting, i_cntloc,v_typeCounting, /* Inventory type blank  : using paramter 1061_101 */
                      v_inventoryName,trunc(SYSDATE), /* inventory date must be today or later */ --to_date(CNTcode2,'MM/DD/RRRR'),
                      0 /* tpos */, i_cntcode1, i_cntqty,i_cntqty,
                      NULL, i_cntlgfi, /* order number is mandatory */
                      NULL, i_cntlgfi, 0 /*trt */,
                      trunc(SYSDATE), SYSDATE,SYSDATE,
                      '3RDPARTY_CNT' /*util */, substr(i_cntfile,1,50), i_cntlgfi,
                      NULL, NULL,
                      i_svcode,
                      4, i_saleprice );/* IVFCACT */
                       /* field IVFCACT (action code) defines the actions that the programme has to carry out:
                             1 ¿ initialisation of the inventory
                             2 ¿ initialisation of and copy of the theoretical stock or only a copy of the stock if the inventory already exists
                             3 ¿ initialisation, copy of the theoretical stock and of the quantities in INVSAISIE or only copy of the quantities in INVSAISIE if the inventory already exists
                             4 ¿ initialisation + copy ofthe theoretical stock + input of the quantities + validation of the input + update of the stock
                             5 ¿ input of the quantities for an existing inventory
                             6 ¿ modification of an existing inventory 9 ¿ deletion of an existing inventory
                        */
                  v_flagLine := flagLine(in_num_log, 101, i_cntfile, i_cntlgfi);
                  EXCEPTION
                    WHEN OTHERS THEN
                      v_flagLine := flagLine(in_num_log, 900, i_cntfile, i_cntlgfi);
                      PKERREURS.fc_erreur(in_num_log, v_Progname, substr('2. Error: ' || i_cntupc || ' ' || i_cntcode1 || ' ' || SQLCODE || SQLERRM, 1,254) );
                  END;
                  END IF;
                END IF;
          END IF;
    END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        v_flagLine := flagLine(in_num_log, 900, i_cntfile, i_cntlgfi);
        PKERREURS.fc_erreur(in_num_log, v_Progname, substr('3. Error: ' || i_cntupc || ' ' || i_cntcode1 || ' ' || SQLCODE || SQLERRM, 1, 254) );
    END;

  INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
  VALUES (in_num_log, v_progname, 8, v_errtrid, 99999,'End Third Party load inventory ' || in_filename || '...',
          SYSDATE,v_Progname);
  END;
END ProcessInventory;


/**
 * This function flag the line in error with a CODE ERROR and MESSAGE
 * TRT = 1 -- Line process successfully
 * TRT = 2 -- Failure during the line mapping (too many references for the code)
 * TRT = 3 -- Unknown item from THIRD PARTY (Generic item code)
*/
FUNCTION flagLine (in_num_log IN NUMBER, in_errorNumber IN NUMBER, in_filename IN VARCHAR2, in_lineNumber IN VARCHAR2) RETURN NUMBER IS

 v_errorMessage THIRDPARTY_COUNTING.CNTMESS%TYPE;
 v_trt THIRDPARTY_COUNTING.CNTTRT%TYPE;
 v_errorNumber THIRDPARTY_COUNTING.CNTNERR%TYPE;
BEGIN
  CASE in_errorNumber
    WHEN 0 THEN
      v_errorMessage := NULL;
      v_errorNumber := NULL;
      v_trt := 1;
    WHEN 100 THEN
      v_errorMessage := v_progname || ' couldn''t retrieve the item/SV code for this inventory line.';
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    WHEN 101 THEN
      v_errorMessage := v_progname || ' retrieved UPC using method 1. UPC/Item code only';
      v_errorNumber := in_errorNumber;
      v_trt := 1;
    WHEN 102 THEN
      v_errorMessage := v_progname || ' retrieved UPC using method 2. Item code only';
      v_errorNumber := in_errorNumber;
      v_trt := 1;
    WHEN 103 THEN
      v_errorMessage := v_progname || ' retrieved UPC using method 3. UPC only';
      v_errorNumber := in_errorNumber;
      v_trt := 1;
    WHEN 104 THEN
      v_errorMessage := v_progname || ' too many codes retrieved for this line item';
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    WHEN 105 THEN
      v_errorMessage := v_progname || ' Item with unknown barcode/item code';
      v_errorNumber := in_errorNumber;
      v_trt := 3;
    WHEN 200 THEN
      v_errorMessage := 'Invalid location number.';
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    WHEN 300 THEN
      v_errorMessage := 'Invalid quantity';
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    WHEN 900 THEN
      v_errorMessage := substr(SQLCODE || SQLERRM, 1, 254);
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    ELSE v_errorMessage := 'No error message for this error number.';
  END CASE;

  BEGIN
    UPDATE THIRDPARTY_COUNTING
    SET CNTTRT=v_trt, CNTNERR=v_errorNumber, CNTMESS= v_errorMessage, CNTDMAJ=SYSDATE
    WHERE CNTFILE = in_filename AND CNTLGFI= in_lineNumber;
  EXCEPTION
    WHEN OTHERS THEN
      PKERREURS.fc_erreur(in_num_log, v_Progname,'3. Error updating line item  ' || in_filename || ' ' || in_lineNumber || ' ' || SQLCODE || SQLERRM );
      RETURN -1;
  END;
  RETURN 1;
END flagLine;


/* Adjust Inventory Procedure */
-- This procedure is used when the inventory file is not integrated prior to the store movement.
-- In this case, the inventory file is integrated at the end of the follow-business days(s).
-- The NEW inventory quantity counted is :
-- The quantity counted by the 3rd party +/- all the operations from midnight to the new end of day integration.
PROCEDURE AdjustInventory (in_num_log IN NUMBER, in_filename IN VARCHAR2,o_return OUT NUMBER) IS

 v_numCounting INTINV.IVFCEXINV%TYPE;
 v_ivfcode INTINV.IVFCODE%TYPE;
 v_ivfcexv INTINV.IVFCEXV%TYPE;
 v_ivfutil INTINV.IVFUTIL%TYPE;
 v_inventoryName INTINV.IVFLIBL%TYPE;
 v_additionalQty NUMBER;
 v_progname ERREURPRG.ERRPROG%TYPE;
 v_errtrid ERREURPRG.ERRTRID%TYPE;

 i_ivfcexinv INTINV.IVFCEXINV%TYPE;
 i_ivfsite INTINV.IVFSITE%TYPE;
 i_ivftinv INTINV.IVFTINV%TYPE;
 i_ivfdinv INTINV.IVFDINV%TYPE;
 i_ivftpos INTINV.IVFTPOS%TYPE;
 i_ivfcode INTINV.IVFCODE%TYPE;
 i_ivfqter INTINV.IVFQTER%TYPE;
 i_ivfpdsinv INTINV.IVFPDSINV%TYPE;
 i_ivfpv INTINV.IVFPV%TYPE;
 i_ivfempl INTINV.IVFEMPL%TYPE;
 i_ivfnordre INTINV.IVFNORDRE%TYPE;
 i_ivforigcexinv INTINV.IVFORIGCEXINV%TYPE;
 i_ivffich INTINV.IVFFICH%TYPE;
 i_ivfnlig INTINV.IVFNLIG%TYPE;
 i_ivflgfi INTINV.IVFLGFI%TYPE;
 i_ivfcexv INTINV.IVFCEXV%TYPE;
 i_ivfdmaj INTINV.IVFDMAJ%TYPE;

 v_count NUMBER;
 v_count_commit NUMBER;
 v_store INTINV.IVFSITE%TYPE;

  CURSOR C_INTINV IS
  SELECT ivfcexinv,ivfsite,ivftinv,
        ivfdinv,
        ivftpos,ivfcode,sum(ivfqter),sum(ivfpdsinv),
        ivfpv, -- sale price required when only item code (saleable assortment potentially disabled)
        ivfempl,ivfnordre,
        ivforigcexinv,ivflgfi,
        ivffich,ivfnlig,ivfcexv
  FROM INTINV
 WHERE IVFFICH = in_filename
   AND IVFTRT = 1 -- Reproces the inventory integrated
   AND EXISTS (SELECT 1 FROM STOMVT, ARTUV WHERE ARVCINV = STMCINL
               AND STMSITE = IVFSITE
               AND TRUNC(STMDCRE) BETWEEN trunc(ivfdinv) AND TRUNC(SYSDATE+1)
               AND STMTMVT NOT IN (113, 150, 125) /* Exclude Customer return/Sales */
               AND ARVCEXR = IVFCODE
               AND ARVCEXV = IVFCEXV)
   GROUP BY ivfcexinv,ivfsite,ivftinv,
        ivfdinv,
        ivftpos,ivfcode,
        ivfpv, -- sale price required when only item code (saleable assortment potentially disabled)
        ivfempl,ivfnordre,
        ivforigcexinv,ivflgfi,
        ivffich,ivfnlig,ivfcexv
   ORDER BY IVFSITE, IVFFICH, IVFLGFI ASC;
BEGIN
 BEGIN
  v_progname := 'ADJCNT';
  o_return := 0;
  v_errtrid := 22214;

  v_count := 0;
	v_store := -1;
  v_count_commit :=200;

  INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
  VALUES (in_num_log, v_progname, 2, v_errtrid, 1,'Starting Adjusting Third Party inventory ' || in_filename || '...',
          SYSDATE,v_Progname);

    BEGIN
      OPEN C_INTINV;
      LOOP
          v_count := v_count + 1;
          IF v_count = v_count_commit THEN
            COMMIT;
            v_count := 1;
          END IF;

          FETCH C_INTINV
          INTO i_ivfcexinv, i_ivfsite, i_ivftinv, i_ivfdinv,
               i_ivftpos, i_ivfcode, i_ivfqter,i_ivfpdsinv,
               i_ivfpv, -- sale price required when only item code (saleable assortment potentially disabled)
               i_ivfempl, i_ivfnordre,
               i_ivforigcexinv, i_ivflgfi,
               i_ivffich, i_ivfnlig, i_ivfcexv;


          IF C_INTINV%NOTFOUND THEN
              EXIT;
          END IF;

          -- Partial commit by stores
          IF v_store != i_ivfsite THEN
            COMMIT;
            v_numCounting := SEQCOUNTING.NEXTVAL; -- New store => new interface inventory code
          END IF;
					
            BEGIN
              v_additionalQty := 0;
              SELECT SUM (stmval)
              INTO v_additionalQty
              FROM STOMVT,
                   ARTUV
              WHERE STMTMVT NOT IN (113, 150, 125) /* Exclude Customer return/Sales */
               AND ARVCINV = STMCINL
               AND STMSITE = i_IVFSITE
               AND TRUNC(STMDCRE) BETWEEN i_ivfdinv AND TRUNC(SYSDATE)
               AND ARVCEXR = i_IVFCODE
               AND ARVCEXV = i_IVFCEXV;

             EXCEPTION
               WHEN NO_DATA_FOUND THEN
                 v_additionalQty := 0;
             END;

             v_inventoryName := to_char(i_ivfdinv,'RRRR/MM/DD') || ' COUNTER COUNTING STORE #' || i_ivfsite || ' - INVENTORY';

             BEGIN
               IF (v_additionalQty IS NOT NULL AND v_additionalQty != 0) THEN
                INSERT INTO INTINV (
                ivfcexinv,ivfsite,ivftinv,
                ivflibl,ivfdinv,
                ivftpos,ivfcode,ivfqter,ivfpdsinv,
                ivfpv, -- sale price required when only item code (saleable assortment potentially disabled)
                ivfempl,ivfnordre,
                ivforigcexinv,ivflgfi,ivftrt,
                ivfdtrt,ivfdcre,ivfdmaj,
                ivfutil,ivffich,ivfnlig,
                ivfnerr,ivfmess,ivfcexv,
                ivfcact) VALUES
                (
                -- Insert using the ITEM CODE last SV
                v_numCounting, i_ivfsite, i_ivftinv, /* Inventory type blank  : using paramter 1061_101 */
                v_inventoryName,trunc(SYSDATE), /* inventory date must be today or later */ --to_date(CNTcode2,'MM/DD/RRRR'),
                i_ivftpos /* tpos */, i_ivfcode, i_ivfqter + NVL(v_additionalQty,0),i_ivfqter + NVL(v_additionalQty,0),
                i_ivfpv,
                NULL, i_ivfnordre, /* order number is mandatory */
                NULL, i_ivflgfi, 0 /*trt */,
                trunc(SYSDATE), SYSDATE,SYSDATE,
                'CHG_3RDPARTY' /*util */, substr('CHG_' || in_filename,1,50), i_ivflgfi,
                NULL, NULL, i_ivfcexv,
                 4); /* IVFCACT */
                 /* field IVFCACT (action code) defines the actions that the programme has to carry out:
                       1 ¿ initialisation of the inventory
                       2 ¿ initialisation of and copy of the theoretical stock or only a copy of the stock if the inventory already exists
                       3 ¿ initialisation, copy of the theoretical stock and of the quantities in INVSAISIE or only copy of the quantities in INVSAISIE if the inventory already exists
                       4 ¿ initialisation + copy ofthe theoretical stock + input of the quantities + validation of the input + update of the stock
                       5 ¿ input of the quantities for an existing inventory
                       6 ¿ modification of an existing inventory 9 ¿ deletion of an existing inventory
                  */

                -- Insert the counter-counting as a Script 3rd Party counter counting
                INSERT INTO THIRDPARTY_COUNTING (
                cntcode1, cntloc,cntqty, cntutil, cntfile, cntlgfi, cntdcre, cntdmaj, cnttrt,cntnerr, cntmess, cntcompany)
                VALUES (
                i_ivfcode, i_ivfsite, i_ivfqter + NVL(v_additionalQty,0),
                'CHG_3RDPARTY' /*util */, substr('CHG_' || in_filename,1,50), i_ivflgfi,
                SYSDATE, SYSDATE, 1, 999, 'Counter inventory generated', 'COUNTER');
               END IF;
            EXCEPTION
              WHEN OTHERS THEN
                PKERREURS.fc_erreur(in_num_log, v_Progname, substr('2. Error: ' || i_ivfcode || ' ' || i_ivfcexv || ' ' || SQLCODE || SQLERRM, 1,254) );
            END;
        END LOOP;
    END;
    INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
    VALUES (in_num_log, v_progname, 8, v_errtrid, 99999,'End Adjust Third Party Inventory' || in_filename || '...',
            SYSDATE,v_Progname);
  END;
END AdjustInventory;

END PKTHIRDPARTY_COUNTING;
/

