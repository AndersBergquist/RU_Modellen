/****************************************
Program: pxweb_skapaStmtFraga.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.10
Uppgift:
- Skapar en fråga som används av sqlstmt för att uppdatera output tabellen med hämtad data.
Innehåller:
***********************************/

proc ds2;
	package &prgLib..pxweb_skapaStmtFraga / overwrite=yes;

		method pxweb_skapaStmtFraga();

		end;
		
		method prepare_s(in_out nvarchar iRespons, in_out nvarchar tmpTable, in_out nvarchar sqlinsert, in_out integer d, in_out integer c);
			declare package json j();
			declare package &prgLib..pxweb_GemensammaMetoder g_metoder();
			declare nvarchar(1000) sqlValues valueString;
			declare nvarchar(250) token code text comment type unit;
			declare integer rc tokenType parseFlags tmpCeller loopNr;

			rc=j.createparser(iRespons);
			sqlInsert='insert into ' || tmpTable || ' ( ';
			sqlValues=' values (';
			loopNr=1;
			d=0;
			c=0;
			do until(trim(token)='columns');
				j.getNextToken(rc,token,tokenType,parseFlags);

			end;
			do until(j.ISRIGHTBRACKET(tokenType));
				type='d'; *Kollar senare om denna behövs;
				do until(j.isrightbrace(tokenType));
					if trim(token)='code' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						g_metoder.kollaVariabelNamn(token);
						code=trim(token);
					end;
					else if trim(token)='text' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						text=trim(token);
					end;
					else if trim(token)='comment' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						comment=trim(token);
					end;
					else if trim(token)='type' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						type=trim(token);
					end;
					else if trim(token)='unit' then do;
						j.getNextToken(rc,token,tokenType,parseFlags);
						unit=trim(token);
					end;

					j.getNextToken(rc,token,tokenType,parseFlags);
				end;
				if type='d' then do;
					if loopNr=0 then do;
						sqlInsert=sqlInsert || ', ';
						sqlValues=sqlValues || ', ';
					end;
					else loopNr=0;
					sqlInsert=sqlInsert || code || '_cd' || ', ' || code || '_nm';
					sqlValues=sqlValues || '?, ?';
					d=d+2;
				end;
				if type='t' then do;
					if loopNr=0 then do;
						sqlInsert=sqlInsert || ', ';
						sqlValues=sqlValues || ', ';
					end;
					else loopNr=0;
					sqlInsert=sqlInsert || code || '_cd' || ', ' ||code || '_nm';
					sqlValues=sqlValues || '?, ?';
					d=d+2;
					if lowCase(text) in ('år', 'vartannat år', 'kvartal', 'månad') then do;
						sqlInsert=sqlInsert || ', ' || code || '_dt';
						sqlValues=sqlValues || ', ?';
						d=d+1;
					end;
				end;
				if type='c' then do;
					sqlInsert=sqlInsert || ', ' || code;
					sqlValues=sqlValues || ', ?';
					c=c+1;
				end;
				j.getNextToken(rc,token,tokenType,parseFlags);
			end;
			sqlInsert=sqlInsert || ' , UPPDATERAT_DTTM)' || sqlValues || ', datetime())';
		end;*S_prepare end;

endpackage;* pxweb_skapaStmtFraga;
run;quit;