proc ds2;
	package &prglib..rumprg_kom_modellen / overwrite=yes;
		declare package &prglib..rumprg_progParam styr();
		dcl package &prglib..rumprg_utjamning utjam();
		dcl package &prglib..rumprg_resultat resultat(%tslit(&userdata) || '.rum_kom_resultat');
		dcl package &prglib..rumprg_befolkning bef();
		dcl package &prglib..rumprg_doda calcDoda();
		dcl package &prglib..rumprg_fodda calcFodda();
		dcl package &prglib..rumprg_inrikesFlyttningar calcInrikesFlytt();
		dcl package &prglib..rumprg_inrikesFlyttningar calcInrikesFlyttKom();
		*dcl package &prglib..rumprg_invandringar calcInvandringar();
		dcl package &prglib..rumprg_utvandringar calcUtvandring();
		dcl package &prglib..pxweb_GemensammaMetoder nyttigheter();
		dcl package &prglib..rumprg_kommunalIPotential calcIP();
		dcl package &prglib..rumprg_komInflyttning calcKomInflytt();
*		dcl package &prglib..rumprg_RAP_REG rap_reg();
		dcl package hash h_regioner();
		dcl package hiter hi_regioner('h_regioner');

		dcl private integer basAr slutAr slutArSCB iUtj iUtglesning;
		dcl private char(8) userdata;
		dcl private char(50) kon region_nm;
		dcl private char(132) resultatTabell kommunalFlyttMatris kommunalFlyttMatrisKom regionTabell;
		dcl private integer ar region alder maxAlderModer minAlderModer skrivFmatris;
		dcl private double befolkning_dec befolkning_jan antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade medelbefolkning;
		dcl private double pojkAndel x;
		forward setSlutAr calcNollaringar skrivResultatFil calcFlyttningar calcUtj calcInflyttning;

		method rumprg_kom_modellen(integer iProgAr);
			dcl package sqlstmt stmtMaxAr();
			dcl package sqlstmt  stmtParam();
			dcl package sqlstmt  stmtAlderSpann();
			userdata=%tslit(&userdata);

	*		resultatTabell=strip(userdata) || '.rum_kom_resultat';
			kommunalFlyttMatris=strip(userdata) || '.rum_kom_flyttmatris';
			kommunalFlyttMatrisKom=strip(userdata) || '.rum_kom_kom_flyttmatris';
*			regionTabell=strip(userdata) || '.rum_reg_resultat';
*			if nyttigheter.finnsTabell(strip(userdata),'rum_kom_resultat')<>0 then 	sqlexec('drop table ' || strip(userdata) || '.rum_kom_resultat');
			if nyttigheter.finnsTabell(strip(userdata),'rum_kom_flyttmatris')<>0 then 	sqlexec('drop table ' || strip(userdata) || '.rum_kom_flyttmatris');
			if nyttigheter.finnsTabell(strip(userdata),'rum_kom_kom_flyttmatris')<>0 then 	sqlexec('drop table ' || strip(userdata) || '.rum_kom_kom_flyttmatris');
			if nyttigheter.finnsTabell(strip(userdata),'rum_reg_resultat')<>0 then 	sqlexec('drop table ' || strip(userdata) || '.rum_reg_resultat');


			stmtAlderSpann.prepare('select max(alderModer) as maxAlderModer, min(alderModer) as minAlderModer from ' || strip(userdata) || '.scb_fodda');			
			stmtAlderSpann.execute();			
			stmtAlderSpann.bindresults([maxAlderModer minAlderModer]);			
			stmtAlderSpann.fetch();			

			basAr=styr.getVardeInt('basAr');
			skrivFmatris=styr.getVardeInt('skrivFmatris');
*			stmtParam.prepare('select basAr from ' || strip(userdata) || '.rum_parameters');
*			stmtParam.execute();
*			stmtParam.bindresults([basAr]);
*			stmtParam.fetch();

			stmtMaxAr.prepare('select max(ar) as slutArSCB from ' || strip(userdata) || '.SCB_PROGNOSER_SAMMANFATTNING');
			stmtMaxAr.execute();
			stmtMaxAr.bindresults([slutArSCB]);
			stmtMaxAr.fetch();

			slutAr=min(slutArSCB, basAr+iProgAr-1);
		*	stmtParam.closeresults();
		end;*fr_modellen, konstrutor;

