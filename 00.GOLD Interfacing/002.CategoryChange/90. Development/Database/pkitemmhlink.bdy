CREATE OR REPLACE PACKAGE BODY "PKITEMMHLINK" AS

v_progname ERREURPRG.ERRPROG%TYPE := 'CATEGORY';
--@(#) PKITEMMHLINK_h.sql /main/centr_dev/centr_maint510/HNE01/2 5/9/2017;

-- Processing Third Party counting data approach
-- Step 1. Insert all the MH/Item link data in the MH/Item link interface table
-- Step 2. Update MH/Item link data if incorrect data are in the file (item code, new MH link)
-- Step 3. Run the integration using unix batch (psifa05p).

-- Requirement:
--     MH/Item link data are uploaded in table ITEMMHLINK
PROCEDURE ProcessMHLinkChange (in_num_log IN NUMBER, in_filename IN VARCHAR2,o_return OUT NUMBER) IS


    i_catcode ITEMMHLINK.CATCODE%TYPE;
    i_catcat ITEMMHLINK.CATCAT%TYPE;
    i_catlgfi ITEMMHLINK.CATLGFI%TYPE;
    i_catfile ITEMMHLINK.CATFILE%TYPE;
    i_catdate ITEMMHLINK.CATDATE%TYPE;

    i_test_artcexr NUMBER;
    i_test_category_linkable NUMBER;
    i_test_category NUMBER;
		
		v_iraid INTARTRAC.IRAID%TYPE;
    v_flagLine NUMBER;
    v_count NUMBER;
    v_commit NUMBER;
    v_errtrid ERREURPRG.ERRTRID%TYPE;

    CURSOR C_ITEMMHLINK IS
    SELECT  CATCODE, CATCAT, CATDATE,CATLGFI,CATFILE
    FROM ITEMMHLINK
    WHERE CATFILE = in_filename
    AND NVL(CATTRT,0) = 0
    ORDER BY  CATFILE, CATLGFI ASC;

BEGIN
  v_count := 0;
  v_commit :=200;
  v_errtrid := 22215;
	
	v_iraid := 0;

   BEGIN
    o_return := 0;

    INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
    VALUES (in_num_log, v_progname, 2, v_errtrid, 1,'Starting item/mh link change ' || in_filename || '...',
            SYSDATE,v_Progname);

    BEGIN
      OPEN C_ITEMMHLINK;
      LOOP
				FETCH C_ITEMMHLINK
				INTO i_catcode, i_catcat, i_catdate, i_catlgfi, i_catfile;

				IF C_ITEMMHLINK%NOTFOUND THEN
						EXIT;
				END IF;

				v_count := v_count + 1;
				IF v_count = v_commit THEN
					COMMIT;
					v_count := 1;
				END IF;

				-- Test on the category
				IF i_catcat IS NULL OR i_catcat LIKE '%$%' THEN
					v_flagLine := flagLine(in_num_log, 102, i_catfile, i_catlgfi);
					CONTINUE;
				END IF;

				-- Test if the item exists
				i_test_artcexr := 0;
				BEGIN
					SELECT ARTCEXR
					 INTO i_test_artcexr
					 FROM ARTRAC
					 WHERE ARTCEXR = i_catcode;
				 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
						 i_test_artcexr := 0;
				 END;
        IF (i_test_artcexr = 0) THEN
           v_flagLine := flagLine(in_num_log, 101, i_catfile, i_catlgfi);
					 CONTINUE;
				END IF;

				-- Test if the category exists and linkable
				i_test_category := 0;
				i_test_category_linkable := 0;
				BEGIN
					SELECT sntaartl, sobcext 
					INTO i_test_category_linkable, i_test_category 
					FROM strucobj t, strucniv 
					WHERE sntidstr=sobidstr AND sntidniv=sobidniv
					AND (sobcext= i_catcat OR sobcextin=i_catcat);
				 EXCEPTION
					 WHEN NO_DATA_FOUND THEN
						 i_test_category := 0;
						 i_test_category_linkable := 0;
				 END;

				 IF (i_test_category IS NULL OR i_test_category = 0) THEN
					 v_flagLine := flagLine(in_num_log, 102, i_catfile, i_catlgfi);
					 CONTINUE;
				 END IF;

				 IF (i_test_category_linkable IS NULL OR i_test_category_linkable = 0) THEN
					 v_flagLine := flagLine(in_num_log, 102, i_catfile, i_catlgfi);
					 CONTINUE;
				 END IF;
				 		 
				BEGIN
							INSERT INTO INTARTRAC (IRACEXT, IRACEXTINP, IRADDEB, iradfin, iraid,
							iralgfi,iratrt,
							iradtrt,iradcre,iradmaj,
							irautil,irafich,iranlig,
							iranerr,iramess,
							iraflag) VALUES
							(i_catcode, i_catcat, trunc(SYSDATE-7), to_date('12/31/49','MM/DD/RRRR'), v_iraid,
							-- Insert using the ITEM CODE last SV
							i_catlgfi, 0 /*trt */,
							trunc(SYSDATE), SYSDATE,SYSDATE,
							'CATEGORY' /*util */, substr(i_catfile,1,50), i_catlgfi,
							NULL, NULL,
							2); /* IRAFLAG */
							  /* field IRAFLAG (action code) defines the actions that the programme has to carry out:
								/* ----------------------------------------------------------------------------------------- */
								/* Trt_struc_march()									     */
								/*	Insertion / Modification d'un lien entre l'article et une structure marchandise      */
								/*											     */
								/* - Le lien avec une structure est identifie par:					     */
								/*		Le code externe racine article (IRACEXT)				     */
								/*		Le code externe du noeud pere (IRACEXTINP)				     */
								/*		La date de debut (IRADDEB)						     */
								/*											     */
								/* - La racine article et le noeud pere doivent exister dans la base			     */
								/* ----------------------------------------------------------------------------------------- */
					v_flagLine := flagLine(in_num_log, 100, i_catfile, i_catlgfi);
					EXCEPTION
						WHEN OTHERS THEN
							v_flagLine := flagLine(in_num_log, 900, i_catfile, i_catlgfi);
							PKERREURS.fc_erreur(in_num_log, v_Progname, substr('2. Error: ' || i_catcode || ' ' || i_catcat || ' ' || SQLCODE || SQLERRM, 1,254) );
					END;
    END LOOP;
    EXCEPTION
      WHEN OTHERS THEN
        v_flagLine := flagLine(in_num_log, 900, i_catfile, i_catlgfi);
        PKERREURS.fc_erreur(in_num_log, v_Progname, substr('2. Error: ' || i_catcode || ' ' || i_catcat || ' ' || SQLCODE || SQLERRM, 1, 254) );
    END;

  INSERT INTO ERREURPRG(errlog,errprog, ERRSTAT, errtrid,errord,errmess,errdcre,errutil)
  VALUES (in_num_log, v_progname, 8, v_errtrid, 99999,'End Item Category change ' || in_filename || '...',
          SYSDATE,v_Progname);
  END;
END ProcessMHLinkChange;


/**
 * This function flag the line in error with a CODE ERROR and MESSAGE
 * TRT = 1 -- Line process successfully
 * TRT = 2 -- Failure during the line mapping (too many references for the code)
 * TRT = 3 -- Unknown item from THIRD PARTY (Generic item code)
*/
FUNCTION flagLine (in_num_log IN NUMBER, in_errorNumber IN NUMBER, in_filename IN VARCHAR2, in_lineNumber IN VARCHAR2) RETURN NUMBER IS

 v_errorMessage ITEMMHLINK.CATMESS%TYPE;
 v_trt ITEMMHLINK.CATTRT%TYPE;
 v_errorNumber ITEMMHLINK.CATNERR%TYPE;
BEGIN
  CASE in_errorNumber
    WHEN 0 THEN
      v_errorMessage := NULL;
      v_errorNumber := NULL;
      v_trt := 1;
    WHEN 100 THEN
      v_errorMessage := v_progname || ' retrieved item/category';
      v_errorNumber := in_errorNumber;
      v_trt := 1;
    WHEN 101 THEN
			v_errorMessage := v_progname || ' couldn''t retrieve the item code for this category change.';
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    WHEN 102 THEN
      v_errorMessage := v_progname || ' couldn''t retrieve the category code .';
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    WHEN 900 THEN
      v_errorMessage := substr(SQLCODE || SQLERRM, 1, 254);
      v_errorNumber := in_errorNumber;
      v_trt := 2;
    ELSE v_errorMessage := 'No error message for this error number.';
  END CASE;

  BEGIN
    UPDATE ITEMMHLINK
    SET CATTRT=v_trt, CATNERR=v_errorNumber, CATMESS= v_errorMessage, CATDMAJ=SYSDATE
    WHERE CATFILE = in_filename AND CATLGFI= in_lineNumber;
  EXCEPTION
    WHEN OTHERS THEN
      PKERREURS.fc_erreur(in_num_log, v_Progname,'3. Error updating line item  ' || in_filename || ' ' || in_lineNumber || ' ' || SQLCODE || SQLERRM );
      RETURN -1;
  END;
  RETURN 1;
END flagLine;

END PKITEMMHLINK;
/

