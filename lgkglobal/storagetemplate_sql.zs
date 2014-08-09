import java.util.*;
import java.text.*;

import java.sql.Connection;
import java.sql.DriverManager;
import javax.sql.DataSource;
import groovy.sql.Sql;

Object getLKTreeRec(String iwhich)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;

	retrec = null;
	sqlstatm = "select * from LKTree where idlookups = " + iwhich;
	retrec = sql.firstRow(sqlstatm);
	sql.close();
	return retrec;
}

Object getStorageTemplate_Rec(String iwhich)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;

	sqlstm = "select * from StorageTemplates where origid=" + iwhich;
	ckrec = sql.firstRow(sqlstm);
	sql.close();
	
	return ckrec;
}

// Check uniq based on template_code
boolean uniqStorageTemplate(String iwhich)
{
	retval = false;
	sql = lgk_mysoftsql();
	if(sql == null) return;

	sqlstm = "select template_code from StorageTemplates where template_code='" + iwhich + "'";
	ckrec = sql.rows(sqlstm);
	sql.close();
	
	if(ckrec.size() == 0) retval = true;
	
	return retval;

}

void saveStorageTemplate_Rec(String icode, String idisptext, String inotes, String itodate)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	
	sqlstm = "insert into StorageTemplates values " +
		"('" + icode + "','" + idisptext + "','" + inotes + "','" + itodate +"',0)";

	sql.execute(sqlstm);

	sql.close();
}

void updateStorageTemplate_Rec(String iorigid, String icode, String idisptext, String inotes, String itodate)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	
	sqlstm = "update StorageTemplates set template_code='" + icode + "'," +
	"template_disptext='" + idisptext + "', template_notes='" + inotes + "'," +
	"lastmodified='" + itodate +"' where origid=" + iorigid;

	sql.execute(sqlstm);
	sql.close();
}

void saveStorageField_Rec(String ifparent_template, String ifcode, String ifdisptext, String ifprefix, String ifsuffix, String ifsorter)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;

	sqlstm = "insert into StorageFields (field_code,field_disptext,sorter,prefix,suffix,parent_template,deleted) values " +
	"('" + ifcode + "','" + ifdisptext + "'," + ifsorter + ",'" + ifprefix + "','" + ifsuffix + "'," + ifparent_template + ",0)";
	
	sql.execute(sqlstm);
	sql.close();
}

// Get StorageField rec based on origid passed
Object getStorageField_Rec(String iwhich)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;
	
	sqlstm = "select * from StorageFields where origid=" + iwhich;
	retrec = sql.firstRow(sqlstm);
	sql.close();
	
	return retrec;

}

void updateStorageField_Rec(String iorigid, String icode, String idisptext, String iprefix, String isuffix, String isorter)
{
	sql = lgk_mysoftsql();
	if(sql == null) return;

	sqlstm = "update StorageFields set field_code='" + icode + "', field_disptext='" + idisptext + "', " +
	"prefix='" + iprefix + "', suffix='" + isuffix + "', sorter=" + isorter + " where origid=" + iorigid;

	sql.execute(sqlstm);
	sql.close();
}

