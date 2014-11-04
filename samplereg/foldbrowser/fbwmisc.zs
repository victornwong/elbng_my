// Folder browser misc funcs

String getPerSampleShareSample(String iorigid)
{
	sqlstm = "select distinct share_sample from jobsamples where share_sample is not null and jobfolders_id=" + iorigid; 
	pssm = sqlhand.gpSqlGetRows(sqlstm);
	retval = "";
	if(pssm.size() != 0)
	{
		for(di : pssm)
		{
			retval += di.get("share_sample") + " ";
		}
	}
	return retval;
}

//--- 15/05/2011: folder cancellation funcs --

selected_cancel_origid = selected_cancel_folder = selected_cancel_client = cancel_reason = "";

void sendCancelFolderNotification(String ifolder, String icancelreason, String iclient, String iuser)
{
	to_string = convertStringArrayToString(cashacct_email_notification);
    subj = "[NOTIFICATION] FOLDER CANCELLED : " + ifolder;
    emailbody = 
    "Client : " + iclient + "\n" +
    "Folder " + ifolder + " has been cancelled by " + iuser + " .\n\n" +
    "With cancellation reason:\n\n" +
    icancelreason + "\n\n" +
    "**PLEASE TAKE NOTE AND DO WHATEVER NECESSARY**\n" +
    "**THIS NOTIFICATION IS AUTO-GEN - DONT REPLY**";

	//simpleSendEmail(SMTP_SERVER,"info@alsglobal.com.my", to_string, subj, emailbody);
	simpleSendEmail(SMTP_SERVER,"elabman@alsglobal.com.my", to_string,subj,emailbody);
}

// 15/05/2011: cancel folder and keep track on cancelation date
void cancelFolder()
{
	if(!sechand.validSupervisor(useraccessobj.username,supervisors)) return;

	if(global_selected_origid.equals("")) return;

	selected_cancel_folder = global_selected_folderno;
	selected_cancel_origid = global_selected_origid;
	selected_cancel_client = global_selected_customername;
	cancelfolder_lbl.setValue("Cancelling " + selected_cancel_folder);
	cancelreason.setValue("");
	cancelfolder_popup.open(cancelfolder_btn);
}

void realCancelFolder()
{
	if(selected_cancel_origid.equals("")) return;
	canreason = kiboo.replaceSingleQuotes(cancelreason.getValue());
	if(canreason.equals("") || canreason.length() < 10 )
	{
		guihand.showMessageBox("Please enter some valid reason why you want to cancel this folder..");
		return;
	}

	if (Messagebox.show("Really cancel this folder " + selected_cancel_folder + " ??", "Are you sure?", 
		Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) ==  Messagebox.NO) return;

	todate = kiboo.getDateFromDatebox(hiddendatebox);

	sqlstm = "update jobfolders set canceldate='" + todate + "', cancelreason='" + canreason + "'," + 
	"canceluser='" + useraccessobj.username + "',deleted=1 where origid=" + selected_cancel_origid;

	sqlhand.gpSqlExecuter(sqlstm);
	loadFoldersList(last_foldersearch_type); // refresh

	//cancelfolder_popup.close();
	guihand.showMessageBox("FOLDER CANCELLED");

	// send email-notification on folder cancellation
	//sendCancelFolderNotification(selected_cancel_folder,canreason,selected_cancel_client,useraccessobj.username);	
}

// ENDOF folder cancellation funcs

// 11/08/2010: to show cash-account details, stored in a diff table mah..
// 05/09/2012: updated to use formkeeper , CASHDETAIL_FORM_ID = 11
void showCashAccountDetails_clicker()
{
	if(global_selected_folderno.equals("")) return;

	fmobj = sqlhand.getFormKeeper_rec(CASHDETAIL_FORM_ID);
	if(fmobj == null) { gui.showMessageBox("ERR: Cannot load XML-form definitions"); return; }
	formxml = sqlhand.clobToString(fmobj.get("xmlformstring"));
	glob_cashdetform = new vicFormMaker(cashdet_holder,"cashdetsform",formxml);
	glob_cashdetform.generateForm();

	// populate 'em boxes
	csrec = samphand.getCashSalesCustomerInfo_Rec(global_selected_folderno);
	if(csrec == null) return;

	Object[] jkl = { ca_customer_name_tb, ca_contact_person1_tb, ca_address1_tb, ca_address2_tb,
		ca_city_tb, ca_zipcode_tb, ca_state_tb, ca_country_tb, ca_telephone_tb, ca_fax_tb,
		ca_email_tb };

	String[] fl = { "customer_name", "contact_person1", "address1", "address2",
		"city", "zipcode", "state", "country", "telephone", "fax", "email" };

	ngfun.populateUI_Data(jkl,fl,csrec);
	cashdet_holder.setVisible(true);
}

