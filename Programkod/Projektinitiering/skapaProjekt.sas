proc ds2;
	package &prglib..rumprg_skapaProjekt / overwrite=yes;
		dcl package &prglib..rumprg_progParam as styrVar();
		dcl package &prglib..rumprg_flyttaTabeller ft();
		dcl package &prglib..rumprg_regIndelning regIndelning();
		dcl package &prglib..rumprg_skattflyttMatriskom skattFlytt();
		dcl package &prglib..rumprg_flyttMatrisFR flyttM();
		dcl package &prglib..rumprg_flyttMatrisKOM flyttM_k();
		dcl package &prglib..rumprg_scbdata bscb();
		dcl package &prglib..rumprg_scbdata bscb_k();
		dcl package &prglib..rumprg_dodsrisker drisk();
		dcl package &prglib..rumprg_dodsrisker drisk_k();
		dcl package &prglib..rumprg_fodelsetal fTal();
		dcl package &prglib..rumprg_fodelsetal fTal_k();
		dcl package &prglib..rumprg_flyttrisker flyttrisk();
		dcl package &prglib..rumprg_flyttrisker flyttrisk_k();
		dcl package &prglib..rumprg_flyttrisker flyttrisk_k_till_r();
		dcl	package &prglib..rumprg_invandringsAndel invAndel();
		dcl	package &prglib..rumprg_invandringsAndel invAndel_k();
		dcl package &prglib..rumprg_utvandringsrisker utvandTal();
		dcl package &prglib..rumprg_utvandringsrisker utvandTal_k();
		dcl package &prglib..rumprg_nybyggnad nyByggnad_k();
		dcl package &prglib..rumprg_inflyttarFordelning inFord_k();
		dcl package &prglib..rumprg_utglesningstal utglesTal();
		dcl package &prglib..rumprg_scbdata_preg preg();
		dcl package hash h_tabeller();
		dcl package hiter hi_tabeller('h_tabeller');

		dcl private integer FR_regioner IR_regioner basAr slutAr dRiskAr fTalAr flyttRiskAr invAndelAr utvRiskAr inflyttAndel nyByggarAr utglesAr;
		dcl private double pojkAndel;
		dcl char(8) userdata inLib datalib;
		dcl char(50) tabell;
		dcl integer antal;
		
		forward dropproj createVariabler setVariabler finnsTabell;
			
		method rumprg_skapaProjekt();
			userdata=%tslit(&userdata);
			datalib=%tslit(&datalib);
		end;*rumprg_skapaProjekt;

		method makeProject();
			dcl package sqlstmt inParameter();
			dcl integer lagAr;
			dropproj();

			lagAr=styrVar.getVardeInt('lagar');;
			basAr=styrVar.getVardeInt('basar');
			SlutAr=styrVar.getVardeInt('slutar');
			if SlutAr > basAr+100 then slutAr=basAr+100;
			pojkAndel=styrVar.getVardeDouble('pojkandel');
			dRiskAr=styrVar.getVardeInt('dRiskAr');
			fTalAr=styrVar.getVardeInt('fTalAr');
			flyttRiskAr=styrVar.getVardeInt('flyttRiskAr');
			invAndelAr=styrVar.getVardeInt('invAndelAr');
			utvRiskAr=styrVar.getVardeInt('utvRiskAr');
			inflyttAndel=styrVar.getVardeInt('inflyttAndel');
			nyByggarAr=styrVar.getVardeInt('nyByggarAr');
			utglesAr=styrVar.getVardeInt('utglesAr');

			ft.run(basAr);
			regIndelning.run();

    *Fixar problemet med att SCB undertrycker flyttningar mindre än 5 personer.;
			skattFlytt.run(strip(datalib) || '.scb_befolkning',  strip(datalib) || '.SCB_RIKTAD_FLYTT_KOMMUN', 'work.SCB_RIKTAD_FLYTT_KOMMUN' );
	*Flerregional modell;
			flyttM.run(basAr, SlutAr, strip(datalib) || '.scb_befolkning', strip(userdata) || '.RUM_REGIONINDELNING', strip(userdata) || '.RUM_REGIONINDELNING', strip(userdata) || '.SCB_FLYTTMATRIS', 'work.SCB_RIKTAD_FLYTT_kommun' , strip(userdata) || '.SCB_FLYTTNINGAR', strip(userdata) || '.rum_flyttrisker', lagAr);
			bscb.run(basAr, strip(userdata) || '.RUM_REGIONINDELNING', strip(userdata) || '.RUM_regionnamn', strip(userdata) || '.SCB_BEFOLKNING', strip(userdata) || '.SCB_FODDA', strip(userdata) || '.SCB_FLYTTNINGAR');
			drisk.run(basAr, dRiskAr, strip(userdata) || '.scb_befolkning', strip(userdata) || '.rum_regionnamn', strip(userdata) || '.rum_dodsrisker');
			fTal.run(basAr, fTalAr, strip(userdata) || '.SCB_FODDA', strip(userdata) || '.rum_regionnamn', strip(userdata) || '.scb_befolkning', strip(userdata) || '.RUM_FODELSETAL');
			flyttrisk.run(basAr, flyttRiskAr, strip(userdata) || '.SCB_BEFOLKNING', strip(userdata) || '.SCB_FLYTTMATRIS', strip(userdata) || '.rum_flyttrisker');
			invAndel.run(basAr, invAndelAr, strip(userdata) || '.SCB_BEFOLKNING', strip(userdata) || '.rum_regionnamn', strip(userdata) || '.rum_Invandringar');
			utvandTal.run(basAr, utvRiskAr, strip(userdata) || '.SCB_BEFOLKNING', strip(userdata) || '.rum_regionnamn', strip(userdata) || '.rum_utvandringsRisker');

	*Kommunal modell;
			flyttM_k.run(basAr, slutAr, strip(datalib) || '.scb_befolkning', strip(userdata) || '.rum_rikes_kommuner', 'work.SCB_RIKTAD_FLYTT_KOMMUN', strip(userdata) || '.SCB_FLYTTMATRIS_KOM', strip(userdata) || '.SCB_FLYTTNINGAR_KOM', strip(userdata) || '.rum_flyttrisker_kom', lagAr);
			bscb_k.run(basAr, strip(userdata) || '.RUM_kommuner', strip(userdata) || '.RUM_kommuner', strip(userdata) || '.SCB_BEFOLKNING_kom', strip(userdata) || '.SCB_FODDA_kom', strip(userdata) || '.SCB_FLYTTNINGAR_KOM' );
			drisk_k.run(basAr, dRiskAr, strip(userdata) || '.scb_befolkning_kom', strip(userdata) || '.RUM_kommuner', strip(userdata) || '.rum_dodsrisker_kom');
			fTal_k.run(basAr, fTalAr, strip(userdata) || '.SCB_FODDA_kom', strip(userdata) || '.rum_kommuner', strip(userdata) || '.scb_befolkning_kom', strip(userdata) || '.RUM_FODELSETAL_kom');
			flyttrisk_k.run(basAr, flyttRiskAr, strip(userdata) || '.SCB_BEFOLKNING_KOM', strip(userdata) || '.SCB_FLYTTMATRIS_KOM', strip(userdata) || '.rum_flyttrisker_kom');
			flyttrisk_k_till_r.run(basAr, flyttRiskAr, strip(userdata) || '.SCB_BEFOLKNING_KOM', strip(userdata) || '.SCB_FLYTTMATRIS_KOM_REG', strip(userdata) || '.rum_flyttrisker_kom_reg');
			invAndel_k.run(basAr, invAndelAr, strip(userdata) || '.scb_befolkning_kom', strip(userdata) || '.RUM_kommuner', strip(userdata) || '.rum_Invandringar_kom');
			utvandTal_k.run(basAr, utvRiskAr, strip(userdata) || '.SCB_BEFOLKNING_kom', strip(userdata) || '.RUM_kommuner', strip(userdata) || '.rum_utvandringsRisker_kom');
			nyByggnad_k.run(basAr, nyByggarAr, strip(userdata) || '.RUM_kommuner',  strip(userdata) || '.RUM_NYBYGGNAD_KOM');
			inFord_k.run(basAr, inflyttAndel, strip(userdata) || '.SCB_BEFOLKNING_kom', strip(userdata) || '.RUM_InflyttAndel_KOM');*			utglesTal.run(basAr, slutAr, utglesAr);
			utglesTal.run(basAr, slutAr, utglesAr);
			preg.run(basAr, strip(userdata) || '.RUM_KOMMUNER',strip(userdata) || '.SCB_FLYTTMATRIS_KOM',strip(userdata) || '.SCB_FLYTTMATRIS',strip(userdata) || '.SCB_BEFOLKNING_KOM',strip(userdata) || '.SCB_BEFOLKNING_preg');

			sqlexec('drop table work.kommuner');
			sqlexec('drop table work.nyakoder');
			sqlexec('drop table work.regionindelning');
			sqlexec('drop table work.regionnamn');
			sqlexec('drop table work.scb_riktad_flytt_kommun');


		end;*makeProject;

		method createVariabler();
			sqlexec('create table ' || strip(userdata) || '.rum_parameters (basAr integer, slutAr integer, pojkandel double, userdata char(8))');
		end;

		method setVariabler();
			dcl package sqlstmt stmt1('insert into ' || strip(userdata) || '.rum_parameters (basAr, slutAr, pojkandel, userdata) values(?,?,?,?)',[basAr, slutAr, pojkandel, userdata]);
			stmt1.execute();
		end;

		method dropproj();
		declare varchar(75) tabellnamn;
			h_tabeller.keys([tabell]);
			h_tabeller.data([tabell]);
			h_tabeller.dataset('{select TABLE_NAME as tabell from dictionary.tables where table_schem=''' || UPCASE(STRIP(userdata)) || '''}');
			h_tabeller.defineDone();

			hi_tabeller.first([tabell]);
			do until(hi_tabeller.next([tabell])<>0);
				if upcase(tabell) not in ('RUM_REGIONNAMN_IN', 'RUM_REGIONINDELNING_IN', 'RUM_KOMMUNER_IN', 'RUM_PARAMETERS') then sqlexec('drop table ' || strip(userdata) || '.' || tabell);
			end;*loop av tabeller;
		end; *dropproj;

run;quit;
