import org.victor.*;
// Supporting funcs for quote-maker

// check if quotation version is = current
boolean currentQuoteVersion(String qorigid, String iversion)
{
	retval = false;
	sqlstm = "select version from elb_quotations where origid=" + qorigid;
	vrec = sqlhand.gpSqlFirstRow(sqlstm);
	curv = (vrec.get("version") == null) ? "0" : vrec.get("version").toString();
	if(curv.equals(iversion)) retval = true;
	return retval;
}

// true = disable all fields, false = enable
void disableQuote_MetadataFields(boolean iwhat)
{
	Object[] jkl = { qt_ar_code, qt_address1, qt_address2, qt_city, qt_zipcode, qt_state, qt_country, qt_telephone,
		qt_fax, qt_contact_person1, qt_email, qt_notes, qt_exchangerate, qt_curcode };

	for(i=0; i<jkl.length; i++)
	{
		jkl[i].setDisabled(iwhat);
	}
}

// Put quote-creators into listbox/dropdown
void populateQTcreator(Listbox lbid)
{
	sqlstm = "select distinct username from elb_quotations where datecreated >= '2014-01-01' order by username";
	r = sqlhand.gpSqlGetRows(sqlstm);
	if(r.size() == 0) return;
	ArrayList kabom = new ArrayList();
	for(d : r)
	{
		kabom.add(d.get("username"));
		lbhand.insertListItems(lbid, kiboo.convertArrayListToStringArray(kabom), "false", "");
		kabom.clear();
	}
	kabom.add("doc"); // HARDCODED
	lbhand.insertListItems(lbid, kiboo.convertArrayListToStringArray(kabom), "false", "");
	kabom.clear();
	kabom.add("padmin");
	lbhand.insertListItems(lbid, kiboo.convertArrayListToStringArray(kabom), "false", "");
}

// This textbox onDrop event knockoff from registernew_samples_v2.zul - modded for this
void dropAR_Code(Event event)
{
	Component dragged = event.dragged;
	iarcode = dragged.getLabel();
	comprec = sqlhand.getCompanyRecord(iarcode); // func in alsglobal_sqlfuncs.zs
	if(comprec != null)
	{
		Object[] jkl = { qt_customer_name, qt_contact_person1, qt_telephone, qt_fax, qt_email, qt_curcode };
		String[] fl = { "customer_name", "contact_person1", "telephone_no", "fax_no", "E_mail", "CurCode" };
		populateUI_Data(jkl,fl,comprec);
		self.setValue(iarcode);
		qt_address1.setValue(comprec.get("address1") + comprec.get("address2"));
		qt_address2.setValue(comprec.get("address3") + comprec.get("Address4"));
	}
}

void showQuoteItems_Metadata()
{
	qirec = quotehand.getQuoteItem_Rec(global_selected_quoteitem);
	if(qirec == null) return;
	Object[] jkl = { qi_description, qi_description2, qi_unitprice, qi_quantity, qi_discount, qi_lor };
	String[] fl = { "description", "description2", "unitprice", "quantity", "discount", "lor" };
	populateUI_Data(jkl, fl, qirec);
	editquoteitem_btn.setLabel("Update..");
}

void clearQuoteItem_inputs()
{
	global_selected_quoteitem = ""; // reset global
	Object[] jkl = { qi_description, qi_description2, qi_unitprice, qi_quantity, qi_discount, qi_lor };
	for(i=0; i<jkl.length; i++)
	{
		jkl[i].setValue("");
	}
	editquoteitem_btn.setLabel("New..");
}

