proc ds2;
	package &prglib..rumprg_Doda / overwrite=yes;
		dcl private integer ar region alder;
		dcl private double dodstal dodsrisk addDtal multDtal scbDodstal scbDodsrisk befolkning_jan antalDoda;
		dcl private char(50) kon;
		dcl package hash h_dodsrisker();
		dcl package hash h_antalDoda();


		method rumprg_doda();
		end;*rumprg_doda - konstruktor;

		method setup(char(50) iDriskTabell);
			h_dodsrisker.keys([ar region kon alder]);
			h_dodsrisker.data([ar region kon alder dodstal dodsrisk addDtal multDtal scbDodstal scbDodsrisk]);
			h_dodsrisker.dataset('{select * from ' || iDriskTabell || '}');
			h_dodsrisker.defineDone();

			h_antalDoda.keys([ar region kon alder]);
			h_antalDoda.data([antalDoda]);
			h_antalDoda.defineDone();
		end;*setup;

		method setAntalDoda(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iBefolkning_jan);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_dodsrisker.find([ar region kon alder],[ar region kon alder dodstal dodsrisk  addDtal multDtal scbDodstal scbDodsrisk]);
			antalDoda=iBefolkning_jan*sum(dodsrisk,addDtal)*multDtal;
			h_antalDoda.ref([ar region kon alder],[antalDoda]);

		end; *setDoda;

		method getAntalDoda(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			dcl integer rc;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;

			rc=h_antalDoda.check([ar region kon alder]);
			if rc=0 then do;
				h_antalDoda.find([ar region kon alder],[antalDoda]);*Finns det i databasen hämtas det.;
			end;
			else do;
				antalDoda=.;
			end;

		return antalDoda;
		end; *getDoda utan möjlighet till beräkning;
		method getAntalDoda(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iBefolkning_jan) returns double;
			dcl integer rc;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;

			rc=h_antalDoda.check([ar region kon alder]);
			if rc=0 then do;
				h_antalDoda.find([ar region kon alder],[antalDoda]);*Finns det i databasen hämtas det.;
			end;
			else do;
				setAntalDoda(iAr, iRegion, iKon, iAlder, iBefolkning_jan);*Annars beräknas det.;
			end;
		return antalDoda;
		end;*getDoda med möjlighet till beräkning;

		method updateAntalDoda(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iAntalDoda);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			antalDoda=iAntalDoda;
			h_antalDoda.replace([ar, region, kon, alder],[antalDoda]);
		end;*updateBefolkning;

	endpackage ;
run;quit;
