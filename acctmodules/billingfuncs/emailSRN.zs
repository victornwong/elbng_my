// Email SRN to customer -- can be used for other mods, need to check

// List out email addresses def in customer_emails
void showEmailsbyCustomer()
{
	Object[] custemails_lb_headers = {
	new dblb_HeaderObj("origid",false,"origid",2),
	new dblb_HeaderObj("Name",true,"contact_name",1),
	new dblb_HeaderObj("E-Mail",true,"contact_email",1),
	};

	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	sqlstm = "select origid,contact_name,contact_email from customer_emails where ar_code='" + selected_arcode + "' order by contact_name";
	Listbox newlb = lbhand.makeVWListbox_onDB(emails_holder,custemails_lb_headers,"custemails_lb",10,sql,sqlstm);
	newlb.setMultiple(true);
	sql.close();
}

// knockoff from send_email_coa.zul .. if update there, do here too
// The real-thing, send out selected documents to client via email
// 09/03/2011: added email type - 1=SRN , 2=normal
void sendOutCOA_clicker(int itype)
{
	if(!lbhand.check_ListboxExist_SelectItem(emails_holder,"custemails_lb")) return;
	if(!lbhand.check_ListboxExist_SelectItem(doculist_holder,"doculinks_lb")) return;

	dialogmsg = "Send document(s) to client..";
	if(itype == 1) dialogmsg = "Really send SRN + document(s) to client..";

	if (Messagebox.show(dialogmsg, "Are you sure?", 
		Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) ==  Messagebox.NO) return;

	seldocs = doculinks_lb.getSelectedItems();
	emails = custemails_lb.getSelectedItems();

	ds_sql = sqlhand.als_DocumentStorage();
	if(ds_sql == null) { guihand.showMessageBox("Cannot connect to document server.."); return; }

	receivers = "";
	String[] recv_names = new String[emails.size()];
	String[] recv_emails = new String[emails.size()];
	cctt = 0;

	// get the list of email addresses selected
	for(dpi : emails)
	{
		receivers += lbhand.getListcellItemLabel(dpi,2) + ",";
		recv_names[cctt] = lbhand.getListcellItemLabel(dpi,1);
		recv_emails[cctt] = lbhand.getListcellItemLabel(dpi,2);
		cctt++;
	}

	String[] tmpfnames = new String[seldocs.size()];
	String[] dorigid = new String[seldocs.size()];
	fnamecount = 0;

	// make tmp-file out of documents
	for(dpi : seldocs)
	{
		dorigid[fnamecount] = lbhand.getListcellItemLabel(dpi,0); // get document origid
		sqlstm = "select file_name,file_data from DocumentTable where origid=" + dorigid[fnamecount];
		docrec = ds_sql.firstRow(sqlstm);

		if(docrec != null)
		{
			kfilename = docrec.get("file_name");
			kblob = docrec.get("file_data");
			kbarray = kblob.getBytes(1,(int)kblob.length());
			tmpfnames[fnamecount] = session.getWebApp().getRealPath("tmp/" + kfilename);
			outstream = new FileOutputStream(tmpfnames[fnamecount]);
			outstream.write(kbarray);
			outstream.close();
			fnamecount++;
		}
	}
	ds_sql.close();

	// 09/03/2011: default compose the email with attachments
	subjstr = "[E-DOCUMENT] " + selected_folderno;
	msgtxt =  "Job/Folder No.: " + selected_folderno + "\n";
	msgtxt += "This email contains the electronic version of the requested document(s).\n\n";
	msgtxt += "Please contact our customer service or sales person if you have any enquiries.\n\n";
	msgtxt += "ALS | Malaysia - Indonesia\n9 Jalan Astaka U8/84, Bukit Jelutong\n40150 Shah Alam, Selangor\n\n";
	msgtxt += "PHONE +60 3 7845 8257\nFAX +60 3 7845 8258\nEMAIL info@alsglobal.com.my\n";
	msgtxt += "WEB http://www.alsglobal.com\n\n-Please consider the environment before printing this email-";

	sql = sqlhand.als_mysoftsql();
    if(sql == null) return;
    
    if(itype == 1)
    {
    ifoldernumber = samphand.extractFolderNo(selected_folderno);

	sqlstm = "select count(origid) as samplecount from " + JOBSAMPLES_TABLE + " where deleted=0 and jobfolders_id=" + ifoldernumber;
   	nsrec = sql.firstRow(sqlstm);
   	numsamples = 0;
   	if(nsrec != null) numsamples = nsrec.get("samplecount");
	
	subjstr = "[NOTIFICATION] SAMPLE(S) RECEIVED : " + selected_folderno;
	msgtxt = 
    "Lab identification number: " + selected_folderno + "\n\n" +
    "We have recently received " + numsamples.toString() + " sample(s) from your company.\n" +
    "Your sample(s) are being processed at the moment.\n\n" +
    "If you required any assistance, please contact the account manager assigned to you. Please quote " + selected_folderno + " during enquiry.\n\n" +
    "**THIS NOTIFICATION IS AUTO-GENERATED**";
    }

	sendEmailWithAttachment(SMTP_SERVER,"info@alsglobal.com.my",receivers,subjstr,msgtxt,tmpfnames);

	// delete temporary files before cabut
	for(i=0;i<tmpfnames.length;i++)
	{
		File f = new File(tmpfnames[i]);
		if(f.exists()) f.delete();
	}

	todaysdate = kiboo.getDateFromDatebox(hiddendatebox);

	// update tables on stuff sent out

	for(i=0;i <dorigid.length; i++)
	{
		for(j=0; j<recv_names.length; j++)
		{
			sqlstm = "insert into stuff_emailed (linking_code,docutype,docu_link,datesent,contact_name,contact_email,username,subject) values " +
			"('" + selected_folderno + "','DOCUMENTS'," + dorigid[i] + ",'" + todaysdate + "','" + 
			recv_names[j] + "','" + recv_emails[j] + "','" + useraccessobj.username + "','" + subjstr + "')";

			sql.execute(sqlstm);
		}
	}
	sql.close();

	// put a bit of audit-trail later

	dialogmsg = "Document(s) sent..";
	if(itype == 1) dialogmsg = "SRN + Document(s) sent..";
	guihand.showMessageBox(dialogmsg);

	//populateDocumentLinks(String ieqid, String iprefix)
	//showDocumentsList(selected_folderno); // refresh
}

