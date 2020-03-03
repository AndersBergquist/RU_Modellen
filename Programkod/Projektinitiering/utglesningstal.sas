proc ds2;
	package &prglib..rumprg_utglesningstal / overwrite=yes;
		declare package hash h_meanUtgles();
		declare package hash h_rum_utglesning();
		declare package hiter hi_meanUtgles(h_meanUtgles);
		declare varchar(8) userdata projdata;
		declare integer antalAr region ar;
		declare double utglesning;

		
		method rumprg_utglesningstal();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);
		end;

		method run(integer iStartAr, integer iSlutAr, integer iAntalAr);
			declare varchar(1000) sqlBef sqlNybygg sqlUtgles;
			declare integer i;

			antalAr=iStartAr-iAntalAr-1;

			sqlBef='CREATE TABLE WORK.BEFOLKNING AS 
			   SELECT t1.ar, t1.region, (SUM(t1.befolkning_dec)) AS befolkning_dec, (SUM(sum(t1.inrikesInflyttning,-t1.inrikesUtflyttning,t1.Invandringar,-t1.Utvandringar,-t1.doda,t1.fodda))) AS folkokning, (SUM(sum(t1.inrikesInflyttning,-t1.inrikesUtflyttning,t1.Invandringar,-t1.Utvandringar))) AS nettoFlytt
		      FROM ' || USERDATA || '.SCB_BEFOLKNING_KOM t1
		      GROUP BY t1.ar, t1.region';
			sqlNybygg='CREATE TABLE WORK.NYBYGGNATION AS 
					   SELECT t1.ar,cast(t1.region as integer) AS region, (SUM(case when t1.hustyp=''SMAHUS'' then 3.3*t1.nyaLgh else 2.1*t1.nyaLgh end)) AS nyaLghInflytt
					      FROM ' || projdata || '.SCB_NYBYGGNATION t1
					      WHERE t1.regiontyp = ''Kommun''
					      GROUP BY t1.ar, t1.region';
			sqlexec(sqlBef);
			sqlexec(sqlNybygg);

			h_meanUtgles.keys([region]);
			h_meanUtgles.data([region utglesning]);
			h_meanUtgles.dataset('{SELECT t1.region, (MEAN(1+(sum(t1.folkokning,-t2.nyaLghInflytt)/sum(t1.befolkning_dec,-t1.nettoFlytt,-t2.nyaLghInflytt)))) AS utglesning
					      FROM WORK.BEFOLKNING t1, WORK.NYBYGGNATION t2
					      WHERE (t1.ar = t2.ar AND t1.region = t2.region) AND t1.ar >= ' || antalAr || '
					      GROUP BY t1.region}');
			h_meanUtgles.defineDone();
			sqlexec('drop table WORK.BEFOLKNING');
			sqlexec('drop table WORK.NYBYGGNATION');

			h_rum_utglesning.keys([ar region]);
			h_rum_utglesning.data([ar region utglesning]);
			h_rum_utglesning.ordered('A');
			h_rum_utglesning.defineDone();

			do i=iStartAr to iSlutAr;
			ar=i;
				hi_meanUtgles.first([region utglesning]);
				do until(hi_meanUtgles.next([region utglesning])<>0);
					h_rum_utglesning.add([ar region],[ar region utglesning]);
				end;
			end;
			h_rum_utglesning.output(userdata || '.rum_utglesningstal_kom');
		end;
		

	endpackage;
run;quit;