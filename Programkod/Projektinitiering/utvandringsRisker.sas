proc ds2;
	package &prglib..rumprg_utvandringsrisker / overwrite=yes;
		dcl package hash h_utvandringsRisker();
		dcl package hash h_utvandringsTal();
		dcl package hash h_scbUtvandringsTal();
		dcl package hash h_progUtvandringsTal();
		dcl package hash h_progAntalAr();
		dcl package hash h_regioner();
		dcl package hiter hi_regioner('h_regioner');
		dcl package hiter hi_progAntalAr('h_progAntalAr');
		dcl private char(8) userdata projdata;
		dcl private char(50) kon;
		dcl private integer ar region alder;
		dcl private double utvandringsTal utvandringsRisk addUtvRisk multUtvRisk progFlyttal riksUtvandringstal;


		method rumprg_utvandringsrisker();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);
		end;*rumprg_utvandringsrisker, konstruktor;

		method run(integer iBasAr, integer iAntalAr,char(50) iScbBefolkning, char(50) iRegionNamn, char(50) uUtvandRisk);
			dcl integer senasteAr startAr;
			senasteAr=iBasAr-1;
			startAr=iBasAr-iAntalAr;
			
			h_regioner.keys([region]);
			h_regioner.data([region]);
			h_regioner.dataset('{select region_cd as region from ' || strip(iRegionNamn) || '}');
			h_regioner.defineDone();

			h_utvandringsTal.keys([region kon alder]);
			h_utvandringsTal.data([utvandringsTal]);
			h_utvandringsTal.dataset('{SELECT region, kon, alder, MEAN(case when medelbefolkning=0 then 0 else (Utvandringar / medelbefolkning) end) AS utvandringstal
				      FROM ' || strip(iScbBefolkning) || ' WHERE ar BETWEEN ' || startAr || ' AND ' || senasteAr || ' GROUP BY region, kon, alder}');
			h_utvandringsTal.defineDone();

			h_scbUtvandringsTal.keys([kon alder]);
			h_scbUtvandringsTal.data([riksUtvandringstal]);
			h_scbUtvandringsTal.dataset('{SELECT kon, alder, MEAN(case when medelbefolkning=0 then 0 else (Utvandringar / medelbefolkning) end) AS riksUtvandringstal
				      FROM ' || strip(projdata) || '.SCB_BEFOLKNING WHERE ar BETWEEN ' || startAr || ' AND ' || senasteAr || ' AND regiontyp=''Riket'' GROUP BY kon, alder}');
			h_scbUtvandringsTal.defineDone();

			h_progUtvandringsTal.keys([ar kon alder]);
			h_progUtvandringsTal.data([progFlyttal]);
			h_progUtvandringsTal.dataset('{SELECT ar, kon, alder, (SUM(Utflyttade) / sum(medelbefolkning)) AS progFlyttal
				      FROM ' || strip(userdata) || '.SCB_PROGNOSER_DETALJ GROUP BY ar, kon, alder}');
			h_progUtvandringsTal.defineDone();

			h_progAntalAr.keys([ar]);
			h_progAntalAr.data([ar]);
			h_progAntalAr.dataset('{SELECT DISTINCT ar from ' || strip(userdata) || '.SCB_PROGNOSER_DETALJ}');
			h_progAntalAr.defineDone();

			h_utvandringsRisker.keys([ar region kon alder]);
			h_utvandringsRisker.data([ar region kon alder utvandringsTal utvandringsRisk addUtvRisk multUtvRisk]);
			h_utvandringsRisker.ordered('A');
			h_utvandringsRisker.defineDone();

			multUtvRisk=1;
			addUtvRisk=0;
			hi_regioner.first([region]);
			do until(hi_regioner.next([region]));
				hi_progAntalAr.first([ar]);
				do until(hi_progAntalAr.next([ar]));
					do kon='män', 'kvinnor';
						do alder=0 to 100;
							h_utvandringsTal.find([region kon alder],[utvandringsTal]);
							h_scbUtvandringsTal.find([kon alder],[riksUtvandringstal]);
							h_progUtvandringsTal.find([ar kon alder],[progFlyttal]);
							utvandringsTal=progFlyttal*(utvandringstal/riksUtvandringstal);
							utvandringsRisk=(1-(EXP(-(utvandringsTal))));
							h_utvandringsRisker.ref([ar region kon alder],[ar region kon alder utvandringsTal utvandringsRisk addUtvRisk multUtvRisk]);
						end;
					end;*kon;
				end; *ar;
			end;*regioner;
		h_utvandringsRisker.output(strip(uUtvandRisk));
		end;*run;

	endpackage;
run;quit;