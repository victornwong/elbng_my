import org.victor.*;
// New folders lister thing

// copied over from browsejobs_v4.zul
FOLDERPICK_COLOR = "background:#AAAAAA;";
OVERDUE_ROWCOLOR = "background:#F74623;";
RELEASED_ROWCOLOR = "background:#AEF520;";
HOLD_REJECT_ROWCOLOR = "background:#cd2467;";

void expfoldersexcel()
{
	if(folders_searchdiv.getFellowIfAny("folders_lb") != null)
		exportExcelFromListbox(folders_lb, kasiexport_holder, newfolderhds, "folderslist.xls","folders");
}

Object[] newfolderhds = {
	new listboxHeaderWidthObj("origid",false,""),
	new listboxHeaderWidthObj("Folder",true,"70px"),
	new listboxHeaderWidthObj("Prty",true,""),
	new listboxHeaderWidthObj("Dated",true,"70px"),
	new listboxHeaderWidthObj("Due",true,"70px"),
	new listboxHeaderWidthObj("Customer",true,""), // 5
	new listboxHeaderWidthObj("HOLD",true,""),
	new listboxHeaderWidthObj("SC",true,""),
	new listboxHeaderWidthObj("LC",true,""),
	new listboxHeaderWidthObj("Subc",true,""),
	new listboxHeaderWidthObj("SRA",true,""), // 10
	new listboxHeaderWidthObj("F.Status",true,""),
	new listboxHeaderWidthObj("LabStat",true,""),
	new listboxHeaderWidthObj("Rel.Date",true,""),
	new listboxHeaderWidthObj("COA.Date",true,""),
	new listboxHeaderWidthObj("T.COA",true,""), // 15
	new listboxHeaderWidthObj("Share",true,""),
	new listboxHeaderWidthObj("PerShare",true,""),
	new listboxHeaderWidthObj("Pkup",true,""),
	new listboxHeaderWidthObj("Brh",true,""),
	new listboxHeaderWidthObj("PKD",true,""), // 20
	new listboxHeaderWidthObj("arcode",false,""),
};

FOLDERNO_POS = 1;
RELDATE_POS = 13;
COADATE_POS = 14;
PERSHARE_POS = 17;
ARCODE_POS = 21;

class lbcliker implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitm = event.getReference();
		s = lbhand.getListcellItemLabel(selitm,0);

		global_selected_origid = lbhand.getListcellItemLabel(selitm,0);
		global_selected_arcode = lbhand.getListcellItemLabel(selitm,ARCODE_POS);
		selected_folderno = global_selected_folderno = lbhand.getListcellItemLabel(selitm,FOLDERNO_POS);
		global_selected_customername = lbhand.getListcellItemLabel(selitm,5);

		foldermeta_area_toggler = false;
		foldermeta_loaded = false;
		foldermeta_area.setVisible(false);
	}
}
cliker = new lbcliker();

