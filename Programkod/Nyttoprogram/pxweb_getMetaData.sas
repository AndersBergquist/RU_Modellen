/****************************************
Program: pxweb_getMetaData.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.12
Uppgift:
- Hämtar metadata från SCB/PX-Web.
Följande externa metoder finns;
- metaDataFirst(in_out varchar(250) io_title, in_out varchar(250) io_code, in_out varchar(250) io_text, in_out varchar(250) io_values, in_out varchar(250) io_valueTexts, in_out varchar(250) io_elimination, in_out varchar(250) io_time)
- metaDataNext(in_out varchar(250) io_title, in_out varchar(250) io_code, in_out varchar(250) io_text, in_out varchar(250) io_values, in_out varchar(250) io_valueTexts, in_out varchar(250) io_elimination, in_out varchar(250) io_time)
- metaDataNumItem() returns integer
- dataStorlekFirst(in_out varchar(250) io_code, in_out integer io_radNr, in_out integer io_CellerPerValue)
- dataStorlekNext(in_out varchar(250) io_code, in_out integer io_radNr, in_out integer io_CellerPerValue)
- hi_dataStorlek.next([code, radNr,CellerPerValue])

***********************************/
proc ds2;
	package &prgLib..pxweb_getMetaData / overwrite=yes;
		declare package &prgLib..pxweb_GemensammaMetoder g();
		declare package hash h_metaData();
		declare package hiter hi_metaData(h_metaData);
		declare package hash h_dataStorlek();
		declare package hiter hi_dataStorlek(h_dataStorlek);
		declare package hash h_dimensionerSum();
		declare package hiter hi_dimensionerSum(h_dimensionerSum);
		declare package hash h_contentSum();
		declare package hiter hi_contentSum(h_contentSum);
		declare integer radNr antal antalCeller cellerPerValue antalVar numItem;
		declare nvarchar(250) title code text values valueTexts elimination "time" subCode oldCode;

		forward getJsonMeta parseJsonMeta printData skapaMetadataSamling skapaFrageStorlek;
		method pxweb_getMetaData();
		end;

		method getData(nvarchar(500) iUrl, integer maxCells, nvarchar(41) fullTabellNamn, nvarchar(32) tmpTable);
			declare nvarchar(500000) respons;
			respons=g.getData(iUrl);
			parseJsonMeta(respons, maxCells, fullTabellNamn, tmpTable);
			sqlexec('create table work.meta_' || tmpTable || ' as select title, code, text, "values", valueTexts, elimination, "time" from work.parse_' || tmpTable );
			sqlexec('drop table work.parse_' || tmpTable);
			skapaMetadataSamling(tmpTable);
			skapaFrageStorlek(maxCells);
		end;*skapaFraga;

** Metoder för att hämta data från package, start **;
		method getAntalCodes() returns integer;
			declare integer antalCodes;
			antalCodes=h_datastorlek.num_items;
			return antalCodes;
		end;

		method getAntalCeller() returns integer;
			declare integer m_antalCeller;
			m_antalCeller=1;
			hi_dimensionerSum.first([code, antalVar]);
			do until(hi_dimensionerSum.next([code, antalVar]));
				m_antalCeller=m_antalCeller*antalVar;
			end;
			hi_contentsum.first([code, antalVar]);
			do until(hi_contentsum.next([code, antalVar]));
				m_antalCeller=m_antalCeller*antalVar;
			end;
			return m_antalCeller;
		end;

		method getAntalCellerFraga() returns integer;
			declare integer m_antalCeller;
			m_antalCeller=1;
			hi_dataStorlek.first([code, radNr,CellerPerValue]);
			do until(hi_dataStorlek.next([code, radNr, CellerPerValue]));
				m_antalCeller=m_antalCeller*CellerPerValue;
			end;
			return m_antalCeller;
		end;

		method getAntalFragor() returns integer;
			declare integer antalCeller antalFragor maxCeller;
			maxCeller=100000;
			antalCeller=getAntalCeller();
			antalFragor=round((antalCeller/maxCeller)+0.5);
			return antalFragor;
		end;
