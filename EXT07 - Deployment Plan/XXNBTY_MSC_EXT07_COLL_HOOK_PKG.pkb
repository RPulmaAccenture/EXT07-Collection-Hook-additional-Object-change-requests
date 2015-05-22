create or replace PACKAGE BODY XXNBTY_MSCEXT07_COLL_HOOK_PKG
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
	,p_org_code	varchar2)		
AS

  TYPE c_typ IS REF CURSOR;
  c_cus_num      c_typ;
  l_cus_num        msc_trading_partner_sites.attribute1%TYPE;
  query_str        VARCHAR2(1000);
  dbLink           msc_apps_instances.M2A_DBLINK%TYPE;
  l_as400_legacy	varchar2(240);
  v_order_number	NUMBER;
  v_plan_id			msc_supplies.plan_id%type;
  v_sr_instance_id	varchar2(100);
  v_transaction_id	varchar2(100);
  l_order_num		varchar2(100);
  v_step			NUMBER;
  v_mess			varchar2(1000);
  v_org_id			msc_supplies.organization_id%type;
  order_number		varchar2(100);
    
  c_order_type msc_supplies.order_type%TYPE := 3;
  TYPE supply_rec			IS RECORD (	 NOTE_ID            NUMBER         
										,ENTITY_TYPE        VARCHAR2(30)   
										,PLAN_ID            NUMBER         
										,SR_INSTANCE_ID     NUMBER         
										,ORGANIZATION_ID    NUMBER         
										,INVENTORY_ITEM_ID  NUMBER         
										,TRANSACTION_ID     NUMBER         
										,DEMAND_ID          NUMBER         
										,NOTE_TEXT1         VARCHAR2(4000) 
										,LAST_UPDATE_DATE   DATE           
										,LAST_UPDATED_BY    NUMBER         
										,CREATION_DATE      DATE           
										,CREATED_BY         NUMBER         
										,LAST_UPDATE_LOGIN  NUMBER         
										,ASSIGNED_TO        NUMBER         
										,DUE_BY             DATE           
										,STATUS             NUMBER    
										);
  
  TYPE t_supply_rec     IS TABLE OF supply_rec;
  l_supply_rec        	t_supply_rec;
  c_limit				NUMBER := 10000;
  v_user_id     		NUMBER;
  
  -- Get DB Link from VCP to EBS
  CURSOR c_dbLink
  IS
	SELECT mai.M2A_DBLINK
    FROM msc_apps_instances mai
	WHERE mai.instance_code = 'EBS';
   
	CURSOR c_supply_rec (p_order_type msc_supplies.order_type%TYPE, p_plan_id msc_supplies.plan_id%TYPE, p_organization_id msc_supplies.organization_id%TYPE)
	IS 
		SELECT substr(order_number,5) order_number
			 ,plan_id 
			 ,sr_instance_id 
			 ,transaction_id 
		FROM  msc_supplies  
		WHERE order_type =  p_order_type
		AND  plan_id = p_plan_id 
		AND organization_id = p_organization_id;

	CURSOR c_get_org_id (p_get_org_code msc_trading_partners.organization_code%TYPE)
	IS
		SELECT sr_tp_id
		FROM msc_trading_partners
		WHERE organization_code = p_get_org_code;
		
	CURSOR c_get_plan_id (p_get_plan_name msc_plans.compile_designator%TYPE)
	IS
		SELECT plan_id
		FROM msc_plans
		WHERE compile_designator = p_get_plan_name;
	  
BEGIN
  v_step := 1;
  EXECUTE IMMEDIATE 'TRUNCATE TABLE msc.msc_user_notes';
  
  v_step := 2;  
  -- Get DB Link from VCP to EBS
  OPEN c_dbLink;
  FETCH c_dbLink 
  INTO dbLink;
  CLOSE c_dbLink;

  v_step := 3;  
  OPEN c_get_org_id (p_org_code); 
  FETCH c_get_org_id 
  INTO v_org_id;
  CLOSE c_get_org_id;
 
  v_step := 4; 
  OPEN c_get_plan_id (p_plan_name); 
  FETCH c_get_plan_id 
  INTO v_plan_id;
  CLOSE c_get_plan_id;
 
  v_step := 5;
  v_user_id := FND_GLOBAL.USER_ID;
  query_str := 'SELECT MSC_USER_NOTES_S.nextval NOTE_ID
					 ,''SUPPLY''	ENTITY_TYPE
					 ,ms.plan_id  PLAN_ID
					 ,ms.sr_instance_id  SR_INSTANCE_ID
					 ,'''' ORGANIZATION_ID
					 ,'''' INVENTORY_ITEM_ID
					 ,ms.transaction_id  TRANSACTION_ID
					 ,'''' DEMAND_ID
					 , (SELECT gbh.attribute1
								FROM gme_batch_header@' || dbLink || ' gbh
								WHERE gbh.batch_no = substr(ms.order_number, 5)
								AND rownum < 2
					 ) NOTE_TEXT1
					 , sysdate LAST_UPDATE_DATE
					 , '||v_user_id || ' LAST_UPDATED_BY
					 , sysdate CREATION_DATE
					 , '||v_user_id || ' CREATED_BY
					 , '''' LAST_UPDATE_LOGIN
					 , '''' ASSIGNED_TO
					 , '''' DUE_BY
					 , '''' STATUS
				 FROM msc_supplies  ms
				WHERE ms.order_type = ' || c_order_type || '
				  AND ms.plan_id = ' || v_plan_id || '
				  AND ms.organization_id = ' || v_org_id || '';
 
  v_step := 6;
  OPEN c_cus_num FOR query_str;
  LOOP
	v_step := 7;
	FETCH c_cus_num BULK COLLECT INTO l_supply_rec LIMIT c_limit;
	--
	v_step := 8;
	FORALL i IN 1..l_supply_rec.COUNT
          INSERT INTO msc_user_notes VALUES l_supply_rec(i);	
	--
	v_step := 9;
    COMMIT;
	--
  EXIT WHEN c_cus_num%NOTFOUND;
  END LOOP;  
  CLOSE c_cus_num;
  --
  v_step := 10;
  COMMIT;
EXCEPTION
    WHEN OTHERS THEN
  		v_mess := 'At step ['||v_step||'] for collect_legacy_num procedure - SQLCODE [' ||SQLCODE|| '] - ' ||substr(SQLERRM,1,100);
		x_errbuf := v_mess;
		x_retcode := 2;
		FND_FILE.PUT_LINE(FND_FILE.LOG,'Error message : ' || x_errbuf);	
  
END collect_legacy_num;  
 
END XXNBTY_MSCEXT07_COLL_HOOK_PKG;

/
show errors;
