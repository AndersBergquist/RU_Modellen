proc ds2;
	package &prglib..rumprg_flyttaTabeller / overwrite=yes;
	dcl varchar(132) inTabell;
	dcl char(8) inLib;
	dcl integer antal;
	dcl varchar(2000) tabell;

		method rumprg_flyttaTabeller();

		end; *rumprg_prog_flyttaTabeller tom konstruktor; 

		method run(integer iBasAr);
			dcl varchar(1000) sql;
			dcl varchar(8) userdata projdata;

			projdata=%tslit(&datalib);
			userdata=%tslit(&userdata);

			do inTabell ='SCB_PROGNOSER_DODSTAL', 'SCB_PROGNOSER_SAMMANFATTNING';
				sql='create table ' || userdata || '.' || intabell || ' as select * from ' || projdata || '.' || intabell || ' where basar=' || iBasAr;
				sqlexec(sql);
			end;

			sqlexec('create table ' || strip(userdata) || '.SCB_PROGNOSER_FODDA as select ar, alderModer, sum(fodda) as fodda
									from ' || strip(projdata) || '.SCB_PROGNOSER_FODDA where basar=' || iBasAr || ' group by ar, alderModer');
			sqlexec('CREATE TABLE ' || strip(userdata) || '.SCB_PROGNOSER_DETALJ AS SELECT t1.ar, t1.kon, t1.alder, (SUM(t1.befolkning_dec)) AS befolkning_dec, (SUM(t1.doda)) AS doda, (SUM(t1.inflyttade)) AS inflyttade, (SUM(t1.utflyttade)) AS utflyttade, (SUM(t1.medelbefolkning)) AS medelbefolkning
				      FROM ' || strip(projdata) || '.SCB_PROGNOSER_DETALJ t1 WHERE t1.BASAR=' || iBasAr || ' GROUP BY t1.ar, t1.kon, t1.alder');

		end; *Flytta, flyttar tabeller utan att bearbeta dem;

	endPackage ;

run;quit;