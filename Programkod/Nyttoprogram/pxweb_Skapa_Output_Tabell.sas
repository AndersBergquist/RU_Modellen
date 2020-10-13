/****************************************
Program: pxweb_Skapa_Input_Tabell.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.12
Uppgift:
- Skapar en tabell där indata från SCB lagras.
Innehåller:
***********************************/

proc ds2;
	package &prgLib..pxweb_skapaOutputTabell / overwrite=yes;
		declare package &prgLib..pxweb_GemensammaMetoder g();
		declare package &prgLib..pxweb_getMetaData getMeta();
		declare package hash h_content();
		declare package hiter hi_content(h_content);
		declare package hash h_metadata();
		declare package hiter hi_metadata(h_metadata);
		declare nvarchar(250) title code text "time" elimination values valueTexts;
		declare integer len_values len_valueTexts;

		forward skapaTabell useExistingTable identifieraTidsvariabler;

		method pxweb_skapaOutputTabell();
		end;

		method skapaOutputTabell(nvarchar(32) tmpTable, nvarchar(40) fullTabellNamn);
			if g.finnsTabell('work', tmpTable)=0 then do;
				if g.finnsTabell(fullTabellNamn)=0 then do;
					skapaTabell(tmpTable);
				end;
				else do;
					useExistingTable(tmpTable, fullTabellNamn);
				end;
			end;
		end;

		method skapaTabell( nvarchar(32) tmpTable);
			declare nvarchar(2000) sqlfraga;
			declare nvarchar(250) txtStr xx;
			declare integer rc d;

			h_metadata.keys([title code text "time" elimination]);
			h_metadata.data([title code text "time" elimination len_values len_valueTexts]);
			h_metadata.dataset('{select title, code, text, "time", elimination, max(CHARACTER_LENGTH(trim("values"))) as len_values, max(CHARACTER_LENGTH(trim(valueTexts))) as len_valueTexts from work.meta_' || tmpTable ||' where trim(code) ^= ''ContentsCode'' group by title, code, text, "time", elimination}');
			h_metadata.ordered('A');
			h_metadata.defineDone();

			h_content.keys([values]);
			h_content.data([values valueTexts]);
			h_content.dataset('{select trim("values") as "values", trim(valueTexts) as valueTexts from work.meta_' || tmpTable ||' where trim(code) = ''ContentsCode''}');
			h_content.defineDone();

*********** Tänk på: variabelnamn som inte är alphanumeriskt skall skrivas ''variablenamn''n En check måste göras;
*********** Gör det allmänt;

			rc=hi_metadata.first([title code text "time" elimination len_values len_valueTexts]);
			if anydigit(strip(code))=1 then code = '_' || strip(code);
			sqlfraga='CREATE TABLE work.' || tmpTable || '{option label=''' || strip(title) || '''} (';
			if strip("time") ^='true' then do;
				sqlfraga=sqlfraga || strip(code) || '_cd varchar(' || len_Values || ') having label ''' || trim(text) || '''';
				sqlfraga=sqlfraga || ',' || strip(code) || '_nm varchar(' || len_ValueTexts || ') having label ''' || trim(text) || '''';
			end;
			else do;
				identifieraTidsvariabler(text, code, text, len_Values, len_ValueTexts,txtStr);
					sqlfraga=sqlfraga || txtStr;
			end;
			rc=hi_metadata.next([title code text "time" elimination len_values len_valueTexts]);
			if rc=0 then do;
				do until(hi_metadata.next([title code text "time" elimination len_values len_valueTexts]));
				if anydigit(strip(code))=1 then code = '_' || strip(code);
					if strip("time")='true' then do;
						identifieraTidsvariabler(text, code, text, len_Values, len_ValueTexts,txtStr);
						sqlfraga=sqlfraga || ',' || txtStr;
					end;
					else do;
						sqlfraga=sqlfraga || ',' || strip(code) || '_cd varchar(' || len_Values || ') having label ''' || trim(text) || '''';
						sqlfraga=sqlfraga || ',' || strip(code) || '_nm varchar(' || len_ValueTexts || ') having label ''' || trim(text) || '''';
					end;
				end;
			end;

			rc=hi_content.first([values valueTexts]);
			do until(hi_content.next([values valueTexts]));
				if anydigit(strip(values))=1 then values = '_' || strip(values);
				sqlfraga=sqlfraga || ', ' || values || ' double having label ''' || valueTexts || '''';
			end;
			sqlfraga=sqlfraga || ', UPPDATERAT_DTTM timestamp having label ''Tid för dataladdning'' format datetime16. )';
			sqlExec(sqlfraga);

		end;*skapaTabell;

		method identifieraTidsvariabler(nvarchar(250) tidTyp, nvarchar(250) code, nvarchar(250) text, integer len_Values, integer len_valueTexts, in_out nvarchar tidString);
			if lowCase(tidTyp) in ('år', 'vartannat år', 'kvartal', 'månad') then do;
					if lowCase(tidTyp) in ('år', 'vartannat år') then tidString=strip(code) || '_dt date having label ''' || trim(text) || ''' format year4.';
					else if lowCase(tidTyp)='kvartal' then tidString=strip(code) || '_dt date having label ''' || trim(text) || ''' format yyq6.';
					else if lowCase(tidTyp)='månad' then tidString=strip(code) || '_dt date having label ''' || trim(text) || ''' format yymmd7.';				
					tidString=tidString || ',' || strip(code) || '_cd varchar(' || len_Values || ') having label ''' || trim(text) || '''';
					tidString=tidString || ',' || strip(code) || '_nm varchar(' || len_ValueTexts || ') having label ''' || trim(text) || '''';
			end;
			else do;
				tidString=strip(code) || '_cd varchar(' || len_Values || ') having label ''' || trim(text) || '''';
				tidString=tidString || ',' || strip(code) || '_nm varchar(' || len_ValueTexts || ') having label ''' || trim(text) || '''';
			end;
		end;

		method useExistingTable(nvarchar(32) tmpTable, nvarchar(40) fullTabellNamn);
			declare varchar(250) sqlfraga;
			sqlfraga='create table ' || tmpTable || ' as select * from ' || fullTabellNamn || ' limit 0';
			sqlExec(sqlfraga);
		end;
	endpackage;
run;quit;