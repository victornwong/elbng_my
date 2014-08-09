import groovy.sql.Sql;
import org.zkoss.zk.ui.*;

/*
Global definations
Cranked out by: Victor Wong (17/10/2010)
*/

MAINLOGIN_PAGE = "index.zul";

VERSION = "0.0.1-vw";

/*
LGKDATABASESERVER = "202.186.181.20:1433";
LGKDATABASENAME = "AccDatabase2";

MYSOFTDATABASESERVER = "202.186.181.20:1433";
MYSOFTDATABASENAME = "AccDatabase2";
*/

/* ASMA database
LGKDATABASESERVER = "5.5.218.120:1433";
LGKDATABASENAME = "AccDatabase2";
*/

// FOXMAY database
LGKDATABASESERVER = "5.5.218.120:1433";
LGKDATABASENAME = "FXMDatabase";

MYSOFTDATABASESERVER = "5.137.254.53:1433";
MYSOFTDATABASENAME = "AccDatabase1";

FOXMAY_DOCUMENTSTORAGE_DB = "FOXMAY_DocumentStorage";
ASMA_DOCUMENTSTORAGE_DB = "ASMA_DocumentStorage";
DOCUMENTSTORAGE_DATABASE = "DocumentStorage"; // this is for ALS

// Used to determine tree trunk in Lookup table - lab-branches, SA = LOCATIONS
LOCATIONS_TREE_SHAHALAM = "LOCATIONS";
LOCATIONS_TREE_JB = "JBLOCATIONS";
LOCATIONS_TREE_KK = "KKLOCATIONS";

MAINPROCPATH = ".";

// GUI types
GUI_PANEL = 1;
GUI_WINDOW = 2;

DATAINPUT_MANUAL = 20;
DATALOGGER_IMPORT = 21;
BROWSE_ALS_FOLDERS = 22;

SITES_MANAGER = 30;
STORAGETEMPLATE_MANAGER = 31;
COC_MANAGER = 32;

SAMPLINGSCHED_MAKER = 40;
SAMPLINGSCHED_TRACKER = 41;
STAFF_LIST_MANAGER = 42;
STAFF_TIMESHEET = 43;

ASSET_MANAGER = 60;

PURCHASE_REQ_MOD = 100;

// Admin stuff
USER_ADMIN = 200;

// Project + Jobs
PROJECTJOBS = 600;

// Sales/Marketing/purchases
PURCHASE_REQ = 700;
PURCHASE_ORDER = 701;

// Finance stuff
AMBANK_EDD = 800;

// Inventory/stock stuff
STOCKBROWSWER = 901;
STOCKDIVISIONGROUP = 902;
SUPPLIER_SETUP = 903;
GRNMAKER = 904;
SETUPWAREHOUSE = 906;
GRNUPDATER = 907;
SUPPLIERCAT_SETUP = 908;

public class modulesObj
{
	public int module_num;
	public String module_name;
	public int accesslevel;
	
	public int module_gui;
	public String module_fn;
	public int modal_flag;
	public String parameters;
	
	public modulesObj(int imodule_num, String imodule_name, int iaccesslevel, int iguitype, String imodule_fn, int imodal_flag, String iparam)
	{
		module_num = imodule_num;
		module_name = imodule_name;
		accesslevel = iaccesslevel;
		module_gui = iguitype;
		module_fn = imodule_fn;
		modal_flag = imodal_flag;
		parameters = iparam;
	}
}

