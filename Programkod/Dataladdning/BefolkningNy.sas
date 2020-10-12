proc  ds2;
	package &prglib..rumprg_SCB_befolkningNy / overwrite=yes;
		declare package &prglib..pxwebtosas3a px();
		declare package &prglib..rumprg_nyttigheter nytta();
		declare varchar(500) url;
		declare varchar(8) datalib;
		declare integer maxCeller;

		method rumprg_SCB_befolkningNy();
			url='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101A/BefolkningNy';
			maxCeller=50000;
			datalib=%tslit(&datalib);
		end;

		method run();
			declare integer finns;
			px.getData(url,maxCeller, datalib, 'SCB_BEFOLKNING', 'AR');
			if nytta.finnsTabell('work','BefolkningNy')=1 then do;
				sqlexec('create table work.BefolkningNyX as select cast(tid_cd as integer) as ar, case when region_cd=''00'' then ''Riket'' when length(region_cd)=2 then ''Län'' 
					else ''Kommun'' end as regiontyp, kon_nm as kon, region_cd as region, alder_cd as alder, BE0101N1 AS befolkning_dec, sum(BE0101N1,-BE0101N2) as befolkning_jan,
					sum(BE0101N1, BE0101N1,-BE0101N2)*0.5 as medelbefolkning, uppdaterat_dttm from work.BefolkningNy');
				sqlexec('create table work.BefolkningNyB as select ar, regiontyp, kon, region, alder, sum(befolkning_dec) AS befolkning_dec, 
					sum(case when ar=1968 then . else befolkning_jan end) as befolkning_jan,
					sum(case when ar=1968 then . else medelbefolkning end) as medelbefolkning from work.BefolkningNyX group by ar, regiontyp, kon, region, alder');
				sqlexec('drop table work.BefolkningNyX');
				sqlexec('drop table work.BefolkningNy');
				sqlexec('drop table work.meta_BefolkningNy');
				sqlexec('drop table ' || datalib || '.meta_SCB_BEFOLKNING');
			end;
		end;
	endpackage;
run;quit;