void loadFoldersList_NG(int itype)
{
	last_foldersearch_type = itype;

	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	searchtext = kiboo.replaceSingleQuotes(customer_tb.getValue());
	byfold = kiboo.replaceSingleQuotes(byfolder_tb.getValue());
	bysamp = kiboo.replaceSingleQuotes(bysampleid_tb.getValue());
	sharesmp = share_sample.getSelectedItem().getLabel();
	creditm = customer_terms_lb.getSelectedItem().getLabel();
	smarking = kiboo.replaceSingleQuotes(bysampmarking_tb.getValue());
	asmapo = kiboo.replaceSingleQuotes(customer_po.getValue());
	trkflag = track_flag.getSelectedItem().getLabel();
	jobhstat = jobhold_status.getSelectedItem().getLabel();

	Listbox newlb = lbhand.makeVWListbox_Width(folders_searchdiv, newfolderhds, "folders_lb", 5);

	sqlstm_head = "select top 300 jf.origid, jf.ar_code, jf.priority, jf.datecreated, jf.folderstatus, jf.branch," + 
	"jf.duedate, jf.tat, jf.folderno_str, jf.labfolderstatus, jf.pkd_samples, jf.share_sample, jf.coadate,jf.prepaid, " +
	"customer.customer_name, csci.customer_name as cashcustomer, " +
	"(select count(origid) from jobsamples where jobfolders_id = jf.origid and deleted=0) as samplecount, " +
	"jf.terimacoa_date, jf.releaseddate, jf.srngenerate_date, jf.jobhold_status, " +
	"(select count(origid) from elb_labcomments where folderno_str=jf.folderno_str) as lccount, " +
	"(select count(origid) from elb_subcon_items where folderno_str=jf.folderno_str) as subcon, " +
	"(select count(sampleid_str) from elb_labpickedsamples where sampleid_str like '____' + cast(jf.origid as varchar) + '______') as pickcount " +
	"from jobfolders jf " +
	"left join customer on customer.ar_code = jf.ar_code " +
	"left join jobsamples js on js.jobfolders_id = jf.origid " +
	"left join cashsales_customerinfo csci on csci.folderno_str = jf.folderno_str " +
	"where jf.deleted=0 and jf.folderstatus in ('" + FOLDERCOMMITED + "','" + FOLDERLOGGED + "') ";
	//"where jf.deleted=0 ";

	sqlstm_foot = "group by jf.origid, jf.ar_code, jf.datecreated, jf.priority, jf.folderstatus, jf.branch," + 
	"jf.duedate, jf.tat, jf.folderno_str, jf.labfolderstatus, jf.pkd_samples, jf.share_sample, jf.coadate, jf.jobhold_status, " +
	"customer.customer_name, csci.customer_name, jf.terimacoa_date,jf.releaseddate,jf.srngenerate_date, jf.prepaid " +
	"order by jf.datecreated desc";
	//sqlstm_foot = "order by jf.datecreated desc";

	bystext = "";
	bydate = "and jf.datecreated between '" + sdate + "' and '" + edate + "' ";
	switch(itype)
	{
		case 2:
			bydate = " ";
			bystext = "and jf.folderno_str like '%" + byfold + "%' ";
			break;

		case 3:
			bydate = " ";		
			bystext = "and js.sampleid_str like '_________%" + bysamp + "%' ";
			break;
			
		case 4:
			bystext = "and jf.share_sample='" + sharesmp + "' ";
			break;
			
		case 5:
			bystext = "and pkd_samples=1 ";
			break;
			
		case 6:
			selitem = qt_salesperson.getSelectedItem();
			salesp = lbhand.getListcellItemLabel(selitem,1);
			if(salesp.equals("None")) return;
			bystext = "and customer.salesman_code='" + salesp + "' ";
			break;
			
		case 7: // by credit-term
			bystext = "and customer.credit_period='" + creditm + "' ";
			break;
			
		case 8:
			bystext = "and js.samplemarking like '%" + smarking + "%' ";
			break;

		case 9: // by customer-category
			cstca = custcat_lb.getSelectedItem().getLabel();
			bystext = "and customer.category='" + cstca + "' ";
			break;

		case 10: // by ASMA project-types
			bystext = "and jf.customerpo='" + asmapo + "' ";
			break;

		case 11: // by track_flag
			bystext = "and jf.track_flag='" + trkflag + "' ";
			break;

		case 12: // by jobhold_status
			bystext = "and jf.jobhold_status='" + jobhstat + "' ";
			break;

		default:
			if(!searchtext.equals("")) bystext = "and (customer.customer_name like '%" + searchtext + "%' " + 
			"or csci.customer_name like '%" + searchtext + "%') ";
			break;
	}

	sqlstm = sqlstm_head + bydate + bystext + sqlstm_foot;

	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() == 0) { return; }

	newlb.setMold("paging"); newlb.setRows(21);
	newlb.addEventListener("onSelect", cliker);
	ArrayList kabom = new ArrayList();

	String[] fl = { "origid", "folderno_str", "priority", "datecreated", "duedate", "customer_name", "jobhold_status",
	"samplecount", "lccount", "subcon", "srngenerate_date", "folderstatus", "labfolderstatus", "releaseddate", "coadate",
	"terimacoa_date", "share_sample", "share_sample", "pickcount", "branch", "pkd_samples", "ar_code" };

	overduecount = releasedcount = jobholdcount = 0;
	todate = new Date();

	for(d : r)
	{
		ngfun.popuListitems_Data(kabom, fl, d);
		ki = lbhand.insertListItems(newlb, kiboo.convertArrayListToStringArray(kabom), "false", "");
		// some post-processing

		kx = lbhand.getListcellItemLabel(ki,RELDATE_POS);
		if(kx.equals("1900-01-01")) lbhand.setListcellItemLabel(ki,RELDATE_POS,""); // take out 1900-01-01 dates
		coadt = lbhand.getListcellItemLabel(ki,COADATE_POS);
		if(coadt.equals("1900-01-01")) { lbhand.setListcellItemLabel(ki,COADATE_POS,""); coadt = ""; }

		psstr = getPerSampleShareSample(d.get("origid").toString());
		lbhand.setListcellItemLabel(ki,PERSHARE_POS,psstr);

		// process overdue bar-color
		duedate = d.get("duedate");
		overdue = 1;
		if(todate.compareTo(duedate) >= 0 && d.get("labfolderstatus").equals("WIP"))
			overdue = 2;
		else
			overdue = 3;

		overduestyle = "";
		labelstyle = "";

		switch(overdue)
		{
			case 2:
				overduestyle = OVERDUE_ROWCOLOR;
				// 22/05/2013: req by Doc. if got coa.date , deemed as RELEASED -- 
				// haha, no results-entry still consider released.
				if(coadt.equals(""))
				{
					labelstyle = "color:#ffffff;font-size:9px;font-weight:bold";
					overduecount++;
				}
				else
				{
					overduestyle= RELEASED_ROWCOLOR;
					labelstyle = "color:#222222;font-size:9px";
					releasedcount++;
				}
				break;
			case 3:
				if(d.get("labfolderstatus").equals("RELEASED"))
				{
					overduestyle= RELEASED_ROWCOLOR;
					labelstyle = "color:#222222;font-size:9px";
					releasedcount++;
				}
				break;
		}

		//ki.setStyle(overduestyle);
		setListcell_Style(ki,COADATE_POS,overduestyle + labelstyle);
		setListcell_Style(ki,RELDATE_POS,overduestyle + labelstyle);

		kabom.clear();
	}

	numofsamples_lbl.setValue(r.size().toString());
	overdue_count_lbl.setValue(overduecount.toString());
	released_count_lbl.setValue(releasedcount.toString());
	wip_lbl.setValue((r.size()-releasedcount).toString());
	jobhold_count_lbl.setValue(jobholdcount.toString());

	folderworkbutts.setVisible(true);
	folderworkarea.setVisible(true);

}