void showQuotationMetadata(Object irec)
{
	Object[] jkl = { qt_ar_code, qt_customer_name, qt_address1, qt_address2, qt_city, qt_zipcode, qt_state, qt_country,
		qt_telephone, qt_fax, qt_contact_person1, qt_email, qt_notes, qt_exchangerate, qt_curcode, qt_terms,
		qt_customer_sector, qt_new_sector };

	String[] fl = { "ar_code", "customer_name", "address1", "address2", "city", "zipcode", "state", "country",
		"telephone", "fax", "contact_person1", "email", "notes", "exchangerate", "curcode", "terms",
		"customer_sector", "new_sector" };

	populateUI_Data(jkl,fl,irec);

	kk = (!irec.get("ar_code").equals("")) ? true : false;
	qt_customer_name.setDisabled(kk); // if this quote is based on client in system - disable the customer-name box

	lbhand.matchListboxItemsColumn(qt_salesperson, kiboo.checkNullString(irec.get("salesperson")), 1);
	lbhand.matchListboxItemsColumn(quote_winloseflag, kiboo.checkNullString(irec.get("winloseflag")), 0);
}

// Save whatever metadata entered for quotation
// optimized 06/06/2014
void saveQuotation_clicker()
{
	Object[] jkl = { qt_ar_code, qt_customer_name, qt_address1, qt_address2, qt_city, qt_zipcode, qt_state, qt_country,
	qt_telephone, qt_fax, qt_contact_person1, qt_email, qt_notes, qt_curcode, qt_exchangerate, 
	qt_salesperson, qt_terms, qt_customer_sector, qt_new_sector };

	dt = getString_fromUI(jkl);

	if(dt[1].equals(""))
	{
		guihand.showMessageBox("Cannot save - Customer.Name is blank");
		return;
	}

	if(dt[14].equals("0.0")) dt[14] = "1";

	sql = sqlhand.als_mysoftsql();
	if(sql == null ) return;
	thecon = sql.getConnection();

	pstmt = thecon.prepareStatement("update elb_Quotations set ar_code=?,customer_name=?,address1=?,address2=?,city=?,zipcode=?,state=?," +
	"country=?,telephone=?,fax=?,contact_person1=?,email=?,notes=?,curcode=?,exchangerate=?,salesperson=?,terms=?, customer_sector=?, new_sector=?" + 
	" where origid=?");

	for(i=0; i<dt.length; i++)
	{
		try { pstmt.setString(i+1,dt[i]); } catch (Exception e) { pstmt.setFloat(i+1, Float.parseFloat(dt[i])); }
	}
	pstmt.setInt(20,Integer.parseInt(global_loaded_quote));
	pstmt.executeUpdate();
	sql.close();
	guihand.showMessageBox("Quotation's metadata saved..");
	showQuotations_Listbox(0);
	
	editquoteitem_btn.setDisabled(false);
	deletequoteitem_btn.setDisabled(false);
}

// 14/1/2011: use built-in customer selector
void playAssignCustomerWindow()
{
//	uniqwindowid = makeRandomId("xqx");
//	globalActivateWindow("miscwindows","dispatch/customer_search_popup.zul", uniqwindowid, "getcust=1",useraccessobj);
	selectcustomer_popup.open(cfind_holder);
}

