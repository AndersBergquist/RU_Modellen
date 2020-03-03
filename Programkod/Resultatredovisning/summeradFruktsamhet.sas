proc ds2;
	package &prglib..rumprg_sumFrukt / overwrite=yes;
		dcl package &prglib..rumprg_nyttigheter nyttig();
		dcl private char(8) userdata;

		method rumprg_sumFrukt();
			userdata=%tslit(&userdata);
		end;*rumprg_sumFrukt;

		method run(char(50) prognosTabell, char(50) regNamnTabell, char(50) rapportTabell);
		dcl integer rc;

		rc=nyttig.finnsTabell(userdata, rapportTabell);
		if rc=1 then sqlexec('drop table ' || userdata || '.' || rapportTabell);

		sqlexec('CREATE TABLE ' || userdata || '.' || strip(rapportTabell) || ' AS SELECT t1.ar, t2.region_cd, t2.region_nm AS region, (SUM(sum(t1.fodelsetal, addFtal) * t1.multFtal)) AS summeradFruktsamhet
		      FROM ' || userdata || '.' || strip(prognosTabell) || ' t1, ' || userdata || '.' || strip(regNamnTabell) || ' t2 WHERE (t1.region = t2.region_cd)
		      GROUP BY t1.ar, t2.region_cd, t2.region_nm;');
		
		end;*run;
run;quit;