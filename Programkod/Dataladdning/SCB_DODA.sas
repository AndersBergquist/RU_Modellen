proc  ds2;
	package &prglib..rumprg_SCB_Doda / overwrite=yes;
		declare package &prglib..pxwebtosas3a px();
		declare package &prglib..rumprg_nyttigheter nytta();
		declare varchar(500) url;
		declare varchar(8) datalib;
		declare integer maxCeller;

		method rumprg_SCB_Doda();
			url='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101I/DodaFodelsearK';
			maxCeller=50000;
			datalib=%tslit(&datalib);
		end;

		method run();
			declare integer finns;
			px.getData(url,maxCeller, datalib, 'SCB_BEFOLKNING', 'AR');
			if nytta.finnsTabell('work','DodaFodelsearK')=1 then do;
				sqlexec('create table work.DodaFodelsearKB as select cast(tid_cd as integer) as ar, case when region_cd=''00'' then ''Riket'' when length(region_cd)=2 then ''Län'' 
					else ''Kommun'' end as regiontyp, kon_nm as kon, region_cd as region, alder_cd as alder, BE0101D8 AS doda, uppdaterat_dttm	from work.DodaFodelsearK');
				sqlexec('drop table work.DodaFodelsearK');
				sqlexec('drop table work.meta_DodaFodelsearK');
				sqlexec('drop table ' || datalib || '.meta_SCB_BEFOLKNING');
			end;
		end;
	endpackage;
run;quit;
