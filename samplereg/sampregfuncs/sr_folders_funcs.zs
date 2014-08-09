// Sample registration module - folders handling funcs

void clearFolderMetadata()
{
	// reset all global-vars
	global_selected_sampleid = global_selected_folder = global_selected_folderstr = "";
	global_selected_arcode = global_folder_status = "";

	Object[] jkl = { folderno, ar_code, extranotes, customer_po, customer_coc, boxescount, box_temperature,
		attention, retest_username, retest_parent, retest_reason, subcontractor_tb, subcon_notes,

		date_created, clientreq_duedate, subcon_sendout,

		modeofdelivery, securityseal, tat_dd, priority_dd, share_sample, retest_sample, track_flag, jobhold_status,

		allgoodorder, paperworknot, paperworksamplesnot, samplesdamaged, pkd_samples, prepaid_tick, subcon_flag,
	};
	clearUI_Field(jkl);

	customername.setValue("Customer information");
	if(samples_div.getFellowIfAny("samples_lb") != null) samples_lb.setParent(null); // clear samples_lb too

	workarea.setVisible(false);
}

void showFolderMetadata(String ifoldernum)
{
	origid = samphand.extractFolderNo(ifoldernum);
	tr = samphand.getFolderJobRec(origid);
	if(tr == null) return;
	
	//alert(ifoldernum + " :: " + origid + " :: " + therec);

	global_selected_origid = tr.get("origid").toString();

	//folderno.setValue(tr.get("folderno_str"));
	folderno.setValue(global_selected_folderstr);

	credate = tr.get("datecreated");
	dudate = tr.get("duedate");

	//global_selected_arcode = tr.get("ar_code");
	ar_code.setValue(global_selected_arcode);
	global_folder_status = tr.get("folderstatus"); // save selected folderstatus to glob

	// 25/11/2010: clear cash-acct inputboxes
	cashacct_gb.setVisible(false);
	clearCashAccountInputs();

	if(!global_selected_arcode.equals(""))
	{
		icompname = sqlhand.getCompanyName(global_selected_arcode);
		customername.setValue(ifoldernum + " : " + icompname);
		if(global_selected_arcode.equals("CASH") || global_selected_arcode.equals("300S-550")) // || global_selected_arcode.equals("CASH USD"))
		{
			cashacct_gb.setVisible(true);
			populateCashAccountPopup(tr.get("folderno_str"));
		}
		// already assigned folder to ar_code, supposed not to change - but then.. 26/1/2010
		// maybe check for uploadToLIMS and uploadToMYSOFT flag, if set, cannot change anymore
		//fj_ar_code.setDisabled(true);
	}

	// 10/2/2010: if create-date is same as due-date, always when a new folder is created, due some TAT calc
	if(dudate.equals(credate))
	{
		//woptat = Integer.parseInt(tr.get("tat"));
		try
		{
			kiboo.addDaysToDate(date_created,due_date,tr.get("tat"));
			kiboo.weekEndCheck(due_date);
		} catch (Exception e) {}
	}

	Object[] jkl = { date_created, extranotes, clientreq_duedate, customer_po, customer_coc, modeofdelivery,
		securityseal, tat_dd, due_date, prepaid_tick, boxescount, box_temperature, allgoodorder,
		paperworknot, paperworksamplesnot, samplesdamaged, attention, priority_dd, pkd_samples,
		share_sample, track_flag, jobhold_status };

	String[] fl = { "datecreated", "extranotes", "custreqdate", "customerpo", "customercoc", "deliverymode",
		"securityseal", "tat", "duedate", "prepaid", "noboxes", "temperature", "allgoodorder",
		"paperworknot", "paperworksamplesnot", "samplesdamaged", "attention", "priority", "pkd_samples",
		"share_sample", "track_flag", "jobhold_status" };

	populateUI_Data(jkl, fl, tr);

	// 27/1/2010: if folderstatus is LOGGED, don't allow changes to the customer-code
	global_selected_folder = origid; // save global for later
	global_folder_status = tr.get("folderstatus");

	// 2/2/2010: disable some of the groupbox if folderstatus is LOGGED or COMMITED
	toggflag = false;
	if(global_folder_status.equals(FOLDERLOGGED) || global_folder_status.equals(FOLDERCOMMITED)) toggflag = true;
	toggleFolderInformationGroupbox(toggflag);

	startFolderSamplesSearch(global_selected_folder);

	showDocumentsList(ifoldernum);
	showRetestFields(tr);
	showSubconFields(tr); // 11/08/2011
	showStorageTraysDisposal(tr);

	workarea.setVisible(true);

	// 11/09/2012: save customer-category to be used by other funcs
	cmpr = sqlhand.getCompanyRecord(global_selected_arcode);
	global_customer_category = (cmpr == null) ? "" : kiboo.checkNullString(cmpr.get("Category"));
}

