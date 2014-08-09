import org.victor.*;
// quote-packages funcs

// 03/08/2011: converted committed quotation to test-package - will discard non-stock items
// quotations must be COMMITTED before converting to test-package
void convertQuotation_TestPackage()
{
	//if(!check_ListboxExist_SelectItem(quotes_div,"quotations_lb")) return;
	if(global_loaded_quote.equals("")) return;

	// admin can convert any quotation to test-package --	
	if(useraccessobj.accesslevel != 9)
	{
		shwmsg = "";

		if(global_quote_status.equals(QTSTAT_RETIRED)) shwmsg = "This quotation is already RETIRED, cannot convert..";
		if(global_quote_status.equals(QTSTAT_NEW)) shwmsg = "Please commit quotation before converting to test-package";

		if(!shwmsg.equals(""))
		{
			guihand.showMessageBox(shwmsg);
			return;
		}
	}

	if (Messagebox.show("Will transfer only pre-defined quoted stock-items to test-package. Open-items will NOT be transfered..", "Are you sure?", 
		Messagebox.YES | Messagebox.NO, Messagebox.QUESTION) ==  Messagebox.NO) return;

	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;

	// check if there's already a test-package converted from this quotation	
	sqlstm = "select origid from testpackages where fromquotation=" + global_loaded_quote;
	existtp = sql.firstRow(sqlstm);
	whopid = "";
	if(existtp != null)
	{
		whopid = existtp.get("origid").toString();

		// if exist testpackage converted from quotation, delete all testpackage_items, will inject new ones
		sqlstm = "delete from testpackage_items where testpackage_id=" + whopid;
		sql.execute(sqlstm);
	}

	// get data from elb_quotation_items by selected quotation - must be stock-items
	sqlstm = "select mysoftcode,lor,unitprice from elb_quotation_items where mysoftcode <> 0 and quote_parent=" + global_loaded_quote;
	quoteitems = sql.rows(sqlstm);
	if(quoteitems.size() == 0) { sql.close(); return; }
	
	// if not exist converted quote-items in testpackage, create a new test package
	if(whopid.equals(""))
	{
		quoterec = quotehand.getQuotation_Rec(global_loaded_quote);
		arcode = quoterec.get("ar_code");
		packname = "QT" + global_loaded_quote + " TRANSFERED";
		todaysdate = kiboo.getDateFromDatebox(hiddendatebox);
		sqlstm = "insert into testpackages (package_name,lastupdate,deleted,ar_code,username,fromquotation) values " +
		"('" + packname + "','" + todaysdate + "',0,'" + arcode + "','" + useraccessobj.username + "'," + global_loaded_quote + ")";
		
		sql.execute(sqlstm);
		
		// get the new testpackage origid
		sqlstm = "select origid from testpackages where fromquotation=" + global_loaded_quote;
		norig = sql.firstRow(sqlstm);
		whopid = norig.get("origid").toString();
	}
	
	// inject quote-items as testpackage-items
	sortc = 1;
	for(dpi : quoteitems)
	{
		mysc = dpi.get("mysoftcode").toString();
		uprice = dpi.get("unitprice").toString();
		lor = dpi.get("lor");

		sqlstm = "insert into testpackage_items (mysoftcode,testpackage_id,deleted,sorter,lor,bill,units,unitprice) values " +
		"(" + mysc + "," + whopid + ",0," + sortc.toString() + ",'" + lor + "','YES',''," + uprice + ")";

		sql.execute(sqlstm);
		sortc++;
	}

	sql.close();

	guihand.showMessageBox("Quoted stock-items transfered into test-package..");
}

void listQuotePackage_Items()
{
	Object[] qpitems_lb_headers = {
	new listboxHeaderObj("Item",true),
	new listboxHeaderObj("Price",true),
	};
	
	Listbox newlb = lbhand.makeVWListbox(qpack_items_holder, qpitems_lb_headers, "qpitems_lb", 5);

	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	sqlstm = "select itemdesc,selling_price from elb_quotepackage_items where qpack_parent=" + selected_qpackage_id;
	qpirecs = sql.rows(sqlstm);
	sql.close();

	if(qpirecs.size() == 0) return;
	newlb.setRows(8);
	//newlb.addEventListener("onSelect", new searchcustomersLB_Listener());

	DecimalFormat nf = new DecimalFormat("##.00");

	for(dpi : qpirecs)
	{
		ArrayList kabom = new ArrayList();
		kabom.add(dpi.get("itemdesc"));
		kabom.add(nf.format(dpi.get("selling_price")));
		strarray = kiboo.convertArrayListToStringArray(kabom);
		lbhand.insertListItems(newlb,strarray,"false","");
	}
}

