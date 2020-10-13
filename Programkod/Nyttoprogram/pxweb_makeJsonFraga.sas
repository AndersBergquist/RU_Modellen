/****************************************
Program: pxweb_makeJsonFraga.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.13
Uppgift:
- Skapar json-fråga till datahämtning och lagrar frågorna i filen work.json_tmpTabell;
***********************************/
proc ds2;
	package &prgLib..pxweb_makeJsonFraga / overwrite=yes;
		declare package &prgLib..pxweb_GemensammaMetoder g();
		declare package &prgLib..pxweb_getMetaData getMetaData();
		declare package sqlstmt s_subFragor();
		declare package sqlstmt s_subFragorFind();
		declare package sqlstmt s_jsonFragor();
		declare package sqlstmt s_countJsonFragor();
		declare package sqlstmt s_loopMetadata();
		declare nvarchar(250) subCode;
			declare nvarchar(250) title code text values valueTexts elimination "time";
		declare nvarchar(25000) subFraga;
		declare nvarchar(100000) jsonFraga;
		declare integer numJsonFragor;
		forward skapaSubFraga skapaFragehash skapaFrageHashHelper skapaFrageHashHelper2 countRows;

		method pxweb_makeJsonFraga();
		end;

		method skapaFraga(nvarchar(500) iUrl, integer maxCells, nvarchar(41) fullTabellNamn, nvarchar(32) tmpTable) returns integer;
			declare integer antalCells;
			getMetaData.getData(iURL, maxCells, fullTabellNamn, tmpTable);
			skapaSubFraga(tmpTable);
			skapaFragehash(tmpTable);
			countRows(tmpTable);
			sqlexec('drop table work.sub_' || tmpTable);
			antalCells=getMetadata.getAntalCeller();
			return antalCells;
		end;

		method skapaFragehash(nvarchar(32) tmpTable);
			declare integer maxDeep;
			declare nvarchar(1000) sql_skapajsontabell;
			sqlexec('create table work.json_' || tmpTable || ' (jsonFraga varchar(1000000))');
			s_jsonFragor = _new_ sqlstmt('insert into work.json_' || tmpTable || '(jsonFraga) values(?)',[jsonFraga]);
			
			maxDeep=getMetaData.getAntalCodes();
			skapaFrageHashHelper(1,maxDeep,'', tmpTable);
			s_jsonFragor.delete();
		end;

		method skapaFrageHashHelper(int deep, int maxDeep, nvarchar(100000) qstring, nvarchar(32) tmpTable);
			declare nvarchar(100000) v_qstring[800];
			declare nvarchar(100000) local_qstring;
			declare integer AntalFragor rc i k;

			s_subFragorFind = _new_ sqlstmt('select strip(subCode) as subCode, strip(subFraga) as subFraga from work.sub_' || tmpTable || ' WHERE subCode=?',[subCode]);

			subCode=getMetaData.getLevelCode(deep);
        ** Läser in frågorna till vektor. Start **;
			antalFragor=0;
			s_subFragorFind.execute();
			s_subFragorFind.bindresults([subCode, subFraga]);
			rc=s_subFragorFind.fetch();
			do while(rc=0);
				antalFragor=antalFragor+1;
				v_qstring[antalFragor]=subFraga;
				rc=s_subFragorFind.fetch();
			end;
			s_subFragorFind.delete();
        ** Läser in frågorna till vektor. Slut **;
			do k=1 to antalFragor;
				if deep=1 then do;
					local_qstring=v_qstring[k];
				end;
				else do;
					local_qstring=qstring || ',' || v_qstring[k];
				end;
				if deep = maxDeep then do;
					jsonFraga='{"query": [' || local_qstring || ',  {"code":"ContentsCode", "selection":{"filter":"all", "values":["*"]}} ], "response": {"format": "json"}}';
					s_jsonFragor.execute();
				end;
				else do;
					skapaFrageHashhelper(deep+1, maxDeep, local_qstring, tmpTable);
				end;
			end;
		end;

		method skapaSubFraga(nvarchar(32) tmpTable);
			declare nvarchar(25000) stubFraga;
			declare integer rundaNr iDataStorlek sizeDataStorlek iMetaData sizeMetaData antal cellerPerValue x;

			sqlexec('create table work.sub_' || tmpTable || ' (subCode nvarchar(250), subFraga nvarchar(25000))');
			s_subFragor = _new_ sqlstmt('insert into work.sub_' || tmpTable || '(subCode, subFraga) values(?, ?)',[subCode, subFraga]);

			iDataStorlek=1;
			sizeDataStorlek=getMetaData.dataStorlekNumItem();
			getMetaData.dataStorlekFirst(subCode,antal,cellerPerValue);
			do until(iDataStorlek>sizeDataStorlek);
				iMetaData=1;
				if cellerPerValue=1 then do;
					sizeMetaData=getMetaData.metaDataNumItem();
					s_loopMetadata = _new_ sqlstmt('select * from work.meta_' || tmpTable);
					s_loopMetadata.execute();
					s_loopMetadata.bindresults([title, code, text, values, valueTexts, elimination, "time"]);
					s_loopMetadata.fetch();
					do until(iMetaData=sizeMetaData);
					s_loopMetadata.fetch();
						if subCode=code then do;
							stubFraga='{"code":"' || strip(subCode) || '", "selection":{"filter":"item", "values":["';
							subFraga=stubFraga || strip(values) || '"';
							subFraga=strip(subFraga) || ']}}';
							s_subFragor.execute();
						end;
					iMetaData=iMetaData+1;
					end;
					s_loopMetadata.delete();
				end;
				* Delmängd av variabler väljs;
				else do;
					rundaNr=0;
					stubFraga='{"code":"' || strip(subCode) || '", "selection":{"filter":"item", "values":[';
					iMetaData=1;
					sizeMetaData=getMetaData.metaDataNumItem();
					s_loopMetadata = _new_ sqlstmt('select * from work.meta_' || tmpTable);
					s_loopMetadata.execute();
					s_loopMetadata.bindresults([title, code, text, values, valueTexts, elimination, "time"]);
					s_loopMetadata.fetch();

					do until(iMetaData>sizeMetaData);
						if subCode=code then do; *and values ^= '' ??;
							rundaNr=rundaNr+1;
							if rundaNr=cellerPerValue then do;
								stubFraga=stubFraga || ', "' || strip(values) || '"]}}';
								subFraga=strip(stubFraga);
								s_subFragor.execute();
								rundaNr=0;
								stubFraga='{"code":"' || strip(subCode) || '", "selection":{"filter":"item", "values":[';
							end;
							else if rundaNr=1 then do;
								stubFraga=stubFraga || '"' || strip(values) || '"';
							end;
							else do;
								stubFraga=stubFraga || ', "' || strip(values) || '"';
							end;
						end;
					s_loopMetadata.fetch();
					iMetaData+1;
					end;
					if (rundaNr^=cellerPerValue and rundaNr^=0) then do;
						stubFraga=stubFraga || ']}}';
						subFraga=stubFraga;
						s_subFragor.execute();
						rundaNr=0;
						stubFraga='{"code":"' || strip(subCode) || '", "selection":{"filter":"item", "values":"';
					end;
					s_loopMetaData.delete();
				end;
				getMetaData.dataStorlekNext(subCode,antal,cellerPerValue);
			iDataStorlek=iDataStorlek+1;
			end;
			s_subFragor.delete();
		end;*skapaSubFraga;
* Ett antal metoder för att kunna hämta jsonfrågor från packetet;
*** Hämtar första fråga;
		method countRows(varchar(32) tmpTable);
		declare integer x;
			s_countJsonFragor = _new_ sqlstmt('select count(*) as numJsonFragor from work.json_' || tmpTable);
			s_countJsonFragor.execute();
			s_countJsonFragor.fetch([numJsonFragor]);
			s_countJsonFragor.delete();
		end;
		method getNumItems()returns integer ;

			return numJsonFragor;
		end;

	endpackage;
run;quit;