/* Modellens beräkningsloop */
		method calc();
			iUtj=styr.getVardeInt('utjamn');
			iUtglesning=styr.getVardeInt('utgles');
			bef.setup(basAr, userdata || '.SCB_BEFOLKNING_kom');
			calcDoda.setup(userdata || '.rum_dodsrisker_kom');
			calcFodda.setup(userdata || '.rum_fodelsetal_kom');
			calcInrikesFlyttKom.setup(userdata || '.RUM_FLYTTRISKER_kom', userdata || '.RUM_kommuner');
			calcInrikesFlytt.setup(userdata || '.RUM_FLYTTRISKER_kom_REG', userdata || '.RUM_regionnamn');
			*calcInvandringar.setup(userdata || '.RUM_INVANDRINGAR_kom');
			calcUtvandring.setup(userdata || '.RUM_UTVANDRINGSRISKER_kom');

			setSlutAr();

			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region, region_nm from ' || strip(userdata) || '.RUM_kommuner }');
			h_regioner.defineDone();

			antalInflyttade=0;
			antalInvandrade=0;
			do ar=basAr to slutAr; *Här börjar själva beräkningssnurran.;
				calcFlyttningar();
				hi_regioner.first([region]);
				do until(hi_regioner.next([region]) <> 0);
					do kon='män', 'kvinnor';
						do alder=1 to 100;
							antalFodda=0; *Annars följer denna variable med alla andra åldrar;
							befolkning_jan=bef.getBefolkning_jan(ar, region, kon, alder);
							antalDoda=calcDoda.getAntalDoda(ar, region, kon, alder, befolkning_jan);
							antalUtflyttade=calcInrikesFlytt.getUtflyttare(ar, region, kon, alder);
							antalUtvandrade=calcUtvandring.getUtvandringar(ar, region, kon, alder, befolkning_jan);
							if kon='kvinnor' and minAlderModer <= alder <= maxAlderModer then do;
								medelbefolkning=sum(2*befolkning_jan,antalDoda,-antalInflyttade,antalUtflyttade,-antalInvandrade,antalUtvandrade)/2;
								calcFodda.setAntalFodda(ar, region, alder, medelbefolkning);
							end;
							bef.calcBefolkning(ar, region, kon, alder, antalDoda, antalFodda, antalInflyttade, antalUtflyttade, antalInvandrade, antalUtvandrade);
						end; *alder;
					end; *kon;
				calcNollaringar(); *räknar ut antalet nollåringar=födda plus lite flyttningar och döda;
				end; *region;
			calcInflyttning(ar, iUtglesning);
			if iUtj=1 then calcUtj(ar);
			if skrivFmatris=2 then do;
				calcInrikesFlytt.skrivTillTabell(kommunalFlyttMatris, skrivFmatris);
				calcInrikesFlyttKom.skrivTillTabell(kommunalFlyttMatrisKom, skrivFmatris);
			end;
*put 'Prognosår: ' ar;
			end;*ar - Här slutar själva beräkningssnurran;
		skrivResultatFil();
		end;*calc, här beräknas modellen;

/* CalcNOLLARINGAR*/
		method calcNollaringar();
			dcl double medelAntalFodda;
			alder=0;
			do kon='män', 'kvinnor';
				antalFodda=calcFodda.getAntalFodda(ar, region, kon);
				antalFodda=calcFodda.getAntalFodda(ar, region, kon);
				medelAntalFodda=antalFodda/2;
				calcInrikesFlytt.skapaFlyttare(ar, region, kon, alder, medelAntalFodda);
				antalDoda=calcDoda.getAntalDoda(ar, region, kon, alder, medelAntalFodda);
				antalInflyttade=calcKomInflytt.getInrikesInflytt(ar, region, kon, alder);
				antalUtflyttade=calcInrikesFlytt.getUtflyttare(ar, region, kon, alder);
				antalInvandrade=calcKomInflytt.getInvandringar(ar, region, kon, alder);
				antalUtvandrade=calcUtvandring.getUtvandringar(ar, region, kon, alder, medelAntalFodda);
				bef.calcBefolkning(ar, region, kon, alder, antalDoda, antalFodda, antalInflyttade, antalUtflyttade, antalInvandrade, antalUtvandrade);

			end; *kon;
	
		end;*calcNollaringar;
