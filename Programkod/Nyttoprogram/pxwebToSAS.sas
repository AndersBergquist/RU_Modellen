/****************************************
Program: pxwebToSAS
Upphovsperson: Anders Bergquist, anders@fambergquist.se
Version: 1.0 RC1.
Att fixa till:  Till releas: Koden skall städas upp och sc skall returneras via funktion:
Senare version: Felmedelanden från package http skall föras vidare i ordnade former. Sista hämtningen i en loop skall inte ge fel.
	Felmedelande om hämtningen är för stor.
	På sikt kan även labels och kommentarer läggas till i resultatfilen.
Installation: Ändra på sasuser om du vill ha filen i ett annan bibliotek.
Användning:
Classen består av två funktioner. getData() och skrivTillTabell();
getData(url, post) hämtar data från SCB, eller annat pxweb API. Har dock inte testat det.
	url=adressen och post är jsonfrågan.
skrivTillTabell(tabellnamn) skriver ut resultatet till en sas-tabell och nollställer hämtningen. Denna används efter getData().
	funktionen är separta eftersom den används efter evt. loop som hämtar mer data än 50000 rader.
OBS! SCB tillåter max 50000 celler vid en hämtning. För att hämta mer måste programmet loopas. Se exempel fil. Användaren ansvarar
själv för detta.
***********************************/

