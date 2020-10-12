proc  ds2;
	package &prglib..rumprg_SCB_flyttning97 / overwrite=yes;
		declare package &prglib..pxwebtosas3a px97();
		declare package &prglib..rumprg_nyttigheter nytta();
		declare varchar(500) url97;
		declare varchar(8) datalib;
		declare integer maxCeller;

		method rumprg_SCB_flyttning97();
			url97='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101J/Flyttningar97';
			maxCeller=50000;
			datalib=%tslit(&datalib);
		end;

		method run();
			declare integer finns;
			px97.getData(url97,maxCeller, datalib, 'SCB_BEFOLKNING', 'AR');
			if nytta.finnsTabell('work','Flyttningar97')=1 then do;
				sqlexec('create table work.Flyttningar97B as select cast(tid_cd as integer) as ar, case when region_cd=''00'' then ''Riket'' when length(region_cd)=2 then ''Län'' 
					else ''Kommun'' end as regiontyp, kon_nm as kon, region_cd as region, alder_cd as alder, BE0101A2 AS inrikesinflyttning, BE0101A3 AS inrikesutflyttning,
					BE0101AX AS Invandringar, BE0101AY AS Utvandringar	from work.Flyttningar97 where alder_cd^=999');
				sqlexec('drop table work.Flyttningar97');
				sqlexec('drop table work.meta_Flyttningar97');
				sqlexec('drop table ' || datalib || '.meta_SCB_BEFOLKNING');
			end;
		end;
	endpackage;
run;quit;