** dataStorlek, start;
	**************** VARFÖR BEHÖVS TVÅ EX AV DESSA************************************;
		method dataStorlekFirst(in_out nvarchar io_code, in_out integer io_radNr, in_out integer io_CellerPerValue);
			hi_dataStorlek.first([code, radNr,CellerPerValue]);
			io_code=code;
			io_radNr=radNr;
			io_CellerPerValue=CellerPerValue;
		end;
		method dataStorlekFirst(in_out nvarchar i_code, in_out integer i_antalCeller);
			code=i_code;
			antalCeller=i_antalCeller;
			hi_dataStorlek.first([code, antal, antalCeller]);
			i_code=code;
			i_antalCeller=antalCeller;
		end;
		method dataStorlekNext(in_out nvarchar io_code, in_out integer io_radNr, in_out integer io_CellerPerValue);
		declare integer rc;
			hi_dataStorlek.next([code, radNr, CellerPerValue]);
			io_code=code;
			io_radNr=radNr;
			io_CellerPerValue=CellerPerValue;
		end;

		method dataStorlekNext(in_out nvarchar i_code, in_out integer i_antalCeller);
			code=i_code;
			antalCeller=i_antalCeller;
			hi_dataStorlek.next([code, antal, antalCeller]);
			i_code=code;
			i_antalCeller=antalCeller;
		end;
		method dataStorlekNumItem() returns integer;
			declare integer numItem;
				numItem=h_dataStorlek.num_items;
				hi_dataStorlek.next([code, antal, antalCeller]);
				do until(hi_dataStorlek.next([code, antal, antalCeller]));
*put 'Datastorlek: ' code antal antalCeller numItem;
				end;
			return numItem;
		end;
		method getLevelCode(integer level) returns nvarchar(250);
			declare integer i;
			do i=1 to level;
				if i=1 then do;
					hi_dataStorlek.first([code, radNr, CellerPerValue]);
				end;
				if i^=1 then do;
					hi_dataStorlek.next([code, radNr, CellerPerValue]);
				end;
			end;
			return code;
		end;
** datastorlek, slut;

*** Metoder för att hämta data ur hashtabellerna. start;
** metaData, start;
		method metaDataFirst(in_out nvarchar io_title, in_out nvarchar io_code, in_out nvarchar io_text, in_out nvarchar io_values, in_out nvarchar io_valueTexts, in_out nvarchar io_elimination, in_out nvarchar io_time);
			hi_metaData.first([title, code, text, values, valueTexts, elimination, "time"]);
			io_title=title;
			io_code=code;
			io_text=text;
			io_values=values;
			io_valueTexts=valueTexts;
			io_elimination=elimination;
			io_time="time";
		end;
		method metaDataNext(in_out nvarchar io_title, in_out nvarchar io_code, in_out nvarchar io_text, in_out nvarchar io_values, in_out nvarchar io_valueTexts, in_out nvarchar io_elimination, in_out nvarchar io_time);
		declare integer rc;
			hi_metaData.next([title, code, text, values, valueTexts, elimination, "time"]);
			io_title=title;
			io_code=code;
			io_text=text;
			io_values=values;
			io_valueTexts=valueTexts;
			io_elimination=elimination;
			io_time="time";
		end;
		method metaDataNumItem() returns integer;
			return numItem;
		end;
** metaData, start;

*** Metoder för att hämta data ur hashtabellerna. slut;
		method skapaMetadataSamling(nvarchar(32) tmpTable);
		declare integer rc qc;

			h_dimensionerSum.keys([code]);
			h_dimensionerSum.data([code, antalVar]);
			h_dimensionerSum.ordered('A');
			h_dimensionerSum.dataset('{select code, count(valueTexts) as antalVar from meta_' || tmpTable || ' where code ^= ''ContentsCode'' group by code}');
			h_dimensionerSum.DefineDone();

			h_contentSum.keys([code]);
			h_contentSum.data([code, antalVar]);
			h_contentSum.ordered('A');
			h_contentSum.dataset('{select code, count(valueTexts) as antalVar from meta_' || tmpTable || ' where code = ''ContentsCode'' group by code}');
			h_contentSum.DefineDone();
		end;

		method skapaFrageStorlek( integer maxCells);
			declare integer rc antalDimCeller antalDimCeller_old divisor tmpCeller;
			h_dataStorlek.keys([code]);
			h_dataStorlek.data([code,radNr,cellerPerValue]);
			h_dataStorlek.ordered('A');
			h_dataStorlek.defineDone();
			radNr=0;
			rc=hi_contentSum.first([code, antalVar]);
			antalDimCeller=round((maxCells/antalVar)-0.5);
			rc=hi_dimensionerSum.first([code, antalVar]);
			do until(hi_dimensionerSum.next([code, antalVar]));
				if antalVar=1 then do;
					cellerPerValue=1;
					radNr=1;
					h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
					radNr=0;
				end;
				else if antalVar<=antalDimCeller then do;
					cellerPerValue=antalVar;
					radNr=antalVar;
					h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
					antalDimCeller_old=antalDimCeller;
					antalDimCeller=antalDimCeller_old/cellerPerValue;
					radNr=0;
				end;
				else if antalVar > antalDimCeller then do;
					divisor=1;
					do until(tmpCeller<=antalDimCeller);
						divisor=divisor+1;
						tmpCeller=round((antalVar/divisor)-0.5)*(antalDimCeller);
						radNr=radNr+1;
					end;
					cellerPerValue=tmpCeller;
					h_dataStorlek.ref([code],[code,radNr,cellerPerValue]);
					antalDimCeller_old=antalDimCeller;
					antalDimCeller=antalDimCeller_old/cellerPerValue;
					radNr=0;
				end;
				radNr=radNr+1;
			end;
		end;