void showFolderMetadata()
{
	if(global_selected_origid.equals("")) return;
	if(!foldermeta_loaded)
	{
		cashdet_holder.setVisible(false);
		if(global_selected_arcode.equals("CASH") || global_selected_arcode.equals("CASH USD") || global_selected_arcode.equals("300S-550"))
			showCashAccountDetails_clicker(); // load cash-account details if this folder is

		showDocumentsList(global_selected_folderno);
		foldermeta_loaded = true;
	}

	foldermeta_area_toggler = (foldermeta_area_toggler) ? false : true;
	foldermeta_area.setVisible(foldermeta_area_toggler);
}

// export list of folders to Excel
// can make this into multi-purpose func later
void kasiExport_clicker()
{
	gridrows = null;

	for(kobj : folders_lb.getChildren())
	{
		if(kobj instanceof Rows) gridrows = kobj;
	}

	if(gridrows == null) return;
	ifilename = "folderslist.xls";
	isheetname = "FoldersList";

	// Uses Apache POI stuff
	HSSFWorkbook wb = new HSSFWorkbook();
	thefn = session.getWebApp().getRealPath("tmp/" + ifilename);
	FileOutputStream fileOut = new FileOutputStream(thefn);
	sheet = wb.createSheet(isheetname);

	stylo = wb.createCellStyle();
	stylo.setFillBackgroundColor((short)210);

	// Header row - folderListHeaders def above
	row1 = sheet.createRow(0);
	for(i=0; i < folderListHeaders.length; i++)
	{
		hedc = row1.createCell(i);
		hedc.setCellValue(folderListHeaders[i]);
		hedc.setCellStyle(stylo);
	}

	cellstylo = wb.createCellStyle();
	cellstylo.setWrapText(true);

	rowcount = 1;

	for(robj : gridrows.getChildren())
	{
		if(robj instanceof Row)
		{
			row = sheet.createRow(rowcount);

			colcount = 0;
			for(lobj : robj.getChildren())
			{
				if(lobj instanceof Label)
				{
					labelval = lobj.getValue();
					row.createCell(colcount).setCellValue(labelval);
				}
				colcount++;
			}
			rowcount++;
		}	
	}

	ps = sheet.getPrintSetup();
	ps.setScale((short)70);

	wb.write(fileOut);
	fileOut.close();

	// long method to let user download a file	
	File f = new File(thefn);
	fileleng = f.length();
	finstream = new FileInputStream(f);
	byte[] fbytes = new byte[fileleng];
	finstream.read(fbytes,0,(int)fileleng);

	AMedia amedia = new AMedia(ifilename, "xls", "application/vnd.ms-excel", fbytes);
	Iframe newiframe = new Iframe();
	newiframe.setParent(kasiexport_holder);
	newiframe.setContent(amedia);
}

