proc ds2;
	package &prglib..rumprg_livstabell / overwrite=yes;
		dcl package &prglib..rumprg_nyttigheter nyttig();
		dcl package hash h_dodsrisker();
		dcl package hiter hi_dodsrisker('h_dodsrisker');
		dcl package hash h_livstabell();
		dcl package hiter hi_livstabell('h_livstabell');
		dcl char(8) userdata;
		dcl char(75) region;
		dcl char(50) kon iKon;
		dcl integer ar lagAlder region_cd alder iRegion iAlder ;
		dcl double dodsrisk kvarlevande_jan avlidna kvarlevande_dec levdaAr sumLevdaAr ackLevdaAr Livslangd;
		dcl double iKvarlevande_jan iAvlidna iKvarlevande_dec iLevdaAr iSumLevdaAr iLivslangd;

		method rumprg_livstabell();
			userdata=%tslit(&userdata);

			h_livstabell.keys([ar region_cd region kon alder]);
			h_livstabell.data([ar region_cd region kon alder kvarlevande_jan avlidna kvarlevande_dec levdaAr sumLevdaAr Livslangd]);
			h_livstabell.ordered('A');
			h_livstabell.defineDone();
		end;*init;

		method run(char(50) inDataTabell, char(50) regNamnTabell, char(50) utDataTabell);
			dcl integer rc;

			h_dodsrisker.keys([ar region_cd region alder kon]);
			h_dodsrisker.data([ar region_cd region alder kon  dodsrisk]);
			h_dodsrisker.dataset('{SELECT t1.ar, t1.region as region_cd, t2.region_nm as region, t1.alder, t1.kon, (sum(t1.dodsrisk,t1.addDtal)*t1.multDtal) as dodsrisk FROM ' || userdata || '.' || strip(inDataTabell) || ' t1, ' || userdata || '.' || strip(regNamnTabell) || ' t2 where (t1.region=t2.region_cd)}');
			h_dodsrisker.ordered('A');
			h_dodsrisker.defineDone();

			hi_dodsrisker.first([ar region_cd region alder kon dodsrisk]);
			do until(hi_dodsrisker.next([ar region_cd region alder kon dodsrisk])<>0);
				if alder=0 then do;
					kvarlevande_jan=100000;
					avlidna=dodsrisk*kvarlevande_jan;
					kvarlevande_dec=kvarlevande_jan-avlidna;
					levdaAr=0.15*avlidna+(kvarlevande_dec);
				end;
				else do;
					lagAlder=alder-1;
					h_livstabell.find([ar region_cd region kon lagAlder],[ar region_cd region kon lagAlder kvarlevande_jan avlidna kvarlevande_dec levdaAr sumLevdaAr livslangd]);
					kvarlevande_jan=kvarlevande_dec;
					avlidna=dodsrisk*kvarlevande_jan;
					kvarlevande_dec=kvarlevande_jan-avlidna;
					levdaAr=0.5*avlidna+(kvarlevande_dec);				
				end;
			h_livstabell.ref([ar region_cd region kon alder],[ar region_cd region kon alder kvarlevande_jan avlidna kvarlevande_dec levdaAr sumLevdaAr Livslangd]);
			end;*dodsrisker loop;
			hi_livstabell.last([ar region_cd region kon alder kvarlevande_jan avlidna kvarlevande_dec levdaAr sumLevdaAr Livslangd]);
			do until(hi_livstabell.prev([ar region_cd region kon alder kvarlevande_jan avlidna kvarlevande_dec levdaAr sumLevdaAr Livslangd])<>0);
				if alder=100 then do;
					ackLevdaAr=levdaAr;
					livslangd=ackLevdaAr/kvarlevande_jan;
				end;
				else do;
					ackLevdaAr=ackLevdaAr+levdaAr;
					livslangd=ackLevdaAr/kvarlevande_jan;
				end;
			h_livstabell.replace([ar region_cd region kon alder],[ar region_cd region kon alder kvarlevande_jan avlidna kvarlevande_dec levdaAr ackLevdaAr Livslangd]);
			end;*livstabell loop;

		rc=nyttig.finnsTabell(userdata,utDataTabell);

		if rc=1 then sqlexec('drop table ' || userdata || '.' || strip(utDataTabell));
		h_livstabell.output(userdata || '.' || strip(utDataTabell));

		end;*run;
	endpackage;
run;quit;