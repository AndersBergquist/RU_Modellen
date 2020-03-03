proc ds2;
	package &prglib..rumprg_RegIndelning / overwrite=yes;
		dcl package hash h_rumKommun();
		dcl package hash h_rumRegIndelning();
		dcl char(75) kommun_nm region_nm;
		dcl char(4) kommun_cd;
		dcl varchar(8) userdata projdata regind;
		dcl integer region_cd kommun_num storRegion_cd prognosregion;

	method rumprg_RegIndelning();
		userdata=%tslit(&userdata);
		projdata=%tslit(&datalib);
		regind=%tslit(&regind);

	end;*rumprg_inomRegIndelning, konstruktor;

	method run();
		h_rumKommun.keys([kommun_cd]);
		h_rumKommun.data([kommun_cd kommun_num kommun_nm region_cd region_nm storRegion_cd prognosregion]);
		h_rumKommun.dataset('{SELECT t1.kommun_cd, cast(t1.kommun_cd as double) as kommun_num, t1.kommun_nm, (cast(t1.kommun_cd as integer)) AS region_cd, t1.kommun_nm AS region_nm, t2.region_cd AS storRegion_cd, 
			      t1.prognosregion FROM work.KOMMUNER t1 INNER JOIN work.REGIONINDELNING t2 ON (t1.kommun_cd = t2.kommun_cd)}');
		h_rumKommun.defineDone();



		h_rumRegIndelning.keys([kommun_cd]);
		h_rumRegIndelning.data([kommun_cd kommun_num kommun_nm region_cd]);
		h_rumRegIndelning.dataset('{SELECT t1.kommun_cd, cast(t1.kommun_cd as double) as kommun_num, t1.kommun_nm, region_cd
			      FROM work.REGIONINDELNING t1 }');
		h_rumRegIndelning.defineDone();

		h_rumKommun.output(USERDATA ||'.RUM_KOMMUNER');
		h_rumRegIndelning.output(userdata || '.RUM_REGIONINDELNING');

sqlexec('create table ' || userdata || '.RUM_REGIONNAMN AS SELECT * FROM work.REGIONNAMN');
		sqlexec('create table ' || userdata || '.rum_rikes_kommuner as 
					select t2.kommun_cd, t2.kommun_num, t2.kommun_nm, t2.kommun_num AS region_cd, t2.kommun_nm AS region_nm, t1.prognosregion, t2.region_cd as storregion_num, t1.storregion_cd as kommun_sreg_cd 
					from ' || userdata || '.RUM_REGIONINDELNING as t2 left join ' || USERDATA ||'.RUM_KOMMUNER as t1 on (t2.kommun_cd = t1.kommun_cd)');

	end;*run;
run;quit;
