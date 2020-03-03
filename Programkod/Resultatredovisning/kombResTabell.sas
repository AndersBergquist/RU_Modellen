proc ds2;
	package &prglib..rumprg_kombResTabell / overwrite=yes;
		dcl package &prglib..rumprg_nyttigheter nyttig();
		dcl private char(8) userdata;

		method rumprg_kombResTabell();
			userdata=%tslit(&userdata);
		end;

		method run(char(50) scbTabell, char(50) prognosTabell, char(50) regNamnTabell, char(50) rapportTabell);
		dcl integer rc;

		rc=nyttig.finnsTabell(userdata, rapportTabell);
		if rc=1 then sqlexec('drop table ' || userdata || '.' || rapportTabell);
		
		sqlexec('create table ' || userdata || '.' || strip(rapportTabell) || ' as
			select t1.ar, t1.region as region_cd, t2.region_nm as region, t1.kon, t1.alder, t1.befolkning_dec, t1.inrikesInflyttning, t1.inrikesUtflyttning, t1.Invandringar, t1.Utvandringar, t1.doda, t1.fodda, ''Faktiskt'' as status from ' || userdata || '.' || strip(scbTabell) || ' t1, ' || userdata || '.' || strip(regNamnTabell) || ' t2 where (t1.region=t2.region_cd) 
			union
			select t1.ar, t1.region as region_cd, t2.region_nm as region, t1.kon, t1.alder, t1.totalBefolkning as befolkning_dec, t1.antalInflyttade as inrikesInflyttning, t1.antalUtflyttade as inrikesUtflyttning, t1.antalInvandrade as Invandringar, t1.antalUtvandrade as Utvandringar, t1.antalDoda as doda, t1.antalFodda as fodda, ''Prognos'' as status from ' || userdata || '.' || strip(prognosTabell) || ' t1, ' || userdata || '.' || strip(regNamnTabell) || ' t2 where (t1.region=t2.region_cd)');

		rc=nyttig.finnsTabell(userdata, strip(rapportTabell) || '_SUM');
		if rc=1 then sqlexec('drop table ' || userdata || '.' || strip(rapportTabell) || '_SUM');
		sqlexec('create table ' || userdata || '.' || strip(rapportTabell) || '_SUM as select ar, region_cd, region, sum(befolkning_dec) as befolkning_dec, sum(inrikesInflyttning) as inrikesInflyttning, sum(inrikesUtflyttning) as inrikesUtflyttning, sum(Invandringar) as Invandringar, sum(Utvandringar) as Utvandringar, sum(doda) as doda, sum(fodda) as fodda, status from ' || userdata || '.' || strip(rapportTabell) || ' group by ar, region_cd, region, status');

		end;
run;quit;