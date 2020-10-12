proc  ds2;
	package &prglib..rumprg_SCB_befolkning / overwrite=yes;
		declare package &prglib..rumprg_nyttigheter nytta();
		declare varchar(8) datalib;
		method rumprg_SCB_befolkning();
			datalib=%tslit(&datalib);
		end;
		method run();
			if nytta.finnsTabell('work','Befolkningnyb')=1 and nytta.finnsTabell('work','DODAFODELSEARKB')=1 and nytta.finnsTabell('work','flyttningar97b')=1 then do;
				if nytta.finnsTabell(datalib,'SCB_BEFOLKNING')= 0 then do;
					sqlexec('create table ' || datalib || '.SCB_BEFOLKNING (
							ar integer,
							regiontyp varchar(6),
							region varchar(4),
							kon varchar(7),
							alder integer,
							BEFOLKNING_DEC integer having format nlnum11.,
							Befolkning_jan integer having format nlnum11.,
							Medelbefolkning integer having format nlnum11.,
							FODDA integer having format nlnum11.,
							DODA integer having format nlnum11.,
							INRIKESINFLYTTNING integer having format nlnum11.,
							INRIKESUTFLYTTNING integer having format nlnum11.,
							INVANDRINGAR integer having format nlnum11.,
							UTVANDRINGAR integer having format nlnum11.,
							uppdaterat_dttm datetime having format datetime16.
							)');
				end;
				if nytta.finnsTabell('work','flyttningar68B')=1 then do;
					sqlexec('insert into work.flyttningar97B select * from work.flyttningar68B');
					sqlexec('drop table work.flyttningar68b');
				end;
				sqlexec('create table work.foddaAgg as select ar, regiontyp, kon, region, alder, sum(FODDA) as FODDA from ' || datalib || '.SCB_FODDA group by ar, regiontyp, kon, region, alder');
				sqlexec('INSERT INTO ' || datalib || '.scb_befolkning  SELECT t2.AR, t2.REGIONTYP, t2.REGION, t2.KON, t2.ALDER, t2.BEFOLKNING_DEC, 
			          (case when t2.alder=0 then 0 else (sum(t2.BEFOLKNING_DEC,t3.DODA,t1.INRIKESUTFLYTTNING,t1.UTVANDRINGAR,-t4.FODDA,-t1.INRIKESINFLYTTNING,-t1.INVANDRINGAR)) end) AS Befolkning_jan, 
			          (case when t2.alder=0 then t2.BEFOLKNING_DEC *0.5 else ((sum(t2.BEFOLKNING_DEC,t2.BEFOLKNING_DEC,t3.DODA,t1.INRIKESUTFLYTTNING,t1.UTVANDRINGAR,-t4.FODDA,-t1.INRIKESINFLYTTNING,-t1.INVANDRINGAR))*0.5)end) AS Medelbefolkning, 
			          t4.FODDA, t3.DODA, t1.INRIKESINFLYTTNING, t1.INRIKESUTFLYTTNING, t1.INVANDRINGAR, t1.UTVANDRINGAR, 
					  (datetime()) AS uppdaterat_dttm
			       FROM WORK.BEFOLKNINGNYB t2
		           INNER JOIN WORK.FLYTTNINGAR97B t1 ON (t2.AR = t1.AR) AND (t2.REGIONTYP = t1.REGIONTYP) AND (t2.KON = t1.KON) 
				          AND (t2.REGION = t1.REGION) AND (t2.ALDER = t1.ALDER)
		           INNER JOIN WORK.DODAFODELSEARKB t3 ON (t2.AR = t3.AR) AND (t2.REGIONTYP = t3.REGIONTYP) AND (t2.KON = t3.KON) AND (t2.REGION = t3.REGION) AND (t2.ALDER = t3.ALDER)
		           LEFT JOIN WORK.FODDAAGG t4 ON (t2.AR = t4.AR) AND (t2.REGIONTYP = t4.REGIONTYP) AND (t2.KON = t4.KON) AND 
			          (t2.REGION = t4.REGION) AND (t2.ALDER = t4.ALDER)
			      WHERE t2.ALDER <= 100');
				sqlexec('drop table work.Befolkningnyb');
				sqlexec('drop table work.DODAFODELSEARKB');
				sqlexec('drop table work.flyttningar97b');
				sqlexec('drop table work.foddaagg');
			end;
		end;
	endpackage;
run;quit;