import org.victor.*;
// Purchase-req general funcs put here
// Written by Victor Wong 16/08/2014

Object getPR_Rec(String iorigid)
{
	sqlstm = "select * from purchaserequisition where origid=" + iorigid;
	retv = sqlhand.gpSqlFirstRow(sqlstm);
	return retv;
}

void populate_DeptNumber(Listbox iwhat)
{
	sqlstm = "select distinct dept_number from pop_detail order by dept_number";
	kcs = sqlhand.gpSqlGetRows(sqlstm);
	if(kcs.size() == 0) return;
	for(dpi : kcs)
	{
		ArrayList kabom = new ArrayList();
		kabom.add(dpi.get("dept_number").toString());
		strarray = kiboo.convertArrayListToStringArray(kabom);	
		lbhand.insertListItems(iwhat,strarray,"false","");
	}
	iwhat.setSelectedIndex(0); // set default selected to item 0
}

// check PR if all items approved - if yes, set PR status to APPR and lock
void checkAllItemsApproved(String iwhat)
{
	sqlstm = "select count(origid) as itemcount, " +
	"(select count(origid)from purchasereq_items where pr_parent_id=" + iwhat + " and item_app_stat=1) as approved " +
	"from purchasereq_items where pr_parent_id=" + iwhat;

	ckre = sqlhand.gpSqlFirstRow(sqlstm);
	if(ckre == null) return;
	itmc = (int)ckre.get("itemcount");
	itma = (int)ckre.get("approved");

	if(itmc == itma) // itemcount = item-approved : PR approved
	{
		if (Messagebox.show("You have approved all request items, proceed to approve this PR?", "Are you sure?", 
			Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) != Messagebox.YES) return;

		doFunc("approvepr_butt"); // use main-func to do the approval
	}
}

// inoti_type: 1=approver query, 2=req response, 3=new PR submitted, .. read switch
void notifyEmail(String iprid, int inoti_type)
{
	subjstr = "";
	switch(inoti_type)
	{
		case 1:
			subjstr = "Approver posted item query";
			break;
		case 2:
			subjstr = "Requester responsed to your item query";
			break;
		case 3:
			subjstr = "New PR submitted for approval";
			break;
		case 4:
			subjstr = "Your PR has been approved";
			break;
		case 5:
			subjstr = "Your PR has been disapproved";
			break;
		case 6:
			subjstr = "Approver posted PR query";
			break;
		case 7:
			subjstr = "Requester updated PR justification";
			break;
	}

	prc = getPR_Rec(iprid);
	if(prc == null) { guihand.showMessageBox("DBERR: Cannot email notification.."); return; }

	subjstr = PR_PREFIX + prc.get("origid").toString() + " : " + subjstr;

	msgbody  = "Purchase Req   : " + PR_PREFIX + prc.get("origid").toString();
	msgbody += "\n\nDate requested : " + prc.get("datecreated").toString().substring(0,10);
	msgbody += "\nApproved by    : " + prc.get("duedate").toString().substring(0,10);
	msgbody += "\nRequested by   : " + prc.get("username");
	msgbody += "\nDepartment     : " + kiboo.checkNullString(prc.get("dept_number"));
	msgbody += "\nApproved by    : " + kiboo.checkNullString(prc.get("approveby")) + 
	" Approved date : " + ((prc.get("approvedate") == null) ? "" : prc.get("approvedate").toString().substring(0,10));
	msgbody += "\n---------------------------------------------------------------------------";
	msgbody += "\nVendor         : " + kiboo.checkNullString(prc.get("SupplierName"));
	msgbody += "\n\nJustification  : ";
	msgbody += "\n" + kiboo.checkNullString(prc.get("notes"));
	msgbody += "\n\nApprover query : ";
	msgbody += "\n" + kiboo.checkNullString(prc.get("approver_notes"));
	msgbody += "\n\n**Login to E-LAMBMAN to access the complete PR to take action**";
	
	topeople22 = luhand.getLookupChildItems_StringArray("PR_APPROVER_USERS",2);
	topeople = kiboo.convertStringArrayToString(topeople22);
	topeople += "," + useraccessobj.email;

	//topeople = APPROVER_EMAIL;
	simpleSendEmail(SMTP_SERVER,"elabman@alsglobal.com.my",topeople,subjstr,msgbody);
	//alert(subjstr + msgbody);
	//alert(topeople);
}

