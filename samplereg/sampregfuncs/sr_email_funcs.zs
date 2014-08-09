import org.victor.*;
// Sample registration emailing funcs

// Internal SRN - doing it for food-division people for now
// 26/09/2012: add stuff for sending notif by lookup-table
void internalSRN(String ifoldernumber,String tarcode)
{
	if(ifoldernumber.equals("")) return;
	comprec = sqlhand.getCompanyRecord(tarcode);
	if(comprec == null) return;
	salesmancode = comprec.get("Salesman_code");
	compname = comprec.get("customer_name");

	if(salesmancode != null)
		salesmancode = salesmancode.trim();
	else
		salesmancode = "";

	subjstr = "SAMPLE RECEIVED NOTIFICATION";
	
	msgtext = "FOLDER#: " + global_selected_folderstr;
	msgtext += "\nCompany: " + compname;
	msgtext += "\n\nSample(s) were received from customer serviced by " + salesmancode;
	msgtext += "\nYou can contact these sales-person or lab-manager for clarification on ambiguous COC or samples";
	msgtext += "\n\nChong Chin Chin : 012 698 7369";
	msgtext += "\nBen : 012 698 7356";
	msgtext += "\nAsliza : 012 698 7071";
	msgtext += "\nDr Koh : 012 698 7256";
	msgtext += "\n\nPLEASE TAKE ANY NECESSARY ACTION ASAP";
	msgtext += "\n\n------\nDO NOT print this notification - save some A4 paper";

	// 23/03/2011: HARDCODED for food-division salesman

	if(salesmancode.equals("CHONG") || salesmancode.equals("ASLIZA") || salesmancode.equals("BEN"))
	{
	// 25/03/2011: send only top 40 food clients samples-received to foodpharma@alsglobal.com.my
	/*if(existInStringArray(top40foodclients,tarcode))
	{
	*/
		//topeople = kiboo.convertStringArrayToString(food_division_people);
		//topeople = "it@alsglobal.com.my";
		topeople = luhand.getLookups_ConvertToStr("SAMPREG_fooddv",2,",");
		simpleSendEmail(SMTP_SERVER,"elabman@alsglobal.com.my",topeople,subjstr,msgtext);
	}

	// 26/09/2011: send email to asliza and zainab on VEOLIA WATER SERVICES MALAYSIA SDN BHD(300V/045) samples
	if(tarcode.equals("300V/045"))
	{
		msgtext  = "FOLDER#: " + global_selected_folderstr;
		msgtext += "\nCompany: " + compname;
		msgtext += "\n\nSample(s) received from company mentioned above. Please contact the client to prepare PO and you prepare the quotation.";
		msgtext += "\n\n(THIS IS AUTOMATED NOTIFICATION)";
		simpleSendEmail(SMTP_SERVER,"elabman@alsglobal.com.my","liza@alsglobal.com.my,zainab@alsglobal.com.my",subjstr,msgtext);
	}

	// 26/09/2012: req by Foong, certain customer's samples reg - notify by email. Based on lookups - easier management
	metcts = luhand.getLookups_ByParent("METAL_NOTI_CUSTOMERS");
	topeople = luhand.getLookups_ConvertToStr("METAL_NOTI_EMAIL",2,",");
	for(dpi : metcts)
	{
		notiarcd = dpi.get("disptext");
		if(notiarcd.equals(tarcode)) // if registration ar_code = lookup ar_code, send email
		{
			simpleSendEmail(SMTP_SERVER,"elabman@alsglobal.com.my",topeople,subjstr,msgtext);
		}
	}
}