/* SkrivResultatFil */
		method skrivResultatFil();
		do ar=basAr to slutAr; 
			hi_regioner.first([region]);
			do until(hi_regioner.next([region])<>0);
				do kon='män', 'kvinnor';
					do alder=0 to 100;
						if alder=0 then do;
							antalFodda=calcFodda.getAntalFodda(ar, region, kon);
						end;else do;
							antalFodda=0;
						end;
						befolkning_dec=bef.getBefolkning(ar, region, kon, alder);
						antalDoda=calcDoda.getAntalDoda(ar, region, kon, alder);
						antalInflyttade=calcKomInflytt.getInrikesInflytt(ar, region, kon, alder);
						antalUtflyttade=calcInrikesFlytt.getUtflyttare(ar, region, kon, alder);
						antalInvandrade=calcKomInflytt.getInvandringar(ar, region, kon, alder);
						antalUtvandrade=calcUtvandring.getUtvandringar(ar, region, kon, alder, befolkning_jan);

						befolkning_jan=bef.getBefolkning_jan(ar, region, kon, alder);

						resultat.laggtillResultat(ar, region, kon, alder, befolkning_dec, befolkning_jan, antalDoda, antalFodda, antalInflyttade, antalUtflyttade, antalInvandrade, antalUtvandrade);

					end; *alder;
				end; *kon;
			end; *region;

		end;
		resultat.skrivTillTabell();

	*	utjam.skrivTillTabell('work.utjmbas');
	*	calcFodda.skrivTillTabell('work.foddatest');

	*	calcIp.skrivTillTabell('work.IPData');
	*	rap_reg.run(regionTabell);
			if skrivFmatris=1 then do;
				calcInrikesFlytt.skrivTillTabell(kommunalFlyttMatris, skrivFmatris);
				calcInrikesFlyttKom.skrivTillTabell(kommunalFlyttMatrisKom, skrivFmatris);
			end;

		end; *skrivResultatFil;

		method setSlutAr();
			slutAr=styr.getVardeInt('slutAr');
*			dcl varchar(1000) sql;
*			sql='update ' || strip(userdata) || '.rum_parameters set slutAr=' || slutAr;
*			sqlexec(sql);
		end;


	method calcFlyttningar();
dcl double x;
		hi_regioner.first([region]);
		do until(hi_regioner.next([region]) <> 0);
			do kon='män', 'kvinnor';
				do alder=0 to 100;
					if alder=0 then do;
						antalFodda=calcFodda.getAntalFodda(ar, region, kon);* /2???;
						calcInrikesFlytt.skapaFlyttare(ar, region, kon, alder, antalFodda);
						calcInrikesFlyttkom.skapaFlyttare(ar, region, kon, alder, antalFodda);
					end; else do;
						befolkning_jan=bef.getBefolkning_jan(ar, region, kon, alder);
						calcInrikesFlytt.skapaFlyttare(ar, region, kon, alder, befolkning_jan);
						calcInrikesFlyttkom.skapaFlyttare(ar, region, kon, alder, befolkning_jan);
					end;
				end; *alder;
			end; *kon;
		end; *regioner;
	end; *calcFlyttningar();
