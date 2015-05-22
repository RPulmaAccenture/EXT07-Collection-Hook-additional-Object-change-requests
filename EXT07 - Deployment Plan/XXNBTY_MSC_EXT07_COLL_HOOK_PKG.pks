CREATE OR REPLACE PACKAGE XXNBTY_MSCEXT07_COLL_HOOK_PKG
AS
----------------------------------------------------------------------------------------------
/*
Package Name: XXNBTY_MSCEXT07_COLL_HOOK_PKG
Author's Name: Erwin Ramos
Date written: 20-May-2015
RICEFW Object: N/A
Description: 
Program Style: 

Maintenance History: 

Date			Issue#		Name					Remarks	
-----------		------		-----------				------------------------------------------------
20-May-2015				 	Erwin Ramos				Initial Development

*/
--------------------------------------------------------------------------------------------

PROCEDURE	collect_legacy_num(
    x_errbuf OUT VARCHAR2
    ,x_retcode OUT VARCHAR2
	,p_plan_name	varchar2
	,p_org_code	varchar2);

	
END XXNBTY_MSCEXT07_COLL_HOOK_PKG;

/
show errors;
