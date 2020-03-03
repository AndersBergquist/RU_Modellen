proc ds2;
	package &prglib..rumprg_nybyggnad / overwrite=yes;
		dcl package hash h_rumNybyggnad();
		dcl package hash h_medelNybyggnad();
		dcl package hiter hi_medelNybyggnad('h_medelNybyggnad');
		dcl private integer slutArSCB senasteAr startAr region storregion ar addNyaLgh multNyaLgh;
		dcl private double nyaLgh;
		dcl private char(6) hustyp;
		dcl private varchar(8) userdata projdata;

		method rumprg_nybyggnad();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);
		end;

		method run(integer iBasAr, integer iAntalAr, char(50) iRegionNamn, char(50) iRumNybyggnad);
			dcl package sqlstmt stmtMaxAr();

			senasteAr=iBasAr-1;
			startAr=iBasAr-iAntalAr;

			h_rumNybyggnad.keys([ar region storregion hustyp]);
			h_rumNybyggnad.data([ar region storregion hustyp nyaLgh addNyaLgh multNyaLgh]);
			h_rumNybyggnad.ordered('A');
			h_rumNybyggnad.defineDone();

			h_medelNybyggnad.keys([region hustyp]);
			h_medelNybyggnad.data([region storregion hustyp nyaLgh]);
			h_medelNybyggnad.dataset('{SELECT t1.region_cd as region, t1.storregion_cd as storregion, t2.hustyp, mean(t2.nyaLgh) as nyaLgh 
					FROM ' || projdata || '.SCB_NYBYGGNATION as t2, ' || iRegionNamn || ' as t1
					where t1.kommun_cd=t2.region and t2.ar BETWEEN ' || startAr || ' AND ' || senasteAr || ' AND t2.AR < ' || iBasAr || '
					GROUP BY t1.region_cd, t1.storregion_cd, t2.hustyp}');
			h_medelNybyggnad.defineDone();

			stmtMaxAr.prepare('select max(ar) as slutArSCB from ' || strip(userdata) || '.SCB_PROGNOSER_SAMMANFATTNING');
			stmtMaxAr.execute();
			stmtMaxAr.bindresults([slutArSCB]);
			stmtMaxAr.fetch();

			addNyaLgh=0;
			multNyaLgh=1;
			hi_medelNybyggnad.first();
			do until(hi_medelNybyggnad.next()<>0);
				do ar=iBasAr to slutArSCB;
					h_rumNybyggnad.add([ar region storregion hustyp],[ar region storregion hustyp nyaLgh addNyaLgh multNyaLgh]);
				end;*ar;
			end;*Variabellistand;
			h_rumNybyggnad.output(iRumNybyggnad);
			h_rumNybyggnad.clear();
		end;
	endpackage;
run;quit;

