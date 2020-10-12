proc  ds2;
	package &prglib..rumprg_SCB_FODDA / overwrite=yes;
		declare package &prglib..pxwebtosas3a px();
		dcl package &prglib..rumprg_nyttigheter nytta();
		declare varchar(500) url;
		declare varchar(8) datalib;
		declare integer maxCeller;

		method rumprg_SCB_FODDA();
			url='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101H/FoddaK';
			maxCeller=50000;
			datalib=%tslit(&datalib);
		end;
		method run();
			declare integer finns;
			px.getData(url,maxCeller, datalib, 'SCB_FODDA', 'AR');
			if nytta.finnsTabell('work','FoddaK')=1 then do;;
				if nytta.finnsTabell(datalib,'SCB_FODDA')=0 then do;
					sqlexec('create table ' || datalib || '.SCB_FODDA (
							ar integer,
							regiontyp varchar(6),
							region varchar(4),
							kon varchar(7),
							alderModer integer,
							alder integer,
							fodda integer having format nlnum11.,
							uppdaterat_dttm datetime having format datetime16.
							)');
				end;
				sqlexec('insert into ' || datalib || '.SCB_FODDA  select cast(tid_cd as integer) as ar, case when region_cd=''00'' then ''Riket'' when length(region_cd)=2 then ''Län'' 
					else ''Kommun'' end as regiontyp, region_cd as region, kon_nm as kon, case when strip(alderModer_cd)=''-14'' then 14
					else cast(substr(alderModer_cd,1,2) as integer) end as alderModer, 0 as alder, BE0101E2 as fodda, uppdaterat_dttm
					from work.FoddaK where alderModer_cd not in (''tot'', ''us'')');
				sqlexec('drop table work.foddak');
				sqlexec('drop table work.meta_foddak');
				sqlexec('drop table ' || datalib || '.meta_SCB_FODDA');
			end;
		end;
	endpackage;
run;quit;