// 19/2/2011: auto-email SRN to client
void sendSRN_email(String ifoldernumber)
{
	/*
	if(!lbhand.check_ListboxExist_SelectItem(folders_searchdiv,"folderjobs_lb")) return;
	jfold = folderjobs_lb.getSelectedItem().getLabel();
	*/
	if(ifoldernumber.equals("")) return;

	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;

	// get emails from customer_emails per ar_code
	sqlstm = "select customer_emails.contact_email from customer_emails " +
	"left join jobfolders on customer_emails.ar_code=jobfolders.ar_code " +
	"where jobfolders.origid=" + ifoldernumber;
	// "and customer_emails.send_srn=1"
	temails = sql.rows(sqlstm);

   	sqlstm = "select count(origid) as samplecount from " + JOBSAMPLES_TABLE + " where deleted=0 and jobfolders_id=" + ifoldernumber;
   	nsrec = sql.firstRow(sqlstm);
   	numsamples = 0;
   	if(nsrec != null) numsamples = nsrec.get("samplecount");

   	sqlstm = "select folderno_str from jobfolders where origid=" + ifoldernumber;
   	fst = sql.firstRow(sqlstm);
   	foldernostr = "--UNDEFINED--";
   	if(fst != null) foldernostr = fst.get("folderno_str");

	sql.close();

	if(temails.size() == 0) return;

	to_string = "";
	for(dpi : temails)
	{
		kkb = dpi.get("contact_email");
		if(!kkb.equals("")) to_string += kkb + ",";
	}

	to_string = to_string.substring(0,to_string.length()-1);
	subj = "[NOTIFICATION] SAMPLE(S) RECEIVED : " + foldernostr;
	emailbody = 
	"Lab identification number: " + foldernostr + "\n\n" +
	"We have recently received " + numsamples.toString() + " sample(s) from your company.\n" +
	"Your sample(s) are being processed at the moment.\n\n" +
	"If you required any assistance, please contact the account manager assigned to you. Please quote " + foldernostr + " during enquiry.\n\n" +
	"**THIS NOTIFICATION IS AUTO-GENERATED**";

	simpleSendEmail(SMTP_SERVER,"info@alsglobal.com.my", to_string, subj, emailbody);
	//simpleSendEmail(SMTP_SERVER,"info@alsglobal.com.my", "it@alsglobal.com.my", subj, emailbody);

	alert("srn email sent");
}

// 15/9/2010: send notification email to everyone if recv samples from black-listed customer
void blacklisted_EmailNotification(Object icomprec)
{
	subjstr = "SAMPLE REGISTRATION NOTIFICATION: RECEIVED SAMPLES FROM BLACK-LISTED CUSTOMER";
	//topeople = kiboo.convertStringArrayToString(blacklisted_notification);
	topeople = luhand.getLookups_ConvertToStr("BLACKLISTED_NOTI",2,",");

	thecustomer = icomprec.get("customer_name");
	tel = icomprec.get("telephone_no");
	contact_person1 = icomprec.get("contact_person1");

	salesman = icomprec.get("Salesman_code");
	salesman = (salesman == null) ? "--UNDEFINED SALES PERSON--" : salesman;
	salesman = (salesman.equals("0")) ? "--UNDEFINED SALES PERSON--" : salesman;

	msgtext = "Customer: " + thecustomer + "\n";
	msgtext += "Contact person: " + contact_person1 + "\n";
	msgtext += "Telephone: " + tel + "\n";
	msgtext += "Customer belongs to: " + salesman + "\n\n";
	msgtext += "Samples are being held in sample-registration room.\n";
	msgtext += "PLEASE TAKE NECESSARY ACTION ASAP";
	msgtext += "\n\n------\nDO NOT print this notification - save some trees";

	simpleSendEmail(SMTP_SERVER,ELABMAN_EMAIL,topeople,subjstr,msgtext);
	//guihand.showMessageBox("BLACK-LISTED email notification sent..");
}