class qpackagesLB_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		selitem = event.getReference();
		selected_qpackage_id = lbhand.getListcellItemLabel(selitem,0);

		// show quote-package metadata
		qprec = quotehand.getQuotePackageRec(selected_qpackage_id);
		if(qprec != null)
		{
			qpack_name.setValue(qprec.get("qpack_name"));
			company_name.setValue(qprec.get("company_name"));
			qpack_notes.setValue(qprec.get("notes"));
			
			qpack_items_lbl.setLabel("Package items : " + selected_qpackage_id);
		}

		grabItems_btn.setDisabled(false);

		// check if already defined some quote items -- else disable grab-items button
		if(quotePackageItems_Avail(selected_qpackage_id) != 0)
		{
			grabItems_btn.setDisabled(true);
			listQuotePackage_Items();
		}
	}
}

void listQuotePackages()
{
Object[] quotepacks_lb_headers = 
	{
	new dblb_HeaderObj("##",true,"origid",2),
	new dblb_HeaderObj("Pack.Name",true,"qpack_name",1),
	new dblb_HeaderObj("Company",true,"company_name",1),
	};

	// show the quote-packages
	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	sqlstatem = "select origid,qpack_name,company_name from elb_quotation_package";
	Listbox newlb = lbhand.makeVWListbox_onDB(recallpacks_holder,quotepacks_lb_headers,"qpackages_lb",5,sql,sqlstatem);
	sql.close();
	if(newlb.getItemCount() == 0) return;
	if(newlb.getItemCount() > 5) newlb.setRows(10);
	//newlb.addEventListener("onSelect", new qpackagesLB_Listener());
}

// Let user create quote-package, abit of checking before showing the popup
void makeQuotePackage_clicker()
{
	listQuotePackages();
	quotemaker_popup.open(qpackmaker_btn);
}

void createNewQuotePackage_clicker()
{
	arcode = qt_ar_code.getValue();
	custname = qt_customer_name.getValue();
	todaysdate = kiboo.getDateFromDatebox(hiddendatebox);
	sqlstm = "insert into elb_quotation_package (qpack_name,ar_code,company_name,notes,datecreated,username) values " + 
	"('','" + arcode + "','" + custname + "','','" + todaysdate + "','" + useraccessobj.username + "')";
	sqlhand.gpSqlExecuter(sqlstm);
	listQuotePackages(); // refresh
}

void saveQuotePackageStuff()
{
	qpname = kiboo.replaceSingleQuotes(qpack_name.getValue());
	qpcomp = kiboo.replaceSingleQuotes(company_name.getValue());
	qpnotes = kiboo.replaceSingleQuotes(qpack_notes.getValue());

	sqlstm = "update elb_quotation_package set qpack_name='" + qpname + "',company_name='" + qpcomp + 
	"',notes='" + qpnotes + "' where origid=" + selected_qpackage_id;

	sqlhand.gpSqlExecuter(sqlstm);
	listQuotePackages(); // refresh
}

void grabQuoteItems_ToPackage()
{
	if(selected_qpackage_id.equals("")) return;
	if(quote_items_div.getFellowIfAny("quote_items_lb") == null) return;
	if(quote_items_lb.getItemCount() == 0)
	{
		guihand.showMessageBox("No quote items. Nothing to grab");
		return;
	}
}

// Memorize whatever quoted items - only store the quotation origid and recalling will retrieve whatever from the quotation
void memorizeQuoteItems_clicker()
{
	if(global_loaded_quote.equals("")) return;
	if(quote_items_div.getFellowIfAny("quote_items_lb") == null) return;
	if(quote_items_lb.getItemCount() == 0)
	{
		guihand.showMessageBox("No items to memorize");
		return;
	}

	memorizeQuote_popup.open(memorizequote_btn);
}