// 16/08/2014: during upload, get the correct curcode from pr-items as pr-meta won't have this info
void uploadPRToMySoft(String ipr)
{
	prec = getPR_Rec(ipr);
	if(prec == null) return;

	todate = kiboo.todayISODateString();

	// chk ap_code
	apcode = kiboo.checkNullString(prec.get("APCode"));
	if(apcode.equals(""))
	{
		guihand.showMessageBox("ERR: Undefined supplier -- please create it to upload this PR");
		return;
	}

	qstm = "select curcode from supplierdetail where apcode='" + apcode + "';";
	r = sqlhand.gpSqlFirstRow(qstm);
	curcode = "MYR";
	if(r != null) curcode = kiboo.checkNullString( r.get("curcode") );
	
	datecrt = prec.get("datecreated").toString().substring(0,10);
	appdt = prec.get("approvedate").toString().substring(0,10);

	prid = PR_PREFIX + ipr;

	// remove old EPR and items if any --
	sqlstm = "delete from popheader where order_number='" + prid + "';";
	sqlstm += "delete from pop_detail where order_number='" + prid + "';";
	sqlhand.gpSqlExecuter(sqlstm);

	sqlstm =
	"insert into popheader (ORDER_NUMBER, ORDER_DATE, ORDER_TYPE, ACCOUNT_REF, Reference," +
	"NAME, ADDRESS_1, ADDRESS_2, ADDRESS_3, ADDRESS_4, ADDRESS_5, " +
	"DELIVERY_NAME, DEL_ADDRESS_1, DEL_ADDRESS_2, DEL_ADDRESS_3, DEL_ADDRESS_4, DEL_ADDRESS_5, " +
	"CONTACT_NAME, SUPP_TEL_NUMBER, SUPP_ORDER_NUMBER, CURRENCY_CODE, CURRENCY_EX_RATE, " +
	"SUPP_DISC_RATE, SUPP_DISC_FOREIGN, SUPP_DISC_VALUE,FOREIGN_GROSS,FOREIGN_TAX, FOREIGN_NET, " +
	"ORDER_GROSS, ORDER_TAX, ORDER_NET, NOTES_1, NOTES_2, NOTES_3, PRINTED_CODE, POSTED_CODE, " +
	"DISC_RATE, DUE_DAYS, STATUS, TAKEN_BY, DATE_CREATED, LAST_MODIFY, " +
	"CurCode, ExchangeRate, BaseRate, ForeignRate, Order_Status, " +
	"DocumentType, ApprovedBy, ApprovedOn, PurchaseOrder,SuppQuotationDate, " +
	"UserName, Warehouse, UpFlag) values " +
	"('" + prid + "','" + datecrt + "','PR','" + apcode + "','PurchaseReq', " +
	"'" + prec.get("SupplierName") + "','" + prec.get("address1") + "','" + prec.get("address2") + 
	"','" + prec.get("address3") + "','" + prec.get("address4") + "',''," +
	"'','','','','',''," +
	"'" + prec.get("contact_name") + "','" + prec.get("supp_tel_number") + "','','',0," +
	"0,0,0,0,0,0," +
	"0,0,0,'" + prec.get("notes") + "','','',null,0, " +
	"0,0,'X','','" + datecrt + "','" + todate + "'," +
	"'" + curcode + "',1,1,1,0," +
	"'PR','" + prec.get("approveby") + "','" + appdt + "','',''," +
	"'" + useraccessobj.username + "','none',0)";

	sqlhand.gpSqlExecuter(sqlstm);

	// insert 'em purchase-items
	sqlstm = "select description,unitprice,quantity,mysoftcode from purchasereq_items where pr_parent_id=" + ipr;
	pitms = sqlhand.gpSqlGetRows(sqlstm);
	if(pitms.size() == 0) return;
	itmc = 1;
	for(dpi : pitms)
	{
		gtotal = dpi.get("unitprice") * dpi.get("quantity");
		mysc = dpi.get("mysoftcode");
		if(mysc.equals("")) mysc = "-";

		sqlstm = "insert into pop_detail (ORDER_NUMBER,ITEM_NUMBER,STOCK_CODE,DESCRIPTION, " +
		"COMMENT_1,COMMENT_2,LONG_DESCRIPTION,DEPT_NUMBER, " +
		"QTY_ORDER,QTY_ALLOCATED,QTY_DELIVERED,QTY_DESPATCH, " +
		"UNIT_OF_SALE,UNIT_PRICE,TAX_AMOUNT,TAX_CODE,TAX_RATE, " +
		"FULL_NET_AMOUNT,DISCOUNT_AMOUNT,DISCOUNT_RATE,NET_AMOUNT, " +
		"NOMINAL_CODE,RequestDate) values (" +
		"'" + prid + "'," + itmc.toString() + ",'" + mysc + "','" + dpi.get("description") + "'," +
		"'','','','" + prec.get("dept_number") + "'," +
		dpi.get("quantity").toString() + ",0,0,0, " +
		"''," + dpi.get("unitprice").toString() + ",0,'Ts',0," +
		gtotal.toString() + ",0,0,0," +
		"'61100.710','" + datecrt + "')";

		sqlhand.gpSqlExecuter(sqlstm);
		itmc++;
	}

	// set upload bit
	sqlstm = "update purchaserequisition set upload=1 where origid=" + ipr;
	sqlhand.gpSqlExecuter(sqlstm);
	loadPurchaseReq(last_load_type);

	guihand.showMessageBox("PR uploaded to MySoft now..");
}

