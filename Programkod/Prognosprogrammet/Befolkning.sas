proc ds2;
	package &prglib..rumprg_befolkning / overwrite=yes;
	dcl private integer ar lagAr region alder lagAlder;
	dcl private char(50) kon;
	dcl private double befolkning_dec befolkning_100;
	dcl package hash h_befolkning();

		method rumprg_befolkning();
		end; *rumprg_befolkning tom konstrutor;

		method setup(integer iBasAr, char(50) iBefTabell);
		dcl integer lastAr;
		dcl varchar(1000) sql;
		dcl char(8) userdata;

			userdata=%tslit(&userdata);
			lastAr=iBasAr-1;
			sql='{select ar, region, kon, alder, befolkning_dec from ' || iBefTabell || ' where ar=' || lastAr || '  }';

			h_befolkning.keys([ar, region, kon, alder]);
			h_befolkning.data([befolkning_dec]);
			h_befolkning.dataset(sql);
			h_befolkning.defineDone();

		end; *setup;

		method getBefolkning_jan(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			dcl private integer rc;
			lagAr=iAr-1; *Förra årets befolkning_dec är årets befolkning_jan;
			region=iRegion;
			kon=iKon;
			lagAlder=iAlder-1; *befolkning_dec blir ett år äldre vid årskiftet då vi utgår från födelseår.;
			alder=iAlder;

			if alder=100 then do;
				rc=h_befolkning.check([lagAr, region, kon, lagAlder]);
				if rc=0 then do;
					h_befolkning.find([lagAr, region, kon, lagAlder],[befolkning_dec]);
					h_befolkning.find([lagAr, region, kon, Alder],[befolkning_100]);
					befolkning_dec=sum(befolkning_dec,befolkning_100);
				end;
				else do;
					befolkning_dec=.;
				end;
			end; *Hundraåringar;
			else do;
				rc=h_befolkning.check([lagAr, region, kon, lagAlder]);
				if rc=0 then do;
					h_befolkning.find([lagAr, region, kon, lagAlder],[befolkning_dec]);
				end;
				else do;
					befolkning_dec=.;
				end;
			end; *vanliga åldrar;
		return befolkning_dec;
		end;

		method calcBefolkning(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iDoda, double iFodda, double iInflyttade, double iUtflyttade, double iInvandrade, double iUtvandrade);
			lagAr=iAr-1;
			lagAlder=iAlder-1;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_befolkning.find([lagAr, region, kon, lagAlder],[befolkning_dec]);
			if alder=0 then do;
				befolkning_dec=sum(iFodda,-iDoda,iInflyttade,-iUtflyttade,iInvandrade,-iUtvandrade);
			end;*nollåringar;
			else if alder=100 then do;
				h_befolkning.find([lagAr, region, kon, lagAlder],[befolkning_dec]);
				h_befolkning.find([lagAr, region, kon, Alder],[befolkning_100]);
				befolkning_dec=sum(befolkning_dec,befolkning_100,iFodda,-iDoda,iInflyttade,-iUtflyttade,iInvandrade,-iUtvandrade);
			end; *Hundraåringar;
			else do;
				befolkning_dec=sum(befolkning_dec,iFodda,-iDoda,iInflyttade,-iUtflyttade,iInvandrade,-iUtvandrade);
			end;*Övriga;
			h_befolkning.ref([ar, region, kon, alder],[befolkning_dec]);
		end;

		method getBefolkning(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;

			h_befolkning.find([ar, region, kon, alder],[befolkning_dec]);
		return befolkning_dec;
		end;*getBefolkning;

		method updateBefolkning(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iBefolkning_dec);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			befolkning_dec=iBefolkning_dec;
			h_befolkning.replace([ar, region, kon, alder],[befolkning_dec]);
		end;*updateBefolkning;

	endpackage ;
run;quit;

