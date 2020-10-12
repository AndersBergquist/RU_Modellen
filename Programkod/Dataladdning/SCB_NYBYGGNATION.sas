proc  ds2;
	package &prglib..rumprg_SCB_NYBYGGNATION / overwrite=yes;
		declare package &prglib..pxwebtosas3a px();
		declare package &prglib..rumprg_nyttigheter nytta();
		declare varchar(500) url;
		declare varchar(8) datalib;
		declare integer maxCeller;

		method rumprg_SCB_NYBYGGNATION();
			url='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BO/BO0101/BO0101A/LghReHustypAr';
			maxCeller=50000;
			datalib=%tslit(&datalib);
		end;

		method run();
			declare integer finns;
			px.getData(url,maxCeller, datalib, 'SCB_NYBYGGNATION', 'AR');
			if nytta.finnsTabell('work','LghReHustypAr')=1 then do;
				if nytta.finnsTabell(datalib,'SCB_NYBYGGNATION')=0 then do;
					sqlexec('create table ' || datalib || '.SCB_NYBYGGNATION (
						ar integer,
						region varchar(4),
						regiontyp varchar(6),
						hustyp varchar(6),
						nyaLgh integer having format nlnum11.,
						uppdaterat_dttm datetime having format datetime16.
						)');
				end;
			sqlexec('insert into ' || datalib || '.SCB_NYBYGGNATION select cast(tid_cd as integer) as ar, region_cd as region,
				case when region_cd=''00'' then ''Riket'' when length(region_cd)=2 then ''Län'' else ''Kommun'' end as regiontyp,					
				hustyp_cd as hustyp, BO0101A5 as nyaLgh, uppdaterat_dttm from LGHREHUSTYPAR');
			sqlexec('drop table work.META_LGHREHUSTYPAR');
			sqlexec('drop table work.LGHREHUSTYPAR');
			sqlexec('drop table ' || datalib || '.META_SCB_NYBYGGNATION');
			end;
		end;
	endpackage;
run;quit;