// Really save the quotation items into package
void reallyMemorizeItems()
{
	packname = kiboo.replaceSingleQuotes(quotePack_name.getValue());
	if(packname.equals(""))
	{
		guihand.showMessageBox("Need a quotation-package name to memorize the items..");
		return;
	}

	// now delete previous quote-package if exist
	sqlstm = "delete from elb_quotation_package where quotation_id=" + global_loaded_quote + ";" ;

	todaysdate = kiboo.getDateFromDatebox(hiddendatebox);
	arcode = kiboo.replaceSingleQuotes(qt_ar_code.getValue().trim());
	custname = kiboo.replaceSingleQuotes(qt_customer_name.getValue().trim());
	sqlstm += "insert into elb_quotation_package (qpack_name,ar_code,company_name,notes,datecreated,username,quotation_id) values " + 
	"('" + packname + "','" + arcode + "','" + custname + "','','" + todaysdate + "','" + useraccessobj.username + "'," + global_loaded_quote + ");";

	sqlhand.gpSqlExecuter(sqlstm);
	guihand.showMessageBox("Quotation items memorized in package: " + packname);
}

class quotepack_dc_Listener implements org.zkoss.zk.ui.event.EventListener
{
	public void onEvent(Event event) throws UiException
	{
		packorigid = qpackages_lb.getSelectedItem().getLabel();
		recallQuote_popup.close();
		reallyRecallItems(packorigid);
	}
}

// itype: 0 = load all, 1 = load by search-string
void listQuotePackages_v2(int itype)
{
Object[] quotepacks_lb_headers = 
	{
	new dblb_HeaderObj("##",false,"origid",2),
	new dblb_HeaderObj("Pack.Name",true,"qpack_name",1),
	new dblb_HeaderObj("Company",true,"company_name",1),
	};

	sqlstatem = "select origid,qpack_name,company_name from elb_quotation_package";
	srctext = kiboo.replaceSingleQuotes(recallpackname.getValue());
	if(itype == 1) sqlstatem += " where qpack_name like '%" + srctext + "%' or company_name like '%" + srctext + "%'";

	// show the quote-packages
	sql = sqlhand.als_mysoftsql();
	if(sql == null) return;
	Listbox newlb = lbhand.makeVWListbox_onDB(recallpacks_holder,quotepacks_lb_headers,"qpackages_lb",5,sql,sqlstatem);
	sql.close();

	if(newlb.getItemCount() == 0) return;

	newlb.setRows(10);
	dc_obj = new quotepack_dc_Listener();
	lbhand.setDoubleClick_ListItems(newlb, dc_obj);
}

void recallQuoteItems_clicker()
{
	if(global_loaded_quote.equals("")) return;
	recallQuote_popup.open(recallquote_btn);
}

void reallyRecallItems(String packorigid)
{
	if(global_loaded_quote.equals("")) return;
	
	if(!global_quote_status.equals(QTSTAT_NEW))
	{
		guihand.showMessageBox("This quotation is not NEW.. no more amendments");
		return;
	}

	qprec = quotehand.getQuotePackageRec(packorigid);
	if(qprec == null)
	{
		guihand.showMessageBox("Error retrieving quotation-package record..");
		return;
	}

	refquoteid = qprec.get("quotation_id");
	// load quoted-items in package and insert into current loaded quotation
	sqlstm = "select * from elb_quotation_items where quote_parent=" + refquoteid;
	qitems = sqlhand.gpSqlGetRows(sqlstm);
	if(qitems.size() == 0) return;
	for(dpi : qitems)
	{
		mysoftc = dpi.get("mysoftcode").toString();
		desc1 = dpi.get("description");
		desc2 = dpi.get("description2");
		curcode = dpi.get("curcode");
		Double sellingp = dpi.get("unitprice");
		quotehand.insertQuoteItem_Rec2(global_loaded_quote,mysoftc,desc1,desc2,curcode,sellingp,global_quote_version);
	}

	showQuoteItems(last_load_quoteitems_type); // refresh quote-items listbox
}
