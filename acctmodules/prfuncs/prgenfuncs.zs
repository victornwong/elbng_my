// Purchase-req general funcs put here
// Written by Victor Wong 16/08/2014

Object getPR_Rec(String iorigid)
{
	sqlstm = "select * from purchaserequisition where origid=" + iorigid;
	retv = sqlhand.gpSqlFirstRow(sqlstm);
	return retv;
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
