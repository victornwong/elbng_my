import org.victor.*;
// General purpose funcs for sample registration

// Use to disable all folder information groupbox 's form components
// uses var whathuh and whathuh_samples to access the components
// 19/11/2010: combine disable/enable function into 1 func..
void toggleFolderInformationGroupbox(boolean iwhat)
{
	Object[] jkl = { 	date_created, extranotes, tat_dd, customer_po, customer_coc, clientreq_duedate,
	modeofdelivery, securityseal, boxescount, box_temperature, allgoodorder, paperworknot,
	paperworksamplesnot, samplesdamaged, attention, pkd_samples, share_sample, prepaid_tick,
	subcon_flag, subcontractor_tb, subcon_sendout, subcon_notes, samplemarking, sample_extranotes };

	disableUI_obj(jkl, iwhat);
}

// 23/03/2011: show re-test fields
void showRetestFields(Object fRecord)
{
	Object[] jkl = { retestdate, retest_parent, retest_reason, retest_sample };
	String[] fl = { "retest_date", "retest_parent", "retest_reason", "retest_sample" };
	populateUI_Data(jkl, fl, fRecord);
	rtusername = fRecord.get("retest_username");
	if(rtusername == null) rtusername = useraccessobj.username;
	retest_username.setValue(rtusername);
}

// 11/08/2011: show subcontract fields
void showSubconFields(Object fRecord)
{
	Object[] jkl = { subcon_flag, subcontractor_tb, subcon_sendout, subcon_notes };
	String[] fl = { "subcon_flag", "subcontractor", "subcon_sendout", "subcon_notes" };
	populateUI_Data(jkl, fl, fRecord);
}

// Clear cash account details inputs
void clearCashAccountInputs()
{
	cashacct_gb.setVisible(false);

	Object[] jkl = { ca_customer_name_tb, ca_contact_person1_tb, ca_address1_tb, ca_address2_tb,
		ca_city_tb, ca_zipcode_tb, ca_state_tb, ca_country_tb, ca_telephone_tb, ca_fax_tb, ca_email_tb };

	clearUI_Field(jkl);
}

// 11/6/2010: Populate cash-account popup's textboxes
void populateCashAccountPopup(String ifolderno)
{
	clearCashAccountInputs();
	cashacct_gb.setVisible(true);
	csrec = samphand.getCashSalesCustomerInfo_Rec(ifolderno);
	if(csrec == null) return;

	// 25/11/2010: show the main company-name holder
	customername.setValue(global_selected_folderstr + " : CshAct: " + csrec.get("customer_name"));

	Object[] jkl = { ca_customer_name_tb, ca_contact_person1_tb, ca_address2_tb, ca_address1_tb,
		ca_city_tb, ca_zipcode_tb, ca_state_tb, ca_country_tb, ca_telephone_tb, ca_fax_tb, ca_email_tb };
	String[] fl = { "customer_name", "contact_person1", "address2", "address1",
		"city", "zipcode", "state", "country", "telephone", "fax", "email" };

	populateUI_Data(jkl, fl, csrec);
}

// 11/6/2010: save cash account details
void saveCashAccountDetails()
{
	if(global_selected_folder.equals("")) return;
	samphand.deleteCashSalesCustomerInfo_Rec(global_selected_folderstr); // del rec from cashsales_customerinfo before inserting new

	Object[] jkl = { ca_customer_name_tb, ca_address1_tb, ca_address2_tb, ca_city_tb, ca_zipcode_tb, ca_state_tb, ca_country_tb,
		ca_telephone_tb, ca_fax_tb, ca_email_tb, ca_contact_person1_tb };

	dt = getString_fromUI(jkl);

	sqlstm = "insert into CashSales_CustomerInfo (folderno_str,customer_name,address1,address2,city,zipcode,state,country,telephone,fax,email,contact_person1)" +
	"values ('" + global_selected_folderstr + "','" + dt[0] + "','" + dt[1] + "','" + dt[2] + "','" + dt[3] + "','" + dt[4] +
	"','" + dt[5] + "','" + dt[6] + "','" + dt[7] + "','" + dt[8] + "','" + dt[9] + "','" + dt[10] + "')";

	sqlhand.gpSqlExecuter(sqlstm);
	cashacct_gb.setVisible(false);
}

void printSRA_Wrapper()
{
	if(global_selected_folder.equals("")) return;
	printSRA(global_selected_folderstr); // samplereg_funcs.zs
} // end of printSRA_Wrapper()

void printSampleLabels_Wrapper()
{
	// see if we have any samples in listbox - hardcoded samples_lb
	if(samples_lb.getItemCount() < 1) return;
	if(global_selected_folder.equals("")) return;

	// 24/2/2010: save samples id full string eg. ALSM000010001 before printing.
	// Previously depended on the onSelect event to kick this func, not totally saved the full-string
	samphand.saveFolderSamplesNo_Main2(samples_lb); // samplereg_funcs.zs

	// 24/2/2010: save also the folder info, BIRT cannot pickup the company-name by ar-code field
	saveFolderMetadata();
	printSampleLabels(global_selected_folderstr); // samplereg_funcs.zs

} // end of printSampleLabels_Wrapper()