// Load and show quotation's metadata -- remember also same knockoff in quotetracker.zul
void loadQuotation_clicker(String iwhat)
{
	//if(!lbhand.check_ListboxExist_SelectItem(quotes_div, "quotations_lb")) return;
	//quotes_div.setVisible(false);
	//qtid = quotations_lb.getSelectedItem().getLabel(); // 1st col is elb_Quotations.origid
	qtrec = quotehand.getQuotation_Rec(iwhat);

	quotetitle_lbl.setValue("Quotation: " + QUOTE_PREFIX + iwhat + " :: " + qtrec.get("customer_name"));
	quote_metadata_div.setVisible(true);

	if(qtrec == null) return;

	//global_loaded_quote = qtrec.get("origid").toString();
	global_quote_curcode = qtrec.get("curcode");
	global_quote_status = qtrec.get("qstatus");
	global_quote_owner = qtrec.get("username");
	qtarcode = qtrec.get("ar_code");

	showQuotationMetadata(qtrec);
	showQuoteItems(last_load_quoteitems_type);
	showFeedbacks(); // quotetracker_funcs.zs

	savequote_btn.setDisabled(false);
	disableQuote_MetadataFields(false);
	printquotation_btn.setDisabled(true); // disable quote printing if quotation is NEW

	if(!global_quote_status.equals(QTSTAT_NEW)) // && useraccessobj.accesslevel < 9) // admin can do
	{
		savequote_btn.setDisabled(true);
		disableQuote_MetadataFields(true);
		printquotation_btn.setDisabled(false); // enable quote printing if quotation is committed
	}

	selected_quotestring = QUOTE_PREFIX + iwhat;
	showDocumentsList(selected_quotestring); // 15/05/2011: show supporting documents

	global_quote_version = (qtrec.get("version") == null) ? "0" : qtrec.get("version").toString();
	quote_version.setValue(global_quote_version); // 24/02/2012: show version

	global_selected_versiontoload = global_quote_version; // for other checkings below..
	global_version_edit = true; // 24/02/2012: allow editing for current q-version loaded
	qt_metadata_div.setVisible(true);

	// 29/02/2012: if it's not version 0, disable save-metadata and get-customer button and disable ar_code textbox
	//savequote_btn.setDisabled(true);
	assign_customer_btn.setDisabled(true);
	qt_ar_code.setDisabled(true);

	if(global_quote_version.equals("0"))
	{
		//savequote_btn.setDisabled(false);
		assign_customer_btn.setDisabled(false);
		qt_ar_code.setDisabled(false);
	}
	
	// 18/05/2012: auto-insert grand-total into quote-table
	sqlstm = "update elb_quotations set quote_net=" + global_quote_grandtotal.toString() + " where origid=" + iwhat;
	sqlhand.gpSqlExecuter(sqlstm);

	// 18/05/2012: quote amount >= RM5k, enable print-btn if already approved by sales-manager
	// 01/06/2012: set to RM20K - 
	if(global_quote_grandtotal >= 20000.00 && !qtarcode.equals("") && !qtarcode.equals("CASH"))
	{
		if(qtrec.get("approveby") == null) printquotation_btn.setDisabled(true);
	}

	if(global_quote_grandtotal >= 5000.00 && (qtarcode.equals("") || qtarcode.equals("CASH")) ) // check non-reg client >= RM5K
	{
		if(qtrec.get("approveby") == null) printquotation_btn.setDisabled(true);
	}

	// 29/06/2012: temporary disabled control - boss and chong not around to approve quotes!!!
	printquotation_btn.setDisabled(false);

	qt_new_sector.setDisabled(true); // always disabled unless MISC in customer-sector - HARDCODED
	custsect = kiboo.checkNullString(qtrec.get("customer_sector"));
	if(custsect.equals("MISC")) qt_new_sector.setDisabled(false);
}

Object[] quotations22_lb_headers = {
	new listboxHeaderWidthObj("Q#",true,"70px"),
	new listboxHeaderWidthObj("ar_code",false,""),
	new listboxHeaderWidthObj("Customer",true,""),
	new listboxHeaderWidthObj("Crt.Date",true,"20px"),
	new listboxHeaderWidthObj("Total",true,"50px"),
	new listboxHeaderWidthObj("User",true,"25px"),
	new listboxHeaderWidthObj("Q.Stat",true,"20px"),
	new listboxHeaderWidthObj("Appr",true,"50px"),
	new listboxHeaderWidthObj("Apr.Date",true,"20px"),
	new listboxHeaderWidthObj("WL",true,"80px"),
	new listboxHeaderWidthObj("V",true,"20px"),
};

// onSelect for showQuotations_Listbox()
class quotes_lb_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		//selitem = quotations_lb.getSelectedItem();
		selitm = event.getReference();
		global_loaded_quote = lbhand.getListcellItemLabel(selitm,0);
		loadQuotation_clicker(global_loaded_quote);
	}
}
qtlbcliker = new quotes_lb_Listener();

