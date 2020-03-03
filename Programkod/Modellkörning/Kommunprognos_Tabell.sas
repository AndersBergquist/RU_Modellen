data _null_;
	set USERDATA.RUM_PARAMETERS;
	if varNamn='prognosLan' then do;
		call symputx ('m_progLan',varde);
	end;
	if varNamn='BASAR' then do;
		call symputx ('m_basAr',varde);
		call symputx ('m_lastAktAr', varde-1);
	end;
	if varNamn='sistaRedAr' then do;
		call symputx('m_sistaRedAr', varde);
	end;
run;

data work.RUM_RAP_KOM_KOMBRESULTAT_SUM1;
	set USERDATA.RUM_RAP_KOM_KOMBRESULTAT_SUM;
	befolkning_dec = round(befolkning_dec,100);

run;
proc report data=work.RUM_RAP_KOM_KOMBRESULTAT_SUM1(where=(&m_lastAktAr<=ar<=&m_sistaRedAr));
title "Prognostiserad befolkningsutveckling i &m_progLan.s kommuner, &m_basAr - &m_sistaRedAr";
	column ar  REGION,BEFOLKNING_DEC;
	define ar / group 'År';
	define REGION / across '' missing;
	define BEFOLKNING_DEC / analysis SUM '' missing format=nlnum11.;
run;

title;
proc datasets lib=work nolist;
	delete RUM_RAP_KOM_KOMBRESULTAT_SUM1;
run;