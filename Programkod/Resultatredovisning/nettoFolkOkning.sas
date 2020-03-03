proc ds2;
	package &prglib..rumprg_nettoTal / overwrite=yes;
		dcl package &prglib..rumprg_nyttigheter nyttig();
		dcl private char(8) userdata;

		method rumprg_nettoTal();
			userdata=%tslit(&userdata);
		end;

		method run(char(50) prognosTabell, char(50) rapportTabell);
		dcl integer rc;

		rc=nyttig.finnsTabell(userdata, rapportTabell);
		if rc=1 then sqlexec('drop table ' || userdata || '.' || rapportTabell);
   			sqlexec('CREATE TABLE ' || userdata || '.' || rapportTabell || ' AS 
				   SELECT AR, REGION_CD, REGION, (INRIKESINFLYTTNING - INRIKESUTFLYTTNING) AS inrikesNettoInflyttning, (INVANDRINGAR - UTVANDRINGAR) AS utrikesNettoInflyttning,  (FODDA - DODA) AS NaturFolkokning
			       FROM ' || userdata || '.' || prognosTabell);		

		end;
run;quit;

