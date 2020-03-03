proc ds2;
	package &prglib..rumprg_fodda / overwrite=yes;
		dcl package hash h_antalFodda();
		dcl package hash h_fodelsetal();
		dcl package hash h_antalFoddaModernsAlder();
		declare package &prglib..rumprg_progParam as styr();

		dcl private integer ar region alderModer;
		dcl private double antalFodda fodelsetal addFtal multFtal SCB_fodelsetal pojkAndel antalFoddaK befolkning_jan;
		dcl private char(8) userdata;
		dcl private char(50) kon;
		dcl package hash h_regioner();
		dcl package hiter hi_regioner('h_regioner');
		dcl package hash h_output();

		method rumprg_fodda();
			dcl package sqlstmt stmtPojkAndel();
			userdata=%tslit(&userdata);

			h_antalFodda.keys([ar region kon]);
			h_antalFodda.data([ar region kon antalFodda]);
			h_antalFodda.defineDone();

			pojkAndel=styr.getVardeDouble('pojkAndel');
*			stmtPojkAndel.prepare('select pojkAndel from ' || strip(userdata) || '.rum_parameters');
*			stmtPojkAndel.execute();
*			stmtPojkAndel.bindresults([pojkAndel]);
*			stmtPojkAndel.fetch();

		end;*rumprg_fodda;

		method setup(char(50) iFTalTabell);
			h_fodelsetal.keys([ar region alderModer]);
			h_fodelsetal.data([fodelsetal addFtal multFtal SCB_fodelsetal]);
			h_fodelsetal.dataset('{select * from ' || iFTalTAbell || ' }');
			h_fodelsetal.defineDone();
		end;*setup;

		method setAntalFodda(integer iAr, integer iRegion, integer iAlderModer, double iBefolkning);
			dcl integer rc;
			dcl double antalFoddaKon;
			ar=iAr;
			region=iRegion;
			alderModer=iAlderModer;
			h_fodelsetal.find([ar region alderModer],[fodelsetal addFtal multFtal SCB_fodelsetal]);
			do kon='män', 'kvinnor';
				if kon='män' then do;
					antalFoddaKon=iBefolkning*sum(fodelsetal,addFtal)*multFtal*pojkAndel;
				end; else do;
					antalFoddaKon=iBefolkning*sum(fodelsetal,addFtal)*multFtal*(1-pojkAndel);
				end;
				rc=h_antalFodda.check([ar region kon]);
				if rc=0 then do;
					h_antalFodda.find([ar region kon],[ar region kon antalFodda]);
					antalFodda=sum(antalFoddaKon,antalFodda);
				end;
				else do;
					antalFodda=antalFoddaKon;
				end;
				h_antalFodda.replace([ar region kon],[ar region kon antalFodda]);
			end;*kon;
		end; *setAntalFodda;

		method getAntalFodda(integer iAr, integer iRegion, char(50) iKon) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;

			h_antalFodda.find([ar region kon],[ar region kon antalFodda]);
		return antalFodda;
		end; *getAntalFodda utan uträkning;

		method skrivTillTabell(char(132) tabellFil);
			h_antalFodda.output(tabellFil);
		end; *skrivTillTabell;

		method updateAntalFodda(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iAntalFodda);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			antalFodda=iAntalFodda;
			if iAlder=0 then h_antalFodda.replace([ar, region, kon],[ar region kon antalFodda]);
		end;*updateBefolkning;

	endpackage ;
run;quit;