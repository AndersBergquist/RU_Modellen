proc ds2;
	package &prglib..rumprg_fr_modellen / overwrite=yes;
		declare package &prglib..rumprg_progParam as styr();
		dcl package &prglib..rumprg_resultat resultat(%tslit(&userdata) || '.rum_fr_resultat');
		dcl package &prglib..rumprg_befolkning bef();
		dcl package &prglib..rumprg_doda calcDoda();
		dcl package &prglib..rumprg_fodda calcFodda();
		dcl package &prglib..rumprg_inrikesFlyttningar calcInrikesFlytt();
		dcl package &prglib..rumprg_invandringar calcInvandringar();
		dcl package &prglib..rumprg_utvandringar calcUtvandring();
		dcl package &prglib..pxweb_GemensammaMetoder nyttigheter();
		dcl package hash h_regioner();
		dcl package hiter hi_regioner('h_regioner');
		dcl private integer basAr slutAr slutArSCB;
		dcl private char(8) userdata;
		dcl private char(50) kon region_nm;
		dcl private char(132) resultatTabell inrikesFlyttMatris;
		dcl private integer ar region alder maxAlderModer minAlderModer;
		dcl private double befolkning_dec befolkning_jan antalDoda antalFodda antalInflyttade antalUtflyttade antalInvandrade antalUtvandrade medelbefolkning;
		dcl private double pojkAndel;
		forward setSlutAr calcNollaringar skrivResultatFil calcFlyttningar;

		method rumprg_fr_modellen(integer iProgAr);
			dcl package sqlstmt stmtMaxAr();
			*dcl package sqlstmt  stmtParam();
			dcl package sqlstmt  stmtAlderSpann();
			userdata=%tslit(&userdata);

			inrikesFlyttMatris=strip(userdata) || '.rum_fr_flyttmatris';
			if nyttigheter.finnsTabell(strip(userdata),'rum_fr_flyttmatris')<>0 then sqlexec('drop table ' || strip(userdata) || '.rum_fr_flyttmatris');
	*		resultatTabell=strip(userdata) || '.rum_fr_resultat';
	*		if nyttigheter.finnsTabell(strip(userdata),'rum_fr_resultat')<>0 then sqlexec('drop table ' || strip(userdata) || '.rum_fr_resultat');

			stmtAlderSpann.prepare('select max(alderModer) as maxAlderModer, min(alderModer) as minAlderModer from ' || strip(userdata) || '.scb_fodda');			
			stmtAlderSpann.execute();			
			stmtAlderSpann.bindresults([maxAlderModer minAlderModer]);			
			stmtAlderSpann.fetch();			

			basar=styr.getVardeInt('basAr');
*			stmtParam.prepare('select basAr from ' || strip(userdata) || '.rum_parameters');
*			stmtParam.execute();
*			stmtParam.bindresults([basAr]);
*			stmtParam.fetch();

			stmtMaxAr.prepare('select max(ar) as slutArSCB from ' || strip(userdata) || '.SCB_PROGNOSER_SAMMANFATTNING');
			stmtMaxAr.execute();
			stmtMaxAr.bindresults([slutArSCB]);
			stmtMaxAr.fetch();

			slutAr=min(slutArSCB, basAr+iProgAr-1);
			*stmtParam.closeresults();
		end;*fr_modellen, konstrutor;

/* Modellens beräkningsloop */
*		method calc(integer iDodaAntalAr);
		method calc();
			bef.setup(basAr, userdata || '.SCB_BEFOLKNING');
			calcDoda.setup(userdata || '.rum_dodsrisker');
			calcFodda.setup(userdata || '.rum_fodelsetal');
			calcInrikesFlytt.setup(userdata || '.RUM_FLYTTRISKER', userdata || '.RUM_regionnamn');
			calcInvandringar.setup(userdata || '.RUM_INVANDRINGAR');
			calcUtvandring.setup(userdata || '.RUM_UTVANDRINGSRISKER');

			setSlutAr();

			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region, region_nm from ' || strip(userdata) || '.RUM_regionnamn }');
			h_regioner.defineDone();

			do ar=basAr to slutAr; *Här börjar själva beräkningssnurran.;
				calcFlyttningar();
				hi_regioner.first([region]);
				do until(hi_regioner.next([region]) <> 0);
					do kon='män', 'kvinnor';
						do alder=1 to 100;
							antalFodda=0; *Annars följer denna variable med alla andra åldrar;
							befolkning_jan=bef.getBefolkning_jan(ar, region, kon, alder);
							antalDoda=calcDoda.getAntalDoda(ar, region, kon, alder, befolkning_jan);
							antalInflyttade=calcInrikesFlytt.getInflyttare(ar, region, kon, alder);
							antalUtflyttade=calcInrikesFlytt.getUtflyttare(ar, region, kon, alder);
							antalInvandrade=calcInvandringar.getInvandringar(ar, region, kon, alder);
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
				antalInflyttade=calcInrikesFlytt.getInflyttare(ar, region, kon, alder);
				antalUtflyttade=calcInrikesFlytt.getUtflyttare(ar, region, kon, alder);
				antalInvandrade=calcInvandringar.getInvandringar(ar, region, kon, alder);
				antalUtvandrade=calcUtvandring.getUtvandringar(ar, region, kon, alder, medelAntalFodda);
				bef.calcBefolkning(ar, region, kon, alder, antalDoda, antalFodda, antalInflyttade, antalUtflyttade, antalInvandrade, antalUtvandrade);

			end; *kon;
	
		end;*calcNollaringar;

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
						antalInflyttade=calcInrikesFlytt.getInflyttare(ar, region, kon, alder);
						antalUtflyttade=calcInrikesFlytt.getUtflyttare(ar, region, kon, alder);
						antalInvandrade=calcInvandringar.getInvandringar(ar, region, kon, alder);
						antalUtvandrade=calcUtvandring.getUtvandringar(ar, region, kon, alder, befolkning_jan);

						befolkning_jan=bef.getBefolkning_jan(ar, region, kon, alder);

						resultat.laggtillResultat(ar, region, kon, alder, befolkning_dec, befolkning_jan, antalDoda, antalFodda, antalInflyttade, antalUtflyttade, antalInvandrade, antalUtvandrade);
					end; *alder;
				end; *kon;
			end; *region;
		end;
*		resultat.skrivTillTabell(resultatTabell);
		resultat.skrivTillTabell();
		calcInrikesFlytt.skrivTillTabell(inrikesFlyttMatris);
	*	calcFodda.skrivTillTabell('work.foddatest');
		end; *skrivResultatFil;

		method setSlutAr();
*;
		slutAr=styr.getVardeInt('slutar');
*			dcl varchar(1000) sql;
*			sql='update ' || strip(userdata) || '.rum_parameters set slutAr=' || slutAr;
*			sqlexec(sql);
		end;


	method calcFlyttningar();
		hi_regioner.first([region]);
		do until(hi_regioner.next([region]) <> 0);
			do kon='män', 'kvinnor';
				do alder=0 to 100;
					if alder=0 then do;
						antalFodda=calcFodda.getAntalFodda(ar, region, kon);
						calcInrikesFlytt.skapaFlyttare(ar, region, kon, alder, antalFodda);
					end; else do;
						befolkning_jan=bef.getBefolkning_jan(ar, region, kon, alder);
						calcInrikesFlytt.skapaFlyttare(ar, region, kon, alder, befolkning_jan);
					end;
				end; *alder;
			end; *kon;
		end; *regioner;
	end; *calcFlyttningar();

	endpackage;
run;quit;