// 12/08/2010: send an email to whoever needed notification on CASH or CASH USD used to register sample
// 27/02/2012: send noti-email according to share-sample type
// cashacct_email_notification
void cashAccount_EmailNotification(String ifoldnum)
{
	csrec = samphand.getCashSalesCustomerInfo_Rec(ifoldnum);
	if(csrec == null) return;

	subjstr = "SAMPLE REGISTRATION NOTIFICATION: NEW/CASH CUSTOMER : " + csrec.get("folderno_str");
	//topeople = kiboo.convertStringArrayToString(cashacct_email_notification);

	// 27/02/2012
	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	sqlstm = "select share_sample from jobfolders where origid=" + global_selected_folder;
	jfrec = sql.firstRow(sqlstm);
	sql.close();
	
	headpep = luhand.getLookups_ConvertToStr("SAMPREG_getAllEmails",2,",");
	//headpep = kiboo.convertStringArrayToString(getAllEmails);
	shdsamp = (jfrec.get("share_sample") != null) ? jfrec.get("share_sample") : "";
	
	if(!shdsamp.equals(""))
	{
		// check for ev only
		evchkstr = "CHEMICAL_EH EV EV_MICRO ORGANIC ORGANIC_EV ORGANIC_MICRO EV_MB_ORGAN EV_FOOD_MB OF_MB_EV_OR EV_FOOD";
		if(evchkstr.indexOf(jfrec.get("share_sample")) != -1) // found share_sample string somewhere
		{
			//hstr = kiboo.convertStringArrayToString(evDivisionEmails);
			hstr = luhand.getLookups_ConvertToStr("SAMPREG_evDivisionEmails",2,",");
			headpep += "," + hstr;
		}
		
		// check for tribo only
		if(jfrec.get("share_sample").equals("WEARCHECK"))
		{
			//hstr = kiboo.convertStringArrayToString(triboDivisionEmails);
			hstr = luhand.getLookups_ConvertToStr("SAMPREG_triboDivisionEmails",2,",");
			headpep += "," + hstr;
		}
	}

	msgtext = "FOLDER#: " + csrec.get("folderno_str") + "\n";
	msgtext += "Sample type : " + shdsamp + "\n\n";
	msgtext += "A new customer's samples have been received. Customer info:\n\n";
	msgtext += csrec.get("customer_name") + "\n";
	msgtext += csrec.get("address1") + "\n";
	msgtext += csrec.get("address2") + "\n";
	msgtext += csrec.get("zipcode") + " " + csrec.get("city") + ", " + csrec.get("state") + "\n";
	msgtext += csrec.get("country") + "\n";
	msgtext += "Tel: " + csrec.get("telephone") + "  Fax:" + csrec.get("fax")  + "\n";
	msgtext += "Contact person: " + csrec.get("contact_person1") + "\n";
	msgtext += "Customer Company-registration no.: \n";
	msgtext += "Email: " + csrec.get("email") + "\n\n";
	msgtext += "PLEASE TAKE NECESSARY ACTION ASAP";
	msgtext += "\n\n------\nDO NOT print this notification - save some trees";

	simpleSendEmail(SMTP_SERVER,ELABMAN_EMAIL,headpep,subjstr,msgtext);
	guihand.showMessageBox("CASH account email notification sent..");

} // end of cashAccount_EmailNotification(ifolds);

String[] retest_notification = { "ymkoh@alsglobal.com.my", "food@alsglobal.com.my", "foodpharma@alsglobal.com.my" };

// 23/03/2011: Internal re-test email notification
void retestEmailNotification(String ifoldernumber,String tarcode, String retestreason, String retestrequester)
{
	if(ifoldernumber.equals("")) return;
	comprec = sqlhand.getCompanyRecord(tarcode);
	if(comprec == null) return;
	compname = comprec.get("customer_name").trim();
	salesman = comprec.get("Salesman_code");

	subjstr = "RE-TEST NOTIFICATION";
	topeople = kiboo.convertStringArrayToString(retest_notification);
	//topeople = "it@alsglobal.com.my";

	msgtext = "FOLDER#: " + ifoldernumber;
	msgtext += "\nCompany: " + compname;
	msgtext += "\nSalesman: " + salesman;
	msgtext += "\nRequested by: " + retestrequester;
	msgtext += "\nReason: " + retestreason;
	msgtext += "\n\nThis is a re-test notification. Please do whatever necessary to justify this re-test.";
	msgtext += "\n\n------\nDO NOT print this notification - save some A4 paper";

	simpleSendEmail(SMTP_SERVER,"info@alsglobal.com.my",topeople,subjstr,msgtext);
}
