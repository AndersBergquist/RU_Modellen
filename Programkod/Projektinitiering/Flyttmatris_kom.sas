proc ds2;
	package &prglib..rumprg_flyttMatrisKom / overwrite=yes;
		declare char(50) tillRegion franRegion;
		declare integer ar statAr justAdd justMult;

		method rumprg_flyttMatris();
		end;

		method run(integer iStartAr, integer iSlutAr, char(50) uScbBefolkning, char(50) iKommunIndelning, char(50) iSCBFlyttmatrisBas, char(50) uSCB_RiktadFlytt, char(50) u_SCB_Flyttningar, char(50) uFlyttRisker, integer iLagAr);
			declare package sqlstmt s_aktAr();
			statAr=iStartAr-min(iLagAr,15);


			sqlexec('CREATE TABLE work.andelKonAlder AS 
			   	SELECT t1.AR, t1.KON, t1.REGION, t1.ALDER, (case when t2.INRIKESUTFLYTTNING=0 then 0 else (t1.INRIKESUTFLYTTNING / t2.INRIKESUTFLYTTNING) end) AS andelUtflyttare
			      FROM ' || uScbBefolkning || ' t1, (SELECT t1.ar, t2.region_cd, t1.REGION, (SUM(t1.INRIKESUTFLYTTNING)) AS INRIKESUTFLYTTNING
			      	FROM ' || uScbBefolkning || ' as t1 INNER JOIN ' || iKommunIndelning || ' as t2 ON (t1.REGION = t2.kommun_cd)
			      	GROUP BY t1.ar, t2.region_cd, t1.REGION) t2
			      WHERE (t1.AR = t2.AR AND t1.REGION = t2.REGION)');

			sqlexec('CREATE TABLE work.bastabell AS 
				   SELECT t2.AR, t2.KON, t3.REGION_CD AS UTREGION_CD, t3.STORREGION_NUM AS ut_sreg_NUM, t4.REGION_CD AS INREGION_CD, 
				          t4.STORREGION_NUM AS in_sreg_NUM, t2.ALDER, (SUM(t1.FLYTTNINGAR * t2.ANDELUTFLYTTARE)) AS Flyttningar, t3.KOMMUN_SREG_CD
				      FROM ' || iSCBFlyttmatrisBas || ' t1, WORK.ANDELKONALDER t2,' || iKommunIndelning || ' t4, ' || iKommunIndelning || ' t3
				      WHERE (t1.AR = t2.AR AND t1.UTREGION_CD = t2.REGION AND t1.UTREGION_CD = t4.kommun_cd
							AND t1.INREGION_CD = t3.kommun_cd) AND (t3.KOMMUN_SREG_CD ^=. AND t4.KOMMUN_SREG_CD ^=. AND t2.AR BETWEEN ' || statAr || ' AND ' || iStartAr || ')
				      GROUP BY t2.AR, t2.KON, t3.REGION_CD, t3.STORREGION_NUM, t4.REGION_CD, t4.STORREGION_NUM, t2.ALDER, t3.KOMMUN_SREG_CD');

			sqlexec('CREATE TABLE ' || uSCB_RiktadFlytt || ' AS
				SELECT  t1.AR, t1.KON, t1.ALDER, t1.utregion_cd, t1.inregion_cd, t1.flyttningar
					FROM work.bastabell as t1
					WHERE t1.UT_sreg_num=t1.IN_sreg_num');

			sqlexec('CREATE TABLE work.bastabell_reg AS 
				   SELECT t2.AR, t2.KON, t3.REGION_CD AS UTREGION_CD, t3.STORREGION_NUM AS ut_sreg_NUM, t4.REGION_CD AS INREGION_CD, 
				          t4.STORREGION_NUM AS in_sreg_NUM, t2.ALDER, (SUM(t1.FLYTTNINGAR * t2.ANDELUTFLYTTARE)) AS Flyttningar, t3.KOMMUN_SREG_CD, t4.KOMMUN_SREG_CD AS IN_KOMMUN_SREG_CD
				      FROM ' || iSCBFlyttmatrisBas || ' t1, WORK.ANDELKONALDER t2,' || iKommunIndelning || ' t4, ' || iKommunIndelning || ' t3
				      WHERE (t1.AR = t2.AR AND t1.UTREGION_CD = t2.REGION AND t1.UTREGION_CD = t4.kommun_cd
							AND t1.INREGION_CD = t3.kommun_cd) AND (t3.prognosregion ^=. AND t4.prognosregion = . AND t2.AR BETWEEN ' || statAr || ' AND ' || iStartAr || ')
				      GROUP BY t2.AR, t2.KON, t3.REGION_CD, t3.STORREGION_NUM, t4.REGION_CD, t4.STORREGION_NUM, t2.ALDER, t3.KOMMUN_SREG_CD, t4.KOMMUN_SREG_CD');


			sqlexec('CREATE TABLE ' || strip(uSCB_RiktadFlytt) || '_REG AS
				SELECT t1.AR, t1.KON, t1.ALDER, t1.utregion_cd, t1.IN_SREG_NUM as inregion_cd, sum(flyttningar) as flyttningar
					FROM work.bastabell_reg as t1
					GROUP BY t1.AR, t1.KON, t1.ALDER, t1.utregion_cd, t1.IN_SREG_NUM
			');

			sqlexec('CREATE TABLE ' || u_SCB_Flyttningar || ' AS 
			   SELECT t1.AR, t1.KON, t1.ALDER, t1.REGION_CD, t2.inrikesInflyttning, t1.inrikesUtflyttning
			      FROM (SELECT t1.AR, t1.KON, t1.ALDER, t1.UTREGION_CD AS REGION_CD, t1.KOMMUN_SREG_CD, SUM(t1.FLYTTNINGAR) AS inrikesUtflyttning
					      FROM work.bastabell t1
					      WHERE t1.UTREGION_CD <> t1.INREGION_CD
					      GROUP BY t1.AR, t1.KON, t1.ALDER, t1.UTREGION_CD, t1.KOMMUN_SREG_CD) t1,
					   (SELECT t1.AR, t1.KON, t1.ALDER, t1.INREGION_CD AS REGION_CD, SUM(t1.FLYTTNINGAR) AS inrikesInflyttning
					      FROM work.bastabell t1
					      WHERE t1.UTREGION_CD <> t1.INREGION_CD
					      GROUP BY t1.AR, t1.KON, t1.ALDER, t1.INREGION_CD) t2
			      WHERE (t1.AR = t2.AR AND t1.KON = t2.KON AND t1.ALDER = t2.ALDER AND t1.REGION_CD = t2.REGION_CD and t1.kommun_sreg_cd^=.)');

			sqlexec('CREATE TABLE work.aktAr(Ar integer)');
			s_aktar.prepare('INSERT INTO work.aktAr(ar) VALUES(?)');
			s_aktar.BINDPARAMETERS([ar]);
			do ar=iStartAr to iSlutAr;
				s_aktAr.execute();
			end;
			s_aktAr.delete();
			sqlexec('CREATE TABLE work.kom_kom_matris as
				SELECT DISTINCT t1.utregion_cd as FRANREGION, t1.inregion_CD as tillregion, 0 as justADD, 1 as justMult
					FROM work.bastabell as t1
					WHERE UT_sreg_num=IN_sreg_num');
			sqlexec('CREATE TABLE ' || strip(uFlyttRisker) || '_TID AS
			   SELECT t2.ar, t1.FRANREGION, t1.TILLREGION, t1.JUSTADD, t1.JUSTMULT
			      FROM WORK.KOM_KOM_MATRIS t1,WORK.AKTAR t2');
			sqlexec('CREATE TABLE work.kom_reg_matris as
				SELECT DISTINCT t1.utregion_cd as FRANREGION, t1.IN_sreg_num as tillregion, 0 as justADD, 1 as justMult
					FROM work.bastabell as t1
					WHERE t1.kommun_sreg_cd^=.');
			sqlexec('CREATE TABLE ' || strip(uFlyttRisker) || '_REG_TID AS
			   SELECT t2.ar, t1.FRANREGION, t1.TILLREGION, t1.JUSTADD, t1.JUSTMULT
			      FROM WORK.KOM_REG_MATRIS t1,WORK.AKTAR t2');

			sqlexec('drop table work.andelKonAlder');
			sqlexec('drop table work.bastabell');
			sqlexec('drop table work.bastabell_reg');
			sqlexec('drop table work.kom_kom_matris');
			sqlexec('drop table work.kom_reg_matris');
			sqlexec('drop table work.aktAr');
		end;
	endpackage;
run;quit;