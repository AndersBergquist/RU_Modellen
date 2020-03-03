proc ds2;
	package &prglib..rumprg_flyttrisker / overwrite=yes;
		dcl char(8) userdata projdata;

		method rumprg_flyttrisker();
			userdata=%tslit(&userdata);
			projdata=%tslit(&datalib);
		end; *rumprg_flyttrisker - konstruktor;

		method run(integer iBasAr, integer iAntalAr, char(50) iScbBef, char(50) iScbFlyttMatris, char(50) uFlyttRisker);
			dcl private integer senasteAr startAr;
			senasteAr=iBasAr-1;
			startAr=iBasAr-iAntalAr;

			sqlexec('CREATE TABLE ' || strip(uFlyttRisker) || ' AS 
				SELECT t2.UTREGION_CD AS franRegion, t2.INREGION_CD AS tillRegion, t2.KON AS kon, t2.ALDER AS alder, 
					(MEAN(case when t2.UTREGION_CD=t2.INREGION_CD then 0 when t1.befolkning_dec=0 then 0 else t2.FLYTTNINGAR / t1.befolkning_dec end)) AS flyttal, 
					(MEAN(case when t2.UTREGION_CD=t2.INREGION_CD then 0 when t1.befolkning_dec=0 then 0 else 1-(exp(-(t2.FLYTTNINGAR / t1.befolkning_dec))) end)) AS flyttrisk, 
					(0) AS addFlyttRisk, 1 AS multFlyttRisk
				FROM ' || strip(iScbBef) || ' t1, ' || iScbFlyttMatris || ' t2
				WHERE (t1.region = t2.UTREGION_CD AND t1.kon = t2.KON AND t1.ar = t2.AR AND t1.alder = t2.ALDER) AND t2.ar >= ' || startAr || ' and t2.AR <= ' || senasteAr || '
				GROUP BY t2.UTREGION_CD, t2.INREGION_CD, t2.KON, t2.ALDER');
		end;*run;
	endpackage;
run;quit;