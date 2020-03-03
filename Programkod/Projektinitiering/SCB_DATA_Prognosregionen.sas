proc ds2;
	package &prglib..rumprg_scbdata_preg / overwrite=yes;
		declare integer ar;
		method rumprg_scbdata_preg();

		end; *rumprg_scbdata; 

		method run(integer iBasAr, varchar(100) iIndelning, varchar(100) iFlyttKomKom, varchar(100) iSCBFlyttRegReg, varchar(100) iSCB_Befolkning, varchar(100) uSCB_Befolkning);
			declare package sqlstmt ejflytt();
			declare integer rc4;
	
			sqlexec('CREATE TABLE work.ejInomFlytt AS
						select t1.ar, t1.kon, t1.alder, t1.inrikesutflyttningar, t2.inrikesinflyttningar
						FROM
						   (SELECT t2.AR, t2.KON, t2.ALDER, t1.storRegion_cd, (SUM(t2.FLYTTNINGAR)) AS INRIKESUTFLYTTNINGAR
						      FROM ' || strip(iIndelning) || ' AS t1, ' || strip(iFlyttKomKom) || ' AS t2, ' || strip(iIndelning) || ' AS t3
						      WHERE (t1.kommun_num = t2.UTREGION_CD AND t3.kommun_num = t2.INREGION_CD) AND t3.prognosregion ^= 1
						      GROUP BY t2.AR, t2.KON, t2.ALDER, t1.storRegion_cd) AS t1,
							(SELECT t2.AR, t2.KON, t2.ALDER, t1.storRegion_cd, (SUM(t2.FLYTTNINGAR)) AS INRIKESINFLYTTNINGAR
						      FROM ' || strip(iIndelning) || ' AS t1, ' || strip(iFlyttKomKom) || ' AS t2, ' || strip(iIndelning) || ' AS  t3
						      WHERE (t1.kommun_num = t2.UTREGION_CD AND t3.kommun_num = t2.INREGION_CD) AND t1.prognosregion ^= 1
						      GROUP BY t2.AR, t2.KON,  t2.ALDER, t1.storRegion_cd) AS t2
						WHERE (t1.AR = t2.AR AND t1.storRegion_cd = t2.storRegion_cd AND t1.KON = t2.KON AND t1.ALDER = t2.ALDER)
					');
   			sqlexec('CREATE TABLE WORK.pregioner AS 
					   SELECT DISTINCT t1.storRegion_cd FROM USERDATA.RUM_KOMMUNER t1 WHERE t1.prognosregion = 1');
			sqlexec('CREATE TABLE work.bruttoFlytt AS
					   SELECT t1.AR, t1.KON, t1.ALDER, (SUM(t1.INRIKESUTFLYTTNINGAR)) AS INRIKESUTFLYTTNINGAR, (SUM(t2.INRIKESINFLYTTNINGAR)) AS INRIKESINFLYTTNINGAR
					   FROM  
						(SELECT t2.AR, t2.KON, t2.ALDER, t2.UTREGION_CD AS REGION_CD, (SUM(t2.FLYTTNINGAR)) AS INRIKESUTFLYTTNINGAR
						      FROM WORK.pregioner AS t3 RIGHT JOIN (WORK.pregioner AS t1 RIGHT JOIN ' || iSCBFlyttRegReg || ' AS t2 ON (t1.storRegion_cd = t2.UTREGION_CD))
								ON (t3.storRegion_cd = t2.INREGION_CD)
						      WHERE t1.storRegion_cd IS NOT NULL AND t3.storRegion_cd IS NULL
						      GROUP BY t2.AR, t2.KON, t2.ALDER, t2.UTREGION_CD) AS t1,
						(SELECT t2.AR, t2.KON, t2.ALDER, t2.INREGION_CD AS REGION_CD, (SUM(t2.FLYTTNINGAR)) AS INRIKESINFLYTTNINGAR
						      FROM WORK.pregioner AS t3 RIGHT JOIN (WORK.pregioner AS t1 RIGHT JOIN ' || iSCBFlyttRegReg || ' AS t2
							  ON (t1.storRegion_cd = t2.UTREGION_CD)) ON (t3.storRegion_cd = t2.INREGION_CD)
						      WHERE t1.storRegion_cd IS NULL AND t3.storRegion_cd IS NOT NULL
						      GROUP BY t2.AR, t2.KON, t2.ALDER, t2.INREGION_CD) AS t2
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
							(SELECT t1.ar, t1.kon, t1.alder, (SUM(t1.befolkning_dec)) AS befolkning_dec, (SUM(t1.medelbefolkning)) AS medelbefolkning, (SUM(t1.inrikesInflyttning)) AS inrikesInflyttningar, (SUM(t1.inrikesUtflyttning)) AS inrikesUtflyttning, 
							          	(SUM(t1.Invandringar)) AS Invandringar, (SUM(t1.Utvandringar)) AS Utvandringar, (SUM(t1.doda)) AS doda, (SUM(t1.fodda)) AS fodda
							      FROM ' || iSCB_Befolkning || ' AS t1 INNER JOIN ' || iIndelning || ' t2 ON (t1.region = t2.kommun_num)
							      WHERE t2.prognosregion = 1
							      GROUP BY t1.ar, t1.kon, t1.alder) AS t1, WORK.flyttningar AS t2
			      WHERE (t1.ar = t2.AR AND t1.kon = t2.KON AND t1.alder = t2.ALDER AND  t1.AR < ' || iBasAr || ')
			      ORDER BY t1.ar, t1.kon, t1.alder');
			sqlexec('CREATE TABLE ' || strip(uSCB_Befolkning) || '_SUM AS 
					   SELECT t1.ar, (SUM(t1.befolkning_dec)) AS befolkning_dec, (SUM(t1.medelbefolkning)) AS medelbefolkning, (SUM(t1.inrikesinflyttningar)) AS inrikesinflyttningar, (SUM(t1.inrikesutflyttningar)) AS inrikesutflyttningar, 
				            (SUM(t1.Invandringar)) AS Invandringar, (SUM(t1.Utvandringar)) AS Utvandringar, (SUM(t1.doda)) AS doda, (SUM(t1.fodda)) AS fodda
  						    FROM ' || uSCB_Befolkning || ' t1
						      GROUP BY t1.ar');
 
			sqlexec('drop table work.ejInomFlytt');
			sqlexec('drop table work.pregioner');
			sqlexec('drop table work.bruttoFlytt');
			sqlexec('drop table work.flyttningar');
		end; *run, skapar data för prognosregionen från SCB:s historiska data;
	endPackage ;

run;quit;
