proc ds2;
	package &prglib..rumprg_fodelsetal / overwrite=yes;
		dcl package hash h_fodelsetalMedel();
		dcl package hash h_fodelsetalRiks();
		dcl package hash h_fodelsetalPrognos();
		dcl package hash h_fodelsetal();
		dcl package hash h_regioner();
		dcl package hiter hi_regioner('h_regioner');
		dcl private integer slutArSCB senasteAr startAr alderModer region ar minAlderModer maxAlderModer;
		dcl private double regionFodelsetal riksFodelsetal prognosFodelsetal fodelsetal addFtal multFtal SCB_fodelsetal;
		dcl private char(8) userdata projdata;

		method rumprg_fodelsetal();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);

		end;*rumprg_fodelsetal - konstruktor;

		method run(integer iBasAr, integer iAntalAr, char(50) iScbFodda, char(50) iRegionNamn, char(50) iScbBef, char(50) uFodelsetal);
			dcl package sqlstmt stmtMaxAr();
			dcl package sqlstmt stmtAlderSpann();

			stmtMaxAr.prepare('select max(ar) as slutArSCB from ' || strip(userdata) || '.SCB_PROGNOSER_SAMMANFATTNING');
			stmtMaxAr.execute();
			stmtMaxAr.bindresults([slutArSCB]);
			stmtMaxAr.fetch();

			stmtAlderSpann.prepare('select max(alderModer) as maxAlderModer, min(alderModer) as minAlderModer from ' || strip(iScbFodda) || '');			
			stmtAlderSpann.execute();			
			stmtAlderSpann.bindresults([maxAlderModer minAlderModer]);			
			stmtAlderSpann.fetch();	
			stmtAlderSpann.delete();	

			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region from ' || strip(iRegionNamn) || '}');
			h_regioner.defineDone();


			senasteAr=iBasAr-1;
			startAr=iBasAr-iAntalAr;
			h_fodelsetalMedel.keys([region alderModer]);
			h_fodelsetalMedel.data([regionFodelsetal]);
			h_fodelsetalMedel.dataset('{SELECT t1.region, t1.alderModer, mean(case when t2.medelbefolkning=0 then 0 when t1.fodda=0 then 0 else (t1.fodda / t2.medelbefolkning) end) AS regionFodelsetal
			      FROM ' || strip(iScbFodda) || ' t1, ' || strip(iScbBef) || ' t2
			      WHERE (t1.ar = t2.ar AND t1.region = t2.region AND t1.alderModer = t2.alder) AND (t2.kon = ''kvinnor'' AND t2.ar BETWEEN ' || startAr || ' AND ' || senasteAr || ')
				  GROUP BY  t1.region, t1.alderModer}');
			h_fodelsetalMedel.defineDone();

			h_fodelsetalRiks.keys([alderModer]);
			h_fodelsetalRiks.data([riksFodelsetal]);
			h_fodelsetalRiks.dataset('{SELECT t1.alderModer, (mean(t1.fodda / t2.medelbefolkning)) AS riksFodelsetal
			      FROM ' || strip(userdata) || '.SCB_FODDA t1, ' || strip(userdata) || '.SCB_BEFOLKNING t2
			      WHERE (t1.ar = t2.ar AND t1.region = t2.region AND t1.alderModer = t2.alder) AND (t2.kon = ''kvinnor'' AND t2.ar 
		          BETWEEN ' || startAr || ' AND ' || senasteAr || ')
			      GROUP BY t1.alderModer}');
			h_fodelsetalRiks.defineDone();

			h_fodelsetalPrognos.keys([ar alderModer]);
			h_fodelsetalPrognos.data([prognosFodelsetal]);
			h_fodelsetalPrognos.dataset('{SELECT t2.AR, t2.alderModer, (t2.FODDA / sum(t1.medelbefolkning)) AS prognosFodelsetal
			      FROM ' || strip(userdata) || '.SCB_PROGNOSER_DETALJ as t1, ' || strip(userdata) || '.SCB_PROGNOSER_FODDA t2
			      WHERE (t1.ar = t2.AR AND t1.alder = t2.alderModer) AND (t1.KON = ''kvinnor'')
			      GROUP BY t2.AR, t2.alderModer,t2.FODDA}');
			h_fodelsetalPrognos.defineDone();
		
			h_fodelsetal.keys([ar region alderModer]);
			h_fodelsetal.data([ar region alderModer fodelsetal addFtal multFtal SCB_fodelsetal]);
			h_fodelsetal.defineDone();

			multFtal=1;
			addFtal=0;
			do ar=iBasAr to slutArSCB;
			hi_regioner.first([region]);
				do until(hi_regioner.next([region])<>0);
					do alderModer=minAlderModer to maxAlderModer;
						h_fodelsetalMedel.find([region alderModer],[regionFodelsetal]);
						h_fodelsetalRiks.find([alderModer],[riksFodelsetal]);
						h_fodelsetalPrognos.find([ar alderModer],[prognosFodelsetal]);
						if regionFodelsetal<>. then do;
							fodelsetal=regionFodelsetal*(prognosFodelsetal/riksFodelsetal);
						end;
						else do;
							fodelsetal=0;
						end;
						SCB_fodelsetal=prognosFodelsetal;
						h_fodelsetal.ref([ar region alderModer],[ar region alderModer fodelsetal addFtal multFtal SCB_fodelsetal]);
					end;*alder;
				end;*region;
			end;*ar;
		h_fodelsetal.output(strip(uFodelsetal));
		end;
	endpackage ;
run;quit;