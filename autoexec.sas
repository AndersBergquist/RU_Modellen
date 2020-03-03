/* Inga ändringar här. De görs i slutet av filen. */
%macro setInstLib;
	%global instLib;
    %if %symexist(_clientapp) %then %do;
        %if &_clientapp = 'SAS Studio' %then %do;
            %let instLib=%sysfunc(tranwrd(%sysfunc(dequote(&_sasprogramfile)), %scan(%unquote(&_sasprogramfile),-1,/), ));	    
	%end;
	%else %if &_clientapp = 'SAS Enterprise Guide' %then %do;
	    %let instLib=%sysfunc(tranwrd(%sysfunc(dequote(&_CLIENTPROJECTPATH)), %sysfunc(dequote(&_CLIENTPROJECTname)), ));
	%end;
    %end;
    %else %do;
        %let instLib=%sysfunc(tranwrd(%sysfunc(dequote(%sysget(SAS_EXECFILEPATH))), %scan(%unquote(%sysget(SAS_EXECFILEPATH)),-1,\), ));
    %end;
%mend setInstLib;
%setInstLib;
run;

%let m_datalib=%sysfunc(cat(&instLib,%sysfunc(dequote("pnosdata"))));
%let m_prglib=%sysfunc(cat(&instLib,%sysfunc(dequote("pnosprg"))));
%let m_userdata=%sysfunc(cat(&instLib,%sysfunc(dequote("userdata"))));
%let m_regInd=%sysfunc(cat(&instLib,%sysfunc(dequote("Manuell_justering\Regionindelning.xlsx"))));
%let m_styrParm=%sysfunc(cat(&instLib,%sysfunc(dequote("Manuell_justering\styrvariabler.xlsx"))));
%let m_projParm=%sysfunc(cat(&instLib,%sysfunc(dequote("Manuell_justering\projektParametrar.xlsx"))));

run;
/*Default värden 
libname pnosdata "m_datalib";
libname pnosprg "m_prglib";
libname userdata "&userdata";
libname regInd XLSX "&m_regInd";
libname styrparm  XLSX "&m_styrParm";
libname projParm XLSX "&m_projParm";

 Default värden slut */

/*Alla ändringar görs här*/

libname datalib "&m_datalib";
libname prglib "&m_prglib";
libname userdata "&m_userdata";
libname regInd XLSX "&m_regInd"; *Som standard hänvisas till xl-fil. XLSX tas bort vid t.ex. serverinstallation med AMO.;
libname styrparm  XLSX "&m_styrParm"; *Som standard hänvisas till xl-fil. XLSX tas bort vid t.ex. serverinstallation med AMO.;
libname projParm XLSX "&m_projParm"; *Som standard hänvisas till xl-fil. XLSX tas bort vid t.ex. serverinstallation med AMO.;

run;
/*Inga ändringar under denna linjer*/

%let datalib=datalib;
%let prglib=prglib;
%let userdata=userdata;
%let regInd=regInd;
%let styrparm=styrparm;
%let projParm=projParm;
options  mstored  sasmstore=&prglib;

run;


