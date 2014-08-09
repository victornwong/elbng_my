import groovy.sql.Sql;

class LookupTree
{
	Treechildren tobeshown;
	Sql mainSql;

	void LookupTree(Treechildren thechild, String queryname, boolean showexpired)
	{
		mainSql = Sql.newInstance("jdbc:mysql://localhost:3306/miris", "mirisproj", "kingkong",
			"org.gjt.mm.mysql.Driver");
			
		sqlstatement = "SELECT * from lookups where myparent='" + queryname + "'";
		List catlist = mainSql.rows(sqlstatement);

		tobeshown = thechild;

		fillMyTree(thechild, catlist, showexpired);
		
		mainSql.close();

	}

	// showexpired : used in normal operation, if showexpired = 0, don't show, user cannot select
	// showexpired = 1 , show expired, during lookup configuratin only
	void fillMyTree(Treechildren tchild, List prolist, boolean showexpired)
	{
		for (opis : prolist)
		{
			if(opis.get("expired") == true && showexpired == false) continue;
			
			Treeitem titem = new Treeitem();
			Treerow newrow = new Treerow();
			Treecell newcell1 = new Treecell();
			Treecell newcell2 = new Treecell();

			lookname = opis.get("name");
			disptext = opis.get("disptext");
	
			sqlqueryline = "select * from lookups where myparent='" + lookname + "'";
			List subchild = mainSql.rows(sqlqueryline);

			newcell1.setLabel(lookname);
			
			if(subchild.size() > 0)
			{
				Treechildren newone = new Treechildren();
				newone.setParent(titem);
				fillMyTree(newone,subchild,showexpired);
		
				//newcell1.setLabel("${subchild.size()} ${opis[2]}");
			}

			expiredstr = "";
			
			if(opis.get("expired") == true)
				expiredstr = "[EXPIRED] ";

			newcell2.setLabel(expiredstr + disptext);
			
			newcell1.setParent(newrow);
			newcell2.setParent(newrow);
			newrow.setParent(titem);
			titem.setParent(tchild);
		}

	}

	void myShowTreeChildren()
	{
		alert(tobeshown);
	}

}
// end of class LookupTree

