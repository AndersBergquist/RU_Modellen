data work.REGIONNAMN;
	set &regInd..REGIONNAMN;
run;
data work.REGIONINDELNING;
	set &regInd..REGIONINDELNING;
run;
data work.KOMMUNER;
	set &regInd..kommuner;
run;

data &userdata..rum_parameters;
	set styrparm.RUM_PARAMETERS;
run;

proc copy in=&regInd out=work;
run;
proc copy in=&styrparm out=&userdata;
run;
proc ds2;
	data _null_;
	dcl package &prglib..rumprg_skapaProjekt pin();

	method run();
		pin.makeProject();
	end;
run;quit;

data &projParm..nybyggnation;
	set &userdata..RUM_NYBYGGNAD_KOM;
run;
data &projParm..utglesningstal;
	set &userdata..RUM_UTGLESNINGSTAL_KOM;
run;
data &projParm..Dodsrisker;
	set &userdata..RUM_DODSRISKER;
run;
data &projParm..Dodsrisker_kommun;
	set &userdata..RUM_DODSRISKER_KOM;
run;
data &projParm..Fodelsetal;
	set &userdata..RUM_FODELSETAL;
run;
data &projParm..Fodelsetal_kommun;
	set &userdata..RUM_Fodelsetal_kom;
run;
data &projParm..Flyttrisker;
	set &userdata..RUM_FLYTTRISKER;
run;
data &projParm..Flyttrisker_tid;
	set &userdata..RUM_FLYTTRISKER_tid;
run;
data &projParm..Flyttrisker_kommun;
	set &userdata..RUM_FLYTTRISKER_KOM;
run;
data &projParm..Flyttrisker_kom_tid;
	set &userdata..RUM_FLYTTRISKER_KOM_tid;
run;
data &projParm..Flyttrisker_kommun_Region;
	set &userdata..RUM_FLYTTRISKER_KOM_REG;
run;
data &projParm..Flyttrisker_kom_Reg_tid;
	set &userdata..RUM_FLYTTRISKER_KOM_REG_tid;
run;
data &projParm..Inflyttarandel;
	set &userdata..RUM_INFLYTTANDEL_KOM;
run;
data &projParm..Invandringar;
	set &userdata..RUM_INVANDRINGAR;
run;
data &projParm..Invandringar_kommun;
	set &userdata..RUM_Invandringar_kom;
run;
data &projParm..Utvandringar;
	set &userdata..RUM_UTVANDRINGSRISKER;
run;
data &projParm..Utvandringar_kommun;
	set &userdata..RUM_UTVANDRINGSRISKER_KOM;
run;