// itype: 0=previous, 1=show owner's by date, 2=load all by date, 3=load all by date and searchstring
// 4=by QT number, 5=by username created quotation
void showQuotations_Listbox(int itype)
{
	Listbox newlb = lbhand.makeVWListbox_Width(quotes_div, quotations22_lb_headers, "quotations_lb", 5);
	
	showtype = itype;
	if(itype == 0) showtype = old_show_quote;
	else old_show_quote = itype;

	srchstr = kiboo.replaceSingleQuotes(quote_search.getValue());
	sdate = kiboo.getDateFromDatebox(startdate);
	edate = kiboo.getDateFromDatebox(enddate);
	qtnum = kiboo.replaceSingleQuotes(qtnumber_search.getValue());
	byusercreated = quotemaker_user_lb.getSelectedItem().getLabel();

	basesql = "select top 200 origid,ar_code,customer_name,datecreated,username," + 
	"qstatus,deleted,version,approveby,approvedate,quote_net,winloseflag from elb_Quotations ";
	sufsql = " order by datecreated,origid desc";
	othercheck = " where username='" + useraccessobj.username + "' and deleted=0 ";
	sqlstm = basesql;
	
	switch(showtype)
	{
		case 1:
			sqlstm += othercheck + " and datecreated between '" + sdate + "' and '" + edate + "' " + sufsql;
			break;
		case 2:
			sqlstm += "where datecreated between '" + sdate + "' and '" + edate + "' " + sufsql;
			break;
		case 3:
			sqlstm += "where (customer_name like '%" + srchstr + "%' or address1 like '%" + srchstr + "%' or " +
			"address2 like '%" + srchstr + "%' or contact_person1 like '%" + srchstr + "%') " +
			"and datecreated between '" + sdate + "' and '" + edate + "' " + sufsql;
			break;
		case 4:
			try {
				wodi = Integer.parseInt(qtnum);
			} catch (NumberFormatException e)
			{
				return;
			}
			sqlstm += "where origid=" + wodi.toString();
			break;
		case 5:
				sqlstm += "where username='" + byusercreated + "' and datecreated between '" + sdate + "' and '" + edate + "' " + sufsql;
			break;
	}

	//if(useraccessobj.accesslevel > 8) sqlstm = basesql + sufsql;
	
	qtrows = sqlhand.gpSqlGetRows(sqlstm);
	if(qtrows.size() == 0) return;
	newlb.setMold("paging");
	newlb.setRows(21);
	newlb.addEventListener("onSelect", qtlbcliker);
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "ar_code", "customer_name", "datecreated", "quote_net", "username", "qstatus", "approveby", "approvedate", "winloseflag","version" };
	for(dpi : qtrows)
	{
		popuListitems_Data(kabom, fl, dpi);
		lbhand.insertListItems(newlb, kiboo.convertArrayListToStringArray(kabom), "false", "");
		kabom.clear();
	}
	quotes_div.setVisible(true);

} // end showQuotations_Listbox()

// onSelect listener for showQuoteItems()
class quote_items_lb_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitem = quote_items_lb.getSelectedItem();
		mysoftc = lbhand.getListcellItemLabel(selitem,1);
		global_selected_quoteitem = lbhand.getListcellItemLabel(selitem,0);
		//autoAssignTestParametersBox(mysoftc);
		showQuoteItems_Metadata();
	}
}
qitmscliker = new quote_items_lb_Listener();