proc ds2;
	package &prglib..pxwebToSAS / overwrite=yes;
		dcl private varchar(5000000) respons;
		dcl private varchar(50000) post;
		dcl private varchar(250) url  varLista;
		dcl private varchar(25) tabell;
		dcl private integer hashDefined;
        dcl integer rc sc myrc;
		vararray varchar(100) d[20];
		vararray double c[20];

	    dcl package http pxwebQuery();
		dcl package hash h_scbIndata();

		forward requestData parseData;

		method pxwebToSAS();
			hashDefined=0;
		end;

		method getData(varchar(250) iUrl, varchar(50000) iPost);
			dcl nvarchar(300) sql;
			dcl double startTid slutTid tid;
			startTid=datetime(); * Sätter tid för när hämtningen startade;
			requestData(iUrl, iPost);*Hämtar data;
			if respons^='Error' then do;
				parseData(); *parsData;
				myrc= 0;
			end;
			else do;
				myrc= 1;
			end;

			do while(datetime()-startTid<1);
			end;*tom loop för att undvika att det blir mer än 10 frågor på 10 sekunder. SCB:s begränsning.;
		end;*getData;

		method requestData(varchar(250) iUrl, varchar(50000) iPost);
           pxwebQuery.createPostMethod(iUrl);
           pxwebQuery.setRequestContentType('application/json; charset=utf-8');
           pxwebQuery.setRequestBodyAsString(iPost);
           pxwebQuery.executeMethod();
     
           sc=pxwebQuery.getStatusCode();

           if substr(sc,1,1) not in ('4', '5') then do;
           		pxwebQuery.getResponseBodyAsString(respons, rc);
           end;
		   else do;
		   		respons='Error';
		   end;
		end;

		method parseData();
			dcl int tokenType parseFlags rc typ;
			dcl private nvarchar(300) sql;
			dcl private nvarchar(128) token;
			dcl private nvarchar (500) colname valuesName hKeys hdata;
			dcl private integer loopD loopC raknareD raknareC;* d är SCB:s kod för dimension och c är SCB:s kod för innehåll=data;
			dcl private char(2) iKey iData;
			dcl package json j();
		
			rc=j.createParser(respons);
			raknareD=0;
			raknareC=0;
			varLista='';

			do while(rc=0);
				j.getNextToken(rc,token,tokenType,parseFlags);
				if token='columns' then do;
					do while(not j.ISRIGHTBRACKET(tokenType));
						j.getNextToken(rc,token,tokenType,parseFlags);
						if token='code' then do;
							j.getNextToken(rc,token,tokenType,parseFlags);
							/** För att undvika numerisk början på kollumnnamn **/
							if anydigit(token)=1 then token = 'X' || token;
							token=transtrn(token,'!','z1');
							token=transtrn(token,'€','z2');
							token=transtrn(token,'£','z3');
							token=transtrn(token,'$','z4');
							token=transtrn(token,'~','z5');
							token=transtrn(token,'§','z6');
							/** Slut **/
							colname=token;
						end;*code;
						if token='type' then do;
							j.getNextToken(rc,token,tokenType,parseFlags);
							if token in ('d' 't') then do;
								raknareD=raknareD+1;
								if varLista='' then do;
									varLista='SELECT d' || raknareD || ' AS ' || colname;
								end; *första delen i listan;
								else do;
									varLista=varLista || ', d' || raknareD || ' AS ' || colname;
								end;*lägger till i listan;
							end;
							else if token='c' then do;
								raknareC=raknareC+1;
								if varLista='' then do;
									varLista='SELECT c' || raknareC || ' AS ' || colname;
								end; *första delen i listan;
								else do;
									varLista=varLista || ', c' || raknareC || ' AS ' || colname;
								end;*lägger till i listan;
						end;
							else do;
							raknareD=raknareD+1;
								if varLista='' then do;
									varLista='SELECT d' || raknareD || ' AS ' || colname;
								end; *första delen i listan;
								else do;
									varLista=varLista || ', d' || raknareD || ' AS ' || colname;
								end;*lägger till i listan;
							end;
						end;*type;
					end;*Hämtar delarna i Columns;
					if hashDefined=0 then do;
						do loopD=1 to raknareD;
							iKey='d' || loopD;
							h_scbIndata.definekey(iKey);
							h_scbIndata.definedata(iKey);
						end;
						do loopC=1 to raknareC;
							iData='c' || loopC;
							h_scbIndata.definedata(iData);
						end;					
						h_scbIndata.ordered('A');
						h_scbIndata.defineDone();
						hashDefined=1;
					end; *hashDefined;
				end;*Columns;

				if token='comment' then do;
					do while(not j.ISRIGHTBRACKET(tokenType));

					j.getNextToken(rc,token,tokenType,parseFlags);
					end;
				end;*comment;



				if token='data' then do;
					raknareD=1;
					raknareC=1;
					do while(not j.isrightbracket(tokenType));
						j.getNextToken(rc,token,tokenType,parseFlags);
							if j.isleftbrace(tokenType) then do;
							do while(not j.isrightbrace(tokenType));
								j.getNextToken(rc,token,tokenType,parseFlags);
								if token='key' then do;
									do while(not j.isrightbracket(tokenType));
									j.getNextToken(rc,token,tokenType,parseFlags);
										if(not j.isrightbracket(tokenType) and not j.isleftbracket(tokenType)) then do;
											d[raknareD]=token;
											raknareD=raknareD+1;
										end;*Hämtar token;
									end;*hämtar värdet i key;
								end;*hämtar key;
								if token='values' then do;
									do while(not j.isrightbracket(tokenType));
									j.getNextToken(rc,token,tokenType,parseFlags);
										if(not j.isrightbracket(tokenType) and not j.isleftbracket(tokenType)) then do;
											c[raknareC]=token;
											raknareC=raknareC+1;

										end;*Hämtar token;
									end;*Hämtar värdet i values;
								h_scbIndata.ref();
								raknareD=1;
								raknareC=1;
								end;*Hämtar values;
							end;*hämtar kategori, key eller values;
						end;
					end;
				end;*token=data;
			end;*parseLoop;
		end; *parseData;

		method skrivTillTabell(varchar(200) utTabell);
			dcl varchar(2000) sql;
			dcl varchar(11) tempFil;
			if hashDefined=1 then do;
				tempFil='tmp' || strip(put(time(),8.));
				sql='create table ' || utTabell || ' as ' || varLista || ' from ' || tempFil;
				h_scbIndata.output(tempFil);
				sqlexec(sql);
				hashDefined=0;
				h_scbIndata.delete();
				sqlexec('drop table ' || tempFil);
			end;*hashDefined=1;
		end; *skrivTillTabell;
	endpackage;
run;
quit;
