proc ds2;
	package &prglib..rumprg_rap_preg / overwrite=yes;
		dcl package &prglib..rumprg_nyttigheter nyttig();
		declare integer ar;
		method rumprg_rap_preg();

		end; *rumprg_scbdata; 

		method run(varchar(100) iIndelning, varchar(100) iFlyttKomKom, varchar(100) iSCBFlyttRegReg, varchar(100) iSCB_Befolkning, varchar(100) iSCB_data, varchar(100) uSCB_Befolkning, varchar(100) uKombRes);
		declare package sqlstmt ejflytt();
		declare varchar(8) udata;
		declare varchar(50) uTabell uTabellSum uKombTabell uKombTabellSum;
		declare integer rc rc1 rc2 rc3 rc4;

		udata=scan(uSCB_Befolkning,1,'.');
		uTabell=scan(uSCB_Befolkning,-1,'.');
		uTabellSum=strip(scan(uSCB_Befolkning,-1,'.')) || '_sum';
		uKombTabell=scan(uKombRes,-1,'.');
		uKombTabellSum=strip(scan(uKombRes,-1,'.')) || '_sum';
		rc=nyttig.finnsTabell(udata, strip(uTabell));
		rc1=nyttig.finnsTabell(udata, strip(uTabellSum));
		rc2=nyttig.finnsTabell(udata, strip(uKombTabell));
		rc3=nyttig.finnsTabell(udata, strip(uKombTabellSum));
		if rc=1 then sqlexec('drop table ' || udata || '.' || strip(uTabell) );
		if rc1=1 then sqlexec('drop table ' || udata || '.' || strip(uTabellSum));
		if rc2=1 then sqlexec('drop table ' || udata || '.' || strip(uKombTabell) );
		if rc3=1 then sqlexec('drop table ' || udata || '.' || strip(uKombTabellSum));
			sqlexec('CREATE TABLE work.ejInomFlytt AS
						select t1.ar, t1.kon, t1.alder, t1.inrikesutflyttningar, t2.inrikesinflyttningar
						FROM
						   (SELECT t2.AR, t2.KON, t2.ALDER, t1.storRegion_cd, (SUM(t2.FLYTTADE)) AS INRIKESUTFLYTTNINGAR
						      FROM ' || strip(iIndelning) || ' AS t1, ' || strip(iFlyttKomKom) || ' AS t2, ' || strip(iIndelning) || ' AS t3
						      WHERE (t1.kommun_num = t2.franRegion AND t3.kommun_num = t2.tillRegion) AND t3.prognosregion ^= 1 and 
							  		t1.storregion_cd = t3.storregion_cd and t2.franRegion ^= t2.tillRegion
						      GROUP BY t2.AR, t2.KON, t2.ALDER, t1.storRegion_cd) AS t1,
							(SELECT t2.AR, t2.KON, t2.ALDER, t1.storRegion_cd, (SUM(t2.FLYTTADE)) AS INRIKESINFLYTTNINGAR
						      FROM ' || strip(iIndelning) || ' AS t1, ' || strip(iFlyttKomKom) || ' AS t2, ' || strip(iIndelning) || ' AS  t3
						      WHERE (t1.kommun_num = t2.franRegion AND t3.kommun_num = t2.tillRegion) AND t1.prognosregion ^= 1 and 
							  		t1.storregion_cd = t3.storregion_cd and t2.franRegion ^= t2.tillRegion
						      GROUP BY t2.AR, t2.KON,  t2.ALDER, t1.storRegion_cd) AS t2
						WHERE (t1.AR = t2.AR AND t1.storRegion_cd = t2.storRegion_cd AND t1.KON = t2.KON AND t1.ALDER = t2.ALDER)
					');
   			sqlexec('CREATE TABLE WORK.pregioner AS 
					   SELECT DISTINCT t1.storRegion_cd FROM USERDATA.RUM_KOMMUNER t1 WHERE t1.prognosregion = 1');
			sqlexec('CREATE TABLE work.bruttoFlytt AS
					   SELECT t1.AR, t1.KON, t1.ALDER, (SUM(t1.INRIKESUTFLYTTNINGAR)) AS INRIKESUTFLYTTNINGAR, (SUM(t2.INRIKESINFLYTTNINGAR)) AS INRIKESINFLYTTNINGAR
					   FROM  
						(SELECT t2.AR, t2.KON, t2.ALDER, t2.franRegion AS REGION_CD, (SUM(t2.FLYTTADE)) AS INRIKESUTFLYTTNINGAR
						      FROM WORK.pregioner AS t3 RIGHT JOIN (WORK.pregioner AS t1 RIGHT JOIN ' || iSCBFlyttRegReg || ' AS t2 ON (t1.storRegion_cd = t2.franRegion))
								ON (t3.storRegion_cd = t2.tillRegion)
						      WHERE t1.storRegion_cd IS NOT NULL AND t3.storRegion_cd IS NULL
						      GROUP BY t2.AR, t2.KON, t2.ALDER, t2.franRegion) AS t1,
						(SELECT t2.AR, t2.KON, t2.ALDER, t2.tillRegion AS REGION_CD, (SUM(t2.FLYTTADE)) AS INRIKESINFLYTTNINGAR
						      FROM WORK.pregioner AS t3 RIGHT JOIN (WORK.pregioner AS t1 RIGHT JOIN ' || iSCBFlyttRegReg || ' AS t2
							  ON (t1.storRegion_cd = t2.franRegion)) ON (t3.storRegion_cd = t2.tillRegion)
						      WHERE t1.storRegion_cd IS NULL AND t3.storRegion_cd IS NOT NULL
						      GROUP BY t2.AR, t2.KON, t2.ALDER, t2.tillRegion) AS t2
				      WHERE (t1.AR = t2.AR AND t1.REGION_CD = t2.REGION_CD AND t1.KON = t2.KON AND t1.ALDER = t2.ALDER)
				      GROUP BY t1.AR, t1.KON, t1.ALDER
					');
					ejflytt.prepare('select ar from work.ejInomFlytt');
					ejFlytt.execute();
					ejFlytt.bindresults([ar]);
					rc4=ejFlytt.fetch();
					ejFlytt.delete();
			if rc4=0 then do;
				sqlexec('CREATE TABLE work.flyttningar AS
						SELECT t2.AR, t1.KON, t1.ALDER, sum(t2.inrikesinflyttningar, -t1.inrikesinflyttningar) AS inrikesinflyttningar, sum(t2.inrikesUTFLYTTNINGAR, -t1.inrikesUTFLYTTNINGAR) AS inrikesUTFLYTTNINGAR
						      FROM WORK.ejInomFlytt t1, WORK.bruttoFlytt t2
						      WHERE (t1.AR = t2.AR AND t1.KON = t2.KON AND t1.ALDER = t2.ALDER)
						      ORDER BY t2.AR
				');
			end;
			else do;
				sqlexec('CREATE TABLE work.flyttningar AS SELECT * FROM WORK.bruttoFlytt');
			end;
			sqlexec('CREATE TABLE ' || uSCB_Befolkning || ' AS
						SELECT t1.ar, t1.kon, t1.alder, t1.befolkning_dec, t1.medelbefolkning, (case when t1.alder=0 then 0 else (sum(2*t1.medelbefolkning,-t1.befolkning_dec)) end) as befolkning_jan,
							sum(t1.befolkning_dec,-(case when t1.alder=0 then 0 else( sum(2*t1.medelbefolkning,-t1.befolkning_dec)) end)) AS folkokning, fodda, t1.doda, t2.inrikesinflyttningar, t2.inrikesutflyttningar, t1.Invandringar, t1.Utvandringar
						FROM
							(SELECT t1.ar, t1.kon, t1.alder, sum(t1.totalbefolkning) as befolkning_dec, sum(sum(t1.totalbefolkning,t1.totalbefolkningjan)/2) AS medelbefolkning, (SUM(t1.antalinflyttade)) AS inrikesInflyttningar, (SUM(t1.antalutflyttade)) AS inrikesUtflyttning, 
							          	(SUM(t1.antalinvandrade)) AS Invandringar, (SUM(t1.antalutvandrade)) AS Utvandringar, (SUM(t1.antaldoda)) AS doda, (SUM(t1.antalfodda)) AS fodda
							      FROM ' || iSCB_Befolkning || ' AS t1 INNER JOIN ' || iIndelning || ' t2 ON (t1.region = t2.kommun_num)
							      WHERE t2.prognosregion = 1
							      GROUP BY t1.ar, t1.kon, t1.alder) AS t1, WORK.flyttningar AS t2
			      WHERE (t1.ar = t2.AR AND t1.kon = t2.KON AND t1.alder = t2.ALDER)
			      ORDER BY t1.ar, t1.kon, t1.alder');
			sqlexec('CREATE TABLE ' || strip(uSCB_Befolkning) || '_SUM AS 
					   SELECT t1.ar, (SUM(t1.befolkning_dec)) AS befolkning_dec, (SUM(t1.medelbefolkning)) AS medelbefolkning, (SUM(t1.inrikesinflyttningar)) AS inrikesinflyttningar, (SUM(t1.inrikesutflyttningar)) AS inrikesutflyttningar, 
				            (SUM(t1.Invandringar)) AS Invandringar, (SUM(t1.Utvandringar)) AS Utvandringar, (SUM(t1.doda)) AS doda, (SUM(t1.fodda)) AS fodda
  						    FROM ' || uSCB_Befolkning || ' t1
						      GROUP BY t1.ar');
 			sqlexec('create table ' || uKombRes || ' (
					ar integer,
					kon varchar(7),
					alder integer,
					BEFOLKNING_DEC double having format nlnum11.,
					Befolkning_jan double having format nlnum11.,
					Medelbefolkning double having format nlnum11.,
					FODDA double having format nlnum11.,
					DODA double having format nlnum11.,
					INRIKESINFLYTTNINGAR double having format nlnum11.,
					INRIKESUTFLYTTNINGAR double having format nlnum11.,
					INVANDRINGAR double having format nlnum11.,
					UTVANDRINGAR double having format nlnum11.,
					status varchar(10),
					uppdaterat_dttm datetime having format datetime16.
					)');
 			sqlexec('create table ' || strip(uKombRes) || '_SUM (
					ar integer,
					BEFOLKNING_DEC double having format nlnum11.,
					Befolkning_jan double having format nlnum11.,
					Medelbefolkning double having format nlnum11.,
					FODDA double having format nlnum11.,
					DODA double having format nlnum11.,
					INRIKESINFLYTTNINGAR double having format nlnum11.,
					INRIKESUTFLYTTNINGAR double having format nlnum11.,
					INVANDRINGAR double having format nlnum11.,
					UTVANDRINGAR double having format nlnum11.,
					status varchar(10)
					)');
			sqlexec('insert into ' || uKombRes || '
					(ar, kon, alder, befolkning_dec, befolkning_jan, medelbefolkning, fodda, doda, inrikesinflyttningar, inrikesutflyttningar, invandringar, utvandringar, status, uppdaterat_dttm)
					select ar, kon, alder, befolkning_dec, befolkning_jan, medelbefolkning, fodda, doda, inrikesinflyttningar, inrikesutflyttningar, invandringar, utvandringar, ''Faktiskt'', datetime()
					from ' || iSCB_data  || '');
			sqlexec('insert into ' || uKombRes || '
					(ar, kon, alder, befolkning_dec, befolkning_jan, medelbefolkning, fodda, doda, inrikesinflyttningar, inrikesutflyttningar, invandringar, utvandringar, status, uppdaterat_dttm)
					select ar, kon, alder, befolkning_dec, befolkning_jan, medelbefolkning, fodda, doda, inrikesinflyttningar, inrikesutflyttningar, invandringar, utvandringar, ''Prognos'', datetime()
					from ' || strip(uSCB_Befolkning)  || '');

			sqlexec('insert into ' || strip(uKombRes) || '_SUM 
					select t1.ar, sum(t1.befolkning_dec) as befolkning_dec, sum(t1.befolkning_jan) as befolkning_jan, sum(t1.medelbefolkning) as medelbefolkning, sum(t1.fodda) as fodda, sum(t1.doda) as doda,
							sum(t1.inrikesinflyttningar) as inrikesinflyttningar, sum(t1.inrikesutflyttningar) as inrikesutflyttningar, sum(t1.invandringar) as invandringar, sum(t1.utvandringar) as utvandringar, status
					from  ' || uKombRes || ' as t1
					group by ar, status');

			sqlexec('drop table work.ejInomFlytt');
			sqlexec('drop table work.pregioner');
			sqlexec('drop table work.bruttoFlytt');
			sqlexec('drop table work.flyttningar');
		end; *run, skapar data f�r prognosregionen fr�n SCB:s historiska data;
	endPackage ;

run;quit;

