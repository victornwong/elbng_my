
// Popup - update quote-item clicker
// updateQuoteItem_Value( java.lang.String, float, float, java.lang.String, java.lang.String, java.lang.String, java.lang.String )
void updateQuoteItem_clicker()
{
	if(global_loaded_quote.equals("")) return; // no quote loaded, return lor

	if(!global_quote_status.equals(QTSTAT_NEW))
	{
		guihand.showMessageBox("Quotation already committed, cannot update..");
		return;
	}

	// 28/02/2012: check if latest version..
	if(!currentQuoteVersion(global_loaded_quote,global_selected_versiontoload))
	{
		guihand.showMessageBox("Not current version.. cannot update items");
		return;
	}

	Object[] jkl = { qi_unitprice, qi_quantity, qi_discount, qi_lor, qi_description, qi_description2 };
	dt = getString_fromUI(jkl);

	if(dt[0].equals("")) dt[0] = "0";
	if(dt[1].equals("")) dt[1] = "1";
	if(dt[2].equals("")) dt[2] = "0";

/*
	unitprice = kiboo.replaceSingleQuotes(qi_unitprice.getValue());
	quantity = kiboo.replaceSingleQuotes(qi_quantity.getValue());
	discount = kiboo.replaceSingleQuotes(qi_discount.getValue());
	lor = kiboo.replaceSingleQuotes(qi_lor.getValue());
	desc1 = kiboo.replaceSingleQuotes(qi_description.getValue());
	desc2 = kiboo.replaceSingleQuotes(qi_description2.getValue());
	if(unitprice.equals("")) unitprice = "0";
	if(quantity.equals("")) quantity = "1";
	if(discount.equals("")) discount = "0";
*/

	if(!global_selected_quoteitem.equals("")) // it's an update
	{
		//quotehand.updateQuoteItem_Value(global_selected_quoteitem,unitprice,discount,quantity,lor,desc1,desc2);
		quotehand.updateQuoteItem_Value(global_selected_quoteitem, dt[0], dt[2], dt[1], dt[3], dt[4], dt[5]);
	}
	else // it's a new item insert
	{
		dunitp = Double.parseDouble(dt[0]);
		quotehand.insertQuoteItem_Rec2(global_loaded_quote, "0", dt[4], dt[5], qt_curcode.getSelectedItem().getLabel(), dunitp, global_quote_version);
	}

	showQuoteItems(last_load_quoteitems_type); // refresh quote-items listbox
	clearQuoteItem_inputs();
}

// quote_items_div quote_items_lb global_loaded_quote global_quote_status
// tests_description_lb testparameters_column global_selected_mysoftcode
void addQuoteItems_clicker()
{
	if(global_loaded_quote.equals("")) return;
	if(!global_quote_status.equals(QTSTAT_NEW))
	{
		guihand.showMessageBox("Quotation already committed, cannot add item.");
		return;
	}

	if(!lbhand.check_ListboxExist_SelectItem(testparameters_column,"tests_description_lb")) return;

	// check if mysoftcode already in list - either don't insert or add elb_Quotation_Items.quantity
	if(lbhand.ExistInListbox(quote_items_lb,global_selected_mysoftcode,1))
	{
		guihand.showMessageBox("Item is already in your quotation.. update quantity instead");
		return;
	}

	// 27/02/2012: if older version loaded, cannot add any items
	if(!global_version_edit)
	{
		guihand.showMessageBox("Not current quotation version, cannot add item..");
		return;
	}

	stkrec = sqlhand.getMySoftMasterProductRec(global_selected_mysoftcode);
	if(stkrec == null) return;

	curcode = qt_curcode.getSelectedItem().getLabel();

	quotehand.insertQuoteItem_Rec2(global_loaded_quote, global_selected_mysoftcode, 
 		stkrec.get("Description"), stkrec.get("Description2"), curcode, stkrec.get("Selling_Price"),global_quote_version);

	showQuoteItems(last_load_quoteitems_type); // refresh quote-items listbox
}

// delete a quote-item clicker
void deleteQuoteItem_clicker()
{
	//if(global_loaded_quote.equals("")) return;
	//if(global_selected_quoteitem.equals("")) return;

	if(!global_quote_status.equals(QTSTAT_NEW))
	{
		guihand.showMessageBox("Quotation already committed, cannot delete anything.. too bad");
		return;
	}

	// 28/02/2012: check if latest version..
	if(!currentQuoteVersion(global_loaded_quote,global_selected_versiontoload))
	{
		guihand.showMessageBox("Not current version.. cannot delete items");
		return;
	}

	selcnts = quote_items_lb.getSelectedCount();
	if(selcnts > 0)
	{
		selitems = quote_items_lb.getSelectedItems();
		// loop and delete selected quote-items
		for(dpi : selitems)
		{
			selorigid = dpi.getLabel();
			quotehand.deleteQuoteItem_Rec(selorigid);
		}
		showQuoteItems(last_load_quoteitems_type); // refresh quote-items listbox
		clearQuoteItem_inputs();
	}
}
