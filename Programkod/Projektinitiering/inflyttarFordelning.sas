proc ds2;
	package &prglib..rumprg_inflyttarFordelning / overwrite=yes;
		dcl package hash h_fordelning();
		dcl package hiter hi_fordelning('h_fordelning');
		dcl package hash h_medeltal();
		dcl package hiter hi_medeltal('h_medeltal');
		dcl package hash h_medeltalTidserie();
		dcl varchar(8) userdata projdata;
		dcl char(50) kon;
		dcl integer ar region slutArSCB alder;
		dcl double sumAndelInflytt sumAndelInvand andelInflytt andelInvand addAndelInflytt multAndelInflytt addAndelInvand multAndelInvand;
		dcl double medAndelInflytt medAndelInvand tidAndelInflytt tidAndelInvand;

		method rumprg_inflyttarFordelning();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);
		end;
		method run(integer iBasAr, integer iAntalAr ,char(50) iScbBefolkning, char(50) iRumInflyttAndelar);
			dcl package sqlstmt stmtMaxAr();
			dcl integer rc senasteAr startAr;

			senasteAr=iBasAr-1;
			startAr=iBasAr-iAntalAr;

			h_fordelning.keys([ar region kon alder]);
			h_fordelning.data([ar region kon alder andelInflytt andelInvand]);
			h_fordelning.dataset('{SELECT t1.ar, t1.region, t1.kon, t1.alder, (case when t2.sumin=0 then 0 else (t1.inrikesInflyttning / t2.sumin) end) AS andelInflytt, 
					(case when t2.suminv = 0 then 0 else (t1.Invandringar / t2.suminv) end) AS andelInvand FROM ' || iScbBefolkning || ' t1,
						(select ar, region, sum(inrikesInflyttning) as sumin, sum(invandringar) as suminv from ' || iScbBefolkning || '  group by ar, region) t2 
						WHERE t1.ar=t2.ar and t1.region=t2.region and (t1.ar BETWEEN ' || startAr || ' AND ' || senasteAr || ')}');
			h_fordelning.defineDone();

			h_medeltal.keys([region kon alder]);
			h_medeltal.data([region kon alder medAndelInflytt medAndelInvand]);
			h_medeltal.ordered('A');
			h_medeltal.defineDone();

			h_medeltalTidserie.keys([ar region kon alder]);
			h_medeltalTidserie.data([ar region kon alder tidAndelInflytt addAndelInflytt multAndelInflytt tidAndelInvand addAndelInvand multAndelInvand]);
			h_medeltalTidserie.ordered('A');
			h_medeltalTidserie.defineDone();

			stmtMaxAr.prepare('select max(ar) as slutArSCB from ' || strip(userdata) || '.SCB_PROGNOSER_SAMMANFATTNING');
			stmtMaxAr.execute();
			stmtMaxAr.bindresults([slutArSCB]);
			stmtMaxAr.fetch();

			sumAndelInFlytt=0;
			sumAndelInvand=0;
			hi_fordelning.first();
			do until(hi_fordelning.next()<>0);
				rc=h_medeltal.find([region kon alder],[region kon alder sumAndelInFlytt sumAndelInvand]);
				if rc=0 then do;
					sumAndelInFlytt=sum(sumAndelInFlytt, AndelInflytt);
					sumAndelInvand=sum(sumAndelInvand, AndelInvand);
					h_medeltal.replace([region kon alder],[region kon alder sumAndelInFlytt sumAndelInvand]);
				end;
				else do;
					sumAndelInFlytt=AndelInflytt;
					sumAndelInvand=AndelInvand;
					h_medeltal.add([region kon alder],[region kon alder sumAndelInFlytt sumAndelInvand]);
				end;
			end;*Summeringsloop;

			hi_medeltal.first();
			do until(hi_medeltal.next()<>0);
				h_medeltal.find([region kon alder],[region kon alder andelInflytt andelInvand]);
				andelInflytt=andelInflytt/(senasteAr-startAr+1);
				andelInvand=andelInvand/(senasteAr-startAr+1);
				h_medeltal.replace([region kon alder],[region kon alder andelInflytt andelInvand]);
			end;*loop för att göra medelvärde;

			addAndelInflytt=0;
			multAndelInflytt=1;
			addAndelInvand=0;
			multAndelInvand=1;
			hi_medeltal.first();
			do until(hi_medeltal.next()<>0);
				h_medeltal.find([region kon alder],[region kon alder andelInflytt andelInvand]);
				do ar=iBasAr to slutArSCB;
					h_medeltalTidserie.ref([ar region kon alder],[ar region kon alder andelInflytt addAndelInflytt multAndelInflytt andelInvand addAndelInvand multAndelInvand]);
				end;*Loop genom alla prognosar;
			end;*Loop för tidserie;
	
			h_medeltalTidserie.output(iRumInflyttAndelar);
		end;*run;

	endpackage;*inflyttarFordelning*;
run;quit;