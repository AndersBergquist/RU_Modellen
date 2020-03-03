proc ds2;
	package &prglib..rumprg_skattflyttMatriskom / overwrite=yes;
	declare varchar(8) userdata projdata;


	method rumprg_flyttMatris();
		projdata=%tslit(&datalib);
		userdata=%tslit(&userdata);
	end;

	method run(varchar(100) scb_befolkning, varchar(100) scb_riktad_flytt_kommun, varchar(100) tmp_rikt_flytt);
	sqlexec('create table work.unobs as
				select t1.AR, t1.UTREGION_CD, sum(t2.SUM_of_INRIKESUTFLYTTNING, - t1.SUM_of_FLYTTNINGAR) AS oobs
				from (SELECT t1.AR, t1.UTREGION_CD, (SUM(t1.FLYTTNINGAR)) AS SUM_of_FLYTTNINGAR
						FROM ' || scb_riktad_flytt_kommun || ' as t1
						WHERE t1.INREGION_CD ^= ''9998''
						GROUP BY t1.AR, t1.UTREGION_CD) as t1,
					 (SELECT t1.AR, t1.REGION, (SUM(t1.INRIKESUTFLYTTNING)) AS SUM_of_INRIKESUTFLYTTNING
						FROM ' || SCB_BEFOLKNING || ' as t1
						GROUP BY t1.AR, t1.REGION) as t2
				WHERE (t1.AR = t2.AR AND t1.UTREGION_CD = t2.REGION)');
	sqlexec('create table work.korrobs as
				select t1.ar, t1.utregion_cd, (t2.oobs / t1.COUNT_of_INREGION_CD) AS korrOobs
				from (SELECT t1.AR, t1.UTREGION_CD, (COUNT(t1.INREGION_CD)) AS COUNT_of_INREGION_CD
					      FROM  ' || scb_riktad_flytt_kommun || ' as t1
					      WHERE t1.FLYTTNINGAR = 0 AND t1.UTREGION_CD ^= t1.INREGION_CD
					      GROUP BY t1.AR, t1.UTREGION_CD) as t1, work.unobs as t2
			    WHERE (t1.AR = t2.AR AND t1.UTREGION_CD = t2.UTREGION_CD)');
	sqlexec('CREATE TABLE ' || tmp_rikt_flytt || ' AS 
		SELECT t1.AR, t1.UTREGION_CD, t1.INREGION_CD, (case when t1.FLYTTNINGAR=0 then t2.korrOobs else t1.FLYTTNINGAR end) AS Flyttningar
		FROM ' || scb_riktad_flytt_kommun || ' as t1, WORK.korrobs as t2
		WHERE (t1.AR = t2.AR AND t1.UTREGION_CD = t2.UTREGION_CD) AND t1.INREGION_CD ^= ''9998'' AND t1.UTREGION_CD ^= t1.INREGION_CD');
	sqlexec('drop table work.unobs');
	sqlexec('drop table work.korrobs');
	userdata=%tslit(&userdata);
	end;
run;quit;
