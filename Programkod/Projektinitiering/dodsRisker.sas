proc ds2;
	package &prglib..rumprg_dodsrisker / overwrite=yes;
		dcl package hash h_regioner();
		dcl package hiter hi_regioner('h_regioner');
		dcl package hash h_dodsriskerMedel();
		dcl package hash h_dodsriskerRiket();
		dcl package hash h_dodsriskerSCBPrognos();
		dcl package hash h_dodsrisker();
		dcl double dodstal dodsrisk SCBdodstal SCBdodsrisk progDodstal progDodsrisk maxar multDtal addDtal;
		dcl integer ar region alder slutArSCB;
		dcl char(50) kon;
		dcl char(8) userdata projdata;

		method rumprg_dodsrisker();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);
		end;*rumprg_dodsrisker - konstruktor;

		method run(integer iBasAr, integer iAntalAr, char(50) iScbBef, char(50) iRegionNamn, char(50) uDodsrisker);
		dcl package sqlstmt stmtMaxAr();
		dcl integer senasteAr startAr;

			senasteAr=iBasAr-1;
			startAr=iBasAr-iAntalAr;

			h_dodsriskerMedel.keys([region kon alder]);
			h_dodsriskerMedel.data([dodstal dodsrisk]);
			h_dodsriskerMedel.dataset('{SELECT t1.REGION, t1.KON,  t1.ALDER, (MEAN(case when medelbefolkning=0 then 0 else t1.DODA / t1.MEDELBEFOLKNING end)) AS Dodstal, (MEAN(case when medelbefolkning=0 then 0 else 1-(EXP(-(t1.DODA / t1.MEDELBEFOLKNING)))end)) AS Dodsrisk
									      FROM ' || strip(iScbBef) || ' t1 WHERE t1.AR BETWEEN ' || startAr || ' AND ' || senasteAr ||'
									      GROUP BY t1.REGION, t1.KON, t1.ALDER}');
			h_dodsriskerMedel.defineDone();

			h_dodsriskerRiket.keys([kon alder]);
			h_dodsriskerRiket.data([SCBdodstal SCBdodsrisk]);
			h_dodsriskerRiket.dataset('{SELECT t1.KON, t1.ALDER, (MEAN(case when medelbefolkning=0 then 0 else t1.DODA / t1.MEDELBEFOLKNING end)) AS SCBdodstal, (MEAN(case when medelbefolkning=0 then 0 else 1-(EXP(-(t1.DODA / t1.MEDELBEFOLKNING)))end)) AS SCBdodsrisk
									      FROM ' || strip(projdata) || '.SCB_BEFOLKNING t1 WHERE t1.AR BETWEEN ' || startAr || ' AND ' || senasteAr ||' and regiontyp=''Riket''
									      GROUP BY t1.KON, t1.ALDER}');
			h_dodsriskerRiket.defineDone();
			
			h_dodsriskerSCBPrognos.keys([ar kon alder]);
			h_dodsriskerSCBPrognos.data([progDodstal progDodsrisk]);
			h_dodsriskerSCBPrognos.dataset('{SELECT t1.ar, t1.KON,  t1.alder, (case when medelbefolkning=0 then 0 else t1.DODA / t1.MEDELBEFOLKNING end) as progDodstal, (case when medelbefolkning=0 then 0 else 1-(EXP(-(t1.DODA / t1.MEDELBEFOLKNING)))end) AS progDodsrisk
											      FROM ' || strip(userdata) || '.SCB_PROGNOSER_DETALJ t1}');
			h_dodsriskerSCBPrognos.defineDone();

			h_dodsrisker.keys([ar region kon alder]);
			h_dodsrisker.data([ar region kon alder dodstal dodsrisk addDtal multDtal scbDodstal scbDodsrisk]);
			h_dodsrisker.ordered('A');
			h_dodsrisker.defineDone();

			stmtMaxAr.prepare('select max(ar) as slutArSCB from ' || strip(userdata) || '.SCB_PROGNOSER_SAMMANFATTNING');
			stmtMaxAr.execute();
			stmtMaxAr.bindresults([slutArSCB]);
			stmtMaxAr.fetch();
			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region from ' || strip(iRegionNamn) || '}');
			h_regioner.defineDone();

			do ar=iBasAr to slutArSCB;
			hi_regioner.first([region]);
			do until(hi_regioner.next([region])<>0);
					do kon='män', 'kvinnor';
						do alder=0 to 100;
							h_dodsriskerMedel.find([region kon alder],[dodstal dodsrisk]);
							h_dodsriskerRiket.find([kon alder],[SCBdodstal SCBdodsrisk]);
							h_dodsriskerSCBPrognos.find([ar kon alder],[progDodstal progDodsrisk]);
							multDtal=1;
							addDtal=0;
							dodstal=(progDodstal/SCBdodstal)*dodstal;
							dodsrisk=(progDodsrisk/SCBDodsrisk)*dodsrisk;
							SCBdodstal=progDodstal;
							SCBdodsrisk=progDodsrisk;
							h_dodsrisker.ref([ar region kon alder],[ar region kon alder dodstal dodsrisk addDtal multDtal scbDodstal scbDodsrisk]);				
						end;
					end;*kon;
				end; *regioner;
			end;*ar;
		h_dodsrisker.output(strip(uDodsrisker));
		end;*run;

	endpackage ;
run;quit;