void showPRItems(String iwhat)
{
	sqlstm = "select mysoftcode,description,curcode,unitprice,quantity," + 
	"justification,approver_query,requester_response from purchasereq_items where origid=" + iwhat;
	retv = sqlhand.gpSqlFirstRow(sqlstm);
	if(retv == null) { guihand.showMessageBox("DBERR: Cannot load purchase item record.."); return; }

	Object[] jkl = { pri_mysoftcode, pri_description, pri_curcode, pri_unitprice, pri_quantity, pri_justification,
		pri_approver_query, pri_requester_response };

	String[] fl = { "mysoftcode", "description", "curcode", "unitprice", "quantity", "justification",
	"approver_query", "requester_response" };

	ngfun.populateUI_Data(jkl,fl,retv);
}

class prilb_onSelect implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_selected_pri = lbhand.getListcellItemLabel(isel,0);
		showPRItems(glob_selected_pri);
	}
}
prilbciker = new prilb_onSelect();

Object[] prilb_headers = 
{
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("#",true,"20px"),
	new listboxHeaderWidthObj("Item.Description",true,""),
	new listboxHeaderWidthObj("Qty",true,"40px"),
	new listboxHeaderWidthObj("U.Price",true,"120px"),
	new listboxHeaderWidthObj("Stat",true,"40px"),
};

void loadPR_items(String iprno)
{
	Listbox newlb = lbhand.makeVWListbox_Width(pritems_holder, prilb_headers, "pri_lb", 10);

	sqlstm = "select origid,description,unitprice,quantity,item_app_stat from purchasereq_items " +
	"where pr_parent_id=" + iprno + " order by origid";

	screcs = sqlhand.gpSqlGetRows(sqlstm);
	if(screcs.size() == 0) return;
	newlb.addEventListener("onSelect", prilbciker);
	lncnt = 1;
	pritotal = 0.0;
	ArrayList kabom = new ArrayList();
	for(dpi : screcs)
	{
		kabom.add(dpi.get("origid").toString());
		kabom.add(lncnt.toString() + ".");
		kabom.add(kiboo.checkNullString(dpi.get("description")));

		pritotal += dpi.get("quantity") * dpi.get("unitprice");

		kabom.add(dpi.get("quantity").toString());
		//kabom.add(kiboo.checkNullString(dpi.get("curcode")) + " " + nf.format(dpi.get("unitprice")) );
		kabom.add(nf.format(dpi.get("unitprice")) );
		kabom.add((dpi.get("item_app_stat") == null) ? "NA" : ((dpi.get("item_app_stat") == 0) ? "NA" : "AP") );

		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();

		lncnt++;
	}
	
	pritems_total.setValue(nf.format(pritotal));
}

