// 25/06/2014: Billing uploader funcs

class folderslb_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitem = event.getReference();
		selected_folder_origid = lbhand.getListcellItemLabel(selitem,0);
		selected_folderno = lbhand.getListcellItemLabel(selitem,2);
		selected_folder_status = lbhand.getListcellItemLabel(selitem,3);
		glob_upload_flag = lbhand.getListcellItemLabel(selitem,6);
		documentLinkProp.global_eq_origid = selected_folder_origid; // used by doculink.zul
	}
}
fldercliker = new folderslb_Listener();

Object[] clientsfolders_headers = {
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("Dated",true,"80px"),
	new listboxHeaderWidthObj("Folder",true,"80px"),
	new listboxHeaderWidthObj("Stats",true,"70px"),
	new listboxHeaderWidthObj("SC",true,"30px"),
	new listboxHeaderWidthObj("CoA",true,"80px"),
	new listboxHeaderWidthObj("MySoft",true,"50px"),
	new listboxHeaderWidthObj("ReUpl",true,"80px"),
	new listboxHeaderWidthObj("P.Pd",true,"30px"),
	new listboxHeaderWidthObj("Inv.No",true,""),
	new listboxHeaderWidthObj("Inv.Date",true,"80px"),
	new listboxHeaderWidthObj("Issuer",true,""),
	new listboxHeaderWidthObj("B.Notes",true,""),
	new listboxHeaderWidthObj("Dated",true,""),
	};
COADATE_IDX = 5;
UPMYSOFT_IDX = 6;
	
void listFoldersByClient(String tarcode)
{
	if(tarcode.equals("")) return;

	// some vars and gui reset
	selected_folderno = "";
	selected_folder_origid = "";
	//if(doculist_holder.getFellowIfAny("doculinks_lb") != null) doculinks_lb.setParent(null);

	jobnotes_tb.setValue(""); // clear job notes text-box

	clearQuotationStuff();

	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);

	sqlstm = "select top 250 jobfolders.origid, jobfolders.datecreated, jobfolders.folderno_str," +
	"jobfolders.coadate, jobfolders.uploadToMYSOFT,jobfolders.prepaid, jobfolders.folderstatus," +
	"jobfolders.billingnotes, jobfolders.billingnotes_date, jobfolders.mysoft_reupload, " +
	"count(jobsamples.origid) as samplescount, " +
	"(select invoicedate from invoice where domaster.invoiceno = invoiceno) as invdate," +
	"domaster.invoiceno as invoice_num, " +
	"invoice.username as issuedby " +
	"from jobfolders " +
	"left join jobsamples on jobsamples.jobfolders_id = jobfolders.origid " +
	"left join invoice on invoice.invoiceno = jobfolders.folderno_str " +
	"left join deliveryordermaster domaster on domaster.dono = jobfolders.folderno_str " +
	"where jobfolders.ar_code='" + tarcode + "' and " +
	"jobfolders.datecreated between '" + sdate + "' and '" + edate + "' " +
	"and jobfolders.deleted=0 and jobsamples.deleted=0 " +
	"and jobfolders.folderstatus in ('" + FOLDERCOMMITED + "','LOGGED')" +
	"group by jobfolders.origid,jobfolders.folderno_str,jobfolders.datecreated," + 
	"jobfolders.coadate, jobfolders.uploadToMYSOFT,jobfolders.prepaid,domaster.invoiceno," + 
	"jobfolders.folderstatus,invoice.username, jobfolders.billingnotes, jobfolders.billingnotes_date, jobfolders.mysoft_reupload " +
	"order by jobfolders.folderno_str";

	therows = sqlhand.gpSqlGetRows(sqlstm);

	foldercount_label.setValue("");
	Listbox newlb = lbhand.makeVWListbox_Width(folders_holder, clientsfolders_headers, "folders_lb", 5);
	if(therows.size() == 0) return;

	newlb.setRows(21);
	newlb.setMultiple(true);
	newlb.setMold("paging");
	newlb.addEventListener("onSelect", fldercliker);

	comitcount = 0;
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "datecreated", "folderno_str", "folderstatus", "samplescount", "coadate",
	"uploadToMYSOFT", "mysoft_reupload", "prepaid", "invoice_num", "invdate", "issuedby", "billingnotes", "billingnotes_date" };
	for(dpi : therows)
	{
		popuListitems_Data(kabom,fl,dpi);
		/*
		kabom.add(dpi.get("origid").toString());
		kabom.add(dpi.get("datecreated").toString().substring(0,10));
		kabom.add(dpi.get("folderno_str"));
		kabom.add(dpi.get("folderstatus"));
		kabom.add(dpi.get("samplescount").toString());
		coadatestr = kiboo.checkNullDate(dpi.get("coadate"),"---");
		if(coadatestr.equals("1900-01-01")) coadatestr = "---";
		kabom.add(coadatestr);

		upmysoft = (dpi.get("uploadToMYSOFT") == 1) ? "UpL" : "---";
		kabom.add(upmysoft);

		kabom.add(kiboo.checkNullDate(dpi.get("mysoft_reupload"),"---"));

		pptick = dpi.get("prepaid");
		pptickstr = (pptick == null) ? "---" : ((pptick == 1) ? "-Y" : "---") ;
		kabom.add(pptickstr);

		kabom.add(kiboo.checkNullString_RetWat(dpi.get("invoice_num"),"---"));
		kabom.add(kiboo.checkNullDate(dpi.get("invdate"),"---"));
		kabom.add(kiboo.checkNullString_RetWat(dpi.get("issuedby"),"---"));
		kabom.add(kiboo.checkNullString_RetWat(dpi.get("billingnotes"),"---"));
		kabom.add(kiboo.checkNullDate(dpi.get("billingnotes_date"),"---"));
*/

		if(dpi.get("folderstatus").equals(FOLDERCOMMITED)) comitcount++;
		ki = lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"","");
		upmysoft = (dpi.get("uploadToMYSOFT") == 1) ? "UpL" : "";
		if(dtf2.format(dpi.get("coadate")).equals("1900-01-01"))
		{
			lbhand.setListcellItemLabel(ki, COADATE_IDX, "");	
		}
		lbhand.setListcellItemLabel(ki, UPMYSOFT_IDX, upmysoft);
		kabom.clear();
	}

	foldercount_label.setValue("Found : " + comitcount.toString() + " committed");
}

