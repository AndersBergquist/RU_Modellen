libname projParm XLSX "&instLib.Manuell_justering\projektParametrar.xlsx";
proc copy in=&styrparm out=&userdata;
run;
data &userdata..RUM_NYBYGGNAD_KOM;
	set projparm.nybyggnation;
run;
data &userdata..RUM_UTGLESNINGSTAL_KOM;
	set &projParm..utglesningstal;
run;
data &userdata..RUM_DODSRISKER;
	set projparm.Dodsrisker;
run;

data &userdata..RUM_DODSRISKER_KOM;
	set projparm.Dodsrisker_kommun;
run;

data &userdata..RUM_FODELSETAL;
	set projparm.Fodelsetal;
run;

data &userdata..RUM_FODELSETAL_KOM;
	set projparm.Fodelsetal_kommun;
run;

data &userdata..RUM_FLYTTRISKER;
	set projparm.Flyttrisker;
run;
data &userdata..RUM_FLYTTRISKER_TID;
	set projparm.Flyttrisker_tid;
run;

data &userdata..RUM_FLYTTRISKER_KOM;
	set projparm.Flyttrisker_kommun;
run;
data &userdata..RUM_FLYTTRISKER_KOM_TID;
	set projparm.Flyttrisker_kom_TID;
run;

data &userdata..RUM_FLYTTRISKER_KOM_REG;
	set projparm.Flyttrisker_kommun_Region;
run;

data &userdata..RUM_FLYTTRISKER_KOM_REG_TID;
	set projparm.Flyttrisker_kom_Reg_tid;
run;

data &userdata..RUM_INFLYTTARANDEL_KOM;
	set projparm.Inflyttarandel;
run;

data &userdata..RUM_INVANDRINGAR;
	set projparm.Invandringar;
run;

data &userdata..RUM_INVANDRINGAR_KOM;
	set projparm.Invandringar_kommun;
run;
data &userdata..RUM_INVANDRINGAR_KOM;
	set projparm.Invandringar_kommun;
run;

data &userdata..RUM_UTVANDRINGSRISKER;
	set projparm.Utvandringar;
run;

data &userdata..RUM_UTVANDRINGSRISKER_KOM;
	set projparm.Utvandringar_kommun;
run;

libname projparm clear;
run;

/* Flerregionala prognosen */
proc ds2;
	data _null_;
		dcl package &prglib..rumprg_fr_modellen fr(100);

		method run();
			fr.calc();
		end;

	enddata ;
run;quit;

/* Kommunprognosen */
proc ds2;
	data _null_;
		dcl package &prglib..rumprg_kom_modellen kom(100);

		method run();
		dcl integer utjamning utglesning;
			kom.calc();
		end;
	enddata ;
run;quit;


proc ds2;
	data _null_;
*		dcl package &prglib..rumprg_skapaJmfData jmf();
		method run();
*			jmf.skapa();
		end;
	enddata;
run;quit;

/* Rapporttabeller */
proc ds2;
	data _null_;
		dcl package &prglib..rumprg_skapaRapportTabeller ct();

		method run();
			ct.run();
		end;
	enddata;
run;quit;
		