** Metoder för att hämta data från package, slut **;

		method parseJsonMeta(nvarchar(500000) iRespons, integer maxCells, nvarchar(41) fullTabellNamn, nvarchar(32) tmpTable);
			declare package sqlstmt s_parseInsert();
			declare package sqlstmt s_parseUpdate();
			declare package sqlstmt s_parseSetTime();
			declare package sqlstmt s_numItem();
			declare package json j();
			declare nvarchar(250) token;
			declare nvarchar(25) senasteTid;
			declare integer rc tokenType parseFlags tmpCeller divisor rc qc;
*Senaste tid är där laghämtningen ska styras ifrån. Bra att redan nu hämtas bara senate data.;
			senasteTid=g.getSenasteTid(fullTabellNamn);
			antalCeller=1;
			sqlexec('create table work.parse_' || tmpTable || ' (radNr integer, title nvarchar(250), code nvarchar(250), text nvarchar(250), "values" nvarchar(250), valueTexts nvarchar(250), elimination nvarchar(250), "time" nvarchar(250))');
			rc=j.createparser(iRespons);
			j.getNextToken(rc,token,tokenType,parseFlags);
			do while(rc=0);
				if token='title' then do;
					j.getNextToken(rc,token,tokenType,parseFlags);
					title=token;
				end;
				if token='variables' then do;
					j.getNextToken(rc,token,tokenType,parseFlags);
					do until(j.ISRIGHTBRACKET(tokenType));
						elimination='false';
						"time"='false';
						do until(j.ISRIGHTBRACE(tokenType));
							if token='code' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								code=token;
							end;
							else if token='text' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								text=token;
							end;
							else if token='elimination' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								elimination=token;
							end;
							else if token='time' then do;
								j.getNextToken(rc,token,tokenType,parseFlags);
								"time"=token;
							end;
							else if token='values' then do;
								s_parseInsert = _new_ sqlstmt('insert into work.parse_' || tmpTable || ' (radNr, title, code, text, "values", valueTexts) values(?, ?, ?, ?, ?, ?)',[radNr, title, code, text, values, valueTexts]);
								radNr=0;
								j.getNextToken(rc,token,tokenType,parseFlags);
								do until(j.isrightbracket(tokenType));
									if j.isleftbracket(tokenType) then do;
									end;
									else do;
										radNr=radNr+1;
										values=token;
										s_parseInsert.execute();
									end;
									j.getNextToken(rc,token,tokenType,parseFlags);
								end;
								s_parseInsert.delete();
							end;
							else if token='valueTexts' then do;
								radNr=0;
								s_parseUpdate = _new_ sqlstmt('update work.parse_' || tmpTable || ' set radNr=0, valueTexts=? where (radNr=?)',[valueTexts, radNr]);
								j.getNextToken(rc,token,tokenType,parseFlags);
								do until(j.isrightbracket(tokenType));
									if j.isleftbracket(tokenType) then do;
									end;
									else do;
										radNr=radNr+1;
										valueTexts=token;
										s_parseUpdate.execute();
									end;
									j.getNextToken(rc,token,tokenType,parseFlags);
								end;
								s_parseUpdate.delete();
							end;
							j.getNextToken(rc,token,tokenType,parseFlags);
						end;
						s_parseSetTime = _new_ sqlstmt('update work.parse_' || tmpTable || ' set elimination=?, "time"=? where (code=?)',[elimination, "time", code]);
						s_parseSetTime.execute();
						s_parseSetTime.delete();

						j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				end;
				j.getNextToken(rc,token,tokenType,parseFlags);
			end;
			s_numItem = _new_ sqlstmt('select count(valueTexts) as numItem from parse_' || tmpTable);
			s_numItem.execute();
			s_numItem.bindresults([numItem]);
			s_numItem.fetch();
			s_numItem.delete();

		end;*parseJsonMeta;



	endpackage;
run;quit;