class clientfolderslb_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitem = event.getReference();
		selected_arcode = lbhand.getListcellItemLabel(selitem,0);

		customername = lbhand.getListcellItemLabel(selitem,2);
		folders_label.setValue("Folders: " + customername);

		folders_gb.setVisible(true);
		listFoldersByClient(selected_arcode);
		showCourierBills(selected_arcode); // 05/09/2012: show send-out-cooler-boxes records
	}
}
clfoldercliker = new clientfolderslb_Listener();

void listClientsWithFolders(int itype)
{
Object[] clients_headers = {
	new listboxHeaderObj("AR Code",true),
	new listboxHeaderObj("Folders",true),
	new listboxHeaderObj("Client name",true),
	new listboxHeaderObj("Cat.",true),
	};

	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	cnm = kiboo.replaceSingleQuotes(clientsearch_tb.getValue());
	clientcat = clientcat_dd.getSelectedItem().getLabel();

	// list by client but no input, return lor
	if(itype == 2 && cnm.equals("")) return;

	otherquery = "";

	if(itype == 2) otherquery = " and customer.customer_name like '%" + cnm + "%'";
	if(itype == 3) otherquery = " and customer.category='" + clientcat + "'";

	sqlstm = "select distinct jobfolders.ar_code, customer.customer_name, count(jobfolders.origid) as folderscount, customer.category " +
	"from jobfolders " +
	"left join customer on jobfolders.ar_code = customer.ar_code " +
	"where datecreated between '" + sdate + "' and '" + edate + "' " +
	"and jobfolders.ar_code <> '' and jobfolders.deleted=0 " + otherquery +
	" group by jobfolders.ar_code,customer.customer_name, customer.category ";

	Listbox newlb = lbhand.makeVWListbox(clients_holder, clients_headers, "clients_lb", 5);
	therows = sqlhand.gpSqlGetRows(sqlstm);
	if(therows.size() == 0) return;

	newlb.setRows(21);
	newlb.setMold("paging");
	newlb.addEventListener("onSelect", clfoldercliker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "ar_code", "folderscount", "customer_name", "category" };
  for(dpi : therows)
  {
  	popuListitems_Data(kabom,fl,dpi);
  	/*
		kabom.add(dpi.get("ar_code"));
		kabom.add(dpi.get("folderscount").toString());
		kabom.add(dpi.get("customer_name"));
		kabom.add(kiboo.checkNullString_RetWat(dpi.get("category"),"--"));
		*/
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"","");
		kabom.clear();
  }
}