// 27/02/2012: add itype to load other quote-version from db
// itype: 1=normal loading, 2=load different version
// quote_items_div quote_items_lb global_loaded_quote global_quote_status
void showQuoteItems(int itype)
{
Object[] quote_items_lb_headers = {
	new listboxHeaderObj("origid",false),
	new listboxHeaderObj("mysoftcode",false),
	new listboxHeaderObj("No.",true),
	new listboxHeaderObj("Tests",true),
	new listboxHeaderObj("Method.Ref",true),
	new listboxHeaderObj("Stk",true),
	new listboxHeaderObj("LOR",true),
	new listboxHeaderObj("U.P",true),
	new listboxHeaderObj("Qty",true),
	new listboxHeaderObj("Dsct",true),
	new listboxHeaderObj("Gross",true),
	new listboxHeaderObj("Nett",true),
};

	if(global_loaded_quote.equals("")) return;

	last_load_quoteitems_type = itype;

	Listbox newlb = lbhand.makeVWListbox(quote_items_div, quote_items_lb_headers, "quote_items_lb", 5);
	quoteitems_meta_div.setVisible(true);

	sql = sqlhand.als_mysoftsql();
	if(sql == null ) return;

	// 27/02/2012: update any quote-items with version == null to 0
	sqlstm3 = "update elb_quotation_items set version=0 where version is null";
	sql.execute(sqlstm3);

	// 27/02/2012: chk quote version to load
	sqlstm2 = "select version from elb_quotations where origid=" + global_loaded_quote;
	vrec = sql.firstRow(sqlstm2);
	verstr = (vrec.get("version") == null) ? "0" : vrec.get("version").toString();

	// type 2 = load selected version
	if(itype == 2) verstr = global_selected_versiontoload;

	sqlstm = "select origid,mysoftcode,description,description2,LOR,unitprice,quantity," + 
	"discount,total_gross,total_net from elb_Quotation_Items " +
	"where quote_parent=" + global_loaded_quote + " and version=" + verstr +
	" order by origid";

	qitems = sql.rows(sqlstm);
	sql.close();
	if(qitems.size() == 0) return;

	newlb.setRows(21);
	newlb.setMold("paging");
	newlb.setMultiple(true);
	newlb.addEventListener("onSelect", qitmscliker);
	rowcounter = 1;
	//newlb.setCheckmark(true);
	//newlb.setMultiple(true);
	grandtotal = 0.0;
	ArrayList kabom = new ArrayList();
	String[] fl = { "origid", "mysoftcode", "lor", "description", "description2", "lor", "lor", "unitprice", "quantity", "discount", "total_gross", "total_net" };
	lnposi = 2; stkposi = 5;

	for(dpi : qitems)
	{
		popuListitems_Data(kabom,fl,dpi);

		grandtotal += dpi.get("total_net");
		mysc = dpi.get("mysoftcode").toString();
		stkitem = (mysc.equals("") || mysc.equals("0")) ? "---" : "-Y-";

		ki = lbhand.insertListItems(newlb, kiboo.convertArrayListToStringArray(kabom), "false", "");
		lbhand.setListcellItemLabel(ki, lnposi, rowcounter.toString() + ".");
		lbhand.setListcellItemLabel(ki, stkposi, stkitem);

		rowcounter++;
		kabom.clear();
	}

	global_quote_grandtotal = grandtotal; // save to glob-var
	quoteitems_grandtotal_lbl.setValue("Grand total: " + global_quote_curcode + " " + nf2.format(grandtotal));
	deletequoteitem_btn.setDisabled(false);
	editquoteitem_btn.setDisabled(false);

	// 27/02/2012: quote is not "NEW" and global_version_edit(loaded old version) = false
	if(!global_quote_status.equals(QTSTAT_NEW) && !global_version_edit)
	{
		deletequoteitem_btn.setDisabled(true);
		editquoteitem_btn.setDisabled(true);
	}

}

// create LB on salesman - dropdown
void populateSalesman_dropdown(Div idiv, String theidstring)
{
	Object[] sm_lb_headers = {
	new dblb_HeaderObj("SM.Name",true,"salesman_name",1),
	new dblb_HeaderObj("SM.Code",false,"salesman_code",1),
	};

	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	sqlstm = "select salesman_code,salesman_name from salesman";
	Listbox newlb = lbhand.makeVWListbox_onDB(idiv,sm_lb_headers,theidstring,1,sql,sqlstm);
	sql.close();
	newlb.setMold("select");
	newlb.setStyle("font-size:9px");
	newlb.setSelectedIndex(0);
}