void saveFolderMetadata()
{
	if(global_selected_folder.equals("")) return;

	Object[] jkl = { ar_code, date_created, extranotes, modeofdelivery, securityseal, boxescount,
		box_temperature, clientreq_duedate, customer_po, customer_coc, tat_dd, due_date, allgoodorder, paperworknot,
		paperworksamplesnot, samplesdamaged, priority_dd, attention, pkd_samples, share_sample,
		prepaid_tick, subcon_flag, subcontractor_tb, subcon_sendout, subcon_notes, track_flag,
		jobhold_status };

	dt = getString_fromUI(jkl);
	dt[11] = kiboo.getDateFromDatebox(due_date);

	// 25/07/2012: add some codes for working-days calc and TODO holidays maybe
	cbizday = kiboo.calcBusinessDays(date_created,Integer.parseInt(dt[10]));
	kiboo.addDaysToDate(date_created,due_date,cbizday);

	// 29/3/2010: to update branch field according to username branch setting.
	ibranch = useraccessobj.branch;
	// if no branch setup or branch="ALL" <-- admin login, set branch "SA"
	if(ibranch.equals("") || ibranch.equals("ALL")) ibranch = "SA";

	// 13/01/2013: createdby - save who owns the folder
	// 13/05/2013: track_flag - to track folder -- hahahaha
	// 13/05/2013: jobhold_status - hold,reject,proceed

	sqlstatem = "update JobFolders set ar_code='" + dt[0] + "', " +
	"datecreated='" + dt[1] + "', extranotes='" + dt[2] + "', " +
	"folderno_str='" + global_selected_folderstr + "', " +
	"deliverymode='" + dt[3] + "', securityseal='" + dt[4] + "', " +
	"noboxes='" + dt[5] + "', temperature='" + dt[6] + "', " +
	"custreqdate='" + dt[7] + "', customerpo='" + dt[8] + "', " +
	"customercoc='" + dt[9] + "', folderstatus='" + global_folder_status + "', " +
	"tat=" + dt[10] + ", duedate='" + dt[11] + "', " +
	"allgoodorder=" + dt[12] + ", paperworknot=" + dt[13] + ", " +
	"paperworksamplesnot=" + dt[14] + ", samplesdamaged=" + dt[15] + ", " +
	"priority='" + dt[16] + "', attention='" + dt[17] + "', " +
	"branch='" + ibranch + "', pkd_samples=" + dt[18] + ", " +
	"share_sample='" + dt[19] + "', prepaid=" + dt[20] + ", " +
	"subcon_flag=" + dt[21] + ", subcontractor='" + dt[22] + "', " + 
	"subcon_sendout='" + dt[23] + "',subcon_notes='" + dt[24] + "', " +
	"createdby='" + useraccessobj.username + "', " +
	"track_flag='" + dt[25] + "', jobhold_status='" + dt[26] + "' " +
	" where origid=" + global_selected_folder;

	sqlhand.gpSqlExecuter(sqlstatem);

	if(dt[0].equals("CASH") || dt[0].equals("CASH USD") || dt[0].equals("300S-550")) saveCashAccountDetails();
	cashacct_gb.setVisible(false); // still hide the cash-acct details groupbox.. incase it was set to cash-acct earlier
}

void createNewFolder_Wrapper(Datebox ihiddendatebox)
{
	kkk = useraccessobj.branch; // 29/3/2010: add in branch
	// 16/4/2010: if user has "ALL" for branch, disallow adding new folder
	if(kkk.equals("ALL"))
	{
		guihand.showMessageBox("Superuser cannot add folder.. please use a normal branch user");
		return;
	}

	// 01/04/2013: req by Saj, limit to max 10 draft folders in listbox, user must login folders, else don't create
	startFolderJobsSearch(startdate,enddate);
	chkdrf = folderjobs_lb.getItemCount();
	if(chkdrf >= 30)
	{
		guihand.showMessageBox("OII!!! Max 30 DRAFT folders. Log them in before creating new ones");
		return;
	}
	samphand.createNewFolderJob(ihiddendatebox,kkk,useraccessobj.username); // samplereg_funcs.zs
	startFolderJobsSearch(startdate,enddate); // refresh again
}

