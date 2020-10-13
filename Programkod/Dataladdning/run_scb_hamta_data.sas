proc ds2;
	package &prglib..rumprg_GET_SCBDATA / overwrite=yes;
		declare package hash h_scbUrl();
		declare package hiter hi_scbUrl(h_scbUrl);
		declare varchar(15) datalib apiVar;
		declare varchar(30) filnamn;
		declare varchar(150) url sql;

		method rumprg_GET_SCBDATA();
			datalib=%tslit(&datalib);

			h_scbUrl.keys([filnamn]);
			h_scbUrl.data([url filnamn]);
			h_scbUrl.dataset('{select url, filnamn from work.apivarSCB}');
			h_scbUrl.defineDone();
		end;
			
		method run();
			declare integer rc;
			rc=hi_scbUrl.first([url, filnamn]);
			do until(hi_scbUrl.next([url, filnamn])<>0);
				declare package &prglib..pxwebtosas4 pxweb();
				pxweb.getData(strip(url), datalib);
				pxweb.delete();
			end;
		end;

	endpackage;
run;quit;