void showPR_metadata(String iwhat)
{
	prec = getPR_Rec(iwhat);
	if(prec == null) { guihand.showMessageBox("DB ERROR!!!! Cannot load PR record"); return; }

	Object[] jkl = { pr_origid, pr_datecreated, pr_suppliername, pr_apcode, pr_address1, pr_address2,
		pr_address3, pr_address4, pr_contact_name, pr_supp_email, pr_supp_tel_number, pr_supp_fax,
		pr_priority, pr_notes, pr_duedate, pr_approver_notes, pr_dept_number };

	String[] fl = { "origid", "datecreated", "SupplierName", "APCode", "address1", "address2", "address3", "address4",
	"contact_name", "supp_email", "supp_tel_number", "supp_fax", "priority", "notes", "duedate", "approver_notes", "dept_number" };

	ngfun.populateUI_Data(jkl,fl,prec);
	workspace.setVisible(true);
}

class prlb_onSelect implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_selected_pr = lbhand.getListcellItemLabel(isel,0);
		glob_selected_status = lbhand.getListcellItemLabel(isel,6);

		showPR_metadata(glob_selected_pr);
		loadPR_items(glob_selected_pr);

		wksb = (!glob_selected_status.equals(PR_STAT_NEW)) ? true : false;
		disableWorkspaceButts(wksb,glob_selected_status);

		fillDocumentsList(glob_selected_pr);
	}
}
prlbcliker = new prlb_onSelect();

Object[] prlb_headers = 
{
	new listboxHeaderWidthObj("EPR",true,"40px"),
	//new listboxHeaderWidthObj("###",true,"35px"),
	new listboxHeaderWidthObj("Req.Date",true,"80px"),
	new listboxHeaderWidthObj("Supplier",true,""),
	new listboxHeaderWidthObj("ReqBy",true,"100px"),
	new listboxHeaderWidthObj("Dept",true,"120px"),
	new listboxHeaderWidthObj("Priority",true,"80px"),
	new listboxHeaderWidthObj("Stat",true,"70px"),
	new listboxHeaderWidthObj("PO",true,"30px"),
	//new listboxHeaderWidthObj("Justification",true,"180px"),
};

// itype: 1=by date or search-text, 2=approved, 3=non-approved
void loadPurchaseReq(int itype)
{
	last_load_type = itype;
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	st = kiboo.replaceSingleQuotes(searhtxt_tb.getValue().trim());

	Listbox newlb = lbhand.makeVWListbox_Width(pr_holder, prlb_headers, "pr_lb", 5);

	sqlstm = "select top 200 origid,datecreated,suppliername,dept_number,username,pr_status,upload,priority from purchaserequisition " +
	"where datecreated between '" + sdate + "' and '" + edate + "' ";

	switch(itype)
	{
		case 1:
			if(!st.equals("")) sqlstm += "and (suppliername like '%" + st + "%' or username like '%" + st + "%') ";
			break;
		case 2:
			sqlstm += "and pr_status='APPR' ";
			break;
		case 3:
			sqlstm += "and pr_status='SUBMIT' ";
			break;
	}
	
	sqlstm += "order by origid";

	screcs = sqlhand.gpSqlGetRows(sqlstm);
	if(screcs.size() == 0) return;
	newlb.setRows(20); newlb.setMold("paging");
	newlb.addEventListener("onSelect", prlbcliker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "datecreated", "suppliername", "username", "dept_number", "priority", "pr_status" };
	for(dpi : screcs)
	{
		ngfun.popuListitems_Data(kabom,fl,dpi);
		kabom.add((dpi.get("upload") == null) ? "N" : ((dpi.get("upload") == 0) ? "N" : "Y") );
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

void disableWorkspaceButts(boolean iwhat, String iprstat)
{
	Object[] jkl = { getsupplier_butt, savepr_butt, newitem_butt, deleteitem_butt, getitem_butt };
	disableUI_obj(jkl,iwhat);

	if(!iprstat.equals(PR_STAT_APPROVE) && !iprstat.equals(PR_STAT_CANCEL)) iwhat = false;

	Object[] jkl2 = { savepritem_butt, approverquery_butt, reqresp_butt, saveapproverquery, approveitem_butt, savejustification_butt};
	disableUI_obj(jkl2,iwhat);
}

//---- Suppliers selector funcs ----

void showSupplierDetails(String iwhat)
{
	sqlstm = "select apcode,suppliername,supadd1,supadd2,supadd3,supadd4,cperson1,email,phone,fax " +
	"from supplierdetail where apcode='" + iwhat + "'";

	retv = sqlhand.gpSqlFirstRow(sqlstm);
	if(retv == null) { guihand.showMessageBox("DB ERR: Cannot access supplier table!!"); return; }

	Object[] jkl = { supp_apcode, supp_suppliername, supp_addr1, supp_addr2, supp_addr3, supp_addr4,
		supp_cperson1, supp_email, supp_phone, supp_fax };

	String[] fl = { "apcode", "suppliername", "supadd1", "supadd2", "supadd3", "supadd4",
		"cperson1", "email", "phone", "fax" };

	ngfun.populateUI_Data(jkl,fl,retv);
	suppdet_grid.setVisible(true);
}

// customize the inject box-id for other module 
void selectTheSupplier()
{
	pr_suppliername.setValue(supp_suppliername.getValue());
	pr_apcode.setValue(supp_apcode.getValue());
	pr_address1.setValue(supp_addr1.getValue());
	pr_address2.setValue(supp_addr2.getValue());
	pr_address3.setValue(supp_addr3.getValue());
	pr_address4.setValue(supp_addr4.getValue());
	pr_contact_name.setValue(supp_cperson1.getValue());
	pr_supp_email.setValue(supp_email.getValue());
	pr_supp_tel_number.setValue(supp_phone.getValue());
	pr_supp_fax.setValue(supp_fax.getValue());
	suppselect_popup.close();
}

class supplb_onSelect implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		isel = event.getReference();
		glob_selected_supplier = lbhand.getListcellItemLabel(isel,0);
		showSupplierDetails(glob_selected_supplier);
	}
}

