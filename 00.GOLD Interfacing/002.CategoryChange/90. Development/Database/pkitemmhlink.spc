CREATE OR REPLACE PACKAGE "PKITEMMHLINK" AS
--@(#) MH/Item link_h.sql /main/centr_dev/centr_maint510/HNE01/2 5/9/2017;

-- Processing Third Party counting data approach
-- Step 1. Insert all the MH/Item link data in the MH/Item link interface table
-- Step 2. Update MH/Item link data if incorrect data are in the file (item code, new MH link)
-- Step 3. Run the integration using unix batch (psifa05p).

-- Requirement:
--     MH/Item link data are uploaded in table ITEMMHLINK

PROCEDURE ProcessMHLinkChange (in_num_log IN NUMBER, in_filename IN VARCHAR2,o_return OUT NUMBER);
FUNCTION flagLine (in_num_log IN NUMBER, in_errorNumber IN NUMBER, in_filename IN VARCHAR2, in_lineNumber IN VARCHAR2) RETURN NUMBER;

END PKITEMMHLINK;
/