// terms distinct extracted from customer.credit_period - can be used for other mods
void populateTerms_dropdown(Div idiv, String ilbid)
{
	Object[] terms_lb_headers = {
	new dblb_HeaderObj("terms",true,"credit_period",1),
	};

	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	sqlstm = "select distinct credit_period from customer order by credit_period";
	Listbox newlb = lbhand.makeVWListbox_onDB(idiv,terms_lb_headers,ilbid,1,sql,sqlstm);
	sql.close();
	newlb.setMold("select");
	newlb.setStyle("font-size:9px");
}

/*
show quote items old codes..
		kabom.add(dpi.get("origid").toString());
		kabom.add(mysc);
		kabom.add(rowcounter.toString() + ".");
		kabom.add(lbhand.trimListitemLabel(kiboo.checkNullString(dpi.get("description")),25));
		kabom.add(lbhand.trimListitemLabel(kiboo.checkNullString(dpi.get("description2")),25));
		kabom.add(stkitem);
		thelor = (dpi.get("LOR").equals("")) ? "---" : dpi.get("LOR");
		kabom.add(thelor);
		kabom.add(nf2.format(dpi.get("unitprice")));
		kabom.add(dpi.get("quantity").toString());
		discstr = (dpi.get("discount") == 0) ? "---" : nf2.format(dpi.get("discount"));
		kabom.add(discstr);
		kabom.add(nf2.format(dpi.get("total_gross")));
		kabom.add(nf2.format(total_net));

*/

		/*
		origid = dpi.get("origid").toString();
		kabom.add(origid);
		kabom.add(dpi.get("ar_code"));
		// text-decoration: line-through
		delstr = (dpi.get("deleted") == 1) ? "[DEL] " : "";
		qcode = delstr + QUOTE_PREFIX + origid;
		kabom.add(qcode);

		customername = kiboo.checkEmptyString(lbhand.trimListitemLabel(dpi.get("customer_name"),30));
		kabom.add(customername);

		datecreated = dpi.get("datecreated").toString().substring(0,10);
		if(datecreated.equals("1900-01-01")) datecreated = "---";

		kabom.add(datecreated);
		kabom.add( (dpi.get("quote_net") != null) ? nf2.format(dpi.get("quote_net")) : "0.00" );
		kabom.add(dpi.get("username"));
		kabom.add(dpi.get("qstatus"));
		kabom.add(kiboo.checkNullString(dpi.get("approveby")));
		kabom.add(kiboo.checkNullDate(dpi.get("approvedate"),"---"));
		kabom.add((dpi.get("version") == null) ? "0" : dpi.get("version").toString());
		*/
		/*
		lastup = "---";
		lastupdate = dpi.get("lastupdate");
		if(lastupdate != null)
		{
			kkx = lastupdate.toString().substring(0,10);
			if(!kkx.equals("1900-01-01")) lastup = kkx;
		}
		kabom.add(lastup);
		*/

		/*
	pstmt.setString(1,ar_code);
	pstmt.setString(2,customer_name);
	pstmt.setString(3,address1);
	pstmt.setString(4,address2);
	pstmt.setString(5,city);
	pstmt.setString(6,zipcode);
	pstmt.setString(7,state);
	pstmt.setString(8,country);

	pstmt.setString(9,telephone);
	pstmt.setString(10,fax);
	pstmt.setString(11,contact_person1);
	pstmt.setString(12,email);
	pstmt.setString(13,notes);
	pstmt.setString(14,curcode);
	pstmt.setFloat(15,exchangerate.floatValue());

	pstmt.setString(16,salesp);
	pstmt.setString(17,terms);

	pstmt.setString(18,custsect);
	pstmt.setString(19,newcustsect);
	pstmt.setInt(20,Integer.parseInt(global_loaded_quote));
*/
/*
	ar_code = kiboo.replaceSingleQuotes(qt_ar_code.getValue());
	customer_name = kiboo.replaceSingleQuotes(qt_customer_name.getValue());
	
	if(customer_name.equals(""))
	{
		guihand.showMessageBox("Cannot save - Customer.Name is blank");
		return;
	}
	
	address1 = kiboo.replaceSingleQuotes(qt_address1.getValue());
	address2 = kiboo.replaceSingleQuotes(qt_address2.getValue());
	city = kiboo.replaceSingleQuotes(qt_city.getValue());
	zipcode = kiboo.replaceSingleQuotes(qt_zipcode.getValue());
	state = kiboo.replaceSingleQuotes(qt_state.getValue());
	country = kiboo.replaceSingleQuotes(qt_country.getValue());
	telephone = kiboo.replaceSingleQuotes(qt_telephone.getValue());
	fax = kiboo.replaceSingleQuotes(qt_fax.getValue());
	contact_person1 = kiboo.replaceSingleQuotes(qt_contact_person1.getValue());
	email = kiboo.replaceSingleQuotes(qt_email.getValue());
	notes = kiboo.replaceSingleQuotes(qt_notes.getValue());
	curcode = qt_curcode.getSelectedItem().getLabel();
	exchangerate = qt_exchangerate.getValue();

	selitem = qt_terms.getSelectedItem();
	terms = lbhand.getListcellItemLabel(selitem,0);

	selitem = qt_salesperson.getSelectedItem();
	salesp = lbhand.getListcellItemLabel(selitem,1);

	// 07/08/2012: customer sector
	selitem = qt_customer_sector.getSelectedItem();
	custsect = lbhand.getListcellItemLabel(selitem,0);
	newcustsect = kiboo.replaceSingleQuotes(qt_new_sector.getValue());
*/
	/*
	qt_ar_code.setValue(qtarcode);
	qt_customer_name.setValue(qtrec.get("customer_name"));
	qt_address1.setValue(kiboo.checkNullString(qtrec.get("address1")));
	qt_address2.setValue(kiboo.checkNullString(qtrec.get("address2")));
	qt_city.setValue(kiboo.checkNullString(qtrec.get("city")));
	qt_zipcode.setValue(kiboo.checkNullString(qtrec.get("zipcode")));
	qt_state.setValue(kiboo.checkNullString(qtrec.get("state")));
	qt_country.setValue(kiboo.checkNullString(qtrec.get("country")));
	qt_telephone.setValue(kiboo.checkNullString(qtrec.get("telephone")));
	qt_fax.setValue(kiboo.checkNullString(qtrec.get("fax")));
	qt_contact_person1.setValue(kiboo.checkNullString(qtrec.get("contact_person1")));
	qt_email.setValue(kiboo.checkNullString(qtrec.get("email")));
	qt_notes.setValue(kiboo.checkNullString(qtrec.get("notes")));
	lbhand.matchListboxItems(qt_curcode,global_quote_curcode);

	doexh = qtrec.get("exchangerate");
	exhrate = new BigDecimal(1);
	if(doexh != null) exhrate = new BigDecimal(doexh);
	qt_exchangerate.setValue(exhrate);
	terms = (qtrec.get("terms") == null) ? "" : qtrec.get("terms");
	lbhand.matchListboxItemsColumn(qt_terms,terms,0);

	// 07/08/2012: customer-sector
	custsect = (qtrec.get("customer_sector") == null) ? "" : qtrec.get("customer_sector");
	lbhand.matchListboxItemsColumn(qt_customer_sector,custsect,0);

	qt_new_sector.setValue( kiboo.checkNullString(qtrec.get("new_sector")) );
*/