// 14/01/2013: view subcontracts for a folder -- knockoff from frontSlab_v2.zul
void viewSubcontract(Component iwhat)
{
	Object[] subcon_headers =
	{
		new listboxHeaderWidthObj("Folder",true,"80px"),
		new listboxHeaderWidthObj("SampleID",true,"80px"),
		new listboxHeaderWidthObj("Samp.Mark",true,"150px"),
		new listboxHeaderWidthObj("Tests",true,"150px"),
	};

	if(global_selected_folderno.equals("")) return;

	sqlstm = "select sc.origid, sc.subcon_name, sc.datecreated, sc.username, sci.test_request, sci.folderno_str, sci.sampleid, sci.samplemarking " +
	"from elb_subcons sc left join elb_subcon_items sci on sci.parent_id = sc.origid " +
	"where sci.folderno_str = '" + global_selected_folderno + "'";

	subcs = sqlhand.gpSqlGetRows(sqlstm);
	if(subcs.size() == 0) return;

	sc_subcon_name.setValue(subcs.get(0).get("subcon_name"));
	sc_origid.setValue(subcs.get(0).get("origid").toString());
	sc_datecreated.setValue(subcs.get(0).get("datecreated").toString().substring(0,10));
	sc_username.setValue(subcs.get(0).get("username"));

	Listbox newlb = lbhand.makeVWListbox_Width(subcon_holder, subcon_headers, "subcon_lb", 8);
	//newlb.addEventListener("onSelect", new sharesamp_onSelect());
	ArrayList kabom = new ArrayList();
	String[] fl = {"folderno_str", "sampleid", "samplemarking", "test_request" };
	for(dpi : subcs)
	{
		ngfun.popuListitems_Data2(kabom,fl,dpi);
		/*
		kabom.add(dpi.get("folderno_str"));
		kabom.add(dpi.get("sampleid"));
		kabom.add(dpi.get("samplemarking"));
		kabom.add(dpi.get("test_request"));
		*/
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}

	subcon_popup.open(iwhat);
}

//----- internal lab-comments funcs, to replace the klunky job-notes
void showLabComments(String ifolder)
{
	Object[] lc_headers =
	{
		new listboxHeaderWidthObj("origid",false,""),
		new listboxHeaderWidthObj("Dated",true,"60px"),
		new listboxHeaderWidthObj("User",true,"70px"),
		new listboxHeaderWidthObj("Comments",true,""),
	};
	Listbox newlb = lbhand.makeVWListbox_Width(lc_holder, lc_headers, "labcomments_lb", 5);

	sqlstm = "select origid,datecreated,username,thecomment from elb_labcomments where folderno_str='" + ifolder + "' order by origid";
	lcrecs = sqlhand.gpSqlGetRows(sqlstm);
	if(lcrecs.size() == 0) return;
	newlb.setRows(10);
	ArrayList kabom = new ArrayList();
	for(dpi : lcrecs)
	{
		kabom.add(dpi.get("origid").toString());
		kabom.add(dpi.get("datecreated").toString().substring(0,10));
		kabom.add(dpi.get("username"));
		kabom.add(dpi.get("thecomment"));
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}
}

void labcommentFunc(Component iwhat)
{
	if(global_selected_folderno.equals("")) return;
	itype = iwhat.getId();
	todate = kiboo.todayISODateString();
	refresh = false;
	sqlstm = "";

	if(itype.equals("savelc_btn"))
	{
		tcomm = kiboo.replaceSingleQuotes(lc_entry.getValue());
		if(tcomm.equals("")) return;

		sqlstm = "insert into elb_labcomments (folderno_str,username,datecreated,thecomment) values " +
		"('" + global_selected_folderno + "','" + useraccessobj.username + "','" + todate + "','" + tcomm + "')";

		refresh = true;
	}

	if(itype.equals("clearlc_btn")) lc_entry.setValue("");

	if(!sqlstm.equals("")) sqlhand.gpSqlExecuter(sqlstm);
	if(refresh) showLabComments(global_selected_folderno);
}

//--- 13/01/2013: dig/show quotation, knockoff from registernew_samples_v4_6.zul
void digShowQuotation()
{
	Object[] qt_headers =
	{
		new listboxHeaderWidthObj("mysc",false,""),
		new listboxHeaderWidthObj("No.",true,"20px"),
		new listboxHeaderWidthObj("TI",true,"20px"),
		new listboxHeaderWidthObj("Test",true,"200px"),
		new listboxHeaderWidthObj("Method",true,"200px"),
		new listboxHeaderWidthObj("Price",true,"60px"),
	};
	qtnm = kiboo.replaceSingleQuotes(digquote_tb.getValue()).trim();
	if(qtnm.equals("")) return;

	// fill the quote metadata
	sqlstm = "select datecreated,username,salesperson,customer_name from elb_quotations where origid=" + qtnm + " and qstatus<>'NEW'";
	qrec = sqlhand.gpSqlFirstRow(sqlstm);
	if(qrec == null) return;
	qt_num.setValue("QT" + qtnm);
	qt_username.setValue(qrec.get("username"));
	qt_sales.setValue(qrec.get("salesperson"));
	qt_customer_name.setValue(qrec.get("customer_name"));
	qt_datecreated.setValue(qrec.get("datecreated").toString().substring(0,10));

	Listbox newlb = lbhand.makeVWListbox_Width(quoteitems_holder, qt_headers, "quoteitems_lb", 5);

	sqlstm = "select mysoftcode,description,description2,unitprice,curcode from elb_quotation_items where quote_parent=" + qtnm + " order by origid";
	qtrecs = sqlhand.gpSqlGetRows(sqlstm);
	if(qtrecs.size() == 0) return;
	newlb.setRows(10);
	lncn = 1;
	DecimalFormat nf = new DecimalFormat("##.00");

	tusername = useraccessobj.username;
	qtuser = qrec.get("username");
	showprice = false;
	if(tusername.equals(qtuser)) showprice = true;
	if(useraccessobj.accesslevel >= 9) showprice = true;
	ArrayList kabom = new ArrayList();
	for(dpi : qtrecs)
	{
		kabom.add(dpi.get("mysoftcode").toString());
		kabom.add(lncn.toString() + ".");
		mysc = dpi.get("mysoftcode");
		mysc = (mysc.equals("0")) ? "N" : "Y";
		kabom.add(mysc);
		kabom.add(dpi.get("description"));
		kabom.add(dpi.get("description2"));
		kabom.add((showprice) ? (dpi.get("curcode") + " " + nf.format(dpi.get("unitprice"))) : "---");
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
		lncn++;
	}
	quotation_workarea.setVisible(true);
}

// 23/05/2013: view samples-pickup by folder
void viewSamplesPickup()
{
	Object[] spc_headers =
	{
		new listboxHeaderWidthObj("SampleID",true,""),
		new listboxHeaderWidthObj("Receiv",true,"50px"),
		new listboxHeaderWidthObj("Pickups",true,"50px"),
	};

	sqlstm = "select lps.sampleid_str, count(lps.sampleid_str) as pickc, js.bottles from elb_labpickedsamples lps " +
	"left join jobsamples js on js.sampleid_str = lps.sampleid_str " +
	"where lps.sampleid_str like '____" + global_selected_origid + "______' " + 
	"group by lps.sampleid_str, js.bottles";

	sprs = sqlhand.gpSqlGetRows(sqlstm);

	if(sprs.size() == 0) return;
	Listbox newlb = lbhand.makeVWListbox_Width(sampickup_holder, spc_headers, "picksamples_lb", 10);
	ArrayList kabom = new ArrayList();
	for(dpi : sprs)
	{
		kabom.add(dpi.get("sampleid_str"));
		kabom.add((dpi.get("bottles") == null) ? "0" : dpi.get("bottles").toString());
		kabom.add(dpi.get("pickc").toString());
		lbhand.insertListItems(newlb,kiboo.convertArrayListToStringArray(kabom),"false","");
		kabom.clear();
	}

	sqlstm = "select top 1 lps.origid,lps.username,lps.pickupperson,lps.datecreated,lps.ptimestamp " +
	"from elb_labpickupsamples lps left join elb_labpickedsamples lds on lds.parent_id = lps.origid " +
	"where lds.sampleid_str like '____" + global_selected_origid + "______'";

	puks = sqlhand.gpSqlFirstRow(sqlstm);

	if(puks != null)
	{
		s_pickorigid.setValue(puks.get("origid").toString());
		s_timestmp.setValue(puks.get("datecreated").toString().substring(0,10) + " " + puks.get("ptimestamp").toString().substring(11,19));
		s_username.setValue(puks.get("username"));
		s_pickupperson.setValue(puks.get("pickupperson"));
	}
	samplepick_popup.open(picksamp_butt);
}

glob_persampleshare_selected = "";

class persampleshr_onclick implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitem = event.getReference();
		glob_persampleshare_selected = lbhand.getListcellItemLabel(selitem,0);
	}
}