void sendDocViaEmail_clicker()
{
	if(!lbhand.check_ListboxExist_SelectItem(doculist_holder,"doculinks_lb")) return;
	showEmailsbyCustomer();
	senddocemail.open(sendemail_doc_btn);
}

// Uses pop-up to show what's been sent related by folder-number
void viewSentHistory_clicker()
{
Object[] senthistorylb_headers = {
	new listboxHeaderObj("Sent",true),
	new listboxHeaderObj("User",true),
	new listboxHeaderObj("To",true),
	new listboxHeaderObj("Title",true),
	new listboxHeaderObj("Filename",true),
	};

	if(selected_folderno.equals("")) return;

	sql = sqlhand.als_mysoftsql();
	if(sql == null ) return;

	sqlstm = "select docu_link,subject,datesent,contact_email,username " + 
	"from stuff_emailed where linking_code='" + selected_folderno + "' order by datesent desc";

	sentrecs = sql.rows(sqlstm);
	sql.close();

	// senthistory_holder - at popup
	Listbox newlb = lbhand.makeVWListbox(senthistory_holder,senthistorylb_headers,"senthistory_lb", 5);

	if(sentrecs.size() == 0) return;
	newlb.setRows(10);
	
	ds_sql = sqlhand.als_DocumentStorage();
	if(ds_sql == null) return;

	for(dpi : sentrecs)
	{
		ArrayList kabom = new ArrayList();
		kabom.add(dpi.get("datesent").toString().substring(0,10));
		kabom.add(dpi.get("username"));
		kabom.add(dpi.get("contact_email"));

		doculink = dpi.get("docu_link");
		
		filetitle = "---";
		filename = "---";

		dcsqlstm = "select file_title,file_name from documenttable where origid=" + doculink;
		drec = ds_sql.firstRow(dcsqlstm);
		if(drec != null)
		{
			filetitle = drec.get("file_title");
			filename = drec.get("file_name");
		}

		kabom.add(filetitle);
		kabom.add(filename);

		strarray = kiboo.convertArrayListToStringArray(kabom);
		lbhand.insertListItems(newlb,strarray,"false","");
	}
	
	ds_sql.close();

	senthistory_popup.open(senthistory_btn);
}

