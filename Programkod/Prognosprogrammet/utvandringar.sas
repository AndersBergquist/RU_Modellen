proc ds2;
	package &prglib..rumprg_utvandringar / overwrite=yes;
		dcl package hash h_utvandringsrisk();
		*dcl package hash h_utvandringarPrognos();
		dcl char(8) userdata;
		dcl integer region alder ar;
		dcl char(50) kon;
		dcl double utvandringsrisk updateUtvandringar;

		method rumprg_utvandringar();
*			userdata=%tslit(&userdata);
		end;*rumprg_invandringar;

		method setup(char(50) iUtvRiskTabell);

			h_utvandringsrisk.keys([ar region kon alder]);
			h_utvandringsrisk.data([utvandringsrisk]);
			h_utvandringsrisk.dataset('{SELECT ar, region, kon, alder, (sum(utvandringsRisk,addUtvRisk)*multUtvRisk) AS utvandringsRisk FROM ' || strip(iUtvRiskTabell) || '}');
			h_utvandringsrisk.defineDone();

		*	h_utvandringarPrognos.keys([ar, region, kon, alder]);
		*	h_utvandringarPrognos.data([updateUtvandringar]);
		*	h_utvandringarPrognos.defineDone();

		end;*setup;

		method getUtvandringar(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iBefolkning) returns double;
			dcl double utvandringar;
			dcl integer rc;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;

*			rc=h_utvandringarPrognos.find([ar, region, kon, alder],[updateUtvandringar]);
*			if rc=0 then utvandringar=updateUtvandringar;
*			else do;
				h_utvandringsrisk.find([ar region kon alder],[utvandringsrisk]);
				utvandringar=utvandringsrisk*iBefolkning;
*				updateUtvandringar=utvandringar;
*				h_utvandringarPrognos.add([ar, region, kon, alder],[updateUtvandringar]);
*			end;
			return utvandringar;
		end;


		method updateUtvandringar(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iAntalUtvandringar);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			updateUtvandringar=iAntalutvandringar;
		*	h_utvandringarPrognos.replace([ar, region, kon, alder],[updateUtvandringar]);
		end;*updateUtflyttade;

	endpackage;
run;quit;