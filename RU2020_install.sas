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

libname datalib "&m_datalib";
libname prglib "&m_prglib";
libname userdata "&m_userdata";
libname regInd XLSX "&m_regInd"; *Som standard hänvisas till xl-fil. XLSX tas bort vid t.ex. serverinstallation med AMO.;

%let datalib=datalib;
%let prglib=prglib;
%let userdata=userdata;
%let regInd=regInd;
options  mstored  sasmstore=&prglib;

filename iNytto "&instLib\Programkod\Nyttoprogram";
filename iProg "&instLib\Programkod\Prognosprogrammet";
filename iDataL "&instLib\Programkod\Dataladdning";
filename iPinit "&instLib\Programkod\Projektinitiering";
filename iRedov "&instLib\Programkod\Resultatredovisning";

%include iNytto('pxweb_Gemensamma_Metoder.sas');
%include iNytto('pxweb_table_update_date.sas');
%include iNytto('pxweb_getMetaData.sas');
%include iNytto('pxweb_makeJsonFraga.sas');
%include iNytto('pxweb_Skapa_Output_Tabell.sas');
%include iNytto('pxweb_skapaStmtFraga.sas');
%include iNytto('pxweb_getData.sas');
%include iNytto('pxwebToSAS4.sas');
%include iNytto('progParam.sas');

%include iProg('Befolkning.sas');
%include iProg('Doda.sas');
%include iProg('Fodda.sas');
%include iProg('inrikesFlyttningar.sas');
%include iProg('Invandringar.sas');
%include iProg('utvandringar.sas');
%include iProg('Resultat.sas');
%include iProg('FR_Modellen.sas');
%include iProg('Utjämning.sas');
%include iProg('kommunalInflyttningsPotential.sas');
%include iProg('kommunalInflyttning.sas');
%include iProg('rumprg_RAP_REG.sas');
%include iProg('Kom_Modellen.sas');

%include iDataL('SCB_FODDA.sas');
%include iDataL('Flyttningar68.sas');
%include iDataL('Flyttningar97.sas');
%include iDataL('SCB_DODA.sas');
%include iDataL('BefolkningNy.sas');
%include iDataL('SCB_BEFOLKNING.sas');
%include iDataL('SCB_NYBYGGNATION.sas');
%include iDataL('SCB_RIKTAD_FLYTT_LAN.sas');
%include iDataL('SCB_PROGNOSER_DETALJ.sas');
%include iDataL('SCB_PROGNOSER_DODSTAL.sas');
%include iDataL('SCB_PROGNOSER_FODDA.sas');
%include iDataL('SCB_PROGNOSER_FODELSETAL.sas');
%include iDataL('SCB_PROGNOSER_SAMMANFATTNING.sas');
%include iDataL('rummac_read_Rikt_Kommunflytt.sas');
%include iDataL('SCB_TABORT.sas');
%include iDataL('SCB_LADDA.sas');
%include iDataL('rummac_read_Rikt_Kommunflytt - med övrigt.sas');
/* Nya dataladdningen */
%include iDataL('run_scb_hamta_data.sas');

%include iPinit('prog_flyttaTabeller.sas');
%include iPinit('prog_indelningar.sas');
%include iPinit('rumprg_skattflyttMatriskom.sas');
%include iPinit('Flyttmatris_FR.sas');
%include iPinit('Flyttmatris_kom.sas');
%include iPinit('SCB_DATA.sas');
%include iPinit('SCB_DATA_Prognosregionen.sas');
%include iPinit('dodsRisker.sas');
%include iPinit('fodelseTal.sas');
%include iPinit('flyttRisker.sas');
%include iPinit('Invandringsandel.sas');
%include iPinit('utvandringsRisker.sas');
%include iPinit('nyByggnad.sas');
%include iPinit('inflyttarFordelning.sas');
%include iPinit('utglesningstal.sas');
%include iPinit('skapaProjekt.sas');

%include iRedov('euroStatStandardBefolkning.sas');
%include iRedov('kombResTabell.sas');
%include iRedov('skaparLivslängdstabell.sas');
%include iRedov('summeradFruktsamhet.sas');
%include iRedov('nettoFolkOkning.sas');
%include iRedov('resultatPrognosregionen.sas');
%include iRedov('skapaRapportTabeller.sas');

run;
