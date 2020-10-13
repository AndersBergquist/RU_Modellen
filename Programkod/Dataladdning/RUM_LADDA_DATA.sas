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
filename autoexec "&instLib";
%include autoexec('autoexec.sas');

data work.apivarSCB;
	set apivar.scb;
run;

proc ds2;
	data _null_;
		declare package &prglib..rumprg_GET_SCBDATA getSCB();

		method run();
			getSCB.run();
		end;
	enddata;
run;quit;

proc datasets lib=work nolist;
	delete apivarSCB;
run;
