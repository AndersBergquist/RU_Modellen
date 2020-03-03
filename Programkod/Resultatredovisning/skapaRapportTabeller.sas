proc ds2;
	package &prglib..rumprg_skapaRapportTabeller / overwrite=yes ;
		dcl package &prglib..rumprg_euroStatStdBef stdbef();
		dcl package &prglib..rumprg_livstabell ltab();
		dcl package &prglib..rumprg_livstabell ltabKOM();
		dcl package &prglib..rumprg_kombResTabell kombi();
		dcl package &prglib..rumprg_kombResTabell kombiKOM();
		dcl package &prglib..rumprg_sumFrukt sumFrukt();
		dcl package &prglib..rumprg_sumFrukt sumFruktKOM();
		dcl package &prglib..rumprg_nettoTal netto();
		dcl package &prglib..rumprg_nettoTal nettoKOM();
		dcl package &prglib..rumprg_rap_preg rap_preg();
		dcl varchar(8) userdata projdata;

		method rumprg_skapaRapportTabeller();
		end;*rumprg_skapaRapportTabeller;

		method run();
			projdata=%tslit(&datalib);
			userdata=%tslit(&userdata);	

			stdbef.run();
			kombi.run('SCB_BEFOLKNING','RUM_FR_RESULTAT', 'RUM_REGIONNAMN', 'RUM_RAP_FR_KOMBRESULTAT');
			kombiKOM.run('SCB_BEFOLKNING_KOM','RUM_KOM_RESULTAT', 'RUM_KOMMUNER', 'RUM_RAP_KOM_KOMBRESULTAT');
			ltab.run('RUM_DODSRISKER','RUM_REGIONNAMN','RUM_RAP_FR_LIVSTABELL');
			ltabKOM.run('RUM_DODSRISKER_KOM','RUM_KOMMUNER','RUM_RAP_KOM_LIVSTABELL');
			sumFrukt.run('RUM_FODELSETAL','RUM_REGIONNAMN','RUM_RAP_FR_SUMFRUKT');
			sumFruktKOM.run('RUM_FODELSETAL_KOM','RUM_KOMMUNER','RUM_RAP_KOM_SUMFRUKT');
			netto.run('RUM_RAP_FR_KOMBRESULTAT_SUM','RUM_RAP_FR_NETTORES');
			nettokom.run('RUM_RAP_kom_KOMBRESULTAT_SUM','RUM_RAP_KOM_NETTORES');
			rap_preg.run(strip(userdata) || '.RUM_KOMMUNER',strip(userdata) || '.rum_kom_kom_flyttmatris',strip(userdata) || '.RUM_FR_FLYTTMATRIS',strip(userdata) || '.RUM_KOM_RESULTAT', strip(userdata) || '.SCB_BEFOLKNING_PREG', strip(userdata) || '.RUM_PREG_RESULTAT',strip(userdata) || '.RUM_RAP_PREG_KOMBRESULTAT');

		end;*run;

	endpackage;
run;quit;
/*
proc ds2;
	data _null_;
		dcl package &prglib..rumprg_skapaRapportTabeller ct();

		method run();
			ct.run();
		end;
	enddata;
run;quit;
		
*/
