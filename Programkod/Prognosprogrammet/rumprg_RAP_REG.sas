proc ds2;
	package &prglib..rumprg_RAP_REG / overwrite=yes;
		declare varchar(8) userdata;

	method rumprg_RAP_REG();
		userdata=%tslit(&userdata);
	end;*rumprg_RAP_REG();

	method run(varchar(150) f_kommunData);
		declare varchar(500) sql_agg;
		declare package &prglib..pxweb_GemensammaMetoder nyttigheter();

		if nyttigheter.finnsTabell(strip(userdata),f_kommunData)<>0 then sqlexec('drop table ' || strip(userdata) || '.' || f_kommunData);
		sqlexec('create table ' || strip(userdata) || '.' || f_kommunData || '{option label=''Prognosdata för prognosregionen''}(
			ar integer having format 4. label ''Prognosår'',
			kon char(7) having label ''Kön'',
			alder integer having format 3. label ''Ålder'',
			totalbefolkning double having format nlnum11. label ''Befolkning den 31 december'',
			totalbefolkningjan double having format nlnum11. label ''Befolkning den 1 januari'',
			antalFodda double having format nlnum11. label ''Födda under året'',
			antalDoda double having format nlnum11. label ''Döda under året'',
			antalInflyttade double having format nlnum11. label ''Inrikes inflyttade under året'',
			antalUtflyttade double having format nlnum11. label ''Inrikes utflyttade under året'',
			antalInvandrade double having format nlnum11. label ''Invandrade under året'',
			antalUtvandrade double having format nlnum11. label ''Utvandrade under året''
		)');

		if nyttigheter.finnsTabell('WORK','aggdata')<>0 then sqlexec('drop table work.aggdata');	
		sqlexec('create table work.aggdata as select t1.ar, t1.kon, t1.alder, sum(t1.totalbefolkning) as totalbefolkning,
			sum(t1.totalbefolkningjan) as totalbefolkningjan, sum(t1.antalFodda) as antalFodda, sum(t1.antalDoda) as antalDoda,
			sum(t1.antalInflyttade) as antalInflyttade, sum(t1.antalUtflyttade) as antalUtflyttade,
			sum(t1.antalInvandrade) as antalInvandrade, sum(t1.antalUtvandrade) as antalUtvandrade
			from ' || strip(userdata) || '.RUM_KOM_RESULTAT t1 inner join ' || strip(userdata) || '.RUM_KOMMUNER t2
			on (t1.region = t2.kommun_num) where t2.prognosregion=1 GROUP BY t1.ar, t1.kon, t1.alder');

		sqlexec('insert into ' || strip(userdata) || '.' || f_kommunData || ' select * from work.aggdata'); *Pröva om det går med subquery. till 2.;
		if nyttigheter.finnsTabell('WORK','aggdata')<>0 then sqlexec('drop table work.aggdata');	
		

	end;*run();

run;quit;

/*
proc ds2;
	data _null_;
		declare package &prglib..rumprg_RAP_REG rap_reg();
		
		method run();
			rap_reg.run('test');
		end;
	enddata;
run;quit;
*/


