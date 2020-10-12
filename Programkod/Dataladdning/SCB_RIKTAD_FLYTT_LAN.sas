proc  ds2;
	package &prglib..rumprg_SCB_RflyttLan_hist / overwrite=yes;
		declare package &prglib..pxwebtosas3a px();
		declare package &prglib..rumprg_nyttigheter nytta();
		declare varchar(500) url;
		declare varchar(8) datalib;
		declare integer maxCeller;

		method rumprg_SCB_RflyttLan_hist();
			url='http://api.scb.se/OV0104/v1/doris/sv/ssd/START/BE/BE0101/BE0101J/InOmflytt';
			maxCeller=50000;
			datalib=%tslit(&datalib);
		end;

		method run();
			declare integer finns;
			px.getData(url,maxCeller, datalib, 'SCB_RIKTAD_FLYTT_LAN', 'AR');
			if nytta.finnsTabell('work','InOmflytt')=1 then do;
				sqlexec('create table ' || datalib || '.SCB_RIKTAD_FLYTT_LAN as select cast(tid_cd as integer) as ar, kon_nm as kon, INFLYTTNINGSL_CD as inflyttLan, UTFLYTTNINGSL_CD as utflyttLan, 
					X000000OW AS omflyttning, uppdaterat_dttm from work.InOmflytt');
				sqlexec('drop table work.InOmflytt');
				sqlexec('drop table work.meta_InOmflytt');
				sqlexec('drop table ' || datalib || '.META_SCB_RIKTAD_FLYTT_LAN');
			end;
		end;
	endpackage;
run;quit;
