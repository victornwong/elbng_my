// Support funcs for anyReservator.zul
// Written by Victor Wong 18/08/2014

void drawBigCalendar(Datebox idate, Label imonlbl, Component idiv, String igid, Object idivcliker)
{
	glob_prev_date = idate.getValue(); // save for later
	cellheight = "60px";

	if(!igid.equals("")) // remove any previous calendar by id
	{
		kk = idiv.getFellowIfAny(igid);
		if(kk != null) kk.setParent(null);
	}

	Grid mgrid = new Grid(); mgrid.setParent(idiv);
	mgrid.setSclass("GridLayoutNoBorder");
	if(!igid.equals("")) mgrid.setId(igid);

	mrows = new Rows(); mrows.setParent(mgrid);

	krow = new Row(); krow.setParent(mrows);
	krow.setStyle("background:#2E2E2D");

	String[] weekname = { "SUN", "MON", "TUE", "WED", "THU", "FRI", "SAT" };
	// Draw week-day name
	for(i=0; i<7; i++)
	{
		dtv = new Div(); dtv.setParent(krow);
		dtv.setStyle("background:#EF1111"); //dtv.setHeight("40px");

		dstr = new Label();
		dstr.setParent(dtv); dstr.setSclass("subhead2"); dstr.setStyle("padding:10px");
		dstr.setValue(weekname[i]);
	}

	Calendar cal = Calendar.getInstance();
	cal.setTime(idate.getValue());
	cal.set(Calendar.DAY_OF_MONTH, 1);
	tstart = dtf2.format(cal.getTime());

	sday = cal.get(Calendar.DAY_OF_WEEK); // get 1st of the month falls on which day
	cal.set(Calendar.DAY_OF_MONTH, cal.getActualMaximum(Calendar.DAY_OF_MONTH) ); // get max days per month
	tend = dtf2.format(cal.getTime());
	eday = cal.get(Calendar.DAY_OF_MONTH) + 1;

	jsqlstm = "select distinct convert(datetime,convert(varchar,res_start,112),112) as rdate, count(origid) as rcount " +
	"from elb_reservator " +
	"where res_start between '" + tstart + "' and '" + tend + "' " +
	"group by convert(datetime,convert(varchar,res_start,112),112)";
	debugbox.setValue(jsqlstm);

	krow = new Row(); krow.setParent(mrows);
	krow.setStyle("background:#2E2E2D");

	// empty days padding
	for(k=1;k<sday;k++)
	{
		dtv = new Div(); dtv.setParent(krow);
		//dtv.setStyle("background:#3E6179");
		dtv.setHeight(cellheight);
	}

	for(i=1; i<eday; i++) // show all dates
	{
		dtv = new Div(); dtv.setParent(krow);
		dtv.setStyle("background:#3E6179"); dtv.setHeight(cellheight);
		if(idivcliker != null) dtv.addEventListener("onDoubleClick", idivcliker );

		dtlb = new Label();
		dtlb.setParent(dtv); dtlb.setSclass("subhead1"); dtlb.setStyle("padding:5px");
		dtlb.setValue(i.toString()); // + " : " + (sday%7).toString());
		
		if(sday%7 == 0) // set to new row when hit "SAT"
		{
			krow = new Row(); krow.setParent(mrows);
			krow.setStyle("background:#2E2E2D");
		}
		sday++;
	}

	// show month and year label
	SimpleDateFormat monyr = new SimpleDateFormat("MMM yyyy");
	imonlbl.setValue(monyr.format(idate.getValue()));
}