Object[] applicationModules = {
	// new modulesObj(DATAINPUT_MANUAL,"datainput_manual",2,GUI_PANEL,"datajuggler/datainput.zul",0,"") ,
	// new modulesObj(DATALOGGER_IMPORT,"datalogger_import",2,GUI_PANEL,"datajuggler/import_datalogger.zul",0,"") ,
	// new modulesObj(BROWSE_ALS_FOLDERS,"browse_als_folders",2,GUI_PANEL,"linkals/browsejobs.zul",0,"") ,
	// new modulesObj(SITES_MANAGER,"sites_manager",2,GUI_PANEL,"staticjuggler/sites_manager.zul",0,"") ,
	// new modulesObj(STORAGETEMPLATE_MANAGER,"storagetemplate_manager",2,GUI_PANEL,"staticjuggler/storage_manager.zul",0,"") ,
	// new modulesObj(SAMPLINGSCHED_MAKER,"samplingsched_maker",2,GUI_PANEL,"samplingjuggler/samplingsched_maker.zul",0,"") ,
	// new modulesObj(SAMPLINGSCHED_TRACKER,"samplingsched_tracker",2,GUI_PANEL,"samplingjuggler/jobscheduler.zul",0,"") ,
	// new modulesObj(COC_MANAGER,"coc_manager",2,GUI_PANEL,"samplingjuggler/coc_manager.zul",0,"") ,
	// new modulesObj(STAFF_LIST_MANAGER,"staff_list_manager",2,GUI_PANEL,"staticjuggler/stafflist_man.zul",0,"") ,
	// new modulesObj(STAFF_TIMESHEET,"staff_timesheet",2,GUI_PANEL,"lgk_acctmods/staff_timesheet.zul",0,"") ,
	// new modulesObj(PURCHASE_REQ_MOD,"purchase_req_mod",2,GUI_PANEL,"lgk_acctmods/purchase_req.zul",0,"") ,
	// new modulesObj(ASSET_MANAGER,"asset_manager",9,GUI_PANEL,"staticjuggler/equipmentmanager.zul",0,"") ,

	new modulesObj(USER_ADMIN,"user_admin",9,GUI_PANEL,"adminmodules/usercontroller.zul",0,"") ,

	new modulesObj(AMBANK_EDD,"ambank_edd",2,GUI_PANEL,"lgk_acctmods/ambank_inout.zul",0, ""),

	new modulesObj(STOCKBROWSWER,"stockbrowswer",2,GUI_PANEL,"lgk_acctmods/stockbrowser.zul",0, ""),
	new modulesObj(STOCKDIVISIONGROUP,"stockdivisiongroup",2,GUI_PANEL,"lgk_acctmods/stockdivisionsetup.zul",0, ""),
	new modulesObj(SUPPLIER_SETUP,"supplier_setup",2,GUI_PANEL,"lgk_acctmods/suppliersetup.zul",0, ""),
	new modulesObj(SUPPLIERCAT_SETUP,"suppliercat_setup",2,GUI_WINDOW,"lgk_acctmods/suppliercatsetup.zul",0, ""),

	new modulesObj(GRNMAKER,"grnmaker",2,GUI_PANEL,"lgk_acctmods/grnmaker.zul",0, ""),
	new modulesObj(GRNUPDATER,"grnupdater",2,GUI_WINDOW,"lgk_acctmods/grnupdater.zul",0, ""),

	new modulesObj(SETUPWAREHOUSE,"setupwarehouse",2,GUI_WINDOW,"lgk_acctmods/setupwarehouse.zul",0, ""),

	new modulesObj(PURCHASE_REQ,"purchase_req",2,GUI_PANEL,"lgk_acctmods/purchase_req.zul",0, ""),
	new modulesObj(PURCHASE_ORDER,"purchase_order",2,GUI_PANEL,"lgk_acctmods/purchaseorder.zul",0, ""),

	new modulesObj(PROJECTJOBS,"projectjobs",2,GUI_PANEL,"lgk_jobs/projectjobs.zul",0, ""),

	};

// General purpose lookups

String[] yesno_dropdown = { "NO" , "YES" };

String[] trail_types = { "NOTES", "INV", "COA" , "RESULTS", "RETEST", "COC", "PO", "DO", "CN" , "DN", "CANCEL", "FLUFF" };
String[] trail_status = { "PENDING", "WIP", "RELEASED", "DONE", "SHIPPED" };
String[] lu_DeliveryMethod = { "By hand", "CityLink", "FedEx", "DHL", "Registered Post", "Normal Post", "PJJ" };

String[] labfolderstatus_lookup = { "ALL" , "WIP" , "RESULT", "RELEASED" , "RETEST" };

// equipment prefix - equip manager module
EQID_PREFIX = "E";

GRNPREFIX = "FGRN";
THIS_WAREHOUSE = "HQFOXMAY";
PO_PREFIX = "FXPO";

// Purchase-req stuff
PURCHASE_REQ_PREFIX = "FXMPR";

PR_STATUS_PENDING = "PENDING";
PR_STATUS_COMMITED = "COMMITTED";
PR_STATUS_APPROVED = "APPROVED";
PR_STATUS_DISAPPROVED = "DISAPPROVED";

String[] purchasereq_priority = { "NORMAL" , "URGENT" };


String[] currencycode = { "MYR","USD","AUD","NZD","SGD","JPY","HKD","IDR" };