Object[] supplb_headers = 
{
	new listboxHeaderWidthObj("APCode",true,"60px"),
	new listboxHeaderWidthObj("Supplier",true,""),
};

void searchSupplier()
{
	srch = kiboo.replaceSingleQuotes(suppselect_search.getValue());
	if(srch.equals("")) return;

	Listbox newlb = lbhand.makeVWListbox_Width(suppsel_holder, supplb_headers, "suppliers_lb", 10);

	sqlstm = "select top 50 apcode,suppliername from supplierdetail " +
	"where apcode like '%" + srch + "%' or suppliername like '%" + srch + "%' or " +
	"supadd1 like '%" + srch + "%' or supadd2 like '%" + srch + "%' or supadd3 like '%" + srch + "%' or " +
	"supadd4 like '%" + srch + "%' or cperson1 like '%" + srch + "%' " +
	"order by suppliername";
	
	screcs = sqlhand.gpSqlGetRows(sqlstm);
	if(screcs.size() == 0) return;
	newlb.addEventListener("onSelect", new supplb_onSelect());
	ArrayList kabom = new ArrayList();
	for(dpi : screcs)
	{
		kabom.add(dpi.get("apcode"));
		kabom.add(kiboo.checkNullString(dpi.get("suppliername")));
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

//---- ENDOF Suppliers selector funcs ----

//---- stock item picker funcs ----

// customize this for other module -- where to put the stock-code and stock-desc
class stkitem_DClicker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		if(glob_selected_pri.equals("")) return;
		selitem = event.getTarget();
		stkc = lbhand.getListcellItemLabel(selitem,0);
		stkde = lbhand.getListcellItemLabel(selitem,1);

		// customize these
		pri_mysoftcode.setValue(stkc);
		pri_description.setValue(stkde);

		stockitem_popup.close();
	}
}

Object[] stkitemlb_headers = 
{
	new listboxHeaderWidthObj("StkCode",true,""),
	new listboxHeaderWidthObj("Item description",true,""),
};

void loadStockItems()
{
	srch = kiboo.replaceSingleQuotes(stk_search.getValue());
	if(srch.equals("")) return;

	Listbox newlb = lbhand.makeVWListbox_Width(stockitem_holder, stkitemlb_headers, "stockitems_lb", 10);

	sqlstm = "select top 50 stock_code,description from stockmasterdetails where " +
	"stock_code like 'po%" + srch + "%' and description like '%" + srch + "%' order by description";

	screcs = sqlhand.gpSqlGetRows(sqlstm);
	if(screcs.size() == 0) return;
	//newlb.addEventListener("onSelect", new supplb_onSelect());
	ArrayList kabom = new ArrayList();
	for(dpi : screcs)
	{
		kabom.add(dpi.get("stock_code"));
		kabom.add(kiboo.checkNullString(dpi.get("description")));
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
	}

	dc_obj = new stkitem_DClicker();
	lbhand.setDoubleClick_ListItems(newlb, dc_obj);
}

//---- ENDOF stock item picker funcs ----

