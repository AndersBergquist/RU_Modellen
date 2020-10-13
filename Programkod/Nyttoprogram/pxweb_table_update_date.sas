/****************************************
Program: pxWeb_table_update_date.sas
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 4.0.9
Uppgift:
- Hämtar datum från tabellens uppdatering på SCB/PxWeb-site, returnerar resultatet.
***********************************/


proc ds2;
	package &prgLib..pxweb_UppdateTableDate / overwrite=yes;
		declare package &prgLib..pxweb_GemensammaMetoder g();
		declare double dbUpdated;
		declare nvarchar(25) tid;
		forward askSCB extractSCBDate;

		method pxweb_UppdateTableDate();

		end;

		method getSCBDate(nvarchar(500) iUrl) returns double;
			declare double datum dtime;
			declare nvarchar(100000) respons;
			declare char(19) datetext;
			declare nvarchar(150) catalogUrl;
			catalogUrl=tranwrd(iUrl,scan(iUrl,-1,'/'),'');
			respons=g.getData(catalogUrl);
			if respons^='Error' then do;
				datetext=extractSCBDate(iURL,respons);
				datum=mdy(put(substr(datetext,6,2),2.),put(substr(datetext,9,2),2.),put(substr(datetext,1,4),4.));
				dtime=dhms(datum,put(substr(datetext,12,2),2.),put(substr(datetext,15,2),2.),put(substr(datetext,18,2),2.));
			end;
			else do;
				put 'getSCBDate: Något gick fel och processen kunde inte fortsätta';
			end;
		return dtime;
		end; *getSCBDate;;

		method extractSCBDate(nvarchar(500) iURL, nvarchar(100000) respons) returns nchar(19);
			declare nvarchar(500) tableName;
			declare nchar(19) updateDatum;
			declare package json j();
			declare integer tokenType parseFlags rc;
			declare nvarchar(250) token;

			tableName=scan(iUrl,-1,'/');
			updateDatum='';
			rc=j.createParser(respons);
* Härr börrjar en loop som letar datum i resonsfilen;
			do while (rc=0);
				j.getNextToken(rc, token, tokenType, parseFlags);
				if token='id' then do;
					j.getNextToken(rc, token, tokenType, parseFlags);
					if token=tableName then do;
						do until(token='updated');
							j.getNextToken(rc, token, tokenType, parseFlags);
						end;
						j.getNextToken(rc, token, tokenType, parseFlags);
						updateDatum=token;
						rc=99;
					end;
				end;
			end;
* Härr slutar loopen;
			return updateDatum;
		end;*extractSCBDate;


		method getDBDate(varchar(40) fullTabellNamn) returns double;
			declare	package sqlstmt s();
			declare nvarchar(93) sqlMax;

			dbUpdated=g.finnsTabell(scan(fullTabellNamn,1,'.'), scan(fullTabellNamn,2,'.'));
			if dbUpdated=1 then do;
				sqlMax='select max(UPPDATERAT_DTTM) as UPPDATERAT_DTTM from ' || fullTabellNamn;
				s.prepare(sqlMax);
				s.execute();
				s.bindresults([dbUpdated]);
				s.fetch();
			end;
		return dbUpdated;
		end;*getDBDate;
	endpackage ;
run;quit;
