import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import groovy.sql.Sql;
import org.zkoss.zk.ui.*;

/*

Global SQL related functions we put them here
Written by : Victor Wong
Date : 28/01/2010

Notes:

-- Check ident value
 	dbcc checkident(tbl_mqb_data_templates)
 -- Reset ident value
 	dbcc checkident(tbl_mqb_data_templates, reseed, 0)

*/

/*
Open a JDBC to Mysoft database
Uses JTDS JDBC driver to access MS-SQL database and groovy.Sql
*/
Sql lgk_mysoftsql()
{
    try
    {
    dbstring = "jdbc:jtds:sqlserver://" + LGKDATABASESERVER + "/" + LGKDATABASENAME;

    return(Sql.newInstance(dbstring, "sa", "sa2007", "net.sourceforge.jtds.jdbc.Driver"));
    }
    catch (SQLException e)
    {
    }
}

// 18/10/2010: change documentstorage_db name as def in globaldefs.zs
Sql lgk_DocumentStorage()
{
    try
    {
    dbstring = "jdbc:jtds:sqlserver://" + LGKDATABASESERVER + "/" + FOXMAY_DOCUMENTSTORAGE_DB;
    return(Sql.newInstance(dbstring, "sa", "sa2007", "net.sourceforge.jtds.jdbc.Driver"));
    }
    catch (SQLException e)
    {
    }
}

// get company name based on ar_code passed
String lgk_getCompanyName(String tar_code)
{
	retval = "-Undefined-";
	
	sql = lgk_mysoftsql();
    if(sql == NULL) return;
	
	sqlstatem = "select customer_name from customer where ar_code='" + tar_code + "'";
	therec = sql.firstRow(sqlstatem);
	sql.close();
	
	if(therec != null)
		retval = therec.get("customer_name");
	
	return retval;
}

// get company customer record from mysoft.customer based on ar_code passed
Object lgk_getCompanyRecord(String tar_code)
{
	if(tar_code == null) return null;

	sql = lgk_mysoftsql();
    if(sql == NULL) return;
	
	sqlstatem = "select * from customer where ar_code='" + tar_code + "'";
	therec = sql.firstRow(sqlstatem);
	sql.close();
	
	return therec;
}

Object lgk_getMySoftMasterProductRec(String iwhich)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstatem = "select * from stockmasterdetails where id=" + iwhich;
	retval = sql.firstRow(sqlstatem);
	sql.close();
	return retval;
}

// get a rec from StockMasterDetails based on which ID/iwhich
Object lgk_getStockMasterDetails(String iwhich)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	sqlstatem = "select * from stockmasterdetails where id=" + iwhich;
	retval = sql.firstRow(sqlstatem);
	sql.close();
	return retval;
}


// get a rec from equipment table
Object lgk_getEquipmentRec(String iorigid)
{
	sql = lgk_mysoftsql();
	if(sql == NULL) return;
	sqlstat = "select * from Equipments where origid=" + iorigid;
	retval = sql.firstRow(sqlstat);
	sql.close();
	return retval;
}

// Database func: imagemap Mapper_Pos get a rec by origid
Object lgk_getMapperPos_Rec(String iorigid)
{
	if(iorigid.equals("")) return null;
	sql = lgk_mysoftsql();
    if(sql == NULL) return;
	sqlstm = "select * from Mapper_Pos where origid=" + iorigid;
	retval = sql.firstRow(sqlstm);
	sql.close();
	return retval;
}
