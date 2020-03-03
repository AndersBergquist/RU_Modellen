proc ds2 ;
	package &prglib..rumprg_euroStatStdBef / overwrite=yes;
		dcl package &prglib..rumprg_nyttigheter nyttig();
		dcl package hash stdBef();
		dcl private char(8) userdata;
		dcl private integer alder rc;
		dcl private double stdBefolkning;

		method rumprg_euroStatStdBef();
			userdata=%tslit(&userdata);
			stdBef.keys([alder]);
			stdBef.data([alder stdBefolkning]);
			stdBef.ordered('A');
			stdBef.defineDone();

		end;*rumprg_euroStatStandardBefolkning;

		method run();
			do alder=0 to 100 by 1;
			if alder=0 then stdBefolkning=1000;
				else if 1<=alder<=4 then stdBefolkning=(4000/4);
				else if 5<=alder<=9 then stdBefolkning=(5500/5);
				else if 10<=alder<=14 then stdBefolkning=(5500/5);
				else if 15<=alder<=19 then stdBefolkning=(5500/5);
				else if 20<=alder<=24 then stdBefolkning=(6000/5);
				else if 25<=alder<=29 then stdBefolkning=(6000/5);
				else if 30<=alder<=34 then stdBefolkning=(6500/5);
				else if 35<=alder<=39 then stdBefolkning=(7000/5);
				else if 40<=alder<=44 then stdBefolkning=(7000/5);
				else if 45<=alder<=49 then stdBefolkning=(7000/5);
				else if 50<=alder<=54 then stdBefolkning=(7000/5);
				else if 55<=alder<=59 then stdBefolkning=(6500/5);
				else if 60<=alder<=64 then stdBefolkning=(6000/5);
				else if 65<=alder<=69 then stdBefolkning=(5500/5);
				else if 70<=alder<=74 then stdBefolkning=(5000/5);
				else if 75<=alder<=79 then stdBefolkning=(4000/5);
				else if 80<=alder<=84 then stdBefolkning=(2500/5);
				else if 85<=alder<=89 then stdBefolkning=(1500/5);
				else if 90<=alder<=94 then stdBefolkning=(800/5);
				else if 95<=alder<=100 then stdBefolkning=(203/6);
				stdBef.add([alder],[alder stdBefolkning]);
			end;*alder;
			rc=nyttig.finnsTabell(userdata,'eurostat_stdBef');
			if rc=1 then sqlexec('drop table ' || userdata || '.eurostat_stdBef');
			stdBef.output(userdata ||'.eurostat_stdBef');

		end;*run;

	endpackage;
run;quit;


