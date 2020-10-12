proc ds2;
	package &prglib..rumprg_SCB_TABORT / overwrite=yes;
		dcl package hash h_SCB_Tabeller();
		dcl package hiter hi_SCB_Tabeller('h_SCB_Tabeller');
		dcl varchar(8) datalib;
		dcl varchar(100) table_name;
		method rumprg_SCB_TABORT();
			datalib=%tslit(&datalib);
		end;*rumprg_SCB_TABORT;

		method run();
			datalib=upcase(datalib);
			h_SCB_Tabeller.keys([table_name]);
			h_SCB_Tabeller.data([table_name]);
			h_SCB_Tabeller.dataset('{SELECT table_name FROM dictionary.tables where TABLE_SCHEM=''' || datalib || '''}');
			h_SCB_Tabeller.definedone();
			hi_SCB_Tabeller.first([table_name]);
			do until(hi_SCB_Tabeller.next([table_name]));
				if substr(table_name,1,4)='SCB_' then do;
					sqlexec('drop table ' || datalib || '.' ||  table_name);
				end;
			end;
		end;*run;

	endpackage;
run;quit;
