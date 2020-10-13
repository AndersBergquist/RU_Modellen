proc ds2;
	package &prglib..rumprg_inrikesFlyttningar / overwrite=yes;
		dcl package &prglib..pxweb_GemensammaMetoder nyttigheter();
		dcl package hash h_flyttrisker();
		dcl package hiter hi_flyttrisker('h_flyttrisker');
		dcl package hash h_tidjustering();
		dcl package hash h_flyttade();
		dcl package hash h_utflyttare();
		dcl package hash h_inflyttare();
		dcl package hash h_regioner();
		dcl package hash h_storregioner();
		dcl package hiter hi_regioner('h_regioner');
		dcl private integer ar franRegion tillRegion region storRegion alder;
		dcl private double flyttrisk flyttade utflyttare inflyttare justMult justAdd;
		dcl private char(8) userdata;
		dcl private char(50) kon friskTAbell;

		method rumprg_inrikesFlyttningar();
			userdata=%tslit(&userdata);

			h_flyttade.keys([ar franRegion tillRegion kon alder]);
			h_flyttade.data([ar franRegion tillRegion kon alder flyttade]);
			h_flyttade.ordered('A');
			h_flyttade.defineDone();
			

		end;*rumprg_inrikesFlyttningar;

		method setup(char(50) iFriskTabell, char(50) iRegionnamn);
			h_flyttrisker.keys([franRegion tillRegion kon alder]);
			h_flyttrisker.data([flyttrisk]);
			h_flyttrisker.dataset('{SELECT franRegion, tillRegion, kon, alder, (sum(flyttrisk,addFlyttRisk)*multFlyttRisk) as flyttrisk from ' || strip(iFriskTabell) || '}');
			h_flyttrisker.defineDone();

			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region from ' || strip(iRegionnamn) || ' }');
			h_regioner.defineDone();

			h_storregioner.keys([region]);
			h_storregioner.data([storRegion]);
			h_storregioner.dataset('{SELECT kommun_num as region, region_cd as storRegion from ' || userdata || '.RUM_REGIONINDELNING}');
			h_storregioner.defineDone();

			h_tidjustering.keys([ar franRegion tillRegion]);
			h_tidjustering.data([ar franRegion tillRegion justMult justAdd]);
			h_tidjustering.dataset('{SELECT ar, franRegion, tillRegion, justMult, justAdd from ' || strip(iFriskTabell) || '_tid}');
			h_tidjustering.defineDone();

			h_utflyttare.keys([ar region kon alder]);
			h_utflyttare.data([utflyttare]);
			h_utflyttare.defineDone();

			h_inflyttare.keys([ar region kon alder]);
			h_inflyttare.data([inflyttare]);
			h_inflyttare.defineDone();

		end;*setup;

		method skapaFlyttare(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iBefolkning);*Bygger en flyttmatris;
			ar=iAr;
			franRegion=iRegion;
			kon=iKon;
			alder=iAlder;
			hi_regioner.first([tillRegion]);
			do until(hi_regioner.next([tillRegion])<>0);
				h_flyttrisker.find([franRegion tillRegion kon alder],[flyttrisk]);
				h_tidjustering.find([ar franRegion tillRegion],[ar franRegion tillRegion justMult justAdd]);
				flyttade=((justMult*flyttrisk)+justAdd)*iBefolkning;
				h_flyttade.replace([ar franRegion tillRegion kon alder],[ar franRegion tillRegion kon alder flyttade]);
			end;*tillRegion;	
		end;*skapaFlyttningar();

		method getUtflyttare(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			dcl double utflyttade;
			dcl integer rc;
			ar=iAr;
			franRegion=iRegion; *regionen som individen flyttar från;
			kon=iKon;
			alder=iAlder;
			*/ FR_modellen, franRegion är storRegion => rc<>0
			*/ Kommun till kommun, tillRegion = kommun => rc<>0
			*/ kommun till storregion, kommun=kommun och storregion=storregoin =>rc=0;
			rc=h_storregioner.find([franRegion],[storRegion]);
			if rc<>0 then storRegion = -1;
			rc=h_utflyttare.find([ar franRegion kon alder],[utflyttare]);
			if rc=0 then do;
				utFlyttade=utflyttare;
			end; 
			else do;
				utflyttade=0;
				hi_regioner.first([tillRegion]);
				do until(hi_regioner.next([tillRegion])<>0);
					if franRegion ^= tillRegion and storRegion ^= tillRegion then do;
						h_flyttade.find([ar franRegion tillRegion kon alder],[ar franRegion tillRegion kon alder flyttade]);
						utflyttade=sum(utflyttade, flyttade);
					end;
				end;*tillRegion;
				utflyttare=utflyttade;
				h_utflyttare.add([ar franRegion kon alder],[utflyttare]);
			end;
		return utFlyttade;
		end;*getUtflyttare;

		method getInflyttare(integer iAr, integer iRegion, char(50) iKon, integer iAlder) returns double;
			dcl double inflyttade;
			dcl integer rc;
			ar=iAr;
			tillRegion=iRegion; *regionen som individen flyttar från;
			kon=iKon;
			alder=iAlder;
			rc=h_inflyttare.find([ar tillRegion kon alder],[inflyttare]);
			if rc=0 then inFlyttade=inflyttare;
			else do;
				inflyttade=0;
				hi_regioner.first([franRegion]);
				do until(hi_regioner.next([franRegion])<>0);
					if franRegion ^= tillRegion then do;
						h_flyttade.find([ar franRegion tillRegion kon alder],[ar franRegion tillRegion kon alder flyttade]);
						inflyttade=sum(inflyttade, flyttade);
					end;
				end;*franRegion;
				inflyttare=inFlyttade;
				h_inflyttare.add([ar tillRegion kon alder],[inflyttare]);		
			end;
		return inFlyttade;
		end;*getInflyttare;

		method updateInflyttade(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iAntalInflyttade);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			inflyttare=iAntalInflyttade;
			h_inflyttare.replace([ar, region, kon, alder],[inflyttare]);
		end;*updateInflyttade;

		method updateUtflyttade(integer iAr, integer iRegion, char(50) iKon, integer iAlder, double iAntalUtflyttade);
			ar=iAr;
			region=iRegion;
			kon=iKon;
			alder=iAlder;
			utflyttare=iAntalUtflyttade;
			h_utflyttare.replace([ar, region, kon, alder],[utflyttare]);
		end;*updateUtflyttade;

		method skrivTillTabell(varchar(50) iUtTabell);
			h_flyttade.output(iUtTabell);
		end;
		method skrivTillTabell(varchar(50) iUtTabell, integer iEmpty);
			declare varchar(50) nameLib nameTabell;
			declare integer tabellFinns;

			if iEmpty=2 then do;
				nameLib=scan(iUtTabell,1,'.');
				nameTabell=scan(iUtTabell,2,'.');
				tabellFinns=nyttigheter.finnsTabell(nameLib, nameTabell);
				if tabellFinns=1 then do;
					h_flyttade.output('work.tmpFmatris');
					h_flyttade.clear();
					sqlexec('INSERT INTO ' || iUtTabell || ' SELECT * from work.tmpFmatris');
					sqlexec('DROP TABLE work.tmpFmatris');
				end;
				else do;
					h_flyttade.output('work.tmpFmatris');
					h_flyttade.clear();
					sqlexec('CREATE TABLE ' || iUtTabell || 'AS SELECT * from work.tmpFmatris');
					sqlexec('DROP TABLE work.tmpFmatris');
				end;
			end;
			else if iEmpty=1 then do;
				h_flyttade.output(iUtTabell);
			end;
		end;
	endpackage ;
run;quit;