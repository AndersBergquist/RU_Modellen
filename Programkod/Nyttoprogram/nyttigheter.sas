proc ds2;
	package &prglib..rumprg_nyttigheter / overwrite=yes;
		dcl private varchar(8) lib;
		dcl private varchar(2000) tabell;
		dcl private integer antal;

	method rumprg_nyttigheter();
	end; *rumprg_nyttigheter;

	method finnsTabell(varchar(8) iLib, varchar(2000) iTabell) returns integer;
		dcl package sqlstmt s('select count(*) as antal from dictionary.tables where TABLE_SCHEM=? AND table_name=?',[lib tabell]);

		tabell=upcase(iTabell);
		lib=upcase(iLib);
		s.execute();
		s.bindresults([antal]);
		s.fetch();
		if antal > 0 then antal=1; else antal=0;
	return antal;
	end;*finnsTabell;


	endpackage;
run;quit;