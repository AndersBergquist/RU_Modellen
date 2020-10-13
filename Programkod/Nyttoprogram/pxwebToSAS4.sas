/****************************************
Program: pxwebToSAS4
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.13

- output:
	1. Lämnar returkod till 0 om uppdatering genomförts och 1 om den inte genomförts.
***********************************/
proc ds2;
	package &prgLib..pxWebToSAS4 / overwrite=yes;
		declare package &prgLib..pxweb_UppdateTableDate SCB_Date();
		declare package &prgLib..pxweb_makeJsonFraga SCB_GetJsonFraga();
		declare package &prgLib..pxweb_getData SCB_getData();
		declare package &prgLib..pxweb_gemensammametoder g();
		declare package sqlstmt s_jsonGet;
		declare nvarchar(100000) jsonFraga;
		declare integer defaultMaxCells;
		declare nvarchar(35) vstring;

		forward getDataStart;

		method pxwebtosas4();
			defaultMaxCells=100000;
			vstring='pxwebToSAS version 4.0.12B3';
		end;
******** getData varianter för att göra det så flexibelt som möjligt att hämta data. start;
		method getData(nvarchar(500) inUrl) returns integer;
			declare nvarchar(8) libname;
			declare nvarchar(32) SASTabell tmpTable;
			declare integer maxCells upd;
			maxCells=defaultMaxCells;
			tmpTable=scan(scan(inUrl, -1, '/') || strip(put(time(),8.)), 1, '.');
			SASTabell=scan(scan(inUrl, -1, '/'), 1, '.');
			upd=getDataStart(inUrl, 'work', SASTabell, maxCells, tmpTable);
			return upd;
		end;

		method getData(nvarchar(500) inUrl, nvarchar(8) SASLib) returns integer;
			declare nvarchar(8) libname;
			declare nvarchar(32) SASTabell tmpTable;
			declare integer maxCells upd;
			maxCells=defaultMaxCells;
			tmpTable=scan(scan(inUrl, -1, '/') || strip(put(time(),8.)), 1, '.');
			SASTabell=scan(scan(inUrl, -1, '/'), 1, '.');
			upd=getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
			return upd;
		end;

		method getData(nvarchar(500) inUrl, integer maxCells, nvarchar(8) SASLib) returns integer;
			declare integer  upd;
			declare nvarchar(32) SASTabell tmpTable;
			tmpTable=scan(scan(inUrl, -1, '/') || strip(put(time(),8.)), 1, '.');
			SASTabell=scan(scan(inUrl, -1, '/'), 1, '.');
			upd=getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
			return upd;
		end;

		method getData(nvarchar(500) inUrl, nvarchar(8) SASLib, nvarchar(32) SASTabell) returns integer;
			declare integer maxCells upd;
			declare nvarchar(32) tmpTable;
			maxCells=defaultMaxCells;
			tmpTable=scan(scan(inUrl, -1, '/') || strip(put(time(),8.)), 1, '.');
			upd=getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
			return upd;
		end;

		method getData(nvarchar(500) inUrl, integer maxCells, nvarchar(8) SASLib, nvarchar(32) SASTabell) returns integer;
			declare integer upd;
			declare nvarchar(32) tmpTable;
			tmpTable=scan(scan(inUrl, -1, '/') || strip(put(time(),8.)), 1, '.');
			upd=getDataStart(inUrl, SASLib, SASTabell, maxCells, tmpTable);
			return upd;
		end;

******** getData varianter för att göra det så flexibelt som möjligt att hämta data. start;

		method getDataStart(nvarchar(500) iUrl, nvarchar(8) SASLib, nvarchar(32) SASTabell, integer maxCells, nvarchar(32) tmpTable) returns integer;
			declare package hash h_jsonFragor();
			declare package hiter hi_jsonFragor(h_jsonFragor);
			declare package sqlstmt s();
			declare double tableUpdated dbUpdate;
			declare nvarchar(41) fullTabellNamn;
			declare nvarchar(250) fraga;
			declare integer ud rc i rcGet rcF;
			declare integer starttid runTime loopStart min sek antalCeller;
			declare float cellerSek;

			starttid=time();

			fullTabellNamn=SASLib || '.' || SASTabell;
			tableUpdated=SCB_Date.getSCBDate(iUrl);
			dbUpdate=SCB_Date.getDBDate(fullTabellNamn);
			if dbUpdate < tableUpdated then do;
				antalCeller=SCB_GetJsonFraga.skapaFraga(iUrl, maxCells, fullTabellNamn, tmpTable);
				s_jsonGet = _new_ sqlstmt('select strip(jsonFraga) as jsonFraga from work.json_' || tmpTable);
				s_jsonGet.execute();
				rc=101;
 				do while (s_jsonGet.fetch()=0 and rc=101);
					s_jsonGet.getvarchar(1,jsonFraga,rcGet);
					loopStart=time();
					if jsonFraga^='' then rc=SCB_getData.hamtaData(iUrl, jsonFraga, tmpTable, fullTabellNamn);
					do while(time()-loopstart < 1);
					end;
				end;
				if rc=101 then rc=0;
				SCB_getData.closeTable();
				s_jsonGet.delete();
				if rc=300 or rc=301 then do;
					sqlexec('DELETE FROM work.' || tmpTable || '');
					ud=rc;
				end;
				if g.finnsTabell(fullTabellNamn)^=0 then sqlexec('INSERT INTO ' || fullTabellNamn || ' SELECT * FROM work.' || tmpTable  || ' EXCEPT SELECT * FROM ' || fullTabellNamn);
				else sqlexec('SELECT * INTO ' || fullTabellNamn || ' FROM work.' || tmpTable || '');

				if g.finnsTabell('work.' || tmpTable) ^= 0 then sqlexec('DROP TABLE work.' || tmpTable);
				if g.finnsTabell('work.meta_' || tmpTable) ^= 0 then sqlexec('DROP TABLE work.meta_' || tmpTable || ';');
				if g.finnsTabell('work.json_' || tmpTable) ^= 0 then sqlexec('DROP TABLE work.json_' || tmpTable || ';');
				ud=rc;
			end;
			else do;
				put 'pxWebToSAS.getDataStart: Det finns ingen uppdatering till' fullTabellNamn;
				ud=1;
			end;
			runtime=time()-starttid;
			cellerSek=divide(antalCeller,runtime);
			if runtime < 60 then do;
				put antalCeller nlnum24.-l ' celler hämtades på' runTime 'sekunder vilket motsvarar ' cellerSek nlnum27.2-l ' celler per sekund. Returkod:' ud;
			end;
			else do;
				min=int(runTime/60);
				sek=mod(runTime,60);
				put AntalCeller nlnum24.-l ' celler hämtades på' min 'minuter och ' sek 'sekunder vilket motsvarar ' cellerSek nlnum27.2-l ' celler per sekund. Returkod:' ud;
			end;
			put vstring;
			return ud;
		end;
	endpackage ;
run;quit;
