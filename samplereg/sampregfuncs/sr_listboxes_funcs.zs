// Sample registration listboxes funcs

// onSelect listener for samples_lb
class SamplesLB_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		if(!global_selected_sampleid.equals(""))
		{
			saveSampleMarking_Details();
			oldlc = samples_lb.getItemAtIndex(sample_lb_currentindex);
			lbhand.setListcellItemLabel(oldlc,3,samplemarking.getValue());
		}

		sample_lb_currentindex = samples_lb.getSelectedIndex(); // 9/2/2010: save the selected index now for use above logic later

		selitem = samples_lb.getSelectedItem();
		global_selected_sampleid = lbhand.getListcellItemLabel(selitem,0);
		showSampleMarking_Details();

		samples_lb.invalidate(); // refresh the listbox
	}
}
smplbcliker = new SamplesLB_Listener();

// Search and populate samples in folders listbox
void startFolderSamplesSearch(String folder_origid)
{
Object[] samples_lb_headers = {
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("##",true,"15px"),
	new listboxHeaderWidthObj("SampleID",true,"90px"),
	new listboxHeaderWidthObj("Samp.Marking",true,""),
	new listboxHeaderWidthObj("Share",true,"50px"),
	new listboxHeaderWidthObj("Conts",true,"50px"),
};

	// 19/11/2010: reset stuff
	global_selected_sampleid = "";
	clearSampleMarking_Details();

	sqlstm = "select top 300 origid,samplemarking,bottles,share_sample from JobSamples where jobfolders_id=" + folder_origid +
	" and deleted=0 order by origid";

	r = sqlhand.gpSqlGetRows(sqlstm);

	Listbox newlb = lbhand.makeVWListbox_Width(samples_div, samples_lb_headers, "samples_lb", 5);
	if(r.size() == 0) return;
	newlb.setRows(15);
	newlb.addEventListener("onSelect", smplbcliker );
	smpcount = 1;
	ArrayList kabom = new ArrayList();
	for(d : r)
	{
		bottl = (d.get("bottles") == null) ? "-" : d.get("bottles").toString();
		kabom.add(d.get("origid").toString());
		kabom.add(smpcount.toString() + ".");
		kabom.add(global_selected_folderstr + kiboo.padZeros5(d.get("origid")));
		kabom.add(lbhand.trimListitemLabel(d.get("samplemarking"),35));
		kabom.add(kiboo.checkNullString(d.get("share_sample")));
		kabom.add(bottl);
		strarray = kiboo.convertArrayListToStringArray(kabom);
		lbhand.insertListItems(newlb,strarray,SAMPLES_PREFIX,"");
		smpcount++;
		kabom.clear();
	}

} // end of startFolderSamplesSearch()

// onSelect listener for folderjobs_lb
class FolderLB_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		// 3/2/2010: to be coded - update JobSamples->sampleid_str with the full ALSM0000100001 string for easier access in BIRT
		// 8/2/2010: if there was a previously selected folder, save the samples full string
		//oldfoldn = whathuh.fj_origid_folderno.getValue();
		if(!global_selected_folder.equals("")) samphand.saveFolderSamplesNo_Main2(samples_lb); // samplereg_funcs.zs
		
		selitem = folderjobs_lb.getSelectedItem();
		global_selected_folderstr = lbhand.getListcellItemLabel(selitem,0);
		global_selected_arcode = lbhand.getListcellItemLabel(selitem,8);

		//global_selected_folderstr = folderjobs_lb.getSelectedItem().getLabel();
		//clearFolderMetadata();
		showFolderMetadata(global_selected_folderstr);
		showLabComments(global_selected_folderstr); // 13/01/2013: show lab-comments if any
	}
}
folderlbcliker = new FolderLB_Listener();

// Do the search and populate listbox
// 29/3/2010: added branch checking - should be deployable to other branches later
// 15/4/2010: added different folder prefix for branches
// 11/6/2010: optimize codes - make use of lbhand.makeVWListbox() to create listbox cols
void startFolderJobsSearch(Datebox startd, Datebox endd)
{
Object[] folders_lb_headers = {

	new listboxHeaderWidthObj("FolderNo",true,"80px"),
	new listboxHeaderWidthObj("R.Date",true,"20px"),
	new listboxHeaderWidthObj("Customer",true,""),
	new listboxHeaderWidthObj("Prty",true,"40px"),
	new listboxHeaderWidthObj("Hold",true,"25px"),
	new listboxHeaderWidthObj("Share",true,"40px"),
	new listboxHeaderWidthObj("Brnch",true,"20px"),
	new listboxHeaderWidthObj("Owner",true,"50px"),
	new listboxHeaderWidthObj("arcode",false,"")
	
};

	sdate = kiboo.getDateFromDatebox(startd);
	edate = kiboo.getDateFromDatebox(endd);
	
	sdate += " 00:00:00";
	edate += " 23:59:00";

	Listbox newlb = lbhand.makeVWListbox_Width(folderjobs_div, folders_lb_headers, "folderjobs_lb", 5);

	// 29/3/2010: check branch
	branch_str = "";

	ibranch = useraccessobj.branch;
	// if admin login, should be able to see all folders else filter according to branch
	if(!ibranch.equals("ALL")) branch_str = "and branch='" + ibranch + "'";

	sqlstm = "select top 200 jf.createdby,jf.origid, jf.branch, jf.datecreated, jf.folderno_str, jf.ar_code, " + 
	"jf.priority, jf.share_sample, jf.jobhold_status, customer.customer_name, csci.customer_name as cashcustomer from jobfolders jf " +
	"left join customer on customer.ar_code = jf.ar_code " +
	"left join cashsales_customerinfo csci on csci.folderno_str = jf.folderno_str " +
	"where jf.datecreated between '" + sdate + "' and '" + edate + "' " +
	"and jf.deleted=0 and jf.folderstatus='" + FOLDERDRAFT + "' " + branch_str + " order by jf.datecreated desc";

	r = sqlhand.gpSqlGetRows(sqlstm);

	if(r.size() == 0) return;
	newlb.setRows(21);
	newlb.setMold("paging");
	newlb.addEventListener("onSelect", folderlbcliker );
	ArrayList kabom = new ArrayList();
	for(d : r)
	{
		db_folderno_str = d.get("folderno_str");
		if(db_folderno_str.equals(""))
		{
			folderprefix = JOBFOLDERS_PREFIX; // default folder prefix
			chkbranch = d.get("branch");
			ifolderno = d.get("origid");

			// 15/4/2010: set branch folders prefix
			if(chkbranch.equals("JB")) folderprefix = JB_JOBFOLDERS_PREFIX;
			if(chkbranch.equals("KK")) folderprefix = KK_JOBFOLDERS_PREFIX;
			db_folderno_str = folderprefix + kiboo.padZeros5(ifolderno);
		}

		kabom.add(db_folderno_str);
		ifolderno = d.get("origid");

		kabom.add(d.get("datecreated").toString().substring(0,10));
		//kabom.add(d.get("duedate").toString().substring(0,10));

		icompanyname = "Undefined";
		iar_code = d.get("ar_code");
		
		if(iar_code != null)
		{
		iar_code = iar_code.toUpperCase().trim();

		if(iar_code.equals("CASH") || iar_code.equals("CASH USD") || iar_code.equals("300S-550"))
		{
			icompanyname = (iar_code.equals("300S-550")) ? "Syabas: " : "CshAcct: ";

			if(d.get("cashcustomer") != null)
				icompanyname += d.get("cashcustomer");
			else
				icompanyname += "UNKNOWN";
		}
		else
			icompanyname = kiboo.checkNullString_RetWat(d.get("customer_name"),"Undefined");
		}

		//kabom.add(lbhand.trimListitemLabel(icompanyname,35));
		kabom.add(icompanyname);
		kabom.add(d.get("priority"));
		//kabom.add(d.get("folderstatus"));
		
		kabom.add(kiboo.checkNullString_RetWat(d.get("jobhold_status"),""));
		
		kabom.add(kiboo.checkNullString_RetWat(d.get("share_sample"),""));
		kabom.add(d.get("branch"));

		kabom.add(kiboo.checkNullString(d.get("createdby"))); // 13/01/2013: show who own the folder during registration
		kabom.add(d.get("ar_code"));

		strarray = kiboo.convertArrayListToStringArray(kabom);
		lbhand.insertListItems(newlb,strarray,"false","");
		kabom.clear();
	}
	java.io.StringWriter wr = new java.io.StringWriter();
	newlb.redraw(wr);

} // end of startFolderJobsSearch()
