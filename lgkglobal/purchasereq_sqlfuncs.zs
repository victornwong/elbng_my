import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import groovy.sql.Sql;
import org.zkoss.zk.ui.*;

/*
Purpose: Purchase requisition SQL related functions we put them here
Written by : Victor Wong
Date : 14/06/2010

Notes:

*/

String lgk_makePurchaseReq_ID(String iorigid)
{
	return PURCHASE_REQ_PREFIX + iorigid;
}

String lgk_makePurchaseOrder_ID(String iwhat)
{
	return PO_PREFIX + iwhat;
}

// Database func: to get a rec from SupplierDetail - based on SupplierDetail.ID
Object getSupplier_Rec(String isuppid)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from SupplierDetail where ID=" + isuppid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: to get a rec from SupplierDetail - based on SupplierDetail.ID
Object getSupplier_Rec_ByCode(String isuppcode)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from SupplierDetail where APCode='" + isuppcode + "'";
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

Object getPurchaseReq_Rec(String iwhich)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from PurchaseRequisition where origid=" + iwhich;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}


// Insert a new purchase-req into db
// iapcode = supplier AP code , isuppname = supplier name, idatecreate = usually today's date, iusername = who's PR
void insertPurchaseReq(String iapcode, String isuppname, String idatecreate,String iusername)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;

	thecon = sql.getConnection();
	
	pstmt = thecon.prepareStatement("insert into PurchaseRequisition (APCode,SupplierName,datecreated,duedate,approvedate,priority,pr_status,notes,deleted,username)" +
		"values (?,?,?,?,?,?,?,?,?,?)");
		
	pstmt.setString(1,iapcode);
	pstmt.setString(2,isuppname);
	pstmt.setString(3,idatecreate);
	pstmt.setString(4,"");
	pstmt.setString(5,"");
	pstmt.setString(6,"NORMAL");
	pstmt.setString(7,"PENDING");
	pstmt.setString(8,"");
	pstmt.setInt(9,0);
	pstmt.setString(10,iusername);
	
	pstmt.executeUpdate();
	sql.close();
}

// Database func: insert a new item into PurchaseReq_Items
void insertPurchaseReqItems(String iprorigid, String idescription, String iunitprice, String iquantity, String imysoftcode)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;

	thecon = sql.getConnection();
	
	pstmt = thecon.prepareStatement("insert into PurchaseReq_Items (pr_parent_id,description,unitprice,quantity,curcode,mysoftcode) values (?,?,?,?,?,?)");
		
	pstmt.setInt(1,Integer.parseInt(iprorigid));
	pstmt.setString(2,idescription);
	pstmt.setFloat(3,Float.parseFloat(iunitprice));
	pstmt.setInt(4,Integer.parseInt(iquantity));
	pstmt.setString(5,"MYR");	// default to currency MYR for now
	pstmt.setString(6,imysoftcode);
	
	pstmt.executeUpdate();
	sql.close();

}

// Database func: Get purchase-req item rec
Object getPurchaseReqItem_Rec(String iorigid)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from PurchaseReq_Items where origid=" + iorigid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: set PurchaseRequisition.pr_status
void setPR_Status(String iorigid, String iwhat)
{
	if(iwhat.equals("") || iorigid.equals("")) return;

	sql = lgk_mysoftsql();
	if(sql == null ) return;
	sqlstm = "update PurchaseRequisition set pr_status='" + iwhat + "' where origid=" + iorigid;
	sql.execute(sqlstm);
	sql.close();
}

// database func: toggle purchaserequisition.deleted flag
void togglePR_Deleted(String iorigid, String iwhat)
{
	if(iwhat.equals("") || iorigid.equals("")) return;

	sql = lgk_mysoftsql();
	if(sql == null ) return;
	sqlstm = "update PurchaseRequisition set deleted=" + iwhat + " where origid=" + iorigid;
	sql.execute(sqlstm);
	sql.close();
}

// tblStockInMaster / Detail DB funcs
// Database func: get rec from tblStockInMaster by tblStockInMaster.Id
Object getStockInMaster_rec(String theid)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from tblStockInMaster where Id=" + theid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: get rec from tblStockInMaster by tblStockInMaster.vouchernumber
Object getStockInMaster_ByVoucher(String thevn)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from tblStockInMaster where VoucherNumber='" + thevn + "'";
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// Database func: get rec from tblStockInDetail by Id
Object getStockInDetail_Rec(String theid)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from tblStockInDetail where Id=" + theid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}
// ENDOF tblStockInMaster / Detail DB funcs

// POPHeader / POP_detail DB funcs

// Database func: get rec from POPHeader by Id
Object getPO_byid(String theid)
{
	retval = null;
	sql = lgk_mysoftsql();
	if(sql == null) return null;
	sqlstm = "select * from popheader where id=" + theid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}

// ENDOF POPHeader / pop_header funcs