/*Utjämning */
	method calcUtj(integer iAr);

	/*Laddar data till utjämning*/
		hi_regioner.first([region]);
		do until(hi_regioner.next([region]) <> 0);
			do kon='män', 'kvinnor';
				do alder=0 to 100;
					befolkning_dec=bef.getBefolkning(iAr, region, kon, alder);
					antalDoda=calcDoda.getAntalDoda(iAr, region, kon, alder);
					antalInflyttade=calcKomInflytt.getInrikesInflytt(iAr, region, kon, alder);
					antalUtflyttade=calcInrikesFlytt.getUtflyttare(iAr, region, kon, alder);
					antalInvandrade=calcKomInflytt.getInvandringar(iAr, region, kon, alder);
					antalUtvandrade=calcUtvandring.getUtvandringar(iAr, region, kon, alder, befolkning_jan);
					if alder=0 then antalFodda=calcFodda.getAntalFodda(iAr, region, kon);
						else antalFodda=0;
					utjam.laddaPrognosData(iAr, region, kon, alder, befolkning_dec, antalDoda, antalFodda, antalInflyttade, antalUtflyttade, antalInvandrade, antalUtvandrade);			
				end;*alder;
			end;*kon;
		end;*regioner;
		utjam.utjamna(iAr);
		hi_regioner.first([region]);
		do until(hi_regioner.next([region]) <> 0);
			do kon='män', 'kvinnor';
				do alder=0 to 100;
					bef.updateBefolkning(iAr, region, kon, alder, utjam.getTotalBefolkning(iAr,region, kon,alder));
					calcDoda.updateAntalDoda(iAr, region , kon, alder, utjam.getDoda(iAr,region, kon,alder));
					calcFodda.updateAntalFodda(iAr, region , kon, alder, utjam.getFodda(iAr,region, kon,alder));
					calcKomInflytt.updateInrikesInflytt(iAr, region , kon, alder, utjam.getInflyttare(iAr,region, kon,alder));
					calcInrikesFlytt.updateUtflyttade(iAr, region , kon, alder , utjam.getUtflyttare(iAr,region, kon,alder));
					calcKomInflytt.updateInvandringar(iAr, region , kon, alder, utjam.getInvandringar(iAr,region, kon,alder));
					calcUtvandring.updateUtvandringar(iAr, region , kon, alder, utjam.getUtvandringar(iAr,region, kon,alder));
				end;*alder;
			end;*kon;
		end;*regioner;
		
	end;*calcUtj;
/*calcInflyttning*/
	method calcInflyttning(integer iAr, integer iUtglesning);
		dcl double inflyttP inrikesInflytt invandringar;
		dcl integer totaltInflyttade;
		hi_regioner.first([region]);
		do until(hi_regioner.next([region]) <> 0);
			do kon='män', 'kvinnor';
					do alder=0 to 100;
					befolkning_jan=bef.getBefolkning(iAr-1, region, kon, alder);
					antalDoda=calcDoda.getAntalDoda(iAr, region, kon, alder);
					antalUtflyttade=calcInrikesFlytt.getUtflyttare(iAr, region, kon, alder);
					antalUtvandrade=calcUtvandring.getUtvandringar(iAr, region, kon, alder, befolkning_jan);
					if alder=0 then antalFodda=calcFodda.getAntalFodda(iAr, region, kon);
						else antalFodda=0;
					calcIp.laddaData(iAr, region, befolkning_jan, antalDoda, antalFodda, antalUtflyttade, antalUtvandrade);
				end;*alder;
			end;*kon;
		calcIp.calcInflyttP(iAr, region, iUtglesning);
		end;
		hi_regioner.first([region]);
		do until(hi_regioner.next([region]) <> 0);
			inflyttP=calcIp.getInflyttP(iAr, region);
			do kon='män', 'kvinnor';
				do alder=0 to 100;
					calcKomInflytt.calcInflyttning(iAr, region, kon, alder, inflyttP);
					inrikesInflytt=calcKomInflytt.getInrikesInflytt(iAr, region, kon, alder);
					invandringar=calcKomInflytt.getInvandringar(iAr, region, kon, alder);
					totaltInflyttade=inrikesInflytt+invandringar+bef.getBefolkning(iAr,region, kon,alder);
					bef.updateBefolkning(iAr, region, kon, alder, totaltInflyttade);
				end;*alder;
			end;*kon;
		end;*regioner;
	end;*calcInflyttning;
	endpackage;
run;quit;
