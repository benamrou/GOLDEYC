-----------------------------------------------------------------
-- Export file for user HNCUSTOM@HN_PROD510                    --
-- Created by Ahmed  Benamrouche on 2/6/2018, 8:51:24 8:51:24  --
-----------------------------------------------------------------

set define off
spool pkthirdpartycounting.log

prompt
prompt Creating package body PKG_EDI_INVOICE_MATCHING_NOVBK
prompt ====================================================
prompt
CREATE OR REPLACE PACKAGE BODY PKG_EDI_INVOICE_MATCHING_NOVBK is

  glo_ErrMessage        varchar2(255);
  glo_Section           varchar2(255);
  const_INTERFACESTATUS NUMBER(1) := 3; --3
  const_UTIL            VARCHAR2(6) := 'EDI894';
  glo_DebugFlag         NUMBER(1) := 0;

  -- To reprocess the untreated invoices for the last 7 days
  PROCEDURE ReprocessCall IS
    CURSOR getInvoicestoReprocess IS
    /*SELECT *
            FROM im_edi_invoice_header
           WHERE status_no in (1, -1)
                 AND trunc(created_date) >= SYSDATE - 7;*/
      SELECT distinct importbatchid
        FROM im_edi_invoice_header im2
       WHERE status_no in (1, -1)
         AND trunc(created_date) >= SYSDATE - 7
         and importbatchid =
             (select max(importbatchid)
                from im_edi_invoice_header im1
               where im1.invoicenumber = im2.invoicenumber);
  BEGIN
    glo_Section := 'getInvoicestoReprocess';
    PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ReprocessCall', glo_Section);
    FOR rec_getInvoicestoReprocess IN getInvoicestoReprocess LOOP
      LoadInterfaceTables(rec_getInvoicestoReprocess.importbatchid);
      UpdateInvoiceStatus(rec_getInvoicestoReprocess.importbatchid);
    END LOOP;
  
    glo_Section := 'UpdateInvoiceStatus';
    PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ReprocessCall', glo_Section);
    -- UpdateInvoiceStatus;
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ReprocessCall', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ReprocessCall', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  -- To move the EDI invoice data from SQL Staging table to Oracle staging tables
  PROCEDURE LoadDataFromSQLToStaging(param_ImportBatchID IN NUMBER) IS
  
    iCountOpenDBLink               INTEGER;
    strGetHeaderDataFrom_SQLServer VARCHAR2(4000);
    strGetItemDataFrom_SQLServer   VARCHAR2(4000);
    strGetItDealDataFrom_SQLServer VARCHAR2(4000);
    strGetFtDealDataFrom_SQLServer VARCHAR2(4000);
    loc_RowCount                   NUMBER(5);
  
  BEGIN
    glo_ErrMessage                 := 'ValidateBatchID';
    loc_RowCount                   := 0;
    strGetHeaderDataFrom_SQLServer := NULL;
    strGetItemDataFrom_SQLServer   := NULL;
    strGetItDealDataFrom_SQLServer := NULL;
    strGetFtDealDataFrom_SQLServer := NULL;
  
    -- Validate BatchID 
    SELECT COUNT(*)
      INTO loc_RowCount
      FROM im_edi_invoice_header
     WHERE importbatchid = param_ImportBatchID;
  
    IF loc_RowCount > 0 THEN
      glo_Section := 'BatchId:' || param_ImportBatchID ||
                     ' already processed';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
    
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
    ELSE
      glo_Section := 'Starting';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
    
      glo_Section := 'Checking if any left overs of the DB Link....';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
    
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
    /*  EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM V$DBLINK WHERE DB_LINK = ''MSQL'''
        INTO iCountOpenDBLink;
    
      IF iCountOpenDBLink > 0 THEN
        glo_Section := 'Yes it is there...Trying to Close DB Link...';
        PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      
        EXECUTE IMMEDIATE 'ALTER SESSION CLOSE DATABASE LINK MSQL';
        glo_Section := 'Closed.';
        PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
      END IF;*/
    
      -- Get the Header Data
      strGetHeaderDataFrom_SQLServer := 'INSERT INTO im_edi_invoice_header  
                                    SELECT "VendorDunsNumber",
         "InvoiceDate",
         "InvoiceNumber",
         "PONumber",
         "ShiptoDuns",
         "TotalInvoiceAmount",
         "UnitsShipped",
         "UOM",
         "Weight",
         "WeightUOM",
         "PaymentTermsCode",
         "PaymentTermsBasis",
         "TermsDiscountPercent",
         "TermsDiscountDate",
         "TermsDiscountDays",
         "TermsNetDays",
         "TermsNetDueDate",
         "TermsDiscountAmount",
         "FileName",
         "RecordStatusID",
         "ImportBatchID", ' || 1 || ' as Status_No,
' || '''Sql_To_OracleStaging''' || '
                                         as Status_Description,' || 0 ||
                                        'as Invoice_Type,' || 'sysdate' ||
                                        ' as Created_Date,' || 'sysdate' ||
                                        ' as Modified_Date,' ||
                                        '''PKG_EDI_IM''' ||
                                        ' as Last_User,"ReceiversLocation","CreditDebitFlag","DocumentType" FROM "vw_EDI894_HeaderInfo"@MSQL WHERE "ImportBatchID" =' ||
                                        param_ImportBatchID ||
                                        ' and "VendorDunsNumber" <> '''' and "InvoiceNumber" <> ''''';
    
      glo_Section := 'strGetHeaderDataFrom_SQLServer';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      EXECUTE IMMEDIATE strGetHeaderDataFrom_SQLServer;
    
      -- Get the Item Data
      strGetItemDataFrom_SQLServer := 'INSERT INTO im_edi_invoice_detail
    SELECT   
    "VendorDunsNumber",
"InvoiceDate",
"InvoiceNumber",
"QtyInvoiced",
"QtyUOM",
"UnitPrice",
"ProductIDQual",
"ProductID",
"UnitsShipped",
"UOM",
"ItemDescription",
"FileName",
         "RecordStatusID",
         "ImportBatchID", ' || 1 || ' as Status_No,
' || '''Sql_To_OracleStaging''' ||
                                      ' as Status_Description,' ||
                                      'sysdate' || ' as Created_Date,' ||
                                      'sysdate' || ' as Modified_Date,' ||
                                      '''PKG_EDI_IM''' ||
                                      ' as Last_User FROM "VW_EDI894_ItemInfo"@MSQL WHERE "ImportBatchID" =' ||
                                      param_ImportBatchID ||
                                      'and "VendorDunsNumber" <> '''' and "InvoiceNumber" <> ''''';
    
      glo_Section := 'strGetItemDataFrom_SQLServer';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      EXECUTE IMMEDIATE strGetItemDataFrom_SQLServer;
    
      -- Get the Item Deals
      strGetItDealDataFrom_SQLServer := 'INSERT INTO im_edi_invoice_itemdeals SELECT
     "VendorDunsNumber",
"InvoiceDate",
"InvoiceNumber",
"ProductIDQual",
"ProductID",
"AllowanceCharge",
"AllowanceChargeCode",
"AllowanceChargeRate",
"AllowanceChargeUOM",
"AllowanceTotalAmount",
    "FileName",
         "RecordStatusID",
         "ImportBatchID", ' || 1 || ' as Status_No,
' || '''Sql_To_OracleStaging''' ||
                                        ' as Status_Description,' ||
                                        'sysdate' || ' as Created_Date,' ||
                                        'sysdate' || ' as Modified_Date,' ||
                                        '''PKG_EDI_IM''' ||
                                        ' as Last_User FROM "VW_EDI894_ItemDeals"@MSQL WHERE "ImportBatchID" =' ||
                                        param_ImportBatchID ||
                                        'and "VendorDunsNumber" <> '''' and "InvoiceNumber" <> ''''';
    
      glo_Section := 'strGetItDealDataFrom_SQLServer';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      EXECUTE IMMEDIATE strGetItDealDataFrom_SQLServer;
    
      -- Get the Footer Deals
      strGetFtDealDataFrom_SQLServer := 'INSERT INTO im_edi_invoice_ftdeals SELECT
     "VendorDunsNumber",
"InvoiceDate",
"InvoiceNumber",
"AllowanceCharge",
"AllowanceChargeCode",
"AllowanceChargeRate",
"AllowanceChargeUOM",
"AllowanceTotalAmount",
    "FileName",
         "RecordStatusID",
         "ImportBatchID", ' || 1 || ' as Status_No,
' || '''Sql_To_OracleStaging''' ||
                                        ' as Status_Description,' ||
                                        'sysdate' || ' as Created_Date,' ||
                                        'sysdate' || ' as Modified_Date,' ||
                                        '''PKG_EDI_IM''' ||
                                        ' as Last_User FROM "VW_EDI894_HeaderDeals"@MSQL WHERE "ImportBatchID" =' ||
                                        param_ImportBatchID ||
                                        'and "VendorDunsNumber" <> '''' and "InvoiceNumber" <> ''''';
    
      glo_Section := 'strGetFtDealDataFrom_SQLServer';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      EXECUTE IMMEDIATE strGetFtDealDataFrom_SQLServer;
    
      glo_Section := 'Received all the data!!!';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      glo_Section := 'Successfully Completed';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_Section);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      COMMIT;
    END IF;
  
    glo_Section := 'CallUpdateCMInvoiceNo';
    PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateCMInvoiceNo', glo_Section);
    UpdateCMInvoiceNo(param_ImportBatchID);
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadDataFromSQLToStaging', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE UpdateInvoiceNo IS
  
    CURSOR get_InvoicesWithLeadingZero IS
      SELECT invoicenumber, vendordunsnumber, importbatchid
        FROM im_edi_invoice_header, intcfinv, intcfbl, fouadres, foudgene
       WHERE cfiinvid = trim(leading '0' from invoicenumber)
         AND cfiinvid = cfbinvid
         AND cficfex = cfbcfex
         AND cficfex = foucnuf
         AND fadcfin = foucfin
         AND fadacci = vendordunsnumber
            --pepsi
         AND vendordunsnumber <> '048407840'
         AND status_no = 1
            --Aug21-Kanchana
         AND substr(invoicenumber, 1, 1) = '0';
  
  BEGIN
  
    FOR rec_InvoicesWithLeadingZero IN get_InvoicesWithLeadingZero LOOP
    
      insert into im_edi_invoice_header
        (VENDORDUNSNUMBER,
         INVOICEDATE,
         INVOICENUMBER,
         PONUMBER,
         SHIPTODUNS,
         TOTALINVOICEAMOUNT,
         UNITSSHIPPED,
         UOM,
         WEIGHT,
         WEIGHTUOM,
         PAYMENTTERMSCODE,
         PAYMENTTERMSBASIS,
         TERMSDISCOUNTPERCENT,
         TERMSDISCOUNTDATE,
         TERMSDISCOUNTDAYS,
         TERMSNETDAYS,
         TERMSNETDUEDATE,
         TERMSDISCOUNTAMOUNT,
         FILENAME,
         RECORDSTATUSID,
         IMPORTBATCHID,
         STATUS_NO,
         STATUS_DESCRIPTION,
         INVOICE_TYPE,
         CREATED_DATE,
         MODIFIED_DATE,
         LAST_USER,
         RECEIVERSLOCATION,
         CREDITDEBITFLAG,
         DOCUMENTTYPE)
        select VENDORDUNSNUMBER,
               INVOICEDATE,
               trim(leading '0' from invoicenumber),
               PONUMBER,
               SHIPTODUNS,
               TOTALINVOICEAMOUNT,
               UNITSSHIPPED,
               UOM,
               WEIGHT,
               WEIGHTUOM,
               PAYMENTTERMSCODE,
               PAYMENTTERMSBASIS,
               TERMSDISCOUNTPERCENT,
               TERMSDISCOUNTDATE,
               TERMSDISCOUNTDAYS,
               TERMSNETDAYS,
               TERMSNETDUEDATE,
               TERMSDISCOUNTAMOUNT,
               FILENAME,
               RECORDSTATUSID,
               IMPORTBATCHID,
               STATUS_NO,
               STATUS_DESCRIPTION,
               INVOICE_TYPE,
               CREATED_DATE,
               MODIFIED_DATE,
               LAST_USER,
               RECEIVERSLOCATION,
               CREDITDEBITFLAG,
               DOCUMENTTYPE
          from im_edi_invoice_header
         where importbatchid = rec_InvoicesWithLeadingZero.importbatchid
           AND invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
           AND vendordunsnumber =
               rec_InvoicesWithLeadingZero.vendordunsnumber
           AND status_no = 1;
    
      insert into im_edi_invoice_detail
        (VENDORDUNSNUMBER,
         INVOICEDATE,
         INVOICENUMBER,
         QTYINVOICED,
         QTYUOM,
         UNITPRICE,
         PRODUCTIDQUAL,
         PRODUCTID,
         UNITSSHIPPED,
         UOM,
         ITEMDESCRIPTION,
         FILENAME,
         RECORDSTATUSID,
         IMPORTBATCHID,
         STATUS_NO,
         STATUS_DESCRIPTION,
         CREATED_DATE,
         MODIFIED_DATE,
         LAST_USER)
        select VENDORDUNSNUMBER,
               INVOICEDATE,
               trim(leading '0' from invoicenumber),
               QTYINVOICED,
               QTYUOM,
               UNITPRICE,
               PRODUCTIDQUAL,
               PRODUCTID,
               UNITSSHIPPED,
               UOM,
               ITEMDESCRIPTION,
               FILENAME,
               RECORDSTATUSID,
               IMPORTBATCHID,
               STATUS_NO,
               STATUS_DESCRIPTION,
               CREATED_DATE,
               MODIFIED_DATE,
               LAST_USER
          from im_edi_invoice_detail det
         where det.importbatchid =
               rec_InvoicesWithLeadingZero.importbatchid
           AND det.invoicenumber =
               rec_InvoicesWithLeadingZero.invoicenumber
           AND det.vendordunsnumber =
               rec_InvoicesWithLeadingZero.vendordunsnumber
           AND status_no = 1;
    
      insert into im_edi_invoice_itemdeals
        (VENDORDUNSNUMBER,
         INVOICEDATE,
         INVOICENUMBER,
         PRODUCTIDQUAL,
         PRODUCTID,
         ALLOWANCECHARGE,
         ALLOWANCECHARGECODE,
         ALLOWANCECHARGERATE,
         ALLOWANCECHARGEUOM,
         ALLOWANCETOTALAMOUNT,
         FILENAME,
         RECORDSTATUSID,
         IMPORTBATCHID,
         STATUS_NO,
         STATUS_DESCRIPTION,
         CREATED_DATE,
         MODIFIED_DATE,
         LAST_USER)
        select VENDORDUNSNUMBER,
               INVOICEDATE,
               trim(leading '0' from invoicenumber),
               PRODUCTIDQUAL,
               PRODUCTID,
               ALLOWANCECHARGE,
               ALLOWANCECHARGECODE,
               ALLOWANCECHARGERATE,
               ALLOWANCECHARGEUOM,
               ALLOWANCETOTALAMOUNT,
               FILENAME,
               RECORDSTATUSID,
               IMPORTBATCHID,
               STATUS_NO,
               STATUS_DESCRIPTION,
               CREATED_DATE,
               MODIFIED_DATE,
               LAST_USER
          from im_edi_invoice_itemdeals ild
         WHERE ild.importbatchid =
               rec_InvoicesWithLeadingZero.importbatchid
           AND ild.invoicenumber =
               rec_InvoicesWithLeadingZero.invoicenumber
           AND ild.vendordunsnumber =
               rec_InvoicesWithLeadingZero.vendordunsnumber
           AND status_no = 1;
    
      insert into im_edi_invoice_ftdeals
        (VENDORDUNSNUMBER,
         INVOICEDATE,
         INVOICENUMBER,
         ALLOWANCECHARGE,
         ALLOWANCECHARGECODE,
         ALLOWANCECHARGERATE,
         ALLOWANCECHARGEUOM,
         ALLOWANCETOTALAMOUNT,
         FILENAME,
         RECORDSTATUSID,
         IMPORTBATCHID,
         STATUS_NO,
         STATUS_DESCRIPTION,
         CREATED_DATE,
         MODIFIED_DATE)
        select VENDORDUNSNUMBER,
               INVOICEDATE,
               trim(leading '0' from invoicenumber),
               ALLOWANCECHARGE,
               ALLOWANCECHARGECODE,
               ALLOWANCECHARGERATE,
               ALLOWANCECHARGEUOM,
               ALLOWANCETOTALAMOUNT,
               FILENAME,
               RECORDSTATUSID,
               IMPORTBATCHID,
               STATUS_NO,
               STATUS_DESCRIPTION,
               CREATED_DATE,
               MODIFIED_DATE
          from im_edi_invoice_ftdeals fld
         WHERE fld.importbatchid =
               rec_InvoicesWithLeadingZero.importbatchid
           AND fld.invoicenumber =
               rec_InvoicesWithLeadingZero.invoicenumber
           AND fld.vendordunsnumber =
               rec_InvoicesWithLeadingZero.vendordunsnumber
           AND status_no = 1;
    
      delete from im_edi_invoice_ftdeals fld
       where fld.importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND fld.invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND fld.vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;
    
      delete from im_edi_invoice_itemdeals ild
       WHERE ild.importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND ild.invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND ild.vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;
    
      delete from im_edi_invoice_detail det
       where det.importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND det.invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND det.vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;
    
      delete from im_edi_invoice_header
       where importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;
    
      /*UPDATE im_edi_invoice_ftdeals fld
         SET fld.invoicenumber = trim(leading '0' from invoicenumber)
       WHERE fld.importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND fld.invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND fld.vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;
      
      UPDATE im_edi_invoice_itemdeals ild
         SET ild.invoicenumber = trim(leading '0' from invoicenumber)
       WHERE ild.importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND ild.invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND ild.vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;
      
      UPDATE im_edi_invoice_detail det
         SET det.invoicenumber = trim(leading '0' from invoicenumber)
       WHERE det.importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND det.invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND det.vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;
      
      UPDATE im_edi_invoice_header
         SET invoicenumber = trim(leading '0' from invoicenumber)
       WHERE importbatchid = rec_InvoicesWithLeadingZero.importbatchid
         AND invoicenumber = rec_InvoicesWithLeadingZero.invoicenumber
         AND vendordunsnumber =
             rec_InvoicesWithLeadingZero.vendordunsnumber
         AND status_no = 1;*/
    
      COMMIT;
    
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateInvoiceNo', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateInvoiceNo', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
    
  END;

  PROCEDURE UpdateCMInvoiceNo(param_ImportBatchID NUMBER) IS
  
  BEGIN
  
    insert into im_edi_invoice_header
      (VENDORDUNSNUMBER,
       INVOICEDATE,
       INVOICENUMBER,
       PONUMBER,
       SHIPTODUNS,
       TOTALINVOICEAMOUNT,
       UNITSSHIPPED,
       UOM,
       WEIGHT,
       WEIGHTUOM,
       PAYMENTTERMSCODE,
       PAYMENTTERMSBASIS,
       TERMSDISCOUNTPERCENT,
       TERMSDISCOUNTDATE,
       TERMSDISCOUNTDAYS,
       TERMSNETDAYS,
       TERMSNETDUEDATE,
       TERMSDISCOUNTAMOUNT,
       FILENAME,
       RECORDSTATUSID,
       IMPORTBATCHID,
       STATUS_NO,
       STATUS_DESCRIPTION,
       INVOICE_TYPE,
       CREATED_DATE,
       MODIFIED_DATE,
       LAST_USER,
       RECEIVERSLOCATION,
       CREDITDEBITFLAG,
       DOCUMENTTYPE)
      select VENDORDUNSNUMBER,
             INVOICEDATE,
             invoicenumber || 'CM',
             PONUMBER,
             SHIPTODUNS,
             TOTALINVOICEAMOUNT,
             UNITSSHIPPED,
             UOM,
             WEIGHT,
             WEIGHTUOM,
             PAYMENTTERMSCODE,
             PAYMENTTERMSBASIS,
             TERMSDISCOUNTPERCENT,
             TERMSDISCOUNTDATE,
             TERMSDISCOUNTDAYS,
             TERMSNETDAYS,
             TERMSNETDUEDATE,
             TERMSDISCOUNTAMOUNT,
             FILENAME,
             RECORDSTATUSID,
             IMPORTBATCHID,
             STATUS_NO,
             STATUS_DESCRIPTION,
             INVOICE_TYPE,
             CREATED_DATE,
             MODIFIED_DATE,
             LAST_USER,
             RECEIVERSLOCATION,
             CREDITDEBITFLAG,
             DOCUMENTTYPE
        from im_edi_invoice_header
       where importbatchid = param_ImportBatchID
         AND trim(creditdebitflag) = 'C'
         AND invoicenumber not like '%CM'
         AND status_no = 1;
  
    insert into im_edi_invoice_detail
      (VENDORDUNSNUMBER,
       INVOICEDATE,
       INVOICENUMBER,
       QTYINVOICED,
       QTYUOM,
       UNITPRICE,
       PRODUCTIDQUAL,
       PRODUCTID,
       UNITSSHIPPED,
       UOM,
       ITEMDESCRIPTION,
       FILENAME,
       RECORDSTATUSID,
       IMPORTBATCHID,
       STATUS_NO,
       STATUS_DESCRIPTION,
       CREATED_DATE,
       MODIFIED_DATE,
       LAST_USER)
      select VENDORDUNSNUMBER,
             INVOICEDATE,
             invoicenumber || 'CM',
             QTYINVOICED,
             QTYUOM,
             UNITPRICE,
             PRODUCTIDQUAL,
             PRODUCTID,
             UNITSSHIPPED,
             UOM,
             ITEMDESCRIPTION,
             FILENAME,
             RECORDSTATUSID,
             IMPORTBATCHID,
             STATUS_NO,
             STATUS_DESCRIPTION,
             CREATED_DATE,
             MODIFIED_DATE,
             LAST_USER
        from im_edi_invoice_detail det
       where det.importbatchid = param_ImportBatchID
         AND EXISTS (SELECT 1
                FROM im_edi_invoice_header
               WHERE invoicenumber = det.invoicenumber
                 AND trim(creditdebitflag) = 'C')
         AND det.invoicenumber not like '%CM'
         AND status_no = 1;
  
    insert into im_edi_invoice_itemdeals
      (VENDORDUNSNUMBER,
       INVOICEDATE,
       INVOICENUMBER,
       PRODUCTIDQUAL,
       PRODUCTID,
       ALLOWANCECHARGE,
       ALLOWANCECHARGECODE,
       ALLOWANCECHARGERATE,
       ALLOWANCECHARGEUOM,
       ALLOWANCETOTALAMOUNT,
       FILENAME,
       RECORDSTATUSID,
       IMPORTBATCHID,
       STATUS_NO,
       STATUS_DESCRIPTION,
       CREATED_DATE,
       MODIFIED_DATE,
       LAST_USER)
      select VENDORDUNSNUMBER,
             INVOICEDATE,
             invoicenumber || 'CM',
             PRODUCTIDQUAL,
             PRODUCTID,
             ALLOWANCECHARGE,
             ALLOWANCECHARGECODE,
             ALLOWANCECHARGERATE,
             ALLOWANCECHARGEUOM,
             ALLOWANCETOTALAMOUNT,
             FILENAME,
             RECORDSTATUSID,
             IMPORTBATCHID,
             STATUS_NO,
             STATUS_DESCRIPTION,
             CREATED_DATE,
             MODIFIED_DATE,
             LAST_USER
        from im_edi_invoice_itemdeals ild
       WHERE ild.importbatchid = param_ImportBatchID
         AND EXISTS (SELECT 1
                FROM im_edi_invoice_header
               WHERE invoicenumber = ild.invoicenumber
                 AND trim(creditdebitflag) = 'C')
         AND ild.invoicenumber not like '%CM'
         AND status_no = 1;
  
    insert into im_edi_invoice_ftdeals
      (VENDORDUNSNUMBER,
       INVOICEDATE,
       INVOICENUMBER,
       ALLOWANCECHARGE,
       ALLOWANCECHARGECODE,
       ALLOWANCECHARGERATE,
       ALLOWANCECHARGEUOM,
       ALLOWANCETOTALAMOUNT,
       FILENAME,
       RECORDSTATUSID,
       IMPORTBATCHID,
       STATUS_NO,
       STATUS_DESCRIPTION,
       CREATED_DATE,
       MODIFIED_DATE)
      select VENDORDUNSNUMBER,
             INVOICEDATE,
             invoicenumber || 'CM',
             ALLOWANCECHARGE,
             ALLOWANCECHARGECODE,
             ALLOWANCECHARGERATE,
             ALLOWANCECHARGEUOM,
             ALLOWANCETOTALAMOUNT,
             FILENAME,
             RECORDSTATUSID,
             IMPORTBATCHID,
             STATUS_NO,
             STATUS_DESCRIPTION,
             CREATED_DATE,
             MODIFIED_DATE
        from im_edi_invoice_ftdeals fld
       WHERE fld.importbatchid = param_ImportBatchID
         AND EXISTS (SELECT 1
                FROM im_edi_invoice_header
               WHERE invoicenumber = fld.invoicenumber
                 AND trim(creditdebitflag) = 'C')
         AND fld.invoicenumber not like '%CM'
         AND status_no = 1;
  
    delete from im_edi_invoice_ftdeals fld
     where fld.importbatchid = param_ImportBatchID
       AND EXISTS (SELECT 1
              FROM im_edi_invoice_header
             WHERE invoicenumber = fld.invoicenumber
               AND trim(creditdebitflag) = 'C')
       AND fld.invoicenumber not like '%CM'
       AND status_no = 1;
  
    delete from im_edi_invoice_itemdeals ild
     WHERE ild.importbatchid = param_ImportBatchID
       AND EXISTS (SELECT 1
              FROM im_edi_invoice_header
             WHERE invoicenumber = ild.invoicenumber
               AND trim(creditdebitflag) = 'C')
       AND ild.invoicenumber not like '%CM'
       AND status_no = 1;
  
    delete from im_edi_invoice_detail det
     where det.importbatchid = param_ImportBatchID
       AND EXISTS (SELECT 1
              FROM im_edi_invoice_header
             WHERE invoicenumber = det.invoicenumber
               AND trim(creditdebitflag) = 'C')
       AND det.invoicenumber not like '%CM'
       AND status_no = 1;
  
    delete from im_edi_invoice_header
     where importbatchid = param_ImportBatchID
       AND trim(creditdebitflag) = 'C'
       AND invoicenumber not like '%CM'
       AND status_no = 1;
  
    /* UPDATE im_edi_invoice_ftdeals fld
       SET fld.invoicenumber = fld.invoicenumber || 'CM'
     WHERE fld.importbatchid = param_ImportBatchID
       AND EXISTS (SELECT 1
              FROM im_edi_invoice_header
             WHERE invoicenumber = fld.invoicenumber
               AND trim(creditdebitflag) = 'C')
       AND fld.invoicenumber not like '%CM'
       AND status_no = 1;
    
    UPDATE im_edi_invoice_itemdeals ild
       SET ild.invoicenumber = ild.invoicenumber || 'CM'
     WHERE ild.importbatchid = param_ImportBatchID
       AND EXISTS (SELECT 1
              FROM im_edi_invoice_header
             WHERE invoicenumber = ild.invoicenumber
               AND trim(creditdebitflag) = 'C')
       AND ild.invoicenumber not like '%CM'
       AND status_no = 1;
    
    UPDATE im_edi_invoice_detail det
       SET det.invoicenumber = det.invoicenumber || 'CM'
     WHERE det.importbatchid = param_ImportBatchID
       AND EXISTS (SELECT 1
              FROM im_edi_invoice_header
             WHERE invoicenumber = det.invoicenumber
               AND trim(creditdebitflag) = 'C')
       AND det.invoicenumber not like '%CM'
       AND status_no = 1;
    
    UPDATE im_edi_invoice_header
       SET invoicenumber = invoicenumber || 'CM'
     WHERE importbatchid = param_ImportBatchID
       AND trim(creditdebitflag) = 'C'
       AND invoicenumber not like '%CM'
       AND status_no = 1;*/
  
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateCMInvoiceNo', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateCMInvoiceNo', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE ValidateIncomingStagingData(param_ImportBatchID IN NUMBER) IS
  
    CURSOR get_staging_header IS
      SELECT DISTINCT invoicenumber,
                      vendordunsnumber,
                      importbatchid,
                      receiverslocation,
                      shiptoduns
        FROM im_edi_invoice_header
       WHERE importbatchid = param_ImportBatchID
         AND status_no in (1, -1);
  
    CURSOR get_staging_detail IS
      SELECT DISTINCT invoicenumber, vendordunsnumber, importbatchid
        FROM im_edi_invoice_detail
       WHERE importbatchid = param_ImportBatchID
         AND status_no in (1, -1)
         AND productid IS NULL;
  
    /*  CURSOR get_creditinvoices IS
    SELECT DISTINCT invoicenumber,
                    vendordunsnumber,
                    importbatchid,
                    receiverslocation,
                    shiptoduns
      FROM im_edi_invoice_header
     WHERE importbatchid = param_ImportBatchID
       AND status_no in (1)
     AND creditdebitflag = 'C';*/
  
    loc_VendorDunsNumber  fouadres.FADACCI%TYPE;
    loc_ReceiversLocation NUMBER(5);
    loc_RowCount          NUMBER(5);
  
  BEGIN
    /*  FOR rec_get_creditinvoices IN get_creditinvoices LOOP
      UpdateStagingHeader(rec_get_creditinvoices.invoicenumber,
                          rec_get_creditinvoices.vendordunsnumber,
                          rec_get_creditinvoices.receiverslocation,
                          rec_get_creditinvoices.shiptoduns,
                          rec_get_creditinvoices.importbatchid,
                          2,
                          'Credit Invoice');
      UpdateStagingDetail(rec_get_creditinvoices.invoicenumber,
                          rec_get_creditinvoices.vendordunsnumber,
                          NULL,
                          rec_get_creditinvoices.importbatchid,
                          2,
                          'Credit Invoice');
    END LOOP;*/
  
    FOR rec_get_staging_header IN get_staging_header LOOP
    
      IF rec_get_staging_header.invoicenumber IS NULL THEN
        glo_Section := 'Validate invoicenumber';
        UpdateStagingHeader(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            rec_get_staging_header.receiverslocation,
                            rec_get_staging_header.shiptoduns,
                            rec_get_staging_header.importbatchid,
                            -1,
                            'Invoicenumber is null');
        UpdateStagingDetail(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            NULL,
                            rec_get_staging_header.importbatchid,
                            -1,
                            'Invoicenumber is null');
        UpdateStagingItDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             NULL,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             -1,
                             'Invoicenumber is null');
        UpdateStagingFtDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             -1,
                             'Invoicenumber is null');
      END IF;
    
      BEGIN
        SELECT FADACCI
          INTO loc_VendorDunsNumber
          FROM fouadres
         WHERE FADACCI = rec_get_staging_header.vendordunsnumber;
      EXCEPTION
        WHEN OTHERS THEN
          loc_VendorDunsNumber := '-1';
      END;
    
      IF rec_get_staging_header.vendordunsnumber IS NULL OR
         loc_VendorDunsNumber = '-1' THEN
        glo_Section := 'Validate vendordunsnumber';
        UpdateStagingHeader(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            rec_get_staging_header.receiverslocation,
                            rec_get_staging_header.shiptoduns,
                            rec_get_staging_header.importbatchid,
                            -1,
                            'Vendornumber is null/invalid');
        UpdateStagingDetail(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            NULL,
                            rec_get_staging_header.importbatchid,
                            -1,
                            'Vendornumber is null/invalid');
        UpdateStagingItDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             NULL,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             -1,
                             'Vendornumber is null/invalid');
        UpdateStagingFtDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             -1,
                             'Vendornumber is null/invalid');
      END IF;
    
      loc_ReceiversLocation := getSite(rec_get_staging_header.receiverslocation,
                                       rec_get_staging_header.shiptoduns);
    
      IF loc_ReceiversLocation = -1 THEN
        glo_Section := 'Validate Location';
        UpdateStagingHeader(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            rec_get_staging_header.receiverslocation,
                            rec_get_staging_header.shiptoduns,
                            rec_get_staging_header.importbatchid,
                            -1,
                            'Location is null/invalid');
        UpdateStagingDetail(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            NULL,
                            rec_get_staging_header.importbatchid,
                            -1,
                            'Location is null/invalid');
        UpdateStagingItDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             NULL,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             -1,
                             'Location is null/invalid');
        UpdateStagingFtDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             -1,
                             'Location is null/invalid');
      END IF;
    
      loc_RowCount := 0;
      SELECT COUNT(*)
        INTO loc_RowCount
        FROM cfdenfac, fouadres
       WHERE efarfou = rec_get_staging_header.invoicenumber
            --AND efasite = loc_ReceiversLocation
         AND efacfin = fadcfin
         AND FADACCI = rec_get_staging_header.vendordunsnumber;
    
      IF loc_RowCount > 0 THEN
        glo_Section := 'Check Invoice Already Exists';
        UpdateStagingHeader(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            rec_get_staging_header.receiverslocation,
                            rec_get_staging_header.shiptoduns,
                            rec_get_staging_header.importbatchid,
                            3,
                            'Invoice already exists in GOLD');
        UpdateStagingDetail(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            NULL,
                            rec_get_staging_header.importbatchid,
                            3,
                            'Invoice already exists in GOLD');
        UpdateStagingItDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             NULL,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             3,
                             'Invoice already exists in GOLD');
        UpdateStagingFtDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             3,
                             'Invoice already exists in GOLD');
      
      END IF;
    
      -- The below scenerio(Data found in Inv header but NO reception) will be reprocessed automatically
    
      loc_RowCount := 0;
      SELECT COUNT(*)
        INTO loc_RowCount
        FROM intcfinv, intcfbl, fouadres, foudgene
       WHERE cfiinvid = rec_get_staging_header.invoicenumber
         AND FADACCI = rec_get_staging_header.vendordunsnumber
         AND fadcfin = foucfin
         AND cfiinvid = cfbinvid
         AND cficfex = cfbcfex
         AND cficfex = foucnuf
         AND NOT EXISTS (SELECT 1
                FROM stoentre
               WHERE serbliv = cfbblid
                 AND sercfin = foucfin
              /*AND cfisite = loc_ReceiversLocation*/
              )
         AND NOT EXISTS
       (SELECT 1
                FROM INTCFART
               WHERE cfainvid = rec_get_staging_header.invoicenumber
                 AND cfacfin = foucfin)
         AND NOT EXISTS
       (SELECT 1
                FROM cfdenfac
               WHERE efarfou = rec_get_staging_header.invoicenumber
                 AND efacfin = foucfin);
    
      IF loc_RowCount > 0 THEN
        glo_Section := 'Check DN';
        UpdateStagingHeader(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            rec_get_staging_header.receiverslocation,
                            rec_get_staging_header.shiptoduns,
                            rec_get_staging_header.importbatchid,
                            1,
                            'DN Not Found');
        UpdateStagingDetail(rec_get_staging_header.invoicenumber,
                            rec_get_staging_header.vendordunsnumber,
                            NULL,
                            rec_get_staging_header.importbatchid,
                            1,
                            'DN Not Found');
        UpdateStagingItDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             NULL,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             1,
                             'DN Not Found');
        UpdateStagingFtDeals(rec_get_staging_header.invoicenumber,
                             rec_get_staging_header.vendordunsnumber,
                             rec_get_staging_header.importbatchid,
                             NULL,
                             1,
                             'DN Not Found');
      
      END IF;
    
    END LOOP;
    COMMIT;
  
    FOR rec_get_staging_detail IN get_staging_detail LOOP
      glo_Section := 'Item UPC null';
      UpdateStagingHeader(rec_get_staging_detail.invoicenumber,
                          rec_get_staging_detail.vendordunsnumber,
                          NULL,
                          NULL,
                          rec_get_staging_detail.importbatchid,
                          -1,
                          'UPC null');
      UpdateStagingDetail(rec_get_staging_detail.invoicenumber,
                          rec_get_staging_detail.vendordunsnumber,
                          NULL,
                          rec_get_staging_detail.importbatchid,
                          -1,
                          'UPC null');
      UpdateStagingItDeals(rec_get_staging_detail.invoicenumber,
                           rec_get_staging_detail.vendordunsnumber,
                           NULL,
                           rec_get_staging_detail.importbatchid,
                           NULL,
                           -1,
                           'UPC null');
      UpdateStagingFtDeals(rec_get_staging_detail.invoicenumber,
                           rec_get_staging_detail.vendordunsnumber,
                           rec_get_staging_detail.importbatchid,
                           NULL,
                           -1,
                           'UPC null');
    END LOOP;
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ValidateIncomingStagingData', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ValidateIncomingStagingData', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE UpdateInvoiceStatus(param_ImportBatchID NUMBER) IS
  
    CURSOR getIncorrectEDIInvoices IS
      SELECT distinct cfiinvid, cficfin
        FROM intcfinv, intcfbl, im_edi_invoice_header, fouadres
       WHERE cfiinvid = cfbinvid
         AND cficfin = cfbcfin
            --kan04152015-remove the filter
            -- AND cfiutil = const_UTIL
         AND cfistat <> 9
         AND cficfin = fadcfin
         AND fadacci = vendordunsnumber
         AND cfiinvid = invoicenumber
         AND importbatchid = param_ImportBatchID
            -- Reception found
         AND EXISTS (SELECT 1 FROM stoentre WHERE serbliv = cfbblid)
            -- Check for EDI Vendors 
         AND EXISTS (SELECT 1
                FROM lienserv
               WHERE liscfin = cficfin
                 AND lisccin = cficcin
                 AND trunc(sysdate) between lisddeb and lisdfin
                 AND liscomf in (9, 10))
            -- Invoice detail not found OR Invoice detail is partially interfaced     
         AND NOT EXISTS
       (SELECT 1
                FROM intcfart
               WHERE cfainvid = cfiinvid
                 AND cfacfin = cficfin
                    --AND cfautil = cfiutil
                 AND cfablid = cfbblid
                 AND NOT EXISTS
               (SELECT 1
                        FROM im_edi_invoice_detail det, fouadres
                       WHERE det.invoicenumber = cfainvid
                         AND det.vendordunsnumber = fadacci
                         AND fadcfin = cficfin
                         and det.importbatchid = param_ImportBatchID
                         AND status_no <> 2 /*
                                                                                                                 AND filename = cfifich*/
                      ))
            --Should not exists in GOLD               
         AND NOT EXISTS (SELECT 1
                FROM CFDENFAC
               WHERE efarfou = cfiinvid
                 AND efacfin = cficfin);
  
  BEGIN
  
    FOR rec_getIncorrectEDIInvoices IN getIncorrectEDIInvoices LOOP
      UPDATE intcfinv
         SET cfistat = 9, cfidmaj = sysdate
       WHERE cfiinvid = rec_getIncorrectEDIInvoices.cfiinvid
         AND cficfin = rec_getIncorrectEDIInvoices.cficfin;
    
      UPDATE im_edi_invoice_header
         SET status_no = -1
       WHERE invoicenumber = rec_getIncorrectEDIInvoices.cfiinvid
         AND vendordunsnumber =
             (select fadacci
                from fouadres
               where fadcfin = rec_getIncorrectEDIInvoices.cficfin);
    
    END LOOP;
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'PKG_UpdateInvoiceStatus', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'PKG_UpdateInvoiceStatus', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE ValidateInterfaceData(param_invoicenumber cfdenfac.efarfou%TYPE,
                                  param_vendorextcode foudgene.foucnuf%TYPE) IS
  
    loc_RowCount NUMBER(3);
  
  BEGIN
    loc_RowCount := 0;
    glo_Section  := param_invoicenumber;
    SELECT COUNT(*)
      INTO loc_RowCount
      FROM INTCFINV
     WHERE cfiinvid = param_invoicenumber
       AND cficcex = param_vendorextcode
          -- AND cfisite = param_site
       AND cfistat = const_INTERFACESTATUS
       AND cfiutil = const_UTIL
       AND EXISTS (SELECT 1
              FROM intcfbl
             WHERE cfbinvid = param_invoicenumber
               AND cfbcfex = param_vendorextcode
               AND cfbstat = const_INTERFACESTATUS)
       AND NOT EXISTS (SELECT 1
              FROM intcfart
             WHERE cfainvid = param_invoicenumber
               AND cfacfex = param_vendorextcode
               AND cfastat = const_INTERFACESTATUS);
  
    IF loc_RowCount > 0 THEN
      /* DELETE FROM INTCFINV
       WHERE cfiinvid = param_invoicenumber
         AND cficcex = param_vendorextcode;
      DELETE FROM INTCFBL
       WHERE cfbinvid = param_invoicenumber
         AND cfbcfex = param_vendorextcode;*/
      DELETE FROM INTCFART
       WHERE cfainvid = param_invoicenumber
         AND cfacfex = param_vendorextcode;
      DELETE FROM INTCFREMISE
       WHERE cfrinvid = param_invoicenumber
         AND cfrcfex = param_vendorextcode;
      DELETE FROM INTCFPIED
       WHERE cfpinvid = param_invoicenumber
         AND cfpcfex = param_vendorextcode;
      COMMIT;
    END IF;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ValidateInterfaceData', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'ValidateInterfaceData', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  -- To move the data from Oracle staging tables to Interface tables
  PROCEDURE LoadInterfaceTables(param_ImportBatchID IN NUMBER) IS
  
    -- To get the list of invoices with receptions on the current batch(records should be found in INTCFINV,INTCFBL)
    CURSOR get_invoices_with_recep IS
      SELECT invoicenumber,
             invoicedate,
             totalinvoiceamount,
             termsdiscountpercent,
             termsdiscountdate,
             termsdiscountdays,
             termsnetdays,
             termsnetduedate,
             termsdiscountamount,
             vendordunsnumber,
             receiverslocation,
             importbatchid,
             shiptoduns,
             filename,
             sercfin,
             serccin,
             sersite,
             sercincde,
             sercexcde,
             serfilf,
             cfbcfex,
             cficcex,
             serbliv,
             nvl(trim(creditdebitflag), 'D') creditdebitflag
        FROM im_edi_invoice_header,
             intcfinv,
             intcfbl,
             stoentre,
             fouadres,
             foudgene
       WHERE invoicenumber = cfbinvid
            --AND cficfin = cfbcfin
         AND cficfex = cfbcfex
         AND cficfex = foucnuf
         AND cfbinvid = cfiinvid
         AND sercfin = foucfin
         AND serbliv = cfbblid
         AND FADACCI = vendordunsnumber
         AND fadcfin = sercfin
         AND importbatchid = param_ImportBatchID
         AND status_no in (1, -1)
         AND sertmvt = 1
         AND trim(creditdebitflag) <> 'C'
      --AND invoicenumber = '67361505CM'
      
      UNION
      
      SELECT invoicenumber,
             invoicedate,
             totalinvoiceamount,
             termsdiscountpercent,
             termsdiscountdate,
             termsdiscountdays,
             termsnetdays,
             termsnetduedate,
             termsdiscountamount,
             vendordunsnumber,
             receiverslocation,
             importbatchid,
             shiptoduns,
             filename,
             sercfin,
             serccin,
             sersite,
             sercincde,
             sercexcde,
             serfilf,
             cfbcfex,
             cficcex,
             serbliv,
             nvl(trim(creditdebitflag), 'D') creditdebitflag
        FROM im_edi_invoice_header,
             intcfinv,
             intcfbl,
             stoentre,
             fouadres,
             foudgene
       WHERE (invoicenumber = cfbinvid || 'CM' OR invoicenumber = cfbinvid)
            --AND cficfin = cfbcfin
         AND cficfex = cfbcfex
         AND cficfex = foucnuf
         AND cfbinvid = cfiinvid
         AND sercfin = foucfin
         AND serbliv = cfbblid
         AND FADACCI = vendordunsnumber
         AND fadcfin = sercfin
         AND importbatchid = param_ImportBatchID
         AND status_no in (1, -1)
         AND sertmvt = 2
         AND trim(creditdebitflag) = 'C';
    --AND (creditdebitflag <> 'C' OR creditdebitflag IS NULL);
  
    -- To get the list of invoices without receptions on the current batch  
    /* CURSOR get_invoices_without_recep IS
    SELECT invoicenumber,
           invoicedate,
           ponumber,
           vendordunsnumber,
           importbatchid,
           shiptoduns,
           totalinvoiceamount,
           termsdiscountpercent,
           termsdiscountdate,
           termsdiscountdays,
           termsnetdays,
           termsnetduedate,
           termsdiscountamount,
           filename,
           receiverslocation
      FROM im_edi_invoice_header
     WHERE NOT EXISTS (SELECT 1
              FROM stoentre, intcfinv, intcfbl, fouadres
             WHERE serbliv = cfbblid
               AND cfiinvid = cfbinvid
               AND cficfin = sercfin
               AND cfbinvid = invoicenumber
               AND FADACCI = vendordunsnumber
               AND sercfin = fadcfin
               AND cfbcfin = fadcfin)
       AND NOT EXISTS (SELECT 1
              FROM cfdenfac, fouadres
             WHERE efarfou = invoicenumber
               AND FADACCI = vendordunsnumber
               AND fadcfin = efacfin)
       AND importbatchid = param_ImportBatchID
       AND status_no = 1;*/
  
    loc_InsertORUpdateFlag NUMBER(1) := 0;
    loc_CheckReceptionFlag NUMBER(1) := 0;
    --loc_DeliveryNoteNumber stoentre.serbliv%TYPE;
    --loc_SupplierIntCode    foudgene.foucfin%TYPE;
    --loc_SupplierExtCode    foudgene.foucnuf%TYPE;
    --loc_CommContIntCode    fouccom.fccccin%TYPE;
    --loc_CommContExtCode    fouccom.fccnum%TYPE;
    --loc_AddressChain       stoentre.serfilf%TYPE;
    --loc_Site               stoentre.sersite%TYPE;
    loc_itemdeal_count    NUMBER(3);
    loc_ftdeal_count      NUMBER(3);
    loc_footerdeal_exists NUMBER(1);
    --loc_ErrFlag            NUMBER(1);
    loc_item_exists NUMBER(3);
  
  BEGIN
  
    glo_Section := 'CallUpdateInvoiceNo';
    PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateInvoiceNo', glo_Section);
    UpdateInvoiceNo;
  
    glo_Section := 'ValidateStagingData';
    ValidateIncomingStagingData(param_ImportBatchID);
  
    --loc_ErrFlag        := 0;
    loc_itemdeal_count := 0;
    loc_ftdeal_count   := 0;
    loc_item_exists    := 0;
    -- Interfacing the invoices with receptions on the current batch
    FOR rec_invoices_with_recep IN get_invoices_with_recep LOOP
      glo_Section := 'Inv with rec loop starts:' ||
                     rec_invoices_with_recep.invoicenumber;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadInterfaceTables', glo_Section);
      loc_CheckReceptionFlag := 1;
      loc_InsertORUpdateFlag := 2;
      loc_footerdeal_exists  := 0;
    
      SELECT COUNT(*)
        INTO loc_itemdeal_count
        FROM im_edi_invoice_itemdeals
       WHERE invoicenumber = rec_invoices_with_recep.invoicenumber
         AND vendordunsnumber = rec_invoices_with_recep.vendordunsnumber;
    
      SELECT COUNT(*)
        INTO loc_ftdeal_count
        FROM im_edi_invoice_ftdeals
       WHERE invoicenumber = rec_invoices_with_recep.invoicenumber
         AND vendordunsnumber = rec_invoices_with_recep.vendordunsnumber;
    
      IF loc_ftdeal_count > 0 THEN
        loc_footerdeal_exists := 1;
      END IF;
    
      glo_Section := 'LoadIntcfinv-1';
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      LoadIntcfinv(rec_invoices_with_recep.vendordunsnumber,
                   rec_invoices_with_recep.receiverslocation,
                   rec_invoices_with_recep.shiptoduns,
                   rec_invoices_with_recep.importbatchid,
                   rec_invoices_with_recep.invoicenumber,
                   rec_invoices_with_recep.invoicedate,
                   rec_invoices_with_recep.totalinvoiceamount,
                   rec_invoices_with_recep.termsdiscountpercent,
                   rec_invoices_with_recep.termsdiscountdate,
                   --rec_invoices_with_recep.termsdiscountdays,
                   --rec_invoices_with_recep.termsnetdays,
                   rec_invoices_with_recep.termsnetduedate,
                   rec_invoices_with_recep.termsdiscountamount,
                   rec_invoices_with_recep.sercfin,
                   rec_invoices_with_recep.serccin,
                   rec_invoices_with_recep.sersite,
                   rec_invoices_with_recep.sercincde,
                   rec_invoices_with_recep.sercexcde,
                   rec_invoices_with_recep.serfilf,
                   rec_invoices_with_recep.cfbcfex,
                   rec_invoices_with_recep.cficcex,
                   rec_invoices_with_recep.filename,
                   loc_InsertORUpdateFlag,
                   --loc_CheckReceptionFlag,
                   loc_footerdeal_exists,
                   rec_invoices_with_recep.creditdebitflag);
    
      glo_Section := 'LoadIntcfbl-1';
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_InsertORUpdateFlag := 2;
      LoadIntcfbl(rec_invoices_with_recep.invoicenumber,
                  rec_invoices_with_recep.totalinvoiceamount,
                  rec_invoices_with_recep.sercfin,
                  rec_invoices_with_recep.cfbcfex,
                  rec_invoices_with_recep.sersite,
                  -- rec_invoices_with_recep.sercincde,
                  --  rec_invoices_with_recep.sercexcde,
                  rec_invoices_with_recep.filename,
                  rec_invoices_with_recep.serbliv,
                  loc_InsertORUpdateFlag,
                  rec_invoices_with_recep.creditdebitflag
                  -- loc_CheckReceptionFlag
                  );
    
      glo_Section := 'LoadIntcfart-1';
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_InsertORUpdateFlag := 1;
      LoadIntcfart(rec_invoices_with_recep.vendordunsnumber,
                   rec_invoices_with_recep.importbatchid,
                   rec_invoices_with_recep.invoicenumber,
                   rec_invoices_with_recep.sercfin,
                   rec_invoices_with_recep.cfbcfex,
                   rec_invoices_with_recep.sersite,
                   -- rec_invoices_with_recep.sercincde,
                   -- rec_invoices_with_recep.sercexcde,
                   rec_invoices_with_recep.filename,
                   rec_invoices_with_recep.serbliv,
                   rec_invoices_with_recep.serccin,
                   rec_invoices_with_recep.creditdebitflag
                   --rec_invoices_with_recep.cficcex
                   --loc_InsertORUpdateFlag,
                   -- loc_CheckReceptionFlag
                   );
    
      SELECT COUNT(*)
        INTO loc_item_exists
        FROM intcfart
       WHERE cfainvid = rec_invoices_with_recep.invoicenumber
         AND cfacfex = rec_invoices_with_recep.cfbcfex
         AND cfablid = rec_invoices_with_recep.serbliv
         AND cfastat = const_INTERFACESTATUS;
    
      IF loc_itemdeal_count > 0 AND loc_item_exists > 0 AND
         rec_invoices_with_recep.creditdebitflag <> 'C' THEN
        glo_Section := 'LoadIntcfremise-1';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        loc_InsertORUpdateFlag := 1;
        LoadIntcfremise(rec_invoices_with_recep.vendordunsnumber,
                        rec_invoices_with_recep.importbatchid,
                        rec_invoices_with_recep.invoicenumber,
                        rec_invoices_with_recep.sercfin,
                        rec_invoices_with_recep.cfbcfex,
                        rec_invoices_with_recep.sersite,
                        -- rec_invoices_with_recep.sercincde,
                        -- rec_invoices_with_recep.sercexcde,
                        rec_invoices_with_recep.filename,
                        rec_invoices_with_recep.serbliv,
                        rec_invoices_with_recep.serccin,
                        rec_invoices_with_recep.creditdebitflag
                        -- loc_CommContExtCode
                        -- loc_InsertORUpdateFlag,
                        -- loc_CheckReceptionFlag
                        );
      END IF;
    
      IF loc_ftdeal_count > 0 AND loc_item_exists > 0 AND
         rec_invoices_with_recep.creditdebitflag <> 'C' THEN
        glo_Section := 'LoadIntcfpied-1';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        loc_InsertORUpdateFlag := 1;
        LoadIntcfpied(rec_invoices_with_recep.vendordunsnumber,
                      rec_invoices_with_recep.importbatchid,
                      rec_invoices_with_recep.invoicenumber,
                      rec_invoices_with_recep.sercfin,
                      rec_invoices_with_recep.cfbcfex,
                      rec_invoices_with_recep.sersite,
                      -- rec_invoices_with_recep.sercincde,
                      -- rec_invoices_with_recep.sercexcde,
                      rec_invoices_with_recep.filename,
                      rec_invoices_with_recep.serbliv,
                      --  loc_CommContIntCode,
                      rec_invoices_with_recep.cficcex,
                      rec_invoices_with_recep.creditdebitflag
                      --loc_InsertORUpdateFlag,
                      --loc_CheckReceptionFlag
                      );
      END IF;
    
      glo_Section := 'Inv with rec loop ends:' ||
                     rec_invoices_with_recep.invoicenumber;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadInterfaceTables', glo_Section);
      COMMIT;
    
      glo_Section := 'UpdateInvoiceStatus:';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateInvoiceStatus', 'start');
      UpdateInvoiceStatus(rec_invoices_with_recep.importbatchid);
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateInvoiceStatus', 'end');
    
    /* glo_Section := 'ValidateInterfaceData:' ||
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                     rec_invoices_with_recep.invoicenumber;
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      PKERREURS.FC_ERREUR('ValidateInterfaceData', glo_Section);
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                      ValidateInterfaceData(rec_invoices_with_recep.invoicenumber,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            rec_invoices_with_recep.cfbcfex,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                            rec_invoices_with_recep.sersite);*/
    
    END LOOP;
  
    /* loc_item_exists := 0;
    FOR rec_invoices_without_recep IN get_invoices_without_recep LOOP
      glo_Section := 'Inv without rec loop starts:' ||
                     rec_invoices_without_recep.invoicenumber;
      PKERREURS.FC_ERREUR('LoadInterfaceTables', glo_Section);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_CheckReceptionFlag := 2;
      --loc_InsertORUpdateFlag := 2;
      loc_footerdeal_exists := 0;
    
      SELECT COUNT(*)
        INTO loc_itemdeal_count
        FROM im_edi_invoice_itemdeals
       WHERE invoicenumber = rec_invoices_without_recep.invoicenumber
         AND vendordunsnumber = rec_invoices_without_recep.vendordunsnumber;
    
      SELECT COUNT(*)
        INTO loc_ftdeal_count
        FROM im_edi_invoice_ftdeals
       WHERE invoicenumber = rec_invoices_without_recep.invoicenumber
         AND vendordunsnumber = rec_invoices_without_recep.vendordunsnumber;
    
      IF loc_ftdeal_count > 0 THEN
        loc_footerdeal_exists := 1;
      END IF;
    
      BEGIN
        glo_Section := 'Find Supp for duns:' ||
                       rec_invoices_without_recep.vendordunsnumber;
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        SELECT fadcfin, foucnuf
          INTO loc_SupplierIntCode, loc_SupplierExtCode
          FROM fouadres, foudgene
         WHERE foucfin = fadcfin
           AND FADACCI = rec_invoices_without_recep.vendordunsnumber;
      
        glo_Section := 'Find Site:' ||
                       rec_invoices_without_recep.receiverslocation;
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        loc_Site := getSite(rec_invoices_without_recep.receiverslocation,
                            rec_invoices_without_recep.shiptoduns);
      
        glo_Section := 'Find DeliveryNote';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        SELECT deliv_note.nextval
          INTO loc_DeliveryNoteNumber
          FROM DUAL;
      
        glo_Section := 'Find CommCont for supp:' || loc_SupplierExtCode ||
                       ' duns:' ||
                       rec_invoices_without_recep.vendordunsnumber ||
                       'site:' || loc_Site;
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        SELECT Temp.CommContract
          INTO loc_CommContIntCode
          FROM (SELECT nvl(getCommContNumber(loc_SupplierIntCode,
                                             getSeqvl(NULL, productid, NULL),
                                             loc_Site),
                           0) CommContract,
                       COUNT(*) COUNT
                  FROM im_edi_invoice_header hd, im_edi_invoice_detail det
                 WHERE hd.invoicenumber = det.invoicenumber
                   AND hd.vendordunsnumber = det.vendordunsnumber
                   AND hd.invoicenumber =
                       rec_invoices_without_recep.invoicenumber
                   AND hd.vendordunsnumber =
                       rec_invoices_without_recep.vendordunsnumber
                 GROUP BY nvl(getCommContNumber(loc_SupplierIntCode,
                                                getSeqvl(NULL,
                                                         productid,
                                                         NULL),
                                                loc_Site),
                              0)) Temp
         WHERE Temp.COUNT =
               (SELECT MAX(COUNT)
                  FROM (SELECT nvl(getCommContNumber(loc_SupplierIntCode,
                                                     getSeqvl(NULL,
                                                              productid,
                                                              NULL),
                                                     loc_Site),
                                   0) CommContract,
                               COUNT(*) COUNT
                          FROM im_edi_invoice_header hd,
                               im_edi_invoice_detail det
                         WHERE hd.invoicenumber = det.invoicenumber
                           AND hd.vendordunsnumber = det.vendordunsnumber
                           AND hd.invoicenumber =
                               rec_invoices_without_recep.invoicenumber
                           AND hd.vendordunsnumber =
                               rec_invoices_without_recep.vendordunsnumber
                         GROUP BY nvl(getCommContNumber(loc_SupplierIntCode,
                                                        getSeqvl(NULL,
                                                                 productid,
                                                                 NULL),
                                                        loc_Site),
                                      0)
                        having nvl(getCommContNumber(loc_SupplierIntCode, getSeqvl(NULL, productid, NULL), loc_Site), 0) > 0))
           AND ROWNUM = 1;
      
        glo_Section := 'Find CommContractExt:' || loc_CommContIntCode;
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        SELECT fccnum
          INTO loc_CommContExtCode
          FROM fouccom
         WHERE fccccin = loc_CommContIntCode;
      
        glo_Section := 'Find AddCh:' || loc_SupplierIntCode || ',' ||
                       loc_CommContIntCode || ',' || loc_Site;
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        SELECT aranfilf
          INTO loc_AddressChain
          FROM artuc
         WHERE aracfin = loc_SupplierIntCode
           AND araccin = loc_CommContIntCode
           AND (ARASITE = loc_Site OR
               ARASITE IN
               (SELECT RELPERE
                   FROM RESREL, RESOBJ
                  WHERE TRUNC(SYSDATE) BETWEEN ARADDEB AND ARADFIN
                    AND RELPERE = ROBID
                 CONNECT BY PRIOR RELPERE = RELID
                  START WITH RELID = loc_Site))
           AND rownum <= 1;
      
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          glo_ErrMessage := 'NoDataFound' || ':' || glo_Section;
          PKERREURS.FC_ERREUR('LoadInterfaceTables', glo_ErrMessage);
          IF glo_DebugFlag = 1 THEN
            dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                                 SQLCODE);
          END IF;
          loc_ErrFlag := 1;
        WHEN OTHERS THEN
          glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
          PKERREURS.FC_ERREUR('LoadInterfaceTables', glo_ErrMessage);
          glo_ErrMessage := 'Failure' || ':' || glo_Section;
          PKERREURS.FC_ERREUR('LoadInterfaceTables', glo_ErrMessage);
          IF glo_DebugFlag = 1 THEN
            dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                                 SQLCODE);
          END IF;
          loc_ErrFlag := 1;
      END;
    
      IF loc_ErrFlag = 0 THEN
      
        glo_Section := 'LoadIntcfinv-2';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        loc_InsertORUpdateFlag := 1;
        LoadIntcfinv(rec_invoices_without_recep.vendordunsnumber,
                     rec_invoices_without_recep.receiverslocation,
                     rec_invoices_without_recep.shiptoduns,
                     rec_invoices_without_recep.importbatchid,
                     rec_invoices_without_recep.invoicenumber,
                     rec_invoices_without_recep.invoicedate,
                     rec_invoices_without_recep.totalinvoiceamount,
                     rec_invoices_without_recep.termsdiscountpercent,
                     rec_invoices_without_recep.termsdiscountdate,
                     --  rec_invoices_without_recep.termsdiscountdays,
                     --  rec_invoices_without_recep.termsnetdays,
                     rec_invoices_without_recep.termsnetduedate,
                     rec_invoices_without_recep.termsdiscountamount,
                     loc_SupplierIntCode,
                     loc_CommContIntCode,
                     loc_Site,
                     NULL,
                     NULL,
                     loc_AddressChain, -- address chain
                     loc_SupplierExtCode,
                     loc_CommContExtCode,
                     rec_invoices_without_recep.filename,
                     loc_InsertORUpdateFlag,
                     -- loc_CheckReceptionFlag,
                     loc_footerdeal_exists);
      
        glo_Section := 'LoadIntcfbl-2';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
        loc_InsertORUpdateFlag := 1;
        LoadIntcfbl(rec_invoices_without_recep.invoicenumber,
                    rec_invoices_without_recep.totalinvoiceamount,
                    loc_SupplierIntCode,
                    loc_SupplierExtCode,
                    loc_Site,
                    --  NULL,
                    --  NULL,
                    rec_invoices_without_recep.filename,
                    loc_DeliveryNoteNumber, -- Delivery note number  
                    loc_InsertORUpdateFlag
                    --  loc_CheckReceptionFlag
                    );
      
        glo_Section := 'LoadIntcfart-2';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
      
        loc_InsertORUpdateFlag := 1;
        LoadIntcfart(rec_invoices_without_recep.vendordunsnumber,
                     rec_invoices_without_recep.importbatchid,
                     rec_invoices_without_recep.invoicenumber,
                     loc_SupplierIntCode,
                     loc_SupplierExtCode,
                     loc_Site,
                     --  NULL,
                     --  NULL,
                     rec_invoices_without_recep.filename,
                     loc_DeliveryNoteNumber, -- Delivery note number  
                     loc_CommContIntCode
                     --loc_CommContExtCode
                     --  loc_InsertORUpdateFlag,
                     -- loc_CheckReceptionFlag
                     );
      
        SELECT COUNT(*)
          INTO loc_item_exists
          FROM intcfart
         WHERE cfainvid = rec_invoices_without_recep.invoicenumber
           AND cfacfex = loc_SupplierExtCode
           AND cfablid = loc_DeliveryNoteNumber
           AND cfastat = const_INTERFACESTATUS;
      
        IF loc_itemdeal_count > 0 AND loc_item_exists > 0 THEN
          glo_Section := 'LoadIntcfremise-2';
          IF glo_DebugFlag = 1 THEN
            dbms_output.put_line(glo_Section);
          END IF;
        
          loc_InsertORUpdateFlag := 1;
          LoadIntcfremise(rec_invoices_without_recep.vendordunsnumber,
                          rec_invoices_without_recep.importbatchid,
                          rec_invoices_without_recep.invoicenumber,
                          loc_SupplierIntCode,
                          loc_SupplierExtCode,
                          loc_Site,
                          --NULL,
                          --NULL,
                          rec_invoices_without_recep.filename,
                          loc_DeliveryNoteNumber,
                          loc_CommContIntCode
                          -- loc_CommContExtCode,
                          -- loc_InsertORUpdateFlag,
                          -- loc_CheckReceptionFlag
                          );
        END IF;
      
        IF loc_ftdeal_count > 0 AND loc_item_exists > 0 THEN
          glo_Section := 'LoadIntcfpied-2';
          IF glo_DebugFlag = 1 THEN
            dbms_output.put_line(glo_Section);
          END IF;
          loc_InsertORUpdateFlag := 1;
          LoadIntcfpied(rec_invoices_without_recep.vendordunsnumber,
                        rec_invoices_without_recep.importbatchid,
                        rec_invoices_without_recep.invoicenumber,
                        loc_SupplierIntCode,
                        loc_SupplierExtCode,
                        loc_Site,
                        --  NULL,
                        --  NULL,
                        rec_invoices_without_recep.filename,
                        loc_DeliveryNoteNumber,
                        --   loc_CommContIntCode,
                        loc_CommContExtCode
                        -- loc_InsertORUpdateFlag,
                        --   loc_CheckReceptionFlag
                        );
        END IF;
        glo_Section := 'Inv without rec loop ends:' ||
                       rec_invoices_without_recep.invoicenumber;
        PKERREURS.FC_ERREUR('LoadInterfaceTables', glo_Section);
        COMMIT;
      END IF;
    
      ValidateInterfaceData(rec_invoices_without_recep.invoicenumber,
                            loc_SupplierExtCode,
                            loc_Site);
    
    END LOOP;*/
  
    --not used
    /*
    IF loc_ErrFlag = 0 THEN
      FOR rec_get_invoices_not_treated IN get_invoices_not_treated LOOP
        glo_Section := 'Invoices not treated';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section || ':' ||
                               rec_get_invoices_not_treated.invoicenumber);
        END IF;
        UpdateStagingHeader(rec_get_invoices_not_treated.invoicenumber,
                            rec_get_invoices_not_treated.vendordunsnumber,
                            rec_get_invoices_not_treated.receiverslocation,
                            rec_get_invoices_not_treated.shiptoduns,
                            rec_get_invoices_not_treated.importbatchid,
                            1,
                            'Invoice header not found');
        UpdateStagingDetail(rec_get_invoices_not_treated.invoicenumber,
                            rec_get_invoices_not_treated.vendordunsnumber,
                            NULL,
                            rec_get_invoices_not_treated.importbatchid,
                            1,
                            'Invoice header not found');
        UpdateStagingItDeals(rec_get_invoices_not_treated.invoicenumber,
                             rec_get_invoices_not_treated.vendordunsnumber,
                             NULL,
                             rec_get_invoices_not_treated.importbatchid,
                             NULL,
                             1,
                             'Invoice header not found');
        UpdateStagingFtDeals(rec_get_invoices_not_treated.invoicenumber,
                             rec_get_invoices_not_treated.vendordunsnumber,
                             rec_get_invoices_not_treated.importbatchid,
                             NULL,
                             1,
                             'Invoice header not found');
      
      END LOOP;
      COMMIT;
    
     FOR rec_invoice_det_not_treated IN get_invoice_det_not_treated LOOP
        glo_Section := 'Invoices det not treated';
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section || ':' ||
                               rec_invoice_det_not_treated.invoicenumber);
        END IF;
         UpdateStagingHeader(rec_invoice_det_not_treated.invoicenumber,
                            rec_invoice_det_not_treated.vendordunsnumber,
                            NULL,
                            NULL,
                            rec_get_invoices_not_treated.importbatchid,
                            1,
                            'DN not found');
        
        UpdateStagingDetail(rec_invoice_det_not_treated.invoicenumber,
                            rec_invoice_det_not_treated.vendordunsnumber,
                            rec_invoice_det_not_treated.productid,
                            rec_invoice_det_not_treated.importbatchid,
                            -1,
                            'DN not found');
      END LOOP;
      COMMIT;
    END IF;*/
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := ':' || SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadInterfaceTables', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadInterfaceTables', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(SQLERRM || ' : ' || SQLCODE);
      END IF;
  END;

  PROCEDURE LoadIntcfinv(param_VendorDunsNumber     fouadres.FADACCI%TYPE,
                         param_ReceiversLocation    VARCHAR2,
                         param_ShiptoDuns           VARCHAR2,
                         param_BatchID              NUMBER,
                         param_invoicenumber        cfdenfac.efarfou%TYPE,
                         param_invoicedate          cfdenfac.efadatf%TYPE,
                         param_totalinvoiceamount   cfdenfac.efamfac%TYPE,
                         param_termsdiscountpercent foucregl.FCRESCO%TYPE,
                         param_termsdiscountdate    cfdenfac.efadatf%TYPE,
                         --param_termsdiscountdays     foucregl.FCRNJESC%TYPE,
                         --param_termsnetdays          foucregl.FCRCRED%TYPE,
                         param_termsnetduedate     cfdenfac.efadatf%TYPE,
                         param_termsdiscountamount cfdenfac.efamfac%TYPE,
                         param_vendorintcode       cfdenfac.efacfin%TYPE,
                         param_commcontnum         cfdenfac.efaccin%TYPE,
                         param_site                cfdenfac.efasite%TYPE,
                         param_pointnumber         stoentre.sercincde%TYPE,
                         param_ponumber            cfdenfac.efacexcde%TYPE,
                         param_addresschain        cfdenfac.efafilf%TYPE,
                         param_vendorextcode       foudgene.foucnuf%TYPE,
                         param_commcontcode        fouccom.fccnum%TYPE,
                         param_FileName            VARCHAR2,
                         param_InsertORUpdateFlag  NUMBER,
                         --param_CheckReceptionFlag    NUMBER,
                         param_CheckFooterDealExists NUMBER,
                         param_creditdebitflag       VARCHAR2) IS
  
    loc_IntcfinvRecord intcfinv%ROWTYPE;
    loc_Invoicetype    NUMBER(3);
    loc_InvoiceAmount  NUMBER(15, 5);
    loc_InvoiceNumber  VARCHAR2(20);
  
  BEGIN
  
    loc_InvoiceAmount := 0;
  
    glo_Section := 'proc_LoadIntcfinv';
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(SQLERRM || ' : ' || SQLCODE);
    END IF;
  
    IF param_creditdebitflag = 'C' THEN
      loc_Invoicetype   := 2;
      loc_InvoiceAmount := -1 * abs(param_totalinvoiceamount);
      loc_InvoiceNumber := param_invoicenumber;
    ELSE
      loc_Invoicetype   := 1;
      loc_InvoiceAmount := param_totalinvoiceamount;
      loc_InvoiceNumber := param_invoicenumber;
    END IF;
  
    -- Override all the columns apart from the key fields
    IF param_InsertORUpdateFlag = 2 THEN
      glo_Section := 'Update Intcfinv:' || param_invoicenumber;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      IF loc_Invoicetype = 1 THEN      
        UPDATE intcfinv
           SET CFINCOM     = NULL,
               CFICEXCDE   = NULL,
               CFIDATE     = param_invoicedate,
               CFITYRP     = 1,
               CFITYPE     = loc_Invoicetype,
               CFIDEV      = 840,
               CFIDECH     = param_termsnetduedate,
               CFIDECHDEM  = param_termsdiscountdate,
               CFIMORP     = 2,
               CFIMOTF     = 1,
               CFINKRO     = NULL,
               CFIDKRO     = param_invoicedate,
               CFIIDEN     = '1',
               CFITVA      = 1,
               CFIMREG     = NULL,
               CFIDVAL     = NULL,
               CFIMFAC     = loc_InvoiceAmount,
               CFITOL      = 1,
               CFICASM     = param_termsdiscountamount,
               CFICASP     = param_termsdiscountpercent,
               CFICASD     = param_termsdiscountdate,
               CFICASB     = NULL,
               CFICASN     = NULL,
               CFIPAY      = NULL,
               CFIBKCD     = NULL,
               CFICFINF    = NULL,
               CFICCINF    = NULL,
               CFICFEXF    = NULL,
               CFICCEXF    = NULL,
               CFITYTRT    = 1, -- 0 - summary reconciliation,1-detailed reconciliation
               CFITYPTOL   = 0,
               CFIMFACEMBA = 0,
               CFIRECYCL   = NULL,
               CFIDFLGI    = 1,
               CFISTAT     = const_INTERFACESTATUS,
               CFIDTRT     = SYSDATE,
               CFIFICH     = substr(param_FileName, 1, 50),
               CFINLIG     = 1,
               CFINERR     = NULL,
               CFIMESS     = NULL,
               --CFIDCRE     = SYSDATE,
               CFIDMAJ     = SYSDATE,
               CFIUTIL     = const_UTIL,
               CFINFILF    = param_addresschain,
               CFINFILFF   = param_addresschain,
               CFINBFAC    = NULL,
               CFINUFAC    = NULL,
               CFICNPAY    = 0,
               CFIEMB      = 0,
               CFIREMA     = 1, -- Item level deals 
               CFIREMP     = param_CheckFooterDealExists, -- footer level check --1 or 1
               CFICASSAI   = 1,
               CFILINK     = NULL,
               CFILD       = NULL,
               CFIMOPAYREF = NULL,
               CFIPAYREF   = NULL,
               CFIQFAC     = NULL,
               CFIINVID    = loc_InvoiceNumber,
               CFICFIN     = param_vendorintcode,
               CFICCIN     = param_commcontnum
        -- CFISITE     = param_site
         WHERE CFIINVID = param_invoicenumber
           AND CFICFEX = param_vendorextcode
              --AND CFISITE = param_site
           AND CFICCEX = param_commcontcode
           AND CFITYPE = 1;
      
      ELSIF loc_Invoicetype = 2 THEN
        UPDATE intcfinv
           SET CFINCOM     = NULL,
               CFICEXCDE   = NULL,
               CFIDATE     = param_invoicedate,
               CFITYRP     = 1,
               CFITYPE     = loc_Invoicetype,
               CFIDEV      = 840,
               CFIDECH     = param_termsnetduedate,
               CFIDECHDEM  = param_termsdiscountdate,
               CFIMORP     = 2,
               CFIMOTF     = 1,
               CFINKRO     = NULL,
               CFIDKRO     = param_invoicedate,
               CFIIDEN     = '1',
               CFITVA      = 1,
               CFIMREG     = NULL,
               CFIDVAL     = NULL,
               CFIMFAC     = loc_InvoiceAmount,
               CFITOL      = 1,
               CFICASM     = param_termsdiscountamount,
               CFICASP     = param_termsdiscountpercent,
               CFICASD     = param_termsdiscountdate,
               CFICASB     = NULL,
               CFICASN     = NULL,
               CFIPAY      = NULL,
               CFIBKCD     = NULL,
               CFICFINF    = NULL,
               CFICCINF    = NULL,
               CFICFEXF    = NULL,
               CFICCEXF    = NULL,
               CFITYTRT    = 1, -- 0 - summary reconciliation,1-detailed reconciliation
               CFITYPTOL   = 0,
               CFIMFACEMBA = 0,
               CFIRECYCL   = NULL,
               CFIDFLGI    = 1,
               CFISTAT     = const_INTERFACESTATUS,
               CFIDTRT     = SYSDATE,
               CFIFICH     = substr(param_FileName, 1, 50),
               CFINLIG     = 1,
               CFINERR     = NULL,
               CFIMESS     = NULL,
               --CFIDCRE     = SYSDATE,
               CFIDMAJ     = SYSDATE,
               CFIUTIL     = const_UTIL,
               CFINFILF    = param_addresschain,
               CFINFILFF   = param_addresschain,
               CFINBFAC    = NULL,
               CFINUFAC    = NULL,
               CFICNPAY    = 0,
               CFIEMB      = 0,
               CFIREMA     = 1, -- Item level deals 
               CFIREMP     = param_CheckFooterDealExists, -- footer level check --1 or 1
               CFICASSAI   = 1,
               CFILINK     = NULL,
               CFILD       = NULL,
               CFIMOPAYREF = NULL,
               CFIPAYREF   = NULL,
               CFIQFAC     = NULL,
               CFIINVID    = loc_InvoiceNumber,
               CFICFIN     = param_vendorintcode,
               CFICCIN     = param_commcontnum
        -- CFISITE     = param_site
         WHERE (CFIINVID = param_invoicenumber OR
               CFIINVID || 'CM' = param_invoicenumber)
           AND CFICFEX = param_vendorextcode
              --AND CFISITE = param_site
           AND CFICCEX = param_commcontcode
           AND CFITYPE = 2;
      
      END IF;
    
    ELSIF param_InsertORUpdateFlag = 1 THEN
      glo_Section := 'Insert Intcfinv:' || param_invoicenumber;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfinvRecord.cficfin     := param_vendorintcode;
      loc_IntcfinvRecord.CFICCIN     := param_commcontnum;
      loc_IntcfinvRecord.CFICFEX     := param_vendorextcode;
      loc_IntcfinvRecord.CFICCEX     := param_commcontcode;
      loc_IntcfinvRecord.CFISITE     := 0; --param_site
      loc_IntcfinvRecord.CFIINVID    := loc_InvoiceNumber;
      loc_IntcfinvRecord.CFINCOM     := param_pointnumber;
      loc_IntcfinvRecord.CFICEXCDE   := param_ponumber;
      loc_IntcfinvRecord.CFIDATE     := param_invoicedate;
      loc_IntcfinvRecord.CFITYRP     := 1;
      loc_IntcfinvRecord.CFITYPE     := loc_Invoicetype;
      loc_IntcfinvRecord.CFIDEV      := 840;
      loc_IntcfinvRecord.CFIDECH     := param_termsnetduedate;
      loc_IntcfinvRecord.CFIDECHDEM  := param_termsdiscountdate;
      loc_IntcfinvRecord.CFIMORP     := 2;
      loc_IntcfinvRecord.CFIMOTF     := 1;
      loc_IntcfinvRecord.CFINKRO     := NULL;
      loc_IntcfinvRecord.CFIDKRO     := param_invoicedate;
      loc_IntcfinvRecord.CFIIDEN     := '1';
      loc_IntcfinvRecord.CFITVA      := 1;
      loc_IntcfinvRecord.CFIMREG     := NULL;
      loc_IntcfinvRecord.CFIDVAL     := NULL;
      loc_IntcfinvRecord.CFIMFAC     := loc_InvoiceAmount;
      loc_IntcfinvRecord.CFITOL      := 1;
      loc_IntcfinvRecord.CFICASM     := param_termsdiscountamount;
      loc_IntcfinvRecord.CFICASP     := param_termsdiscountpercent;
      loc_IntcfinvRecord.CFICASD     := param_termsdiscountdate;
      loc_IntcfinvRecord.CFICASB     := NULL;
      loc_IntcfinvRecord.CFICASN     := NULL;
      loc_IntcfinvRecord.CFIPAY      := NULL;
      loc_IntcfinvRecord.CFIBKCD     := NULL;
      loc_IntcfinvRecord.CFICFINF    := NULL;
      loc_IntcfinvRecord.CFICCINF    := NULL;
      loc_IntcfinvRecord.CFICFEXF    := NULL;
      loc_IntcfinvRecord.CFICCEXF    := NULL;
      loc_IntcfinvRecord.CFITYTRT    := 1;
      loc_IntcfinvRecord.CFITYPTOL   := 0;
      loc_IntcfinvRecord.CFIMFACEMBA := 0;
      loc_IntcfinvRecord.CFIRECYCL   := NULL;
      loc_IntcfinvRecord.CFIDFLGI    := 1;
      loc_IntcfinvRecord.CFISTAT     := const_INTERFACESTATUS;
      loc_IntcfinvRecord.CFIDTRT     := NULL;
      loc_IntcfinvRecord.CFIFICH     := param_FileName;
      loc_IntcfinvRecord.CFINLIG     := 1;
      loc_IntcfinvRecord.CFINERR     := NULL;
      loc_IntcfinvRecord.CFIMESS     := NULL;
      loc_IntcfinvRecord.CFIDCRE     := SYSDATE;
      loc_IntcfinvRecord.CFIDMAJ     := SYSDATE;
      loc_IntcfinvRecord.CFIUTIL     := const_UTIL;
      loc_IntcfinvRecord.CFINFILF    := param_addresschain;
      loc_IntcfinvRecord.CFINFILFF   := param_addresschain;
      loc_IntcfinvRecord.CFINBFAC    := NULL;
      loc_IntcfinvRecord.CFINUFAC    := NULL;
      loc_IntcfinvRecord.CFICNPAY    := 0;
      loc_IntcfinvRecord.CFIEMB      := 0;
      loc_IntcfinvRecord.CFIREMA     := 1;
      loc_IntcfinvRecord.CFIREMP     := param_CheckFooterDealExists;
      loc_IntcfinvRecord.CFICASSAI   := 1;
      loc_IntcfinvRecord.CFILINK     := NULL;
      loc_IntcfinvRecord.CFILD       := NULL;
      loc_IntcfinvRecord.CFIMOPAYREF := NULL;
      loc_IntcfinvRecord.CFIPAYREF   := NULL;
      loc_IntcfinvRecord.CFIQFAC     := NULL;
    
      INSERT INTO intcfinv VALUES loc_IntcfinvRecord;
    END IF;
    glo_Section := 'Intcfinv-End';
  
    UpdateStagingHeader(param_invoicenumber,
                        param_VendorDunsNumber,
                        param_ReceiversLocation,
                        param_ShiptoDuns,
                        param_BatchID,
                        2,
                        'OracleStaging_To_Interface');
  
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfinv', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfinv', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(SQLERRM || ' : ' || SQLCODE);
      END IF;
  END;

  PROCEDURE LoadIntcfbl(param_invoicenumber        cfdenfac.efarfou%TYPE,
                        param_totalinvoiceamount   cfdenfac.efamfac%TYPE,
                        param_SupplierInternalCode cfdenfac.efacfin%TYPE,
                        param_SupplierExternalCode foudgene.foucnuf%TYPE,
                        param_Site                 cdeentcde.ecdsite%TYPE,
                        --param_OrderInternalCode    cdeentcde.ecdcincde%TYPE,
                        --param_OrderExternalCode    cdeentcde.ecdcexcde%TYPE,
                        param_FileName           VARCHAR2,
                        param_DeliveryNoteNumber stoentre.serbliv%TYPE,
                        param_InsertORUpdateFlag NUMBER,
                        param_creditdebitflag    VARCHAR2
                        --param_CheckReceptionFlag   NUMBER
                        ) IS
  
    loc_IntcfblRecord intcfbl%ROWTYPE;
  
    loc_InvoiceAmount NUMBEr(15, 5);
    loc_InvoiceNumber VARCHAR2(20);
  BEGIN
    loc_InvoiceAmount := 0;
  
    glo_Section := 'proc_LoadIntcfbl';
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
  
    IF param_creditdebitflag = 'C' THEN
      loc_InvoiceAmount := -1 * abs(param_totalinvoiceamount);
      loc_InvoiceNumber := param_invoicenumber;
    ELSE
      loc_InvoiceAmount := param_totalinvoiceamount;
      loc_InvoiceNumber := param_invoicenumber;
    END IF;
  
    IF param_InsertORUpdateFlag = 2 THEN
      glo_Section := 'Update LoadIntcfbl:' || param_invoicenumber;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      UPDATE intcfbl
         SET CFBTYPE   = 1,
             CFBREFID  = NULL,
             CFBNCDE   = NULL,
             CFBCEXCDE = NULL,
             CFBTXTVA  = 0,
             CFBSITE   = param_Site,
             CFBMONT   = loc_InvoiceAmount,
             CFBTXMNT  = 0,
             CFBDETAIL = NULL,
             CFBDFLGI  = 1,
             CFBSTAT   = const_INTERFACESTATUS,
             CFBDTRT   = SYSDATE,
             CFBFICH   = substr(param_FileName, 1, 50),
             CFBNLIG   = 1,
             CFBNERR   = NULL,
             CFBMESS   = NULL,
             --CFBDCRE   = SYSDATE,
             CFBDMAJ  = SYSDATE,
             CFBUTIL  = const_UTIL,
             CFBINVID = loc_InvoiceNumber,
             CFBCFIN  = param_SupplierInternalCode
       WHERE --CFBCFIN = param_SupplierInternalCode 
       CFBCFEX = param_SupplierExternalCode
       AND (CFBINVID = param_invoicenumber OR
       CFBINVID || 'CM' = param_invoicenumber)
       AND CFBBLID = param_DeliveryNoteNumber;
    
    ELSIF param_InsertORUpdateFlag = 1 THEN
      glo_Section := 'Insert LoadIntcfbl:' || param_invoicenumber;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfblRecord.CFBCFIN   := param_SupplierInternalCode;
      loc_IntcfblRecord.CFBCFEX   := param_SupplierExternalCode;
      loc_IntcfblRecord.CFBINVID  := loc_InvoiceNumber;
      loc_IntcfblRecord.CFBBLID   := param_DeliveryNoteNumber;
      loc_IntcfblRecord.CFBTYPE   := 1;
      loc_IntcfblRecord.CFBREFID  := NULL;
      loc_IntcfblRecord.CFBNCDE   := NULL;
      loc_IntcfblRecord.CFBCEXCDE := NULL;
      loc_IntcfblRecord.CFBTXTVA  := 0;
      loc_IntcfblRecord.CFBSITE   := param_Site;
      loc_IntcfblRecord.CFBMONT   := loc_InvoiceAmount;
      loc_IntcfblRecord.CFBTXMNT  := 0;
      loc_IntcfblRecord.CFBDETAIL := NULL;
      loc_IntcfblRecord.CFBDFLGI  := 1;
      loc_IntcfblRecord.CFBSTAT   := const_INTERFACESTATUS;
      loc_IntcfblRecord.CFBDTRT   := NULL;
      loc_IntcfblRecord.CFBFICH   := substr(param_FileName, 1, 50);
      loc_IntcfblRecord.CFBNLIG   := 1;
      loc_IntcfblRecord.CFBNERR   := NULL;
      loc_IntcfblRecord.CFBMESS   := NULL;
      loc_IntcfblRecord.CFBDCRE   := SYSDATE;
      loc_IntcfblRecord.CFBDMAJ   := SYSDATE;
      loc_IntcfblRecord.CFBUTIL   := const_UTIL;
    
      INSERT INTO intcfbl VALUES loc_IntcfblRecord;
    END IF;
    glo_Section := 'LoadIntcfbl End';
  
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfbl', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfbl', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(SQLERRM || ' : ' || SQLCODE);
      END IF;
  END;

  PROCEDURE LoadIntcfart(param_VendorDunsNumber     fouadres.FADACCI%TYPE,
                         param_BatchID              NUMBER,
                         param_invoicenumber        cfdenfac.efarfou%TYPE,
                         param_SupplierInternalCode cfdenfac.efacfin%TYPE,
                         param_SupplierExternalCode foudgene.foucnuf%TYPE,
                         param_Site                 cdeentcde.ecdsite%TYPE,
                         --param_OrderInternalCode    cdeentcde.ecdcincde%TYPE,
                         --param_OrderExternalCode    cdeentcde.ecdcexcde%TYPE,
                         param_FileName           VARCHAR2,
                         param_DeliveryNoteNumber stoentre.serbliv%TYPE,
                         param_commcontnum        cfdenfac.efaccin%TYPE,
                         param_creditdebitflag    VARCHAR2
                         --param_commcontcode       fouccom.fccnum%TYPE
                         --param_InsertORUpdateFlag   NUMBER,
                         --param_CheckReceptionFlag   NUMBER
                         ) IS
  
    loc_IntcfartRecord intcfart%ROWTYPE;
    --loc_LVIntCode      artvl.arlseqvl%TYPE;
    loc_LineNo            NUMBER(5);
    loc_ItemAlreadyExists NUMBER(3);
  
    -- Get the list of items found in reception for the invoice
    CURSOR get_invoice_detail_data IS
      SELECT arlcexvl,
             arlcexr,
             getARAREFC(sercfin,
                        serccin,
                        arlseqvl,
                        sersite,
                        serdcom,
                        serfilf) Refc,
             getARACEXTA(sercfin,
                         serccin,
                         arlseqvl,
                         sersite,
                         serdcom,
                         serfilf) PurVariantExtCode,
             QtyInvoiced * (getSKUUnits(arlcexr, arlcexvl, QtyUOM)) SKUQtyInvoiced,
             decode((getSKUUnits(arlcexr, arlcexvl, QtyUOM)),
                    0,
                    0,
                    UnitPrice / (getSKUUnits(arlcexr, arlcexvl, QtyUOM))) UnitListCost,
             productid
        FROM artvl, stoentre, im_edi_invoice_detail, stodetre
       WHERE arlseqvl = decode(getSeqvl(sercinrec,
                                        productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite),
                               -1,
                               getSeqvltoReplace(sercfin, serdcom),
                               getSeqvl(sercinrec,
                                        productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite))
         AND serbliv = param_DeliveryNoteNumber
         AND sersite = param_Site
         AND invoicenumber = param_invoicenumber
         AND sercinrec = sdrcinrec
         AND arlcinr = sdrcinr
         AND sdrseqvl = arlseqvl
         AND importbatchid = param_BatchID
         AND param_creditdebitflag <> 'C';
  
    /* -- Get the list of items for the invoice without reception
    CURSOR get_invoice_detail_wo_rec IS
      SELECT arlcexvl,
             arlcexr,
             getARAREFC(param_SupplierInternalCode,
                        param_commcontnum,
                        arlseqvl,
                        param_Site,
                         sysdate,
                        0) Refc,
             getARACEXTA(param_SupplierInternalCode,
                         param_commcontnum,
                         arlseqvl,
                         param_Site,
                          sysdate,
                         0) PurVariantExtCode,
             QtyInvoiced * (getSKUUnits(arlcexr, arlcexvl, QtyUOM)) SKUQtyInvoiced,
             decode((getSKUUnits(arlcexr, arlcexvl, QtyUOM)),
                    0,
                    0,
                    UnitPrice / (getSKUUnits(arlcexr, arlcexvl, QtyUOM))) UnitListCost,
             productid
        FROM artvl, im_edi_invoice_detail
       WHERE arlseqvl = getSeqvl(NULL, productid, sysdate)
         AND invoicenumber = param_invoicenumber
         AND vendordunsnumber = param_VendorDunsNumber
         AND NOT EXISTS
       (SELECT 1
                FROM intcfinv, intcfbl, stoentre, fouadres
               WHERE cfiinvid = cfbinvid
                 AND cficfin = cfbcfin
                 AND fadcfin = cficfin
                 AND cfiinvid = param_invoicenumber
                 AND serbliv = param_DeliveryNoteNumber
                 AND sercfin = cficfin
                 AND sersite = cfisite
                 AND serccin = cficcin
                 AND FADACCI = param_VendorDunsNumber);*/
  
    -- Get the list of items not found in reception for the invoice
    CURSOR get_invoice_detail_addon IS
      SELECT arlcexvl,
             arlcexr,
             getARAREFC(sercfin,
                        serccin,
                        arlseqvl,
                        sersite,
                        serdcom,
                        serfilf) Refc,
             getARACEXTA(sercfin,
                         serccin,
                         arlseqvl,
                         sersite,
                         serdcom,
                         serfilf) PurVariantExtCode,
             QtyInvoiced * (getSKUUnits(arlcexr, arlcexvl, QtyUOM)) SKUQtyInvoiced,
             decode((getSKUUnits(arlcexr, arlcexvl, QtyUOM)),
                    0,
                    0,
                    UnitPrice / (getSKUUnits(arlcexr, arlcexvl, QtyUOM))) UnitListCost,
             productid
        FROM artvl, stoentre, im_edi_invoice_detail
       WHERE arlseqvl = decode(getSeqvl(sercinrec,
                                        productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite),
                               -1,
                               getSeqvltoReplace(sercfin, serdcom),
                               getSeqvl(sercinrec,
                                        productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite))
         AND serbliv = param_DeliveryNoteNumber
            -- AND sersite = param_Site
         AND invoicenumber = param_invoicenumber
         AND importbatchid = param_BatchID
         AND NOT EXISTS (SELECT 1
                FROM stoentre, stodetre
               WHERE serbliv = param_DeliveryNoteNumber
                    -- AND sersite = param_Site
                 AND sercinrec = sdrcinrec
                 AND sdrcinr = arlcinr
                 AND sdrseqvl = arlseqvl)
         AND param_creditdebitflag <> 'C';
  
    -- Get the list of items found in return for the credit memo
    CURSOR get_cm_invoice_detail_data IS
      SELECT arlcexvl,
             arlcexr,
             getARAREFC(sercfin,
                        serccin,
                        arlseqvl,
                        sersite,
                        serdcom,
                        serfilf) Refc,
             getARACEXTA(sercfin,
                         serccin,
                         arlseqvl,
                         sersite,
                         serdcom,
                         serfilf) PurVariantExtCode,
             abs(QtyInvoiced) * (getSKUUnits(arlcexr, arlcexvl, QtyUOM)) SKUQtyInvoiced,
             abs(QtyInvoiced) QtyInvoiced,
             /*decode((getSKUUnits(arlcexr, arlcexvl, QtyUOM)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               0,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               0,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               UnitPrice / (getSKUUnits(arlcexr, arlcexvl, QtyUOM))) UnitListCost,*/
             QtyUOM,
             det.productid productid,
             det.UnitPrice UnitPrice,
             ild.allowancecharge allowancecharge,
             ild.allowancechargerate allowancechargerate,
             ild.allowancechargeuom allowancechargeuom,
             ild.allowancetotalamount allowancetotalamount,
             getSKUUnits(arlcexr, arlcexvl, QtyUOM) SKU
        FROM artvl,
             stoentre,
             im_edi_invoice_detail det,
             stodetre,
             im_edi_invoice_itemdeals ild
       WHERE arlseqvl = decode(getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite),
                               -1,
                               getSeqvltoReplace(sercfin, serdcom),
                               getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite)) --getSeqvl(sercinrec, det.productid, serdcom)
         AND serbliv = param_DeliveryNoteNumber
         AND sersite = param_Site
         AND det.invoicenumber = param_invoicenumber
         AND sercinrec = sdrcinrec
         AND arlcinr = sdrcinr
         AND sdrseqvl = arlseqvl
         AND det.importbatchid = param_BatchID
         AND det.invoicenumber = ild.invoicenumber(+)
         AND det.vendordunsnumber = ild.vendordunsnumber(+)
         AND det.productid = ild.productid(+)
         AND det.importbatchid = ild.importbatchid(+)
         AND param_creditdebitflag = 'C'
         AND sertmvt = 2;
  
    -- Get the list of addon items found in return for the credit memo
    CURSOR get_cm_invoice_detail_addon IS
      SELECT arlcexvl,
             arlcexr,
             getARAREFC(sercfin,
                        serccin,
                        arlseqvl,
                        sersite,
                        serdcom,
                        serfilf) Refc,
             getARACEXTA(sercfin,
                         serccin,
                         arlseqvl,
                         sersite,
                         serdcom,
                         serfilf) PurVariantExtCode,
             abs(QtyInvoiced) QtyInvoiced,
             abs(QtyInvoiced) * (getSKUUnits(arlcexr, arlcexvl, QtyUOM)) SKUQtyInvoiced,
             /*decode((getSKUUnits(arlcexr, arlcexvl, QtyUOM)),
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               0,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               0,
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                               UnitPrice / (getSKUUnits(arlcexr, arlcexvl, QtyUOM))) UnitListCost,*/
             QtyUOM,
             det.productid productid,
             det.UnitPrice UnitPrice,
             ild.allowancecharge allowancecharge,
             ild.allowancechargerate allowancechargerate,
             ild.allowancechargeuom allowancechargeuom,
             ild.allowancetotalamount allowancetotalamount,
             getSKUUnits(arlcexr, arlcexvl, QtyUOM) SKU
        FROM artvl,
             stoentre,
             im_edi_invoice_detail det,
             im_edi_invoice_itemdeals ild
       WHERE arlseqvl = decode(getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite),
                               -1,
                               getSeqvltoReplace(sercfin, serdcom),
                               getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite)) --getSeqvl(sercinrec, det.productid, serdcom)
         AND serbliv = param_DeliveryNoteNumber
         AND sersite = param_Site
         AND det.invoicenumber = param_invoicenumber
         AND det.importbatchid = param_BatchID
         AND det.invoicenumber = ild.invoicenumber(+)
         AND det.vendordunsnumber = ild.vendordunsnumber(+)
         AND det.productid = ild.productid(+)
         AND det.importbatchid = ild.importbatchid(+)
         AND param_creditdebitflag = 'C'
         AND sertmvt = 2
         AND NOT EXISTS (SELECT 1
                FROM stoentre, stodetre
               WHERE serbliv = param_DeliveryNoteNumber
                    -- AND sersite = param_Site
                 AND sercinrec = sdrcinrec
                 AND sdrcinr = arlcinr
                 AND sdrseqvl = arlseqvl);
  
    CURSOR get_generic_items IS
      SELECT cfacexr,
             cfacexvl,
             cfacexta,
             cfarefc,
             sum(cfaqty) SKUQtyInvoiced,
             round(sum(cfabtprx * cfaqty) / sum(cfaqty), 5) UnitListCost
        FROM intcfart
       WHERE cfainvid = param_invoicenumber
         AND cfablid = param_DeliveryNoteNumber
         AND cfastat = 3
       GROUP BY cfacexr, cfacexvl, cfacexta, cfarefc
      HAVING COUNT(cfacexr) > 1;
  
    loc_InvoiceNumber         VARCHAR2(20);
    loc_UnitPrice             NUMBER(15, 5);
    loc_allowancechargerate   NUMBER(15, 5);
    loc_allowancechargeamount NUMBER(15, 5);
  BEGIN
    glo_Section := 'LoadIntcfart start';
  
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
    loc_LineNo := 1;
  
    loc_ItemAlreadyExists := 0;
    SELECT COUNT(*)
      INTO loc_ItemAlreadyExists
      FROM intcfart
     WHERE cfainvid = param_InvoiceNumber
       AND cfacfin = param_SupplierInternalCode;
  
    IF loc_ItemAlreadyExists <> 0 THEN
      DELETE FROM intcfart
       WHERE cfainvid = param_InvoiceNumber
         AND cfacfin = param_SupplierInternalCode;
      COMMIT;
    END IF;
  
    FOR rec_get_invoice_detail_data IN get_invoice_detail_data LOOP
    
      glo_Section := 'Insert LoadIntcfart1:Item' ||
                     rec_get_invoice_detail_data.arlcexr;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfartRecord.CFACFIN    := param_SupplierInternalCode;
      loc_IntcfartRecord.CFACFEX    := param_SupplierExternalCode;
      loc_IntcfartRecord.CFAINVID   := param_InvoiceNumber;
      loc_IntcfartRecord.CFABLID    := param_DeliveryNoteNumber;
      loc_IntcfartRecord.CFANCDE    := NULL;
      loc_IntcfartRecord.CFANCEXCDE := NULL;
      loc_IntcfartRecord.CFACEXR    := rec_get_invoice_detail_data.arlcexr;
      loc_IntcfartRecord.CFACEXVL   := rec_get_invoice_detail_data.arlcexvl;
      loc_IntcfartRecord.CFACEXTA   := rec_get_invoice_detail_data.PurVariantExtCode;
      loc_IntcfartRecord.CFAREFC    := rec_get_invoice_detail_data.Refc;
      loc_IntcfartRecord.CFATXTVA   := 0;
      loc_IntcfartRecord.CFAQTY     := rec_get_invoice_detail_data.SKUQtyInvoiced;
      loc_IntcfartRecord.CFABTPRX   := rec_get_invoice_detail_data.UnitListCost;
      loc_IntcfartRecord.CFANTPRX   := 0;
      loc_IntcfartRecord.CFATYPE    := 1;
      loc_IntcfartRecord.CFAREFID   := NULL;
      loc_IntcfartRecord.CFASITE    := param_Site;
      loc_IntcfartRecord.CFAQTG     := 0;
      loc_IntcfartRecord.CFADFLGI   := 1;
      loc_IntcfartRecord.CFASTAT    := const_INTERFACESTATUS;
      loc_IntcfartRecord.CFADTRT    := NULL;
      loc_IntcfartRecord.CFAFICH    := substr(param_FileName, 1, 50);
      loc_IntcfartRecord.CFANLIG    := loc_LineNo;
      loc_IntcfartRecord.CFANERR    := NULL;
      loc_IntcfartRecord.CFAMESS    := NULL;
      loc_IntcfartRecord.CFADCRE    := SYSDATE;
      loc_IntcfartRecord.CFADMAJ    := SYSDATE;
      loc_IntcfartRecord.CFAUTIL    := const_UTIL;
      loc_IntcfartRecord.CFAPPUBLIC := NULL;
      loc_IntcfartRecord.CFACODLOG  := NULL;
      loc_IntcfartRecord.CFACODCAI  := NULL;
    
      INSERT INTO intcfart VALUES loc_IntcfartRecord;
    
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingDetail(param_InvoiceNumber,
                          param_VendorDunsNumber,
                          rec_get_invoice_detail_data.productid,
                          param_BatchID,
                          2,
                          'OracleStaging_To_Interface');
    
    END LOOP;
    /* loc_LineNo := 1;
    FOR rec_get_invoice_detail_wo_rec IN get_invoice_detail_wo_rec LOOP
      glo_Section := 'Insert LoadIntcfart2:Item' ||
                     rec_get_invoice_detail_wo_rec.arlcexr;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfartRecord.CFACFIN    := param_SupplierInternalCode;
      loc_IntcfartRecord.CFACFEX    := param_SupplierExternalCode;
      loc_IntcfartRecord.CFAINVID   := param_invoicenumber;
      loc_IntcfartRecord.CFABLID    := param_DeliveryNoteNumber;
      loc_IntcfartRecord.CFANCDE    := NULL;
      loc_IntcfartRecord.CFANCEXCDE := NULL;
      loc_IntcfartRecord.CFACEXR    := rec_get_invoice_detail_wo_rec.arlcexr;
      loc_IntcfartRecord.CFACEXVL   := rec_get_invoice_detail_wo_rec.arlcexvl;
      loc_IntcfartRecord.CFACEXTA   := rec_get_invoice_detail_wo_rec.PurVariantExtCode;
      loc_IntcfartRecord.CFAREFC    := rec_get_invoice_detail_wo_rec.Refc;
      loc_IntcfartRecord.CFATXTVA   := 0;
      loc_IntcfartRecord.CFAQTY     := rec_get_invoice_detail_wo_rec.SKUQtyInvoiced;
      loc_IntcfartRecord.CFABTPRX   := rec_get_invoice_detail_wo_rec.UnitListCost;
      loc_IntcfartRecord.CFANTPRX   := 0;
      loc_IntcfartRecord.CFATYPE    := 1;
      loc_IntcfartRecord.CFAREFID   := NULL;
      loc_IntcfartRecord.CFASITE    := param_Site;
      loc_IntcfartRecord.CFAQTG     := 0;
      loc_IntcfartRecord.CFADFLGI   := 1;
      loc_IntcfartRecord.CFASTAT    := const_INTERFACESTATUS;
      loc_IntcfartRecord.CFADTRT    := NULL;
      loc_IntcfartRecord.CFAFICH    := param_FileName;
      loc_IntcfartRecord.CFANLIG    := loc_LineNo;
      loc_IntcfartRecord.CFANERR    := NULL;
      loc_IntcfartRecord.CFAMESS    := NULL;
      loc_IntcfartRecord.CFADCRE    := SYSDATE;
      loc_IntcfartRecord.CFADMAJ    := SYSDATE;
      loc_IntcfartRecord.CFAUTIL    := const_UTIL;
      loc_IntcfartRecord.CFAPPUBLIC := NULL;
      loc_IntcfartRecord.CFACODLOG  := NULL;
      loc_IntcfartRecord.CFACODCAI  := NULL;
    
      INSERT INTO intcfart VALUES loc_IntcfartRecord;
    
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingDetail(param_InvoiceNumber,
                          param_VendorDunsNumber,
                          rec_get_invoice_detail_wo_rec.productid,
                          param_BatchID,
                          2,
                          'OracleStaging_To_Interface');
    
    END LOOP;*/
  
    -- loc_LineNo := 1;
    FOR rec_get_invoice_detail_addon IN get_invoice_detail_addon LOOP
      glo_Section := 'Insert LoadIntcfart3:Item' ||
                     rec_get_invoice_detail_addon.arlcexr;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfartRecord.CFACFIN    := param_SupplierInternalCode;
      loc_IntcfartRecord.CFACFEX    := param_SupplierExternalCode;
      loc_IntcfartRecord.CFAINVID   := param_InvoiceNumber;
      loc_IntcfartRecord.CFABLID    := param_DeliveryNoteNumber;
      loc_IntcfartRecord.CFANCDE    := NULL;
      loc_IntcfartRecord.CFANCEXCDE := NULL;
      loc_IntcfartRecord.CFACEXR    := rec_get_invoice_detail_addon.arlcexr;
      loc_IntcfartRecord.CFACEXVL   := rec_get_invoice_detail_addon.arlcexvl;
      loc_IntcfartRecord.CFACEXTA   := rec_get_invoice_detail_addon.PurVariantExtCode;
      loc_IntcfartRecord.CFAREFC    := rec_get_invoice_detail_addon.Refc;
      loc_IntcfartRecord.CFATXTVA   := 0;
      loc_IntcfartRecord.CFAQTY     := rec_get_invoice_detail_addon.SKUQtyInvoiced;
      loc_IntcfartRecord.CFABTPRX   := rec_get_invoice_detail_addon.UnitListCost;
      loc_IntcfartRecord.CFANTPRX   := 0;
      loc_IntcfartRecord.CFATYPE    := 1;
      loc_IntcfartRecord.CFAREFID   := NULL;
      loc_IntcfartRecord.CFASITE    := param_Site;
      loc_IntcfartRecord.CFAQTG     := 0;
      loc_IntcfartRecord.CFADFLGI   := 1;
      loc_IntcfartRecord.CFASTAT    := const_INTERFACESTATUS;
      loc_IntcfartRecord.CFADTRT    := NULL;
      loc_IntcfartRecord.CFAFICH    := substr(param_FileName, 1, 50);
      loc_IntcfartRecord.CFANLIG    := loc_LineNo;
      loc_IntcfartRecord.CFANERR    := NULL;
      loc_IntcfartRecord.CFAMESS    := NULL;
      loc_IntcfartRecord.CFADCRE    := SYSDATE;
      loc_IntcfartRecord.CFADMAJ    := SYSDATE;
      loc_IntcfartRecord.CFAUTIL    := const_UTIL;
      loc_IntcfartRecord.CFAPPUBLIC := NULL;
      loc_IntcfartRecord.CFACODLOG  := NULL;
      loc_IntcfartRecord.CFACODCAI  := NULL;
    
      INSERT INTO intcfart VALUES loc_IntcfartRecord;
    
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingDetail(param_InvoiceNumber,
                          param_VendorDunsNumber,
                          rec_get_invoice_detail_addon.productid,
                          param_BatchID,
                          2,
                          'OracleStaging_To_Interface');
    
    END LOOP;
  
    loc_LineNo    := 1;
    loc_UnitPrice := 0;
    FOR rec_get_cm_invoice_detail_data IN get_cm_invoice_detail_data LOOP
      glo_Section := 'Insert LoadIntcfart5:Item' ||
                     rec_get_cm_invoice_detail_data.arlcexr;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      IF nvl(rec_get_cm_invoice_detail_data.allowancechargerate, 0) <> 0 THEN
        -- Kanchana:07312015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        if rec_get_cm_invoice_detail_data.allowancecharge = 'A' then
          loc_allowancechargerate := abs(rec_get_cm_invoice_detail_data.allowancechargerate);
        elsif rec_get_cm_invoice_detail_data.allowancecharge = 'C' then
          loc_allowancechargerate := -1 *
                                     abs(rec_get_cm_invoice_detail_data.allowancechargerate);
        else
          loc_allowancechargerate := -1 *
                                     rec_get_cm_invoice_detail_data.allowancechargerate;
        
        end if;
      
        loc_UnitPrice := (rec_get_cm_invoice_detail_data.UnitPrice -
                         ( /*-1 *
                                                                           rec_get_cm_invoice_detail_data.allowancechargerate*/
                          loc_allowancechargerate)) /
                         rec_get_cm_invoice_detail_data.SKU;
      ELSIF nvl(rec_get_cm_invoice_detail_data.allowancetotalamount, 0) <> 0 THEN
        -- Kanchana:07312015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        if rec_get_cm_invoice_detail_data.allowancecharge = 'A' then
          loc_allowancechargeamount := abs(rec_get_cm_invoice_detail_data.allowancetotalamount);
        elsif rec_get_cm_invoice_detail_data.allowancecharge = 'C' then
          loc_allowancechargeamount := -1 *
                                       abs(rec_get_cm_invoice_detail_data.allowancetotalamount);
        else
          loc_allowancechargeamount := -1 *
                                       rec_get_cm_invoice_detail_data.allowancetotalamount;
        
        end if;
      
        loc_UnitPrice := ((rec_get_cm_invoice_detail_data.UnitPrice /*/
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         rec_get_cm_invoice_detail_data.SKU)*/
                         - ( /*-1 *
                                                                           rec_get_cm_invoice_detail_data.allowancetotalamount*/
                          loc_allowancechargeamount /
                          rec_get_cm_invoice_detail_data.QtyInvoiced)) /
                         rec_get_cm_invoice_detail_data.SKU);
      ELSE
        loc_UnitPrice := rec_get_cm_invoice_detail_data.UnitPrice /
                         rec_get_cm_invoice_detail_data.SKU;
      
      END IF;
    
      loc_IntcfartRecord.CFACFIN    := param_SupplierInternalCode;
      loc_IntcfartRecord.CFACFEX    := param_SupplierExternalCode;
      loc_IntcfartRecord.CFAINVID   := param_InvoiceNumber;
      loc_IntcfartRecord.CFABLID    := param_DeliveryNoteNumber;
      loc_IntcfartRecord.CFANCDE    := NULL;
      loc_IntcfartRecord.CFANCEXCDE := NULL;
      loc_IntcfartRecord.CFACEXR    := rec_get_cm_invoice_detail_data.arlcexr;
      loc_IntcfartRecord.CFACEXVL   := rec_get_cm_invoice_detail_data.arlcexvl;
      loc_IntcfartRecord.CFACEXTA   := rec_get_cm_invoice_detail_data.PurVariantExtCode;
      loc_IntcfartRecord.CFAREFC    := rec_get_cm_invoice_detail_data.Refc;
      loc_IntcfartRecord.CFATXTVA   := 0;
      loc_IntcfartRecord.CFAQTY     := rec_get_cm_invoice_detail_data.SKUQtyInvoiced;
      loc_IntcfartRecord.CFABTPRX   := loc_UnitPrice;
      loc_IntcfartRecord.CFANTPRX   := 0;
      loc_IntcfartRecord.CFATYPE    := 1;
      loc_IntcfartRecord.CFAREFID   := NULL;
      loc_IntcfartRecord.CFASITE    := param_Site;
      loc_IntcfartRecord.CFAQTG     := 0;
      loc_IntcfartRecord.CFADFLGI   := 1;
      loc_IntcfartRecord.CFASTAT    := const_INTERFACESTATUS;
      loc_IntcfartRecord.CFADTRT    := NULL;
      loc_IntcfartRecord.CFAFICH    := substr(param_FileName, 1, 50);
      loc_IntcfartRecord.CFANLIG    := loc_LineNo;
      loc_IntcfartRecord.CFANERR    := NULL;
      loc_IntcfartRecord.CFAMESS    := NULL;
      loc_IntcfartRecord.CFADCRE    := SYSDATE;
      loc_IntcfartRecord.CFADMAJ    := SYSDATE;
      loc_IntcfartRecord.CFAUTIL    := const_UTIL;
      loc_IntcfartRecord.CFAPPUBLIC := NULL;
      loc_IntcfartRecord.CFACODLOG  := NULL;
      loc_IntcfartRecord.CFACODCAI  := NULL;
    
      INSERT INTO intcfart VALUES loc_IntcfartRecord;
    
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingDetail(param_InvoiceNumber,
                          param_VendorDunsNumber,
                          rec_get_cm_invoice_detail_data.productid,
                          param_BatchID,
                          2,
                          'OracleStaging_To_Interface');
    
    END LOOP;
  
    loc_UnitPrice := 0;
    FOR rec_cm_invoice_detail_addon IN get_cm_invoice_detail_addon LOOP
      glo_Section := 'Insert LoadIntcfart5:Item' ||
                     rec_cm_invoice_detail_addon.arlcexr;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      IF nvl(rec_cm_invoice_detail_addon.allowancechargerate, 0) <> 0 THEN
      
        -- Kanchana:07312015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        if rec_cm_invoice_detail_addon.allowancecharge = 'A' then
          loc_allowancechargerate := abs(rec_cm_invoice_detail_addon.allowancechargerate);
        elsif rec_cm_invoice_detail_addon.allowancecharge = 'C' then
          loc_allowancechargerate := -1 *
                                     abs(rec_cm_invoice_detail_addon.allowancechargerate);
        else
          loc_allowancechargerate := -1 *
                                     rec_cm_invoice_detail_addon.allowancechargerate;
        
        end if;
      
        loc_UnitPrice := (rec_cm_invoice_detail_addon.UnitPrice -
                         ( /*-1 *
                                                  rec_cm_invoice_detail_addon.allowancechargerate*/
                          loc_allowancechargerate)) /
                         rec_cm_invoice_detail_addon.SKU;
      ELSIF nvl(rec_cm_invoice_detail_addon.allowancetotalamount, 0) <> 0 THEN
      
        -- Kanchana:07312015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        if rec_cm_invoice_detail_addon.allowancecharge = 'A' then
          loc_allowancechargeamount := abs(rec_cm_invoice_detail_addon.allowancetotalamount);
        elsif rec_cm_invoice_detail_addon.allowancecharge = 'C' then
          loc_allowancechargeamount := -1 *
                                       abs(rec_cm_invoice_detail_addon.allowancetotalamount);
        else
          loc_allowancechargeamount := -1 *
                                       rec_cm_invoice_detail_addon.allowancetotalamount;
        
        end if;
      
        loc_UnitPrice := ((rec_cm_invoice_detail_addon.UnitPrice /*/
                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                         rec_get_cm_invoice_detail_data.SKU)*/
                         - ( /*-1 *
                                                  rec_cm_invoice_detail_addon.allowancetotalamount*/
                          loc_allowancechargeamount /
                          rec_cm_invoice_detail_addon.QtyInvoiced)) /
                         rec_cm_invoice_detail_addon.SKU);
      ELSE
        loc_UnitPrice := rec_cm_invoice_detail_addon.UnitPrice /
                         rec_cm_invoice_detail_addon.SKU;
      
      END IF;
    
      loc_IntcfartRecord.CFACFIN    := param_SupplierInternalCode;
      loc_IntcfartRecord.CFACFEX    := param_SupplierExternalCode;
      loc_IntcfartRecord.CFAINVID   := param_InvoiceNumber;
      loc_IntcfartRecord.CFABLID    := param_DeliveryNoteNumber;
      loc_IntcfartRecord.CFANCDE    := NULL;
      loc_IntcfartRecord.CFANCEXCDE := NULL;
      loc_IntcfartRecord.CFACEXR    := rec_cm_invoice_detail_addon.arlcexr;
      loc_IntcfartRecord.CFACEXVL   := rec_cm_invoice_detail_addon.arlcexvl;
      loc_IntcfartRecord.CFACEXTA   := rec_cm_invoice_detail_addon.PurVariantExtCode;
      loc_IntcfartRecord.CFAREFC    := rec_cm_invoice_detail_addon.Refc;
      loc_IntcfartRecord.CFATXTVA   := 0;
      loc_IntcfartRecord.CFAQTY     := rec_cm_invoice_detail_addon.SKUQtyInvoiced;
      loc_IntcfartRecord.CFABTPRX   := loc_UnitPrice;
      loc_IntcfartRecord.CFANTPRX   := 0;
      loc_IntcfartRecord.CFATYPE    := 1;
      loc_IntcfartRecord.CFAREFID   := NULL;
      loc_IntcfartRecord.CFASITE    := param_Site;
      loc_IntcfartRecord.CFAQTG     := 0;
      loc_IntcfartRecord.CFADFLGI   := 1;
      loc_IntcfartRecord.CFASTAT    := const_INTERFACESTATUS;
      loc_IntcfartRecord.CFADTRT    := NULL;
      loc_IntcfartRecord.CFAFICH    := substr(param_FileName, 1, 50);
      loc_IntcfartRecord.CFANLIG    := loc_LineNo;
      loc_IntcfartRecord.CFANERR    := NULL;
      loc_IntcfartRecord.CFAMESS    := NULL;
      loc_IntcfartRecord.CFADCRE    := SYSDATE;
      loc_IntcfartRecord.CFADMAJ    := SYSDATE;
      loc_IntcfartRecord.CFAUTIL    := const_UTIL;
      loc_IntcfartRecord.CFAPPUBLIC := NULL;
      loc_IntcfartRecord.CFACODLOG  := NULL;
      loc_IntcfartRecord.CFACODCAI  := NULL;
    
      INSERT INTO intcfart VALUES loc_IntcfartRecord;
    
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingDetail(param_InvoiceNumber,
                          param_VendorDunsNumber,
                          rec_cm_invoice_detail_addon.productid,
                          param_BatchID,
                          2,
                          'OracleStaging_To_Interface');
    
    END LOOP;
  
    FOR rec_get_generic_items IN get_generic_items LOOP
    
      glo_Section := 'Insert LoadIntcfart4:Item' ||
                     rec_get_generic_items.cfacexr;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfartRecord.CFACFIN    := param_SupplierInternalCode;
      loc_IntcfartRecord.CFACFEX    := param_SupplierExternalCode;
      loc_IntcfartRecord.CFAINVID   := param_InvoiceNumber;
      loc_IntcfartRecord.CFABLID    := param_DeliveryNoteNumber;
      loc_IntcfartRecord.CFANCDE    := NULL;
      loc_IntcfartRecord.CFANCEXCDE := NULL;
      loc_IntcfartRecord.CFACEXR    := rec_get_generic_items.cfacexr;
      loc_IntcfartRecord.CFACEXVL   := rec_get_generic_items.cfacexvl;
      loc_IntcfartRecord.CFACEXTA   := rec_get_generic_items.cfacexta;
      loc_IntcfartRecord.CFAREFC    := rec_get_generic_items.cfarefc;
      loc_IntcfartRecord.CFATXTVA   := 0;
      loc_IntcfartRecord.CFAQTY     := rec_get_generic_items.SKUQtyInvoiced;
      loc_IntcfartRecord.CFABTPRX   := rec_get_generic_items.UnitListCost;
      loc_IntcfartRecord.CFANTPRX   := 0;
      loc_IntcfartRecord.CFATYPE    := 1;
      loc_IntcfartRecord.CFAREFID   := NULL;
      loc_IntcfartRecord.CFASITE    := param_Site;
      loc_IntcfartRecord.CFAQTG     := 0;
      loc_IntcfartRecord.CFADFLGI   := 1;
      loc_IntcfartRecord.CFASTAT    := const_INTERFACESTATUS;
      loc_IntcfartRecord.CFADTRT    := NULL;
      loc_IntcfartRecord.CFAFICH    := substr(param_FileName, 1, 50);
      loc_IntcfartRecord.CFANLIG    := loc_LineNo;
      loc_IntcfartRecord.CFANERR    := NULL;
      loc_IntcfartRecord.CFAMESS    := NULL;
      loc_IntcfartRecord.CFADCRE    := SYSDATE;
      loc_IntcfartRecord.CFADMAJ    := SYSDATE;
      loc_IntcfartRecord.CFAUTIL    := 'EDI894_MOD';
      loc_IntcfartRecord.CFAPPUBLIC := NULL;
      loc_IntcfartRecord.CFACODLOG  := NULL;
      loc_IntcfartRecord.CFACODCAI  := NULL;
    
      INSERT INTO intcfart VALUES loc_IntcfartRecord;
    
      DELETE FROM intcfart
       WHERE CFABLID = param_DeliveryNoteNumber
         AND CFAINVID = param_InvoiceNumber
         AND CFAUTIL = const_UTIL
         AND CFACEXR = rec_get_generic_items.cfacexr
         AND cfacexvl = rec_get_generic_items.cfacexvl;
    
    END LOOP;
  
    glo_Section := 'LoadIntcfart End';
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfart', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfart', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(SQLERRM || ' : ' || SQLCODE);
      END IF;
  END;

  PROCEDURE LoadIntcfremise(param_VendorDunsNumber     fouadres.FADACCI%TYPE,
                            param_BatchID              NUMBER,
                            param_invoicenumber        cfdenfac.efarfou%TYPE,
                            param_SupplierInternalCode cfdenfac.efacfin%TYPE,
                            param_SupplierExternalCode foudgene.foucnuf%TYPE,
                            param_Site                 cdeentcde.ecdsite%TYPE,
                            --param_OrderInternalCode    cdeentcde.ecdcincde%TYPE,
                            --param_OrderExternalCode    cdeentcde.ecdcexcde%TYPE,
                            param_FileName           VARCHAR2,
                            param_DeliveryNoteNumber stoentre.serbliv%TYPE,
                            param_commcontnum        cfdenfac.efaccin%TYPE,
                            param_creditdebitflag    VARCHAR2
                            --param_commcontcode         fouccom.fccnum%TYPE,
                            --param_InsertORUpdateFlag   NUMBER,
                            --param_CheckReceptionFlag   NUMBER
                            ) IS
  
    loc_IntcfremiseRecord intcfremise%ROWTYPE;
  
    loc_LineNo NUMBER(5) := 0;
    -- Get the item deals found in reception for the invoice
    CURSOR get_invoice_it_deals IS
      SELECT srrordc,
             srrorda,
             srrunit,
             srruapp,
             sdrpcu,
             sdruauvc,
             srrtrem,
             trecexrem,
             arlcexvl,
             arlcexr,
             getARAREFC(sercfin,
                        serccin,
                        arlseqvl,
                        sersite,
                        serdcom,
                        serfilf) Refc,
             getARACEXTA(sercfin,
                         serccin,
                         arlseqvl,
                         sersite,
                         serdcom,
                         serfilf) PurVariantExtCode,
             getCoefficient(ild.allowancechargeuom,
                            sdrcinr,
                            sdrseqvl,
                            nvl(srruapp, ild.allowancechargeuom)) as coefficient,
             ild.allowancechargerate,
             ild.allowancetotalamount,
             getCalAllowancechargerate(ild.allowancechargeuom,
                                       srruapp,
                                       sdrpcu,
                                       sdruauvc,
                                       getCoefficient(ild.allowancechargeuom,
                                                      sdrcinr,
                                                      sdrseqvl,
                                                      nvl(srruapp,
                                                          ild.allowancechargeuom)),
                                       ild.allowancechargerate) calcallowancechargerate,
             det.productid,
             det.QtyInvoiced QtyInvoiced,
             QtyInvoiced * (getSKUUnits(arlcexr, arlcexvl, det.QtyUOM)) SKUQtyInvoiced,
             det.QtyUOM,
             ild.allowancecharge
        FROM im_edi_invoice_itemdeals ild,
             im_edi_invoice_detail det,
             stoentre,
             storemre,
             stodetre,
             taremise,
             artvl
       WHERE ild.invoicenumber = param_invoicenumber
         AND det.invoicenumber = ild.invoicenumber
         AND ild.vendordunsnumber = det.vendordunsnumber
         AND ild.productid = det.productid
         AND sercinrec = sdrcinrec
         AND sercinrec = srrcinrec
         AND sdrnlrec = srrnlrec
         AND arlseqvl = decode(getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite),
                               -1,
                               getSeqvltoReplace(sercfin, serdcom),
                               getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite))
         AND trecinrem = srrcinrem
         AND sdrseqvl = arlseqvl
         AND sdrcinr = arlcinr
         AND serbliv = param_DeliveryNoteNumber
         AND ild.vendordunsnumber = param_VendorDunsNumber
            -- fix for 810 document(2 corresponds to 5 and 6 corresponds to 20 in GOLD)
         AND srrtrem = decode(ild.allowancechargecode,
                              2,
                              5,
                              6,
                              20,
                              ild.allowancechargecode)
         AND det.importbatchid = ild.importbatchid
         AND det.importbatchid = param_BatchID;
  
    /*-- Get the item deals for the invoice without reception
    CURSOR get_invoice_it_deals_wor IS
      SELECT arlcexvl,
             arlcexr,
             getARAREFC(param_SupplierInternalCode,
                        param_commcontnum,
                        arlseqvl,
                        param_Site,
                        \* sysdate,*\
                        0) Refc,
             getARACEXTA(param_SupplierInternalCode,
                         param_commcontnum,
                         arlseqvl,
                         param_Site,
                         \*sysdate,*\
                         0) PurVariantExtCode,
             allowancechargerate,
             allowancechargeuom,
             allowancechargecode,
             productid
        FROM im_edi_invoice_itemdeals, artvl
       WHERE invoicenumber = param_invoicenumber
         AND vendordunsnumber = param_VendorDunsNumber
         AND NOT EXISTS
       (SELECT 1
                FROM intcfinv, intcfbl, stoentre, fouadres
               WHERE cfiinvid = cfbinvid
                 AND cficfin = cfbcfin
                 AND fadcfin = cficfin
                 AND serbliv = param_DeliveryNoteNumber
                 AND sercfin = cficfin
                 AND sersite = cfisite
                 AND serccin = cficcin
                 AND sersite = param_Site
                 AND FADACCI = param_VendorDunsNumber
                 AND cfiinvid = param_invoicenumber)
         AND arlseqvl = getSeqvl(NULL, productid, sysdate);*/
  
    -- Get the item deals not found in reception for the invoice
    CURSOR get_invoice_it_deals_adon IS
      SELECT arlcexvl,
             arlcexr,
             getARAREFC(sercfin,
                        serccin,
                        arlseqvl,
                        sersite,
                        serdcom,
                        serfilf) Refc,
             getARACEXTA(sercfin,
                         serccin,
                         arlseqvl,
                         sersite,
                         serdcom,
                         serfilf) PurVariantExtCode,
             ild.allowancechargerate,
             ild.allowancetotalamount,
             ild.allowancechargeuom,
             --ild.allowancechargecode,
             decode(ild.allowancechargecode,
                    2,
                    5,
                    6,
                    20,
                    ild.allowancechargecode) allowancechargecode,
             ild.productid,
             det.QtyInvoiced QtyInvoiced,
             det.QtyInvoiced * (getSKUUnits(arlcexr, arlcexvl, det.QtyUOM)) SKUQtyInvoiced,
             det.QtyUOM,
             ild.allowancecharge
        FROM im_edi_invoice_itemdeals ild,
             im_edi_invoice_detail det,
             artvl,
             stoentre
       WHERE det.invoicenumber = param_invoicenumber
         AND ild.invoicenumber = param_invoicenumber
         AND ild.vendordunsnumber = det.vendordunsnumber
         AND ild.vendordunsnumber = param_VendorDunsNumber
         AND serbliv = param_DeliveryNoteNumber
            --AND sersite = param_Site
         AND sercfin = param_SupplierInternalCode
         AND ild.productid = det.productid
         AND det.importbatchid = ild.importbatchid
         AND det.importbatchid = param_BatchID
         AND NOT EXISTS
       (SELECT 1
                FROM stoentre, stodetre, storemre
               WHERE serbliv = param_DeliveryNoteNumber
                    --AND sersite = param_Site
                 AND sercinrec = sdrcinrec
                 AND srrcinrec = sercinrec
                 AND srrtrem = decode(ild.allowancechargecode,
                                      2,
                                      5,
                                      6,
                                      20,
                                      ild.allowancechargecode)
                 AND sdrnlrec = srrnlrec
                 AND sdrcinr = arlcinr
                 AND sdrseqvl = arlseqvl)
         AND arlseqvl = decode(getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite),
                               -1,
                               getSeqvltoReplace(sercfin, serdcom),
                               getSeqvl(sercinrec,
                                        det.productid,
                                        serdcom,
                                        sercfin,
                                        serccin,
                                        sersite));
  
    CURSOR get_invoice_itdeals_unauth IS
      SELECT cfrcexr,
             cfrcexvl,
             cfrcexta,
             cfrrefc,
             cfrunar,
             cfrtypr,
             round(sum(cfrvale * CFRDFLGI) /
                   (SELECT sum(nvl(cfaqty, 0))
                      FROM intcfart
                     WHERE cfainvid = cfrinvid
                       AND cfacfex = cfrcfex
                       AND cfablid = cfrblid
                       AND cfacexr = cfrcexr),
                   5) UnitDealValue
        FROM intcfremise
       WHERE cfrinvid = param_invoicenumber
         AND cfrblid = param_DeliveryNoteNumber
       GROUP BY cfrinvid,
                cfrcfex,
                cfrblid,
                cfrcexr,
                cfrcexvl,
                cfrcexta,
                cfrrefc,
                cfrunar,
                cfrtypr
      HAVING COUNT(cfrcexr) > 1;
  
    loc_DealAlreadyExists NUMBER(5);
  
  BEGIN
  
    glo_Section := 'LoadIntcfremise Starts';
  
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
  
    loc_LineNo := 1;
  
    loc_DealAlreadyExists := 0;
    SELECT COUNT(*)
      INTO loc_DealAlreadyExists
      FROM intcfremise
     WHERE cfrinvid = param_InvoiceNumber
       AND CFRCFEX = param_SupplierExternalCode;
  
    IF loc_DealAlreadyExists <> 0 THEN
      DELETE FROM intcfremise
       WHERE cfrinvid = param_InvoiceNumber
         AND CFRCFEX = param_SupplierExternalCode;
      COMMIT;
    END IF;
  
    FOR rec_get_invoice_it_deals IN get_invoice_it_deals LOOP
      glo_Section := 'Insert LoadIntcfremise1:Deal' ||
                     rec_get_invoice_it_deals.srrtrem;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfremiseRecord.CFRCFEX   := param_SupplierExternalCode;
      loc_IntcfremiseRecord.CFRINVID  := param_InvoiceNumber;
      loc_IntcfremiseRecord.CFRBLID   := param_DeliveryNoteNumber;
      loc_IntcfremiseRecord.CFRCEXCDE := NULL;
      loc_IntcfremiseRecord.CFRTYPE   := 1;
      loc_IntcfremiseRecord.CFRREFID  := NULL;
      loc_IntcfremiseRecord.CFRCEXR   := rec_get_invoice_it_deals.arlcexr;
      loc_IntcfremiseRecord.CFRCEXVL  := rec_get_invoice_it_deals.arlcexvl;
      loc_IntcfremiseRecord.CFRCEXTA  := rec_get_invoice_it_deals.PurVariantExtCode;
      loc_IntcfremiseRecord.CFRREFC   := rec_get_invoice_it_deals.Refc;
      loc_IntcfremiseRecord.CFRCEXREM := rec_get_invoice_it_deals.trecexrem;
    
      IF rec_get_invoice_it_deals.allowancechargerate <> 0 Then
        -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        loc_IntcfremiseRecord.CFRVALE :=  /*-1 **/
         rec_get_invoice_it_deals.calcallowancechargerate; -- discount value      
        loc_IntcfremiseRecord.CFRUNAR := rec_get_invoice_it_deals.srruapp; -- discount UOM
      ELSIF rec_get_invoice_it_deals.allowancetotalamount <> 0 THEN
        -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        loc_IntcfremiseRecord.CFRVALE :=  /* -1 **/
         (rec_get_invoice_it_deals.allowancetotalamount /
                                         rec_get_invoice_it_deals.SKUQtyInvoiced); -- discount value  
        --loc_IntcfremiseRecord.CFRUNAR := rec_get_invoice_it_deals.QtyUOM; -- discount UOM
        loc_IntcfremiseRecord.CFRUNAR := 1; -- discount UOM
      END IF;
    
      -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
      IF rec_get_invoice_it_deals.allowancecharge = 'A' then
        loc_IntcfremiseRecord.CFRVALE := abs(loc_IntcfremiseRecord.CFRVALE);
      ELSIF rec_get_invoice_it_deals.allowancecharge = 'C' then
        loc_IntcfremiseRecord.CFRVALE := -1 *
                                         abs(loc_IntcfremiseRecord.CFRVALE);
        -- Other than 810 EDI files
      ELSE
        loc_IntcfremiseRecord.CFRVALE := -1 * loc_IntcfremiseRecord.CFRVALE;
      END IF;
    
      loc_IntcfremiseRecord.CFRUNIT := rec_get_invoice_it_deals.srrunit; -- discount application unit
      loc_IntcfremiseRecord.CFRORDC := rec_get_invoice_it_deals.srrordc;
      loc_IntcfremiseRecord.CFRORDA := rec_get_invoice_it_deals.srrorda;
      loc_IntcfremiseRecord.CFRTYPR := rec_get_invoice_it_deals.srrtrem; -- discount type
    
      loc_IntcfremiseRecord.CFRDFLGI  := rec_get_invoice_it_deals.QtyInvoiced; -- 1
      loc_IntcfremiseRecord.CFRSTAT   := const_INTERFACESTATUS;
      loc_IntcfremiseRecord.CFRDTRT   := SYSDATE;
      loc_IntcfremiseRecord.CFRFICH   := substr(param_FileName, 1, 50);
      loc_IntcfremiseRecord.CFRNLIG   := loc_LineNo;
      loc_IntcfremiseRecord.CFRNERR   := NULL;
      loc_IntcfremiseRecord.CFRMESS   := NULL;
      loc_IntcfremiseRecord.CFRDCRE   := SYSDATE;
      loc_IntcfremiseRecord.CFRDMAJ   := SYSDATE;
      loc_IntcfremiseRecord.CFRUTIL   := const_UTIL;
      loc_IntcfremiseRecord.CFRCODLOG := NULL;
      loc_IntcfremiseRecord.CFRCODCAI := NULL;
    
      INSERT INTO intcfremise VALUES loc_IntcfremiseRecord;
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingItDeals(param_InvoiceNumber,
                           param_VendorDunsNumber,
                           rec_get_invoice_it_deals.productid,
                           param_BatchID,
                           rec_get_invoice_it_deals.srrtrem,
                           2,
                           'OracleStaging_To_Interface');
    
    END LOOP;
  
    /*  loc_LineNo := 1;
    FOR rec_get_invoice_it_deals_wor IN get_invoice_it_deals_wor LOOP
      glo_Section := 'Insert LoadIntcfremise2:Deal' ||
                     rec_get_invoice_it_deals_wor.allowancechargecode;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfremiseRecord.CFRCFEX   := param_SupplierExternalCode;
      loc_IntcfremiseRecord.CFRINVID  := param_invoicenumber;
      loc_IntcfremiseRecord.CFRBLID   := param_DeliveryNoteNumber;
      loc_IntcfremiseRecord.CFRCEXCDE := NULL;
      loc_IntcfremiseRecord.CFRTYPE   := 1;
      loc_IntcfremiseRecord.CFRREFID  := NULL;
      loc_IntcfremiseRecord.CFRCEXR   := rec_get_invoice_it_deals_wor.arlcexr;
      loc_IntcfremiseRecord.CFRCEXVL  := rec_get_invoice_it_deals_wor.arlcexvl;
      loc_IntcfremiseRecord.CFRCEXTA  := rec_get_invoice_it_deals_wor.PurVariantExtCode;
      loc_IntcfremiseRecord.CFRREFC   := rec_get_invoice_it_deals_wor.Refc;
      loc_IntcfremiseRecord.CFRCEXREM := NULL;
      loc_IntcfremiseRecord.CFRVALE   := rec_get_invoice_it_deals_wor.allowancechargerate; -- discount value
      loc_IntcfremiseRecord.CFRUNIT   := 2; -- discount application unit
      loc_IntcfremiseRecord.CFRORDC   := 10;
      loc_IntcfremiseRecord.CFRORDA   := 10;
      loc_IntcfremiseRecord.CFRTYPR   := rec_get_invoice_it_deals_wor.allowancechargecode; -- discount type
      loc_IntcfremiseRecord.CFRUNAR   := rec_get_invoice_it_deals_wor.allowancechargeuom; -- discount UOM
      loc_IntcfremiseRecord.CFRDFLGI  := 1;
      loc_IntcfremiseRecord.CFRSTAT   := const_INTERFACESTATUS;
      loc_IntcfremiseRecord.CFRDTRT   := SYSDATE;
      loc_IntcfremiseRecord.CFRFICH   := param_FileName;
      loc_IntcfremiseRecord.CFRNLIG   := loc_LineNo;
      loc_IntcfremiseRecord.CFRNERR   := NULL;
      loc_IntcfremiseRecord.CFRMESS   := NULL;
      loc_IntcfremiseRecord.CFRDCRE   := SYSDATE;
      loc_IntcfremiseRecord.CFRDMAJ   := SYSDATE;
      loc_IntcfremiseRecord.CFRUTIL   := const_UTIL;
      loc_IntcfremiseRecord.CFRCODLOG := NULL;
      loc_IntcfremiseRecord.CFRCODCAI := NULL;
    
      INSERT INTO intcfremise VALUES loc_IntcfremiseRecord;
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingItDeals(param_InvoiceNumber,
                           param_VendorDunsNumber,
                           rec_get_invoice_it_deals_wor.productid,
                           param_BatchID,
                           rec_get_invoice_it_deals_wor.AllowanceChargeCode,
                           2,
                           'OracleStaging_To_Interface');
    
    END LOOP;*/
  
    -- loc_LineNo := 1;
    FOR rec_get_invoice_it_deals_adon IN get_invoice_it_deals_adon LOOP
      glo_Section := 'Insert LoadIntcfremise3:Deal' ||
                     rec_get_invoice_it_deals_adon.allowancechargecode;
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      loc_IntcfremiseRecord.CFRCFEX   := param_SupplierExternalCode;
      loc_IntcfremiseRecord.CFRINVID  := param_InvoiceNumber;
      loc_IntcfremiseRecord.CFRBLID   := param_DeliveryNoteNumber;
      loc_IntcfremiseRecord.CFRCEXCDE := NULL;
      loc_IntcfremiseRecord.CFRTYPE   := 1;
      loc_IntcfremiseRecord.CFRREFID  := NULL;
      loc_IntcfremiseRecord.CFRCEXR   := rec_get_invoice_it_deals_adon.arlcexr;
      loc_IntcfremiseRecord.CFRCEXVL  := rec_get_invoice_it_deals_adon.arlcexvl;
      loc_IntcfremiseRecord.CFRCEXTA  := rec_get_invoice_it_deals_adon.PurVariantExtCode;
      loc_IntcfremiseRecord.CFRREFC   := rec_get_invoice_it_deals_adon.Refc;
      loc_IntcfremiseRecord.CFRCEXREM := NULL;
    
      IF rec_get_invoice_it_deals_adon.allowancechargerate <> 0 Then
        -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        loc_IntcfremiseRecord.CFRVALE :=  /* -1 **/
         rec_get_invoice_it_deals_adon.allowancechargerate; -- discount value      
        loc_IntcfremiseRecord.CFRUNAR := nvl(rec_get_invoice_it_deals_adon.allowancechargeuom,
                                             rec_get_invoice_it_deals_adon.qtyuom); -- discount UOM
      ELSIF rec_get_invoice_it_deals_adon.allowancetotalamount <> 0 THEN
        -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
        loc_IntcfremiseRecord.CFRVALE :=  /* -1 **/
         (rec_get_invoice_it_deals_adon.allowancetotalamount /
                                         rec_get_invoice_it_deals_adon.SKUQtyInvoiced); -- discount value  
        --loc_IntcfremiseRecord.CFRUNAR := rec_get_invoice_it_deals_adon.QtyUOM; -- discount UOM
        loc_IntcfremiseRecord.CFRUNAR := 1; -- discount UOM
      END IF;
    
      -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
      IF rec_get_invoice_it_deals_adon.allowancecharge = 'A' then
        loc_IntcfremiseRecord.CFRVALE := abs(loc_IntcfremiseRecord.CFRVALE);
      ELSIF rec_get_invoice_it_deals_adon.allowancecharge = 'C' then
        loc_IntcfremiseRecord.CFRVALE := -1 *
                                         abs(loc_IntcfremiseRecord.CFRVALE);
        -- Other than 810 EDI files
      ELSE
        loc_IntcfremiseRecord.CFRVALE := -1 * loc_IntcfremiseRecord.CFRVALE;
      END IF;
    
      -- loc_IntcfremiseRecord.CFRVALE   := rec_get_invoice_it_deals_adon.allowancechargerate; -- discount value
      loc_IntcfremiseRecord.CFRUNIT   := 2; -- discount application unit
      loc_IntcfremiseRecord.CFRORDC   := 10;
      loc_IntcfremiseRecord.CFRORDA   := 10;
      loc_IntcfremiseRecord.CFRTYPR   := rec_get_invoice_it_deals_adon.allowancechargecode; -- discount type   
      loc_IntcfremiseRecord.CFRDFLGI  := rec_get_invoice_it_deals_adon.QtyInvoiced; --1
      loc_IntcfremiseRecord.CFRSTAT   := const_INTERFACESTATUS;
      loc_IntcfremiseRecord.CFRDTRT   := SYSDATE;
      loc_IntcfremiseRecord.CFRFICH   := substr(param_FileName, 1, 50);
      loc_IntcfremiseRecord.CFRNLIG   := loc_LineNo;
      loc_IntcfremiseRecord.CFRNERR   := NULL;
      loc_IntcfremiseRecord.CFRMESS   := NULL;
      loc_IntcfremiseRecord.CFRDCRE   := SYSDATE;
      loc_IntcfremiseRecord.CFRDMAJ   := SYSDATE;
      loc_IntcfremiseRecord.CFRUTIL   := const_UTIL;
      loc_IntcfremiseRecord.CFRCODLOG := NULL;
      loc_IntcfremiseRecord.CFRCODCAI := NULL;
    
      INSERT INTO intcfremise VALUES loc_IntcfremiseRecord;
      loc_LineNo := loc_LineNo + 1;
    
      UpdateStagingItDeals(param_InvoiceNumber,
                           param_VendorDunsNumber,
                           rec_get_invoice_it_deals_adon.productid,
                           param_BatchID,
                           rec_get_invoice_it_deals_adon.AllowanceChargeCode,
                           2,
                           'OracleStaging_To_Interface');
    
    END LOOP;
  
    FOR rec_get_invoice_itdeals_unauth IN get_invoice_itdeals_unauth LOOP
    
      loc_IntcfremiseRecord.CFRCFEX   := param_SupplierExternalCode;
      loc_IntcfremiseRecord.CFRINVID  := param_InvoiceNumber;
      loc_IntcfremiseRecord.CFRBLID   := param_DeliveryNoteNumber;
      loc_IntcfremiseRecord.CFRCEXCDE := NULL;
      loc_IntcfremiseRecord.CFRTYPE   := 1;
      loc_IntcfremiseRecord.CFRREFID  := NULL;
      loc_IntcfremiseRecord.CFRCEXR   := rec_get_invoice_itdeals_unauth.cfrcexr;
      loc_IntcfremiseRecord.CFRCEXVL  := rec_get_invoice_itdeals_unauth.cfrcexvl;
      loc_IntcfremiseRecord.CFRCEXTA  := rec_get_invoice_itdeals_unauth.cfrcexta;
      loc_IntcfremiseRecord.CFRREFC   := rec_get_invoice_itdeals_unauth.cfrrefc;
      loc_IntcfremiseRecord.CFRCEXREM := NULL;
      loc_IntcfremiseRecord.CFRVALE   := rec_get_invoice_itdeals_unauth.unitdealvalue;
      loc_IntcfremiseRecord.CFRUNAR   := rec_get_invoice_itdeals_unauth.cfrunar;
      loc_IntcfremiseRecord.CFRUNIT   := 2; -- discount application unit
      loc_IntcfremiseRecord.CFRORDC   := 10;
      loc_IntcfremiseRecord.CFRORDA   := 10;
      loc_IntcfremiseRecord.CFRTYPR   := rec_get_invoice_itdeals_unauth.cfrtypr; -- discount type   
      loc_IntcfremiseRecord.CFRDFLGI  := 1;
      loc_IntcfremiseRecord.CFRSTAT   := const_INTERFACESTATUS;
      loc_IntcfremiseRecord.CFRDTRT   := SYSDATE;
      loc_IntcfremiseRecord.CFRFICH   := substr(param_FileName, 1, 50);
      loc_IntcfremiseRecord.CFRNLIG   := loc_LineNo;
      loc_IntcfremiseRecord.CFRNERR   := NULL;
      loc_IntcfremiseRecord.CFRMESS   := NULL;
      loc_IntcfremiseRecord.CFRDCRE   := SYSDATE;
      loc_IntcfremiseRecord.CFRDMAJ   := SYSDATE;
      loc_IntcfremiseRecord.CFRUTIL   := 'EDI894_MOD';
      loc_IntcfremiseRecord.CFRCODLOG := NULL;
      loc_IntcfremiseRecord.CFRCODCAI := NULL;
    
      INSERT INTO intcfremise VALUES loc_IntcfremiseRecord;
    
      DELETE FROM intcfremise
       WHERE cfrinvid = param_InvoiceNumber
         AND cfrblid = param_DeliveryNoteNumber
         AND cfrcexr = rec_get_invoice_itdeals_unauth.cfrcexr
         AND cfrtypr = rec_get_invoice_itdeals_unauth.cfrtypr
         AND cfrcexvl = rec_get_invoice_itdeals_unauth.cfrcexvl
         AND cfrunar = rec_get_invoice_itdeals_unauth.cfrunar
         AND CFRUTIL = const_UTIL;
    
    END LOOP;
  
    glo_Section := 'LoadIntcfremise End';
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfremise', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfremise', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE LoadIntcfpied(param_VendorDunsNumber     fouadres.FADACCI%TYPE,
                          param_BatchID              NUMBER,
                          param_invoicenumber        cfdenfac.efarfou%TYPE,
                          param_SupplierInternalCode cfdenfac.efacfin%TYPE,
                          param_SupplierExternalCode foudgene.foucnuf%TYPE,
                          param_Site                 cdeentcde.ecdsite%TYPE,
                          --param_OrderInternalCode    cdeentcde.ecdcincde%TYPE,
                          --param_OrderExternalCode    cdeentcde.ecdcexcde%TYPE,
                          param_FileName           VARCHAR2,
                          param_DeliveryNoteNumber stoentre.serbliv%TYPE,
                          --param_CommContNum          cfdenfac.efaccin%TYPE,
                          param_CommContCode    fouccom.fccnum%TYPE,
                          param_creditdebitflag VARCHAR2
                          --param_InsertORUpdateFlag   NUMBER,
                          --param_CheckReceptionFlag   NUMBER
                          ) IS
  
    loc_IntcfpiedRecord intcfpied%ROWTYPE;
  
    -- Get the footer deals found in reception for the invoice
    CURSOR get_invoice_ft_deals IS
      SELECT sprtrem,
             sprsrub,
             sprunit,
             sprordc,
             sprorda,
             totalinvoiceamount,
             allowancechargerate,
             allowancetotalamount,
             allowancecharge
        FROM im_edi_invoice_ftdeals ft,
             stoentre,
             stopiere,
             im_edi_invoice_header hd
       WHERE ft.invoicenumber = param_invoicenumber
         AND ft.vendordunsnumber = param_VendorDunsNumber
         AND sersite = param_Site
         AND sercinrec = sprcinrec
         AND serbliv = param_DeliveryNoteNumber
         AND sprtrem =
             decode(allowancechargecode, 2, 5, 6, 20, allowancechargecode)
         AND sprrubr = 2
         AND ft.invoicenumber = hd.invoicenumber
         AND ft.vendordunsnumber = hd.vendordunsnumber
         AND hd.importbatchid = ft.importbatchid
         AND hd.importbatchid = param_BatchID;
  
    /*  -- Get the footer deals for the invoice without reception
    CURSOR get_invoice_ft_deals_wor IS
      SELECT allowancechargeuom,
             totalinvoiceamount,
             allowancechargerate,
             allowancechargecode
        FROM im_edi_invoice_ftdeals ft, im_edi_invoice_header hd
       WHERE NOT EXISTS (SELECT 1
                FROM intcfinv, intcfbl, stoentre, fouadres
               WHERE cfiinvid = cfbinvid
                 AND cficfin = cfbcfin
                 AND fadcfin = cficfin
                 AND serbliv = param_DeliveryNoteNumber
                 AND sercfin = cficfin
                 AND sersite = cfisite
                 AND serccin = cficcin
                 AND sersite = param_Site
                 AND FADACCI = param_VendorDunsNumber
                 AND cfiinvid = param_invoicenumber)
         AND ft.invoicenumber = param_invoicenumber
         AND hd.invoicenumber = ft.invoicenumber
         AND hd.vendordunsnumber = ft.vendordunsnumber
         AND ft.vendordunsnumber = param_VendorDunsNumber;*/
  
    -- Get the footer deals not found in reception for the invoice
    CURSOR get_invoice_ft_deals_adon IS
      SELECT allowancechargeuom,
             totalinvoiceamount,
             allowancechargerate,
             --allowancechargecode,
             decode(allowancechargecode, 2, 5, 6, 20, allowancechargecode) allowancechargecode,
             allowancetotalamount,
             allowancecharge
        FROM im_edi_invoice_ftdeals ft,
             im_edi_invoice_header  hd,
             stoentre               hd
       WHERE ft.invoicenumber = param_invoicenumber
         AND ft.vendordunsnumber = param_VendorDunsNumber
         AND serbliv = param_DeliveryNoteNumber
            --  AND sersite = param_Site
         AND sercfin = param_SupplierInternalCode
         AND hd.importbatchid = ft.importbatchid
         AND hd.importbatchid = param_BatchID
         AND NOT EXISTS
       (SELECT 1
                FROM stoentre, stopiere
               WHERE sercinrec = sprcinrec
                 AND sprtrem = decode(allowancechargecode,
                                      2,
                                      5,
                                      6,
                                      20,
                                      allowancechargecode)
                 AND sprrubr = 2
                 AND hd.sersite = sersite
                 AND sercfin = param_SupplierInternalCode
                 AND hd.sercinrec = sercinrec)
         AND ft.invoicenumber = hd.invoicenumber
         AND ft.vendordunsnumber = hd.vendordunsnumber;
  
    loc_LineNo            NUMBER(5) := 0;
    loc_DealAlreadyExists NUMBER(3);
  BEGIN
    glo_Section := 'LoadIntcfpied Starts';
  
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section || param_Site ||
                           param_DeliveryNoteNumber || param_invoicenumber ||
                           param_SupplierInternalCode);
    END IF;
    loc_LineNo := 1;
  
    loc_DealAlreadyExists := 0;
    SELECT COUNT(*)
      INTO loc_DealAlreadyExists
      FROM intcfpied
     WHERE cfpinvid = param_InvoiceNumber
       AND CFPCFEX = param_SupplierExternalCode;
  
    IF loc_DealAlreadyExists <> 0 THEN
      DELETE FROM intcfpied
       WHERE cfpinvid = param_InvoiceNumber
         AND CFPCFEX = param_SupplierExternalCode;
    
      COMMIT;
    END IF;
  
    FOR rec_get_invoice_ft_deals IN get_invoice_ft_deals LOOP
      glo_Section := 'Insert LoadIntcfpied:Deal' ||
                     rec_get_invoice_ft_deals.sprtrem;
    
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
      loc_IntcfpiedRecord.CFPCFEX  := param_SupplierExternalCode;
      loc_IntcfpiedRecord.CFPCCEX  := param_commcontcode;
      loc_IntcfpiedRecord.CFPINVID := param_InvoiceNumber;
      loc_IntcfpiedRecord.CFPBLID  := param_DeliveryNoteNumber;
      loc_IntcfpiedRecord.CFPREFID := NULL;
      loc_IntcfpiedRecord.CFPTYPE  := 1;
      loc_IntcfpiedRecord.CFPSITE  := param_Site;
      loc_IntcfpiedRecord.CFPTYPR  := rec_get_invoice_ft_deals.sprtrem;
      loc_IntcfpiedRecord.CFPSRUB  := rec_get_invoice_ft_deals.sprsrub;
      loc_IntcfpiedRecord.CFPUNIT  := 2; --rec_get_invoice_ft_deals.sprunit (hardcoded based on given mapping)
      loc_IntcfpiedRecord.CFPORDC  := rec_get_invoice_ft_deals.sprordc;
      loc_IntcfpiedRecord.CFPORDA  := rec_get_invoice_ft_deals.sprorda;
      loc_IntcfpiedRecord.CFPBASE  := rec_get_invoice_ft_deals.totalinvoiceamount; -- Base Amt
      -- loc_IntcfpiedRecord.CFPVALE   := rec_get_invoice_ft_deals.allowancechargerate; -- Discount value     
    
      IF rec_get_invoice_ft_deals.allowancechargerate <> 0 THEN
        loc_IntcfpiedRecord.CFPVALE :=  /*-1 **/
         rec_get_invoice_ft_deals.allowancechargerate; -- Discount value
      ELSIF rec_get_invoice_ft_deals.allowancetotalamount <> 0 THEN
        loc_IntcfpiedRecord.CFPVALE :=  /*-1 **/
         rec_get_invoice_ft_deals.allowancetotalamount; -- Discount value
      ELSE
        loc_IntcfpiedRecord.CFPVALE := 0;
      END IF;
    
      -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
      IF rec_get_invoice_ft_deals.allowancecharge = 'A' then
        loc_IntcfpiedRecord.CFPVALE := abs(loc_IntcfpiedRecord.CFPVALE);
      ELSIF rec_get_invoice_ft_deals.allowancecharge = 'C' then
        loc_IntcfpiedRecord.CFPVALE := -1 *
                                       abs(loc_IntcfpiedRecord.CFPVALE);
        -- Other than 810 EDI files
      ELSE
        loc_IntcfpiedRecord.CFPVALE := -1 * loc_IntcfpiedRecord.CFPVALE;
      END IF;
    
      loc_IntcfpiedRecord.CFPMONT   := 0;
      loc_IntcfpiedRecord.CFPDFLGI  := 1;
      loc_IntcfpiedRecord.CFPSTAT   := const_INTERFACESTATUS;
      loc_IntcfpiedRecord.CFPDTRT   := SYSDATE;
      loc_IntcfpiedRecord.CFPFICH   := substr(param_FileName, 1, 50);
      loc_IntcfpiedRecord.CFPNLIG   := loc_LineNo;
      loc_IntcfpiedRecord.CFPNERR   := NULL;
      loc_IntcfpiedRecord.CFPMESS   := NULL;
      loc_IntcfpiedRecord.CFPDCRE   := SYSDATE;
      loc_IntcfpiedRecord.CFPDMAJ   := SYSDATE;
      loc_IntcfpiedRecord.CFPUTIL   := const_UTIL;
      loc_IntcfpiedRecord.CFPCEXREM := NULL;
      loc_IntcfpiedRecord.CFPCEXCDE := NULL;
    
      INSERT INTO intcfpied VALUES loc_IntcfpiedRecord;
      loc_LineNo := loc_LineNo + 1;
      UpdateStagingFtDeals(param_InvoiceNumber,
                           param_VendorDunsNumber,
                           param_BatchID,
                           rec_get_invoice_ft_deals.sprtrem,
                           2,
                           'OracleStaging_To_Interface');
    
    END LOOP;
  
    /* loc_LineNo := 1;
      FOR rec_get_invoice_ft_deals_wor IN get_invoice_ft_deals_wor LOOP
        glo_Section := 'Insert LoadIntcfpied2:Deal' ||
                       rec_get_invoice_ft_deals_wor.allowancechargecode;
      
        IF glo_DebugFlag = 1 THEN
          dbms_output.put_line(glo_Section);
        END IF;
      
        loc_IntcfpiedRecord.CFPCFEX   := param_SupplierExternalCode;
        loc_IntcfpiedRecord.CFPCCEX   := param_commcontcode;
        loc_IntcfpiedRecord.CFPINVID  := param_invoicenumber;
        loc_IntcfpiedRecord.CFPBLID   := param_DeliveryNoteNumber;
        loc_IntcfpiedRecord.CFPREFID  := NULL;
        loc_IntcfpiedRecord.CFPTYPE   := 1;
        loc_IntcfpiedRecord.CFPSITE   := param_Site;
        loc_IntcfpiedRecord.CFPTYPR   := rec_get_invoice_ft_deals_wor.allowancechargecode;
        loc_IntcfpiedRecord.CFPSRUB   := rec_get_invoice_ft_deals_wor.allowancechargecode;
        loc_IntcfpiedRecord.CFPUNIT   := 2; --rec_get_invoice_ft_deals.sprunit (hardcoded based on given mapping)
        loc_IntcfpiedRecord.CFPORDC   := 10;
        loc_IntcfpiedRecord.CFPORDA   := 10;
        loc_IntcfpiedRecord.CFPBASE   := rec_get_invoice_ft_deals_wor.totalinvoiceamount; -- Base Amt
        loc_IntcfpiedRecord.CFPVALE   := rec_get_invoice_ft_deals_wor.allowancechargerate; -- Discount value
        loc_IntcfpiedRecord.CFPMONT   := 0;
        loc_IntcfpiedRecord.CFPDFLGI  := 1;
        loc_IntcfpiedRecord.CFPSTAT   := const_INTERFACESTATUS;
        loc_IntcfpiedRecord.CFPDTRT   := SYSDATE;
        loc_IntcfpiedRecord.CFPFICH   := param_FileName;
        loc_IntcfpiedRecord.CFPNLIG   := loc_LineNo;
        loc_IntcfpiedRecord.CFPNERR   := NULL;
        loc_IntcfpiedRecord.CFPMESS   := NULL;
        loc_IntcfpiedRecord.CFPDCRE   := SYSDATE;
        loc_IntcfpiedRecord.CFPDMAJ   := SYSDATE;
        loc_IntcfpiedRecord.CFPUTIL   := const_UTIL;
        loc_IntcfpiedRecord.CFPCEXREM := NULL;
        loc_IntcfpiedRecord.CFPCEXCDE := NULL;
      
        INSERT INTO intcfpied VALUES loc_IntcfpiedRecord;
      
        loc_LineNo := loc_LineNo + 1;
      
        UpdateStagingFtDeals(param_InvoiceNumber,
                             param_VendorDunsNumber,
                             param_BatchID,
                             rec_get_invoice_ft_deals_wor.allowancechargecode,
                             2,
                             'OracleStaging_To_Interface');
      
      END LOOP;
    */
    -- loc_LineNo := 1;
    FOR rec_get_invoice_ft_deals_adon IN get_invoice_ft_deals_adon LOOP
      glo_Section := 'Insert LoadIntcfpied3:Deal' ||
                     rec_get_invoice_ft_deals_adon.allowancechargecode;
    
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_Section);
      END IF;
    
      loc_IntcfpiedRecord.CFPCFEX  := param_SupplierExternalCode;
      loc_IntcfpiedRecord.CFPCCEX  := param_commcontcode;
      loc_IntcfpiedRecord.CFPINVID := param_InvoiceNumber;
      loc_IntcfpiedRecord.CFPBLID  := param_DeliveryNoteNumber;
      loc_IntcfpiedRecord.CFPREFID := NULL;
      loc_IntcfpiedRecord.CFPTYPE  := 1;
      loc_IntcfpiedRecord.CFPSITE  := param_Site;
      loc_IntcfpiedRecord.CFPTYPR  := rec_get_invoice_ft_deals_adon.allowancechargecode;
      loc_IntcfpiedRecord.CFPSRUB  := rec_get_invoice_ft_deals_adon.allowancechargecode;
      loc_IntcfpiedRecord.CFPUNIT  := 2; --rec_get_invoice_ft_deals.sprunit (hardcoded based on given mapping)
      loc_IntcfpiedRecord.CFPORDC  := 10;
      loc_IntcfpiedRecord.CFPORDA  := 10;
      loc_IntcfpiedRecord.CFPBASE  := rec_get_invoice_ft_deals_adon.totalinvoiceamount; -- Base Amt
      --loc_IntcfpiedRecord.CFPVALE   := rec_get_invoice_ft_deals_adon.allowancechargerate; -- Discount value
    
      IF rec_get_invoice_ft_deals_adon.allowancechargerate <> 0 THEN
        loc_IntcfpiedRecord.CFPVALE :=  /*-1 **/
         rec_get_invoice_ft_deals_adon.allowancechargerate; -- Discount value
      ELSIF rec_get_invoice_ft_deals_adon.allowancetotalamount <> 0 THEN
        loc_IntcfpiedRecord.CFPVALE :=  /* -1 **/
         rec_get_invoice_ft_deals_adon.allowancetotalamount; -- Discount value
      ELSE
        loc_IntcfpiedRecord.CFPVALE := 0;
      END IF;
    
      -- Kanchana:03042015:Fix for handling 810 EDI files(which will have A & C for allowance and charges instead of Sign)
      IF rec_get_invoice_ft_deals_adon.allowancecharge = 'A' then
        loc_IntcfpiedRecord.CFPVALE := abs(loc_IntcfpiedRecord.CFPVALE);
      ELSIF rec_get_invoice_ft_deals_adon.allowancecharge = 'C' then
        loc_IntcfpiedRecord.CFPVALE := -1 *
                                       abs(loc_IntcfpiedRecord.CFPVALE);
        -- Other than 810 EDI files
      ELSE
        loc_IntcfpiedRecord.CFPVALE := -1 * loc_IntcfpiedRecord.CFPVALE;
      END IF;
    
      loc_IntcfpiedRecord.CFPMONT   := 0;
      loc_IntcfpiedRecord.CFPDFLGI  := 1;
      loc_IntcfpiedRecord.CFPSTAT   := const_INTERFACESTATUS;
      loc_IntcfpiedRecord.CFPDTRT   := SYSDATE;
      loc_IntcfpiedRecord.CFPFICH   := substr(param_FileName, 1, 50);
      loc_IntcfpiedRecord.CFPNLIG   := loc_LineNo;
      loc_IntcfpiedRecord.CFPNERR   := NULL;
      loc_IntcfpiedRecord.CFPMESS   := NULL;
      loc_IntcfpiedRecord.CFPDCRE   := SYSDATE;
      loc_IntcfpiedRecord.CFPDMAJ   := SYSDATE;
      loc_IntcfpiedRecord.CFPUTIL   := const_UTIL;
      loc_IntcfpiedRecord.CFPCEXREM := NULL;
      loc_IntcfpiedRecord.CFPCEXCDE := NULL;
    
      INSERT INTO intcfpied VALUES loc_IntcfpiedRecord;
      loc_LineNo := loc_LineNo + 1;
      UpdateStagingFtDeals(param_InvoiceNumber,
                           param_VendorDunsNumber,
                           param_BatchID,
                           rec_get_invoice_ft_deals_adon.allowancechargecode,
                           2,
                           'OracleStaging_To_Interface');
    
    END LOOP;
    glo_Section := 'LoadIntcfpied End';
    IF glo_DebugFlag = 1 THEN
      dbms_output.put_line(glo_Section);
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfpied', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'LoadIntcfpied', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  FUNCTION getSeqvltoReplace(param_Vendor    artuc.ARACFIN%TYPE,
                             param_OrderDate in cdeentcde.ecddcom%type)
    RETURN NUMBER IS
    loc_LVIntCode artvl.arlseqvl%TYPE;
  BEGIN
    SELECT /*+ rule */  araseqvl
      INTO loc_LVIntCode
      FROM artuc
     WHERE aracfin = param_Vendor
       AND param_OrderDate BETWEEN araddeb AND aradfin
       AND EXISTS (SELECT 1
              FROM artrac, artattri
             WHERE artcinr = aatcinr
               and AATCCLA = 'EDI'
               AND artcinr = aracinr)
       AND rownum <= 1;
  
    RETURN loc_LVIntCode;
  
  EXCEPTION
    WHEN OTHERS THEN
      RETURN - 1;
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvltoReplace', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvltoReplace', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  FUNCTION getSeqvl(param_OrderNumber   in stoentre.sercexcde%type,
                    param_UPCCode       VARCHAR2,
                    param_OrderDate     in cdeentcde.ecddcom%type,
                    param_VendorIntCode in stoentre.sercfin%type,
                    param_CommCont      in stoentre.serccin%type,
                    param_Site          in stoentre.sersite%type)
    RETURN NUMBER IS
    loc_LVIntCode artvl.arlseqvl%TYPE;
  BEGIN
    glo_Section := param_UPCCode;
    SELECT /*+ rule */ sdrseqvl
      INTO loc_LVIntCode
      FROM artcoca, artvl, artuv, stodetre, stoentre
     WHERE arccode like '%' || param_UPCCode || '%'
       AND arccinv = arvcinv
       AND arccinr = arlcinr
       AND param_OrderDate between arcddeb AND arcdfin
       AND arlseqvl = sdrseqvl
       AND sdrcinrec = sercinrec
       AND sercinrec = param_OrderNumber;
    RETURN loc_LVIntCode;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT /*+ rule */  sdrseqvl
          INTO loc_LVIntCode
          FROM artcoca, artvl, artuv, stodetre, stoentre
         WHERE arccode like
              --   '%' || trim(leading '0' from param_UPCCode) || '%'
               substr(param_UPCCode, 2, length(param_UPCCode) - 1) || '%'
           AND arccinv = arvcinv
           AND arccinr = arlcinr
           AND param_OrderDate between arcddeb AND arcdfin
           AND arlseqvl = sdrseqvl
           AND sdrcinrec = sercinrec
           and sdrcinrec = param_OrderNumber
           AND sercinrec = param_OrderNumber;
        RETURN loc_LVIntCode;
      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          BEGIN
            glo_Section := param_UPCCode;
            SELECT /*+ rule */  arlseqvl
              INTO loc_LVIntCode
              FROM artcoca, artvl, artuv
             WHERE arccode like
                  --   '%' || trim(leading '0' from param_UPCCode) || '%'
                   substr(param_UPCCode, 2, length(param_UPCCode) - 1) || '%'
               AND (param_OrderDate between arcddeb AND arcdfin OR
                   param_OrderDate IS NULL OR
                   SYSDATE between arcddeb AND arcdfin)
               AND arccinv = arvcinv
               AND arccinr = arlcinr
                  --Kan-09022014-Fixing the LV selection based on artuc
               and exists
             (select 1
                      from artuc
                     where aracinr = arlcinr
                       and araseqvl = arlseqvl
                       and aracfin = param_VendorIntCode
                       and araccin = param_CommCont
                       and param_OrderDate between araddeb AND aradfin
                       and (arasite = param_Site OR
                           arasite in
                           (select relid
                               from resrel
                             connect by prior relpere = relid
                              start with relid = param_Site
                                     and trunc(sysdate) between relddeb and
                                         reldfin
                             union all
                             select robid from resobj where robprof = 1)))
               AND rownum < = 1;
            RETURN loc_LVIntCode;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              BEGIN
                glo_Section := param_UPCCode;
                SELECT /*+ rule */  arlseqvl
                  INTO loc_LVIntCode
                  FROM artcoul, artvl, artul
                 WHERE acucode like
                      --   '%' || trim(leading '0' from param_UPCCode) || '%'
                       substr(param_UPCCode, 2, length(param_UPCCode) - 1) || '%'
                   AND (param_OrderDate between acuddeb AND acudfin OR
                       param_OrderDate IS NULL OR
                       SYSDATE between acuddeb AND acudfin)
                   AND acucinr = arlcinr
                   AND acucinl = arucinl
                   AND aruseqvl = arlseqvl
                      --Kan-09022014-Fixing the LV selection based on artuc
                   and exists
                 (select 1
                          from artuc
                         where aracinr = arlcinr
                           and araseqvl = arlseqvl
                           and aracfin = param_VendorIntCode
                           and araccin = param_CommCont
                           and param_OrderDate between araddeb AND aradfin
                           and (arasite = param_Site OR
                               arasite in
                               (select relid
                                   from resrel
                                 connect by prior relpere = relid
                                  start with relid = param_Site
                                         and trunc(sysdate) between relddeb and
                                             reldfin
                                 union all
                                 select robid from resobj where robprof = 1)))
                   AND rownum < = 1;
                RETURN loc_LVIntCode;
              EXCEPTION
                WHEN NO_DATA_FOUND THEN
                  BEGIN
                    glo_Section := param_UPCCode;
                    SELECT /*+ rule */  arlseqvl
                      INTO loc_LVIntCode
                      FROM artcoul, artvl, artul
                     WHERE acucode like '%' || param_UPCCode || '%'
                       AND (param_OrderDate between acuddeb AND acudfin OR
                           param_OrderDate IS NULL OR
                           SYSDATE between acuddeb AND acudfin)
                       AND acucinr = arlcinr
                       AND acucinl = arucinl
                       AND aruseqvl = arlseqvl
                          --Kan-09022014-Fixing the LV selection based on artuc
                       and exists
                     (select 1
                              from artuc
                             where aracinr = arlcinr
                               and araseqvl = arlseqvl
                               and aracfin = param_VendorIntCode
                               and araccin = param_CommCont
                               and param_OrderDate between araddeb AND
                                   aradfin
                               and (arasite = param_Site OR
                                   arasite in
                                   (select relid
                                       from resrel
                                     connect by prior relpere = relid
                                      start with relid = param_Site
                                             and trunc(sysdate) between
                                                 relddeb and reldfin
                                     union all
                                     select robid
                                       from resobj
                                      where robprof = 1)))
                       AND rownum < = 1;
                    RETURN loc_LVIntCode;
                  EXCEPTION
                    WHEN NO_DATA_FOUND THEN
                      BEGIN
                        glo_Section := param_UPCCode;
                        SELECT /*+ rule */  arlseqvl
                          INTO loc_LVIntCode
                          FROM artcoca, artvl, artuv
                         WHERE arccode like
                              --   '%' || trim(leading '0' from param_UPCCode) || '%'
                               substr(param_UPCCode,
                                      1,
                                      length(param_UPCCode) - 1) || '%'
                           AND (param_OrderDate between arcddeb AND arcdfin OR
                               param_OrderDate IS NULL OR
                               SYSDATE between arcddeb AND arcdfin)
                           AND arccinv = arvcinv
                           AND arccinr = arlcinr
                              --Kan-09022014-Fixing the LV selection based on artuc
                           and exists
                         (select 1
                                  from artuc
                                 where aracinr = arlcinr
                                   and araseqvl = arlseqvl
                                   and aracfin = param_VendorIntCode
                                   and araccin = param_CommCont
                                   and param_OrderDate between araddeb AND
                                       aradfin
                                   and (arasite = param_Site OR
                                       arasite in
                                       (select relid
                                           from resrel
                                         connect by prior relpere = relid
                                          start with relid = param_Site
                                                 and trunc(sysdate) between
                                                     relddeb and reldfin
                                         union all
                                         select robid
                                           from resobj
                                          where robprof = 1)))
                           AND rownum < = 1;
                        RETURN loc_LVIntCode;
                      EXCEPTION
                        WHEN OTHERS THEN
                          RETURN - 1;
                      END;
                    WHEN OTHERS THEN
                      RETURN - 1;
                      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
                      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
                      glo_ErrMessage := 'Failure' || ':' || glo_Section;
                      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
                      IF glo_DebugFlag = 1 THEN
                        dbms_output.put_line(glo_ErrMessage || ':' ||
                                             SQLERRM || ' : ' || SQLCODE);
                      END IF;
                  END;
                WHEN OTHERS THEN
                  RETURN - 1;
                  glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
                  PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
                  glo_ErrMessage := 'Failure' || ':' || glo_Section;
                  PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
                  IF glo_DebugFlag = 1 THEN
                    dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM ||
                                         ' : ' || SQLCODE);
                  END IF;
              END;
            WHEN OTHERS THEN
              RETURN - 1;
              glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
              PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
              glo_ErrMessage := 'Failure' || ':' || glo_Section;
              PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
              IF glo_DebugFlag = 1 THEN
                dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM ||
                                     ' : ' || SQLCODE);
              END IF;
          END;
        WHEN OTHERS THEN
          RETURN - 1;
          glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
          PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
          glo_ErrMessage := 'Failure' || ':' || glo_Section;
          PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
          IF glo_DebugFlag = 1 THEN
            dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                                 SQLCODE);
          END IF;
      END;
    WHEN OTHERS THEN
      RETURN - 1;
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || ':' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSeqvl', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  FUNCTION getARAREFC(param_Vendor       artuc.ARACFIN%TYPE,
                      param_CommCont     artuc.ARACCIN%TYPE,
                      param_LVCode       artuc.ARASEQVL%TYPE,
                      param_Site         artuc.ARASITE%TYPE,
                      param_OrderDate    cdeentcde.ecddcom%TYPE,
                      param_AddressChain cdeentcde.ecdnfilf%TYPE)
    RETURN VARCHAR2 IS
  
    loc_REFC VARCHAR2(20) := NULL;
  
  BEGIN
    glo_Section := param_Vendor || ',' || param_CommCont || ',' ||
                   param_Site || ',' || param_LVCode;
    SELECT ARAREFC
      INTO loc_REFC
      FROM artuc
     WHERE araseqvl = param_LVCode
       AND araccin = param_CommCont
       AND aracfin = param_Vendor
       AND trunc(param_OrderDate) BETWEEN araddeb AND aradfin
       AND (arasite = param_Site OR
           arasite IN (SELECT relpere
                          FROM resrel, resobj
                         WHERE TRUNC(SYSDATE) BETWEEN relddeb AND reldfin
                           AND relpere = robid
                        CONNECT BY PRIOR relpere = relid
                         START WITH relid = param_Site))
       AND aranfilf = param_AddressChain
       AND rownum = 1;
    RETURN loc_REFC;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      glo_ErrMessage := 'NoDataFound:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getARAREFC', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN null;
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getARAREFC', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getARAREFC', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN null;
  END;

  FUNCTION getARACEXTA(param_Vendor       artuc.ARACFIN%TYPE,
                       param_CommCont     artuc.ARACCIN%TYPE,
                       param_LVCode       artuc.ARASEQVL%TYPE,
                       param_Site         artuc.ARASITE%TYPE,
                       param_OrderDate    cdeentcde.ecddcom%TYPE,
                       param_AddressChain cdeentcde.ecdnfilf%TYPE)
    RETURN VARCHAR2 IS
  
    loc_ARACEXTA VARCHAR2(20) := NULL;
  
  BEGIN
    glo_Section := param_Vendor || ',' || param_CommCont || ',' ||
                   param_Site || ',' || param_LVCode;
    SELECT aracexta
      INTO loc_ARACEXTA
      FROM artuc
     WHERE araseqvl = param_LVCode
       AND araccin = param_CommCont
       AND aracfin = param_Vendor
       AND trunc(param_OrderDate) BETWEEN araddeb AND aradfin
       AND aranfilf = param_AddressChain
       AND (arasite = param_Site OR
           arasite IN (SELECT relpere
                          FROM RESREL, RESOBJ
                         WHERE TRUNC(SYSDATE) BETWEEN relddeb AND reldfin
                           AND relpere = robid
                        CONNECT BY PRIOR relpere = relid
                         START WITH relid = param_Site))
       AND rownum = 1;
    RETURN loc_ARACEXTA;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      BEGIN
        SELECT aracexta
          INTO loc_ARACEXTA
          FROM artuc
         WHERE araseqvl = param_LVCode
           AND araccin = param_CommCont
           AND aracfin = param_Vendor
              --AND trunc(param_OrderDate) BETWEEN araddeb AND aradfin
           AND aranfilf = param_AddressChain
           AND (arasite = param_Site OR
               arasite IN
               (SELECT relpere
                   FROM RESREL, RESOBJ
                  WHERE TRUNC(SYSDATE) BETWEEN relddeb AND reldfin
                    AND relpere = robid
                 CONNECT BY PRIOR relpere = relid
                  START WITH relid = param_Site))
           AND rownum = 1;
        RETURN loc_ARACEXTA;
      EXCEPTION
        WHEN OTHERS THEN
          glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
          PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getARACEXTA', glo_ErrMessage);
          glo_ErrMessage := 'Failure' || glo_Section;
          PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getARACEXTA', glo_ErrMessage);
          IF glo_DebugFlag = 1 THEN
            dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                                 SQLCODE);
          END IF;
          RETURN null;
      END;
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getARACEXTA', glo_ErrMessage);
      glo_ErrMessage := 'Failure' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getARACEXTA', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN null;
  END;

  FUNCTION getSKUUnits(param_ItemExtCode IN intcfart.cfacexr%TYPE,
                       param_ItemExtLV   IN intcfart.cfacexvl%TYPE,
                       param_TypeLU      IN NUMBER) RETURN NUMBER IS
    loc_SKUUnits  NUMBER := 0;
    loc_ItemIntLU NUMBER := 0;
    loc_ItemIntLV NUMBER := 0;
  BEGIN
  
    glo_Section := param_ItemExtCode;
    SELECT arlseqvl
      INTO loc_ItemIntLV
      FROM artvl
     WHERE arlcexr = param_ItemExtCode
       AND arlcexvl = param_ItemExtLV;
  
    SELECT arucinl
      INTO loc_ItemIntLU
      FROM artul
     WHERE aruseqvl = loc_ItemIntLV
       AND arutypul = param_TypeLU;
  
    loc_SKUUnits := pkartstock.get_skuunits(CONST_NUM_LOG, loc_ItemIntLU);
  
    RETURN loc_SKUUnits;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      glo_ErrMessage := 'NoDataFound:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSKUUnits', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN 1;
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSKUUnits', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSKUUnits', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN 1;
  END;

  FUNCTION getCommContNumber(param_SupplierIntCode artuc.aracfin%TYPE,
                             param_ItemSeqvl       artuc.araseqvl%TYPE,
                             param_Site            artuc.arasite%TYPE)
    RETURN artuc.araccin%TYPE IS
  
    loc_CommContNumber artuc.araccin%TYPE := NULL;
  BEGIN
    glo_Section := param_SupplierIntCode || ':' || param_ItemSeqvl;
    SELECT MAX(araccin)
      INTO loc_CommContNumber
      FROM ARTUC
     WHERE aracfin = param_SupplierIntCode
          -- AND aracinl = param_ItemLUCode
       AND araseqvl = param_ItemSeqvl
       AND TRUNC(SYSDATE) BETWEEN ARADDEB AND ARADFIN
       AND (arasite = param_Site OR
           arasite IN (SELECT relpere
                          FROM resrel, resobj
                         WHERE TRUNC(SYSDATE) BETWEEN araddeb AND aradfin
                           AND relpere = robid
                        CONNECT BY PRIOR relpere = relid
                         START WITH relid = param_Site));
    RETURN loc_CommContNumber;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      glo_ErrMessage := 'NoDataFound:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCommContNumber', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN - 1;
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCommContNumber', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCommContNumber', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN - 1;
  END;

  FUNCTION getSite(param_ReceiversLocation VARCHAR2,
                   param_Shiptoduns        VARCHAR2) RETURN NUMBER IS
    loc_Site stoentre.sersite%TYPE;
  BEGIN
    glo_Section := param_ReceiversLocation || ':' || param_Shiptoduns;
    IF param_ReceiversLocation IS NOT NULL THEN
      SELECT substr(param_ReceiversLocation,
                    length(param_ReceiversLocation) - 1,
                    length(param_ReceiversLocation))
        INTO loc_Site
        FROM DUAL;
    ELSIF param_Shiptoduns IS NOT NULL THEN
      SELECT substr(param_Shiptoduns,
                    length(param_Shiptoduns) - 1,
                    length(param_Shiptoduns))
        INTO loc_Site
        FROM DUAL;
    ELSE
      loc_Site       := -1;
      glo_ErrMessage := 'ReceiversLocation,Shiptoduns NULL';
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSite', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
    END IF;
    RETURN loc_Site;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      glo_ErrMessage := 'NoDataFound for:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSite', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN - 1;
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSite', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getSite', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN - 1;
  END;

  FUNCTION getCoefficient(param_InvDealAppCode in stodetre.sdruapp%TYPE,
                          param_ItemNbr        in stodetre.sdrcinr%TYPE,
                          param_Seqvl          in stodetre.sdrseqvl%TYPE,
                          param_RecDealAppCode in stodetre.sdruapp%TYPE)
    RETURN NUMBER IS
  
    loc_Coefficient NUMBER(13) := 1;
  
  BEGIN
  
    glo_Section := param_InvDealAppCode || ':' || param_ItemNbr;
    --For non weighted deals (srruapp<>180)
    if param_RecDealAppCode <> 180 and
       param_InvDealAppCode <> param_RecDealAppCode then
    
      SELECT NVL(COEFF1, COEFF2)
        INTO loc_Coefficient
        FROM (SELECT (EXP(SUM(LN(ABS(ALLCOEFF)))) *
                     DECODE(MOD(COUNT(DECODE(SIGN(ALLCOEFF), -1, 1, NULL)),
                                 2),
                             1,
                             -1,
                             1) * nvl(max(decode(ALLCOEFF, 0, 0, NULL)), 1)) COEFF1
                FROM ARTULUL
               WHERE ALLCINLP IN
                     (SELECT ARUCINL
                        FROM ARTUL
                       WHERE ARUCINR = TRIM(param_ItemNbr)
                         AND ARUSEQVL = TRIM(param_Seqvl)
                         AND ARUTYPUL BETWEEN TRIM(param_InvDealAppCode) AND
                             TRIM(param_RecDealAppCode)
                         AND ARUTYPUL != TRIM(param_InvDealAppCode))),
             
             (SELECT (EXP(SUM(LN(ABS(ALLCOEFF)))) *
                     DECODE(MOD(COUNT(DECODE(SIGN(ALLCOEFF), -1, 1, NULL)),
                                 2),
                             1,
                             -1,
                             1) * nvl(max(decode(ALLCOEFF, 0, 0, NULL)), 1)) COEFF2
                FROM ARTULUL
               WHERE ALLCINLP IN
                     (SELECT ARUCINL
                        FROM ARTUL
                       WHERE ARUCINR = TRIM(param_ItemNbr)
                         AND ARUSEQVL = TRIM(param_Seqvl)
                         AND ARUTYPUL BETWEEN TRIM(param_RecDealAppCode) AND
                             TRIM(param_InvDealAppCode)
                         AND ARUTYPUL != TRIM(param_RecDealAppCode)));
      RETURN loc_Coefficient;
    
    ELSE
      RETURN 1;
    END IF;
  
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      glo_ErrMessage := 'NoDataFound:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCoefficient', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN 1;
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCoefficient', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCoefficient', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN 1;
  END;

  FUNCTION getCalAllowancechargerate(param_InvoiceDealUOM storemre.srruapp%TYPE,
                                     param_RecDealUOM     storemre.srruapp%TYPE,
                                     param_ItemWeight     stodetre.sdrpcu%TYPE,
                                     param_ItemCoeff      stodetre.sdruauvc%TYPE,
                                     param_Coefficient    NUMBER,
                                     param_InvDealValue   NUMBER)
    RETURN NUMBER IS
  
    loc_CalculatedDealValue NUMBER(15, 5) := 0;
  BEGIN
    glo_Section := param_InvoiceDealUOM;
    IF param_InvDealValue <> 0 THEN
      IF param_RecDealUOM <> 0 THEN
        --Non weighted item deal-if invoice is in lower UOM and reception in higher UOM
        IF (param_InvoiceDealUOM < param_RecDealUOM) AND
           param_InvoiceDealUOM <> 180 AND param_RecDealUOM <> 180 THEN
          IF param_Coefficient <> 0 THEN
            loc_CalculatedDealValue := param_InvDealValue * param_ItemCoeff;
          END IF;
        ELSIF (param_InvoiceDealUOM > param_RecDealUOM) AND
              param_InvoiceDealUOM <> 180 AND param_RecDealUOM <> 180 THEN
          IF param_Coefficient <> 0 THEN
            loc_CalculatedDealValue := param_InvDealValue / param_ItemCoeff;
          END IF;
        ELSIF (param_InvoiceDealUOM = param_RecDealUOM) THEN
          loc_CalculatedDealValue := param_InvDealValue;
        ELSIF (param_InvoiceDealUOM = 180 AND param_RecDealUOM <> 180) THEN
          loc_CalculatedDealValue := param_InvDealValue * param_ItemWeight *
                                     param_ItemCoeff;
        ELSIF (param_InvoiceDealUOM <> 180 AND param_RecDealUOM = 180) THEN
          IF param_ItemWeight = 0 OR param_ItemCoeff = 0 THEN
            loc_CalculatedDealValue := param_InvDealValue;
          ELSE
            loc_CalculatedDealValue := param_InvDealValue /
                                       (param_ItemWeight * param_ItemCoeff);
          END IF;
        ELSE
          loc_CalculatedDealValue := param_InvDealValue;
        
        END IF;
      ELSE
        loc_CalculatedDealValue := param_InvDealValue;
      END IF;
      --  ELSIF invtotaldeal amount chk    
    END IF;
    RETURN loc_CalculatedDealValue;
  EXCEPTION
    WHEN NO_DATA_FOUND THEN
      glo_ErrMessage := 'NoDataFound:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCalAllowancechargerate', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN 1;
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCalAllowancechargerate', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'getCalAllowancechargerate', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
      RETURN 1;
  END;

  PROCEDURE UpdateStagingHeader(param_InvoiceNumber     VARCHAR2,
                                param_VendorDunsNumber  VARCHAR2,
                                param_ReceiversLocation VARCHAR2,
                                param_ShiptoDuns        VARCHAR2,
                                param_BatchID           NUMBER,
                                param_StatusNo          NUMBER,
                                param_StatusDescription VARCHAR2) IS
  
  BEGIN
    glo_Section := param_InvoiceNumber || ':' || param_BatchID;
    UPDATE im_edi_invoice_header
       SET status_no          = param_StatusNo,
           status_description = param_StatusDescription,
           modified_date      = sysdate,
           last_user          = 'UpdStagHd'
     WHERE (invoicenumber = param_InvoiceNumber OR
           param_InvoiceNumber IS NULL)
       AND (vendordunsnumber = param_VendorDunsNumber OR
           param_VendorDunsNumber IS NULL)
       AND importbatchid = param_BatchID
       AND (receiverslocation = param_ReceiversLocation OR
           param_ReceiversLocation IS NULL)
       AND (shiptoduns = param_ShiptoDuns OR param_ShiptoDuns IS NULL);
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingHeader', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingHeader', glo_ErrMessage);
    
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE UpdateStagingDetail(param_InvoiceNumber     VARCHAR2,
                                param_VendorDunsNumber  VARCHAR2,
                                param_ItemUPC           VARCHAR2,
                                param_BatchID           NUMBER,
                                param_StatusNo          NUMBER,
                                param_StatusDescription VARCHAR2) IS
  BEGIN
  
    glo_Section := param_InvoiceNumber || ':' || param_BatchID || ':' ||
                   param_ItemUPC;
  
    UPDATE im_edi_invoice_detail
       SET status_no          = param_StatusNo,
           status_description = param_StatusDescription,
           modified_date      = sysdate,
           last_user          = 'UpdStagDt'
     WHERE (invoicenumber = param_InvoiceNumber OR
           param_InvoiceNumber IS NULL)
       AND (vendordunsnumber = param_VendorDunsNumber OR
           param_VendorDunsNumber IS NULL)
       AND importbatchid = param_BatchID
       AND (productid = param_ItemUPC OR param_ItemUPC IS NULL);
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingDetail', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingDetail', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE UpdateStagingItDeals(param_InvoiceNumber       VARCHAR2,
                                 param_VendorDunsNumber    VARCHAR2,
                                 param_ItemUPC             VARCHAR2,
                                 param_BatchID             NUMBER,
                                 param_AllowanceChargeCode NUMBER,
                                 param_StatusNo            NUMBER,
                                 param_StatusDescription   VARCHAR2) IS
  BEGIN
    glo_Section := param_InvoiceNumber || ':' || param_BatchID || ':' ||
                   param_ItemUPC || param_AllowanceChargeCode;
    UPDATE im_edi_invoice_itemdeals
       SET status_no          = param_StatusNo,
           status_description = param_StatusDescription,
           modified_date      = sysdate,
           last_user          = 'UpdStagItD'
     WHERE (invoicenumber = param_InvoiceNumber OR
           param_InvoiceNumber IS NULL)
       AND (vendordunsnumber = param_VendorDunsNumber OR
           param_VendorDunsNumber IS NULL)
       AND importbatchid = param_BatchID
          --AND productid = param_ItemUPC
       AND (productid = param_ItemUPC OR param_ItemUPC IS NULL)
          --AND allowancechargecode = param_AllowanceChargeCode
       AND (allowancechargecode = param_AllowanceChargeCode OR
           param_AllowanceChargeCode IS NULL);
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingItDeals', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingItDeals', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

  PROCEDURE UpdateStagingFtDeals(param_InvoiceNumber       VARCHAR2,
                                 param_VendorDunsNumber    VARCHAR2,
                                 param_BatchID             NUMBER,
                                 param_AllowanceChargeCode NUMBER,
                                 param_StatusNo            NUMBER,
                                 param_StatusDescription   VARCHAR2) IS
  BEGIN
    glo_Section := param_InvoiceNumber || param_BatchID ||
                   param_AllowanceChargeCode;
    UPDATE im_edi_invoice_ftdeals
       SET status_no          = param_StatusNo,
           status_description = param_StatusDescription,
           modified_date      = sysdate,
           last_user          = 'UpdStagFtD'
     WHERE (invoicenumber = param_InvoiceNumber OR
           param_InvoiceNumber IS NULL)
       AND (vendordunsnumber = param_VendorDunsNumber OR
           param_VendorDunsNumber IS NULL)
       AND importbatchid = param_BatchID
          --AND allowancechargecode = param_AllowanceChargeCode
       AND (allowancechargecode = param_AllowanceChargeCode OR
           param_AllowanceChargeCode IS NULL);
    COMMIT;
  
  EXCEPTION
    WHEN OTHERS THEN
      glo_ErrMessage := SQLERRM || ' : ' || SQLCODE;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingFtDeals', glo_ErrMessage);
      glo_ErrMessage := 'Failure:' || glo_Section;
      PKERREURS.FC_ERREUR(CONST_NUM_LOG, 'UpdateStagingFtDeals', glo_ErrMessage);
      IF glo_DebugFlag = 1 THEN
        dbms_output.put_line(glo_ErrMessage || ':' || SQLERRM || ' : ' ||
                             SQLCODE);
      END IF;
  END;

END PKG_EDI_INVOICE_MATCHING_NOVBK;
/


spool off
