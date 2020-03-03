proc ds2;
	package &prglib..rumprg_utjamning / overwrite=yes;
		dcl package hash h_totaltRegionFr();
		dcl package hash h_kommuner();
		dcl package hiter hi_kommuner('h_kommuner');
		dcl package hash h_kommundata();
		dcl package hash h_totaltRegionKom();
		dcl package hash h_nyKommundata();
		dcl private integer ar region alder storregion;
		dcl private char(50) kon;
		dcl private char(8) userdata;
		dcl private double totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade;
		dcl private double sTotalBefolkning sAntalDoda sAntalFodda sAntalInflyttade sAntalUtflyttade sAntalInvandrade sAntalUtvandrade;
		dcl private double nsTotalBefolkning nsAntalDoda nsAntalFodda nsAntalInflyttade nsAntalUtflyttade nsAntalInvandrade nsAntalUtvandrade;
		dcl private double kTotalBefolkning kAntalDoda kAntalFodda kAntalInflyttade kAntalUtflyttade kAntalInvandrade kAntalUtvandrade;
		dcl private double tTotalBefolkning tAntalDoda tAntalFodda tAntalInflyttade tAntalUtflyttade tAntalInvandrade tAntalUtvandrade;
		dcl private double frTotalBefolkning frAntalDoda frAntalFodda frAntalInflyttade frAntalUtflyttade frAntalInvandrade frAntalUtvandrade;

		forward sumStorRegion;

		method rumprg_utjamning();
			userdata=%tslit(&userdata);

			h_totaltRegionFr.keys([ar region kon alder]);
			h_totaltRegionFr.data([totalBefolkning  antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
			h_totaltRegionFr.dataset('{SELECT ar, region, kon, alder, totalBefolkning, antalDoda, antalFodda, antalInflyttade,
				antalUtflyttade, antalInvandrade, antalUtvandrade FROM ' || userdata || '.RUM_FR_RESULTAT}');
			h_totaltRegionFr.defineDone();

			h_kommuner.keys([region]);
			h_kommuner.data([region storregion]);
			h_kommuner.dataset('{SELECT DISTINCT region_cd AS region, storRegion_cd AS storRegion FROM ' || userdata || '.RUM_KOMMUNER;}');
			h_kommuner.defineDone();

			h_kommundata.keys([ar region kon alder]);
			h_kommundata.data([ar region kon alder storregion totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
			h_kommundata.defineDone();

			h_totaltRegionKom.keys([ar storregion kon alder]);
			h_totaltRegionKom.data([ar storregion kon alder totalBefolkning  antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
			h_totaltRegionKom.defineDone();

			h_nyKommundata.keys([ar region kon alder]);
			h_nyKommundata.data([ar region kon alder totalBefolkning  antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
			h_nyKommundata.defineDone();

		end;

		method laddaPrognosData(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iTotalBefolkning, double iAntalDoda, double iAntalFodda, double iAntalInflyttade, double iAntalUtflyttade, double iAntalInvandrade, double iAntalUtvandrade);
			dcl integer rc;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			totalBefolkning=iTotalBefolkning;
			antalDoda=iAntalDoda;
			antalFodda=iAntalFodda;
			antalInflyttade=iAntalInflyttade;
			antalUtflyttade=iAntalUtflyttade;
			antalInvandrade=iAntalInvandrade;
			antalUtvandrade=iAntalUtvandrade;

			h_kommuner.find([region],[region storregion]);
			h_kommundata.ref([ar region kon alder],[ar region kon alder storregion totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);

			rc=h_totaltRegionKom.find([ar storregion kon alder],[ar storregion kon alder sTotalBefolkning sAntalDoda sAntalFodda sAntalInflyttade sAntalUtflyttade sAntalInvandrade sAntalUtvandrade]);
			if rc=0 then do;
				nsTotalBefolkning=sum(sTotalBefolkning,totalBefolkning);
				nsAntalDoda=sum(sAntalDoda,antalDoda);
				nsAntalFodda=sum(sAntalFodda,antalFodda);
				nsAntalInflyttade=sum(sAntalInflyttade,antalInflyttade);
				nsAntalUtflyttade=sum(sAntalUtflyttade,antalUtflyttade);
				nsAntalInvandrade=sum(sAntalInvandrade,antalInvandrade);
				nsAntalUtvandrade=sum(sAntalUtvandrade,antalUtvandrade);
				h_totaltRegionKom.replace([ar storregion kon alder],[ar storregion kon alder nsTotalBefolkning nsAntalDoda nsAntalFodda nsAntalInflyttade nsAntalUtflyttade nsAntalInvandrade nsAntalUtvandrade]);
			end;*Data finns;
			else do;
				nsTotalBefolkning=totalBefolkning;
				nsAntalDoda=antalDoda;
				nsAntalFodda=antalFodda;
				nsAntalInflyttade=antalInflyttade;
				nsAntalUtflyttade=antalUtflyttade;
				nsAntalInvandrade=antalInvandrade;
				nsAntalUtvandrade=antalUtvandrade;
				h_totaltRegionKom.add([ar storregion kon alder],[ar storregion kon alder nsTotalBefolkning nsAntalDoda nsAntalFodda nsAntalInflyttade nsAntalUtflyttade nsAntalInvandrade nsAntalUtvandrade]);
			end;*Data finns ej;


		end;*laddaPrognosData;

		method utjamna(integer iAr);
			ar=iAr;
			hi_kommuner.first([region storregion]);
			do until(hi_kommuner.next([region storregion])<>0);
				do kon='män', 'kvinnor';
					do alder=0 to 100;
						h_kommundata.find([ar region kon alder],[ar region kon alder storregion kTotalBefolkning kAntalDoda kAntalFodda kAntalInflyttade kAntalUtflyttade kAntalInvandrade kAntalUtvandrade]);
						h_totaltRegionKom.find([ar storregion kon alder],[ar storregion kon alder tTotalBefolkning tAntalDoda tAntalFodda tAntalInflyttade tAntalUtflyttade tAntalInvandrade tAntalUtvandrade]);
						h_totaltRegionFr.find([ar storregion kon alder],[frTotalBefolkning  frAntalDoda frAntalFodda frAntalInflyttade frAntalUtflyttade frAntalInvandrade frAntalUtvandrade]);
						if tTotalBefolkning > 0 then totalBefolkning=(kTotalBefolkning/tTotalBefolkning)*frTotalBefolkning; else totalBefolkning=0;
						if tAntalDoda > 0 then antalDoda=(kAntalDoda/tAntalDoda)*frAntalDoda; else antalDoda=0;
						if tAntalFodda > 0 then antalFodda=(kAntalFodda/tAntalFodda)*frAntalFodda; else antalFodda=0;
						if tAntalInflyttade > 0 then antalInflyttade=(kAntalInflyttade/tAntalInflyttade)*frAntalInflyttade; else antalInflyttade=0;
						if tAntalUtflyttade > 0 then antalUtflyttade=(kAntalUtflyttade/tAntalUtflyttade)*frAntalUtflyttade; else antalUtflyttade=0;
						if tAntalInvandrade > 0 then antalInvandrade=(kAntalInvandrade/tAntalInvandrade)*frAntalInvandrade; else antalInvandrade=0;
						if tAntalUtvandrade > 0 then antalUtvandrade=(kAntalUtvandrade/tAntalUtvandrade)*frAntalUtvandrade; else antalUtvandrade=0;
						h_nyKommundata.ref([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
					end;*alder;
				end;*kon;
			end;*region och storregioner;
		end; *utjamna;

		method rensa();
			h_kommundata.clear();
			h_totaltRegionKom.clear();
			h_nyKommundata.clear();
		end;*rensa;

		method getTotalBefolkning(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_nyKommundata.find([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		return totalBefolkning;
		end;*getTotalBefolkning;
		
		method getDoda(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_nyKommundata.find([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		return antalDoda;
		end;*getDoda;

		method getFodda(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_nyKommundata.find([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		return antalFodda;
		end;*getFodda;

		method getInflyttare(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_nyKommundata.find([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		return antalInflyttade;
		end;*getInflyttare;

		method getUtflyttare(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_nyKommundata.find([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		return antalUtflyttade;
		end;*getUtflyttare;

		method getInvandringar(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_nyKommundata.find([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		return antalInvandrade;
		end;*getInvandringar;

		method getUtvandringar(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			h_nyKommundata.find([ar region kon alder],[ar region kon alder totalBefolkning antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade]);
		return antalUtvandrade;
		end;*getUtvandringar;

		method skrivTillTabell(char(50) iTabell);
			h_kommundata.output('h_kommundata' || int(datetime()));
			h_totaltRegionKom.output('h_totaltRegionKom' || int(time()));
		end;*skrivTillTabell;
	endpackage;
run;quit;

/*
<1. ladda med årets data. h_kommundata;
<2. summera för storregionen (storregion_cd). h_kommundata => h_totalRegionKom.
<3. skala om: (h_kommundata/h_totalRegionKom)*h_totalRegionFr.
<4. spara nya variabler.h_nyKommundata
5. hämta nya variabler och ersätt de gammal, som finns i h_kommundata
*/
