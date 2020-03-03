proc ds2;
	package &prglib..rumprg_flyttMatrisFR / overwrite=yes;
		declare integer ar;
	method rumprg_flyttMatris();
	end;

	method run(integer iStartAr, integer iSlutAr, char(50) uScbBefolkning, char(50) iFranRegionIndelning, char(50) iTillRegionIndelning, char(50) uSCB_RiktadFlytt, char(50) iSCBFlyttmatrisBas, char(50) u_SCB_Flyttningar, char(50) uFlyttRisker, integer iLagAr);
		declare package sqlstmt s_aktAr();
		declare integer i statAr;
		statAr=iStartAr-min(iLagAr,15);

		sqlexec('CREATE TABLE work.andelKonAlder AS 
		   	SELECT t1.AR, t1.KON, t1.REGION, t1.ALDER, (case when t2.INRIKESUTFLYTTNING=0 then 0 else (t1.INRIKESUTFLYTTNING / t2.INRIKESUTFLYTTNING) end) AS andelUtflyttare
		      FROM ' || uScbBefolkning || ' t1, (SELECT t1.ar, t2.region_cd, t1.REGION, (SUM(t1.INRIKESUTFLYTTNING)) AS INRIKESUTFLYTTNING
		      	FROM ' || uScbBefolkning || ' as t1 INNER JOIN ' || iFranRegionIndelning || ' as t2 ON (t1.REGION = t2.kommun_cd)
		      	GROUP BY t1.ar, t2.region_cd, t1.REGION) t2
		      WHERE (t1.AR = t2.AR AND t1.REGION = t2.REGION)');
		sqlexec('CREATE TABLE ' || uSCB_RiktadFlytt || ' AS 
		   SELECT t1.AR, t1.KON, t1.ALDER, t3.region_cd AS utregion_cd, t4.region_cd AS inregion_cd, (SUM(t2.FLYTTNINGAR * t1.ANDELUTFLYTTARE)) AS flyttningar
		      FROM WORK.ANDELKONALDER t1, 
					' || iSCBFlyttmatrisBas || ' t2, ' || iFranRegionIndelning || ' t3, ' || iTillRegionIndelning || ' t4
		      WHERE (t1.AR = t2.AR AND t1.REGION = t2.UTREGION_CD AND t2.UTREGION_CD = t3.kommun_cd AND t2.INREGION_CD = 
		           t4.kommun_cd)  and (t1.ar >= ' || statAr || ' and t1.ar <= ' || iStartAr || ')
		      GROUP BY t1.AR, t1.KON, t1.ALDER, t3.region_cd, t4.region_cd');
		sqlexec('CREATE TABLE ' || u_SCB_Flyttningar || ' AS 
		   SELECT t1.AR, t1.KON, t1.ALDER, t1.REGION_CD, t2.inrikesInflyttning, t1.inrikesUtflyttning
		      FROM (SELECT t1.AR, t1.KON, t1.ALDER, t1.UTREGION_CD AS REGION_CD, SUM(t1.FLYTTNINGAR) AS inrikesUtflyttning
				      FROM ' || uSCB_RiktadFlytt || ' t1
				      WHERE t1.UTREGION_CD <> t1.INREGION_CD
				      GROUP BY t1.AR, t1.KON, t1.ALDER, t1.UTREGION_CD) t1,
				   (SELECT t1.AR, t1.KON, t1.ALDER, t1.INREGION_CD AS REGION_CD, SUM(t1.FLYTTNINGAR) AS inrikesInflyttning
				      FROM ' || uSCB_RiktadFlytt || ' t1
				      WHERE t1.UTREGION_CD <> t1.INREGION_CD
				      GROUP BY t1.AR, t1.KON, t1.ALDER, t1.INREGION_CD) t2
		      WHERE (t1.AR = t2.AR AND t1.KON = t2.KON AND t1.ALDER = t2.ALDER AND t1.REGION_CD = t2.REGION_CD)');

			sqlexec('CREATE TABLE work.aktAr(Ar integer)');
			s_aktar.prepare('INSERT INTO work.aktAr(ar) VALUES(?)');
			s_aktar.BINDPARAMETERS([ar]);
			do ar=iStartAr to iSlutAr;
				s_aktAr.execute();
			end;
			s_aktAr.delete();
			sqlexec('CREATE TABLE work.fr_matris as
				SELECT DISTINCT t1.utregion_cd as FRANREGION, t1.inregion_CD as tillregion, 0 as justADD, 1 as justMult
					FROM ' || uSCB_RiktadFlytt || ' as t1');
			sqlexec('CREATE TABLE ' || strip(uFlyttRisker) || '_TID AS
			   SELECT t2.ar, t1.FRANREGION, t1.TILLREGION, t1.JUSTADD, t1.JUSTMULT
			      FROM WORK.fr_MATRIS t1,WORK.AKTAR t2');

		sqlexec('drop table work.fr_matris');
		sqlexec('drop table work.aktAr');
		sqlexec('drop table work.andelKonAlder');
	end;

run;
quit;