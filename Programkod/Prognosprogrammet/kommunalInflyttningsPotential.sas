proc ds2;
	package &prglib..rumprg_kommunalIPotential / overwrite=yes;
		dcl package hash h_totaltRegionKom();
		dcl package hash h_nyByggande();
		dcl package hash h_iPotential();
		dcl package hash h_allaInvar();
		dcl package hash h_utglesning();
		dcl varchar(8) userdata;
		dcl integer ar lagAr region alder storregion;
		dcl char(50) kon;
		dcl double inflyttNyBygg lInflyttNyBygg inflyttade;
		dcl double totalBefolkning totalBefolkning_jan antalDoda antalFodda antalUtflyttade antalUtvandrade utglesning_in;
		dcl double sTotalBefolkning sTotalBefolkning_jan sAntalDoda sAntalFodda  sAntalUtflyttade  sAntalUtvandrade;
		dcl double lTotalBefolkning_jan lAntalDoda lAntalFodda  lAntalUtflyttade lAntalUtvandrade;

		forward calcKvarboende calcUtglesning;

	method rumprg_kommunalIPotential();
		userdata=%tslit(&userdata);

		h_totaltRegionKom.keys([ar region]);
		h_totaltRegionKom.data([sTotalBefolkning_jan sAntalDoda sAntalFodda  sAntalUtflyttade  sAntalUtvandrade]);
		h_totaltRegionKom.defineDone();

		h_nyByggande.keys([ar region]);
		h_nyByggande.data([inflyttNyBygg]);
		h_nyByggande.dataset('{SELECT ar, region, (SUM(case when hustyp=''FLERBO'' then ((nyaLgh * multNyaLgh + addNyaLgh)*2.1) else 
				((nyaLgh * multNyaLgh + addNyaLgh)*3.3) end)) AS inflyttNyBygg
			      FROM ' || USERDATA || '.RUM_NYBYGGNAD_KOM GROUP BY ar, region}');
		h_nyByggande.defineDone();

		h_iPotential.keys([ar region]);
		h_iPotential.data([ar region inflyttade]);
		h_iPotential.defineDone();

		h_allaInVar.keys([ar region ]);
		h_allaInVar.data([ar region inflyttade inflyttNyBygg sAntalUtflyttade sAntalUtvandrade sAntalDoda sAntalFodda]);
		h_allaInVar.ordered('A');
		h_allaInVar.defineDone();

		h_utglesning.keys([ar region]);
		h_utglesning.data([ar region utglesning_in]);
		h_utglesning.dataset('{select ar, region, utglesning as utglesning_in from ' || userdata || '.RUM_UTGLESNINGSTAL_KOM}');
		h_utglesning.defineDone();

	end;*rumprg_kommunalIPotential;

	method laddaData(integer iAr, integer iRegion, double iBefolkning_jan, double iDoda, double iFodda, double iUtflyttade, double iUtvandrade);
		dcl integer rc;

		ar=iAr;
		region=iRegion;
		totalBefolkning_jan=iBefolkning_jan;
		antalDoda=iDoda;
		antalFodda=iFodda;
		antalUtflyttade=iUtflyttade;
		antalUtvandrade=iUtvandrade;
		rc=h_totaltRegionKom.find([ar region],[sTotalBefolkning_jan sAntalDoda sAntalFodda  sAntalUtflyttade  sAntalUtvandrade]);
		if rc=0 then do;
			sTotalBefolkning_jan=sum(sTotalBefolkning_jan,totalBefolkning_jan);
			sAntalDoda=sum(sAntalDoda,antalDoda);
			sAntalFodda=sum(sAntalFodda,antalFodda);
			sAntalUtflyttade=sum(sAntalUtflyttade,antalUtflyttade);
			sAntalUtvandrade=sum(sAntalUtvandrade,antalUtvandrade);
			h_totaltRegionKom.replace([ar region],[sTotalBefolkning_jan sAntalDoda sAntalFodda  sAntalUtflyttade  sAntalUtvandrade]);
		end;
		else do;
			sTotalBefolkning_jan=iBefolkning_jan;
			sAntalDoda=iDoda;
			sAntalFodda=iFodda;
			sAntalUtflyttade=iUtflyttade;
			sAntalUtvandrade=iUtvandrade;
			h_totaltRegionKom.ref([ar region],[sTotalBefolkning_jan sAntalDoda sAntalFodda  sAntalUtflyttade sAntalUtvandrade]);
		end;
	end;*Ladda;

	method calcInflyttP(integer iAr, integer iRegion, integer iUtglesning);
		dcl double kvarbo utglesning utglessum inflyttare utflyttare;
*OBS Låser nere utglesning. Tass bort när en fungerande algoritm finns;
*iUtglesning=0;
*Slut;
		ar=iAr;
		lagAr=iAr-1;
		region=iRegion;

		h_nyByggande.find([lagAr region],[lInflyttNyBygg]);
		h_totaltRegionKom.find([lagAr region],[lTotalBefolkning_jan lAntalDoda lAntalFodda lAntalUtflyttade lAntalUtvandrade]);
		h_nyByggande.find([ar region],[inflyttNyBygg]);
		h_totaltRegionKom.find([ar region],[sTotalBefolkning_jan sAntalDoda sAntalFodda  sAntalUtflyttade sAntalUtvandrade]);

		inflyttare=sum(sTotalBefolkning_jan,-lTotalBefolkning_jan,-lAntalFodda,lAntalUtflyttade, lAntalUtvandrade,lAntalDoda);
		utflyttare=sum(lAntalUtflyttade, lAntalUtvandrade);
		kvarbo=sum(sTotalBefolkning_jan,-sAntalUtflyttade,-sAntalUtvandrade,-sAntalDoda,sAntalFodda,-inflyttNyBygg);
		if iUtglesning=1 then do;
			h_utglesning.find([ar region],[ar region utglesning_in]);
			utglesning=utglesning_in;
		end;
		else if iUtglesning=2 and sum(lTotalBefolkning_jan,-lInflyttNyBygg,-inflyttare) > 0 then do;
			utglesning=1+(sum(sTotalBefolkning_jan,-lTotalBefolkning_jan,-lInflyttNyBygg)/sum(sTotalBefolkning_jan,-lInflyttNyBygg,-inflyttare, utflyttare));
		end;
		else do ;
			utglesning=1;
		end;
		utglessum=sum(kvarbo*utglesning,-kvarbo);
		inflyttade=sum(inflyttNyBygg,sAntalUtflyttade, sAntalUtvandrade,sAntalDoda,-sAntalFodda,utglessum);
*h_allaInVar.ref([ar region],[ar region inflyttade inflyttNyBygg sAntalUtflyttade sAntalUtvandrade sAntalDoda sAntalFodda]);
		h_iPotential.ref([ar region],[ar region inflyttade]);
	end;*calcInflyttP;

	method getInflyttP(integer iAr, integer iRegion) returns double;
		ar=iAr;
		region=iRegion;
		h_iPotential.find([ar region],[ar region inflyttade]);
	return inflyttade;
	end;*getInflyttP;
		
	method skrivTillTabell(varchar(50) iTabell);
		h_iPotential.output(iTabell);
*		h_allaInVar.output(iTabell);
	end;*skrivTillTabell;
run;quit;