void deleteFolderJob()
{
	// instead of deleting straight from the database, set the deleted flag instead
	if(global_selected_folder.equals("")) return;

	// 27/1/2010: if folderstatus is logged, cannot delete
	//therec = samphand.getFolderJobRec(whathuh.getOrigid().toString());

	if(!global_folder_status.equals(FOLDERDRAFT))
	{
		guihand.showMessageBox(global_selected_folderstr + " is " + global_folder_status + " . Cannot delete");
		return;
	}

	if (Messagebox.show("Delete folder/job " + global_selected_folderstr, "Are you sure?",
		Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) == Messagebox.YES)
	{
		sqlstatem = "update JobFolders set deleted=1 where origid=" + global_selected_folder;
		sqlhand.gpSqlExecuter(sqlstatem);
		startFolderJobsSearch(startdate,enddate); // refresh
	}

} // end of deleteFolderJob()

// 11/6/2010: really save the folder information - this is after checking for cash-account and etc
void reallySaveFolderInfo()
{
	saveFolderMetadata();
	clearFolderMetadata();
	folderjobs_lb.clearSelection();
	startFolderJobsSearch(startdate,enddate);
}

// Save folder metadata
// 11/6/2010: would add checks for CASH ACCOUNT - need to enter cash client's info properly instead of using the Comment field.
// 15/9/2010: check customer status - if black-listed, don't save..
// 25/11/2010: new code-base without object
void updateFolderJob()
{
	if(global_selected_folder.equals("")) return;
	// 2/2/2010: make sure folder is in DRAFT
	if(!foldersamplesCRUD_Check()) return;

	arcode = ar_code.getValue().trim().toUpperCase();
	comprec = sqlhand.getCompanyRecord(arcode);
	if(comprec == null)
	{
		guihand.showMessageBox("Invalid customer code..");
		return; 
	}

	// 15/9/2010: check for black-listed
	credit_period = comprec.get("credit_period");
	if(credit_period != null)
	{
		if(credit_period.equals("BLACKLIST"))
		{
			ar_code.setValue(""); // clear the ar_code field - prevent registering new samples
			guihand.showMessageBox("Customer is BLACK-LISTED - cannot register samples - please contact Credit-Control");
			blacklisted_EmailNotification(comprec);
			return;
		}
	}

	// check if ar_code = CASH (hardcoded as def in mysoft)
	//if(global_selected_arcode.equals("CASH") || global_selected_arcode.equals("CASH USD")) saveCashAccountDetails(); // save cash-acct details too
	reallySaveFolderInfo();	// actually saving the folder details
}


// Change folder/job status to logged. once logged, only higher level user will be able to change the data
// 25/11/2010: added checks to see if any COC uploaded, if not.. cannot login folder
// 23/03/2011: samp-recv notification for food-division people
// 07/10/2011: save logged-in date
// 09/04/2013: save time too!!
void logFolderJob()
{
	if(global_selected_folder.equals("")) return;
	if(global_folder_status.equals(FOLDERLOGGED) || global_folder_status.equals(FOLDERCOMMITED)) return;

	// 25/11/2010: check if COC uploaded
	if(!checkDocumentExist(global_selected_folderstr))
	{
		guihand.showMessageBox("[ERROR] Cannot log-in folder without any documents. Scan and upload COC to continue");
		return;
	}

	if (Messagebox.show("Log-in job/folder " + global_selected_folderstr + 
		". Once log-in, only HOD and senior supervisor will be able to amend info." , "Are you sure?", 
		Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) ==  Messagebox.YES)
	{
		global_folder_status = FOLDERLOGGED;

		// 12/08/2010: added email notification if CASH/CASH USD being used
		// 27/02/2012: put in chk for syabas-cash-customer as well 300S-550
		if(global_selected_arcode.equals("CASH") || global_selected_arcode.equals("CASH USD") || global_selected_arcode.equals("300S-550"))
		{
			saveCashAccountDetails();
			cashAccount_EmailNotification(global_selected_folderstr);
		}

		// ** 26/2/2011: Doc Chin instruction to stop auto-email SRN until further notice
		// sendSRN_email(global_selected_folder); // 22/02/2011
		internalSRN(global_selected_folder, global_selected_arcode);

		// save logged-in date
		todate = kiboo.todayISODateTimeString();
		sqlstm = "update jobfolders set logindate='" + todate + "' where origid=" + global_selected_folder;
		sqlhand.gpSqlExecuter(sqlstm);

		reallySaveFolderInfo(); // this will clear folder metadata once saved..
	}
}
