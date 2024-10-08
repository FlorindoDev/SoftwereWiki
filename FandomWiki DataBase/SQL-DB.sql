PGDMP      0                 |           Wiki    16.3    16.0 Y    t           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            u           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            v           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            w           1262    16389    Wiki    DATABASE     h   CREATE DATABASE "Wiki" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE_PROVIDER = libc LOCALE = 'C';
    DROP DATABASE "Wiki";
                filix820zec    false            x           0    0    DATABASE "Wiki"    ACL     0   GRANT ALL ON DATABASE "Wiki" TO neon_superuser;
                   filix820zec    false    3447                        2615    2200    public    SCHEMA        CREATE SCHEMA public;
    DROP SCHEMA public;
                pg_database_owner    false            y           0    0    SCHEMA public    COMMENT     6   COMMENT ON SCHEMA public IS 'standard public schema';
                   pg_database_owner    false    4            n           1247    16489    d_email    DOMAIN     ~   CREATE DOMAIN public.d_email AS character varying(255)
	CONSTRAINT d_email_check CHECK (((VALUE)::text ~~ '_%@_%._%'::text));
    DROP DOMAIN public.d_email;
       public          filix820zec    false    4            �            1255    368645 -   accettaproposta(public.d_email, integer, bit) 	   PROCEDURE     _  CREATE PROCEDURE public.accettaproposta(IN emailin public.d_email, IN idoperazione integer, IN accettatain bit)
    LANGUAGE plpgsql
    AS $$
DECLARE
	
	notifica_rec notifica%ROWTYPE;

BEGIN
	select * into notifica_rec from notifica where autore_notificato = EmailIn AND id_operazione = IdOperazione;
	IF FOUND THEN
		UPDATE operazione_utente SET accettata = AccettataIn, dataa = LOCALTIMESTAMP(0), visionata = 1::BIT(1) WHERE id_operazione = IdOperazione AND autore_notificato = EmailIn;
	ELSE
		RAISE NOTICE 'Non esiste una proposta per % con id_operazione %', EmailIn, IdOperazione; 
	END IF;

END;
$$;
 o   DROP PROCEDURE public.accettaproposta(IN emailin public.d_email, IN idoperazione integer, IN accettatain bit);
       public          filix820zec    false    878    4            �            1255    311388 !   aggiornamento_generalita_pagina()    FUNCTION       CREATE FUNCTION public.aggiornamento_generalita_pagina() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
    generalita VARCHAR (41);
    cur CURSOR FOR SELECT id_pagina FROM PAGINA WHERE emailautore=NEW.email;
	idPagina INTEGER;
BEGIN
    
    generalita := NEW.Nome || ';' || NEW.Cognome;
    OPEN cur;
	LOOP
		FETCH cur INTO idPagina;
        EXIT WHEN NOT FOUND;
        UPDATE PAGINA SET generalita_autore=generalita WHERE id_pagina = idPagina;
		
    END LOOP;
    CLOSE cur;
    
    RETURN NEW;
END;
$$;
 8   DROP FUNCTION public.aggiornamento_generalita_pagina();
       public          filix820zec    false    4            �            1255    311384    aggiornamentodatamod()    FUNCTION     �   CREATE FUNCTION public.aggiornamentodatamod() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    new.DataR = localtimestamp(0);
    RETURN NEW;
END;
$$;
 -   DROP FUNCTION public.aggiornamentodatamod();
       public          filix820zec    false    4                       1255    409600    checkaggiornamentopagina()    FUNCTION     �  CREATE FUNCTION public.checkaggiornamentopagina() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF NEW.accettata = 1::bit(1) THEN
		IF NEW.modifica = 1::bit(1) THEN
			UPDATE frase SET testo = NEW.testo, link = NEW.link, linkpagina = NEW.link_pagina WHERE pagina = NEW.pagina_frase AND posizione = NEW.posizione_frase;
		ELSE
			INSERT INTO frase VALUES (NEW.pagina_frase, NEW.posizioneins, NEW.testo, NEW.link, NEW.link_pagina);
		END IF;
	END IF;
	
    RETURN NEW;
END;
$$;
 1   DROP FUNCTION public.checkaggiornamentopagina();
       public          filix820zec    false    4            �            1255    311411 '   checkautore(character varying, integer) 	   PROCEDURE       CREATE PROCEDURE public.checkautore(IN emailautore_in character varying, IN id_pagina_in integer)
    LANGUAGE plpgsql
    AS $$

BEGIN
	IF EXISTS(SELECT id_pagina FROM pagina where id_pagina_in = pagina.id_pagina) THEN
		IF EXISTS(SELECT email FROM Utente where EmailAutore_in = utente.email and Utente.autore = 1::BIT(1)) THEN
			IF EXISTS(SELECT email from utente join pagina on pagina.emailautore = utente.email where EmailAutore_in like utente.email and id_pagina_in = pagina.id_pagina) THEN
				RETURN;
			ELSE
				RAISE EXCEPTION 'Questo utente non è autore della pagina';
				ROLLBACK;		
			END IF;
		ELSE
			RAISE EXCEPTION 'Utente non trovato o utente non è autore';
			ROLLBACK;		
		END IF;
	ELSE
		RAISE EXCEPTION 'La pagina non esiste';
		ROLLBACK;
	END IF;
END;
$$;
 a   DROP PROCEDURE public.checkautore(IN emailautore_in character varying, IN id_pagina_in integer);
       public          filix820zec    false    4            �            1255    311395 \   creazionepagina(character varying, character varying, text, bit, character varying, integer) 	   PROCEDURE     �  CREATE PROCEDURE public.creazionepagina(IN titolo_in character varying, IN emailautore character varying, IN testo text, IN link bit, IN titolo_pagina_link character varying, IN posizione integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
	Nome VARCHAR(20);
	Cognome VARCHAR(20);
	Generalita VARCHAR(41);
	id_page integer;

BEGIN
	IF EXISTS(SELECT email FROM Utente where Emailautore = utente.email) THEN	
			SELECT u.cognome , u.nome into Cognome, nome FROM Utente as u where Emailautore = u.email;
			Generalita := nome || ';' || cognome;
			INSERT INTO Pagina (Titolo, Generalita_Autore, DataUltimaModifica, DataCreazione, emailAutore) VALUES(Titolo_in, Generalita, localtimestamp(0), localtimestamp(0), Emailautore);
			SELECT id_pagina into id_page FROM pagina where Titolo_in = pagina.titolo;
			CALL InsertFraseAutore(id_page, Emailautore , Testo, link , titolo_pagina_link , posizione);
	else
		RAISE EXCEPTION 'Utente non trovato';
		ROLLBACK;	
	END IF;

END;
$$;
 �   DROP PROCEDURE public.creazionepagina(IN titolo_in character varying, IN emailautore character varying, IN testo text, IN link bit, IN titolo_pagina_link character varying, IN posizione integer);
       public          filix820zec    false    4            �            1255    311408    datamodficapagina()    FUNCTION     �   CREATE FUNCTION public.datamodficapagina() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	UPDATE pagina set dataultimamodifica = localtimestamp(0) where id_pagina = new.pagina; 
	RETURN NEW;
END;
$$;
 *   DROP FUNCTION public.datamodficapagina();
       public          filix820zec    false    4                       1255    434176    deletefraseoputente()    FUNCTION     �   CREATE FUNCTION public.deletefraseoputente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	DELETE FROM operazione_utente WHERE pagina_frase=OLD.id_pagina AND posizione_frase is NULL;
 
	RETURN NEW;
END;
$$;
 ,   DROP FUNCTION public.deletefraseoputente();
       public          filix820zec    false    4                        1255    376832 8   getlimtusermodpage(character varying, character varying)    FUNCTION     �  CREATE FUNCTION public.getlimtusermodpage(ids_page character varying, emailin character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	pos INTEGER := 0;
	oldpos INTEGER := 1;
	parola varchar(10000) := '';
	commando varchar(10000) := 'SELECT distinct(utente) FROM operazione_utente where utente NOT LIKE ''' || emailIn || ''' AND (pagina_frase = ';
	u operazione_utente.utente%TYPE;

BEGIN
	
	LOOP
		pos := POSITION('+' IN SUBSTRING(Ids_page FROM oldpos));
		
		RAISE NOTICE '% | %', pos, oldpos;
		EXIT WHEN pos = 0;
		parola := SUBSTRING(Ids_page FROM oldpos FOR pos-1);
		oldpos := oldpos + pos;
		call CheckAutore(emailin,parola::INTEGER);
		commando := commando || parola || ' OR pagina_frase = ';
		
	END LOOP;
	
	parola := SUBSTRING(Ids_page FROM oldpos);
	commando := commando || parola || ');';
	RAISE NOTICE '%', parola;
	RAISE NOTICE '%', commando;
	parola := '';
	FOR u in EXECUTE commando LOOP
		parola := parola || '+' || u;
	END LOOP;
	
	
	RETURN parola;
	
END;
$$;
 `   DROP FUNCTION public.getlimtusermodpage(ids_page character varying, emailin character varying);
       public          filix820zec    false    4            �            1255    385042 2   getnotifiche(character varying, character varying)    FUNCTION     M  CREATE FUNCTION public.getnotifiche(ids_page character varying, emailin character varying) RETURNS character varying
    LANGUAGE plpgsql
    AS $$
DECLARE
	pos INTEGER := 0;
	oldpos INTEGER := 1;
	parola varchar(10000) := '';
	commando varchar(10000) := 'SELECT * FROM notifica where autore_notificato LIKE ''' || emailIn || ''' AND (pagina_frase = ';
	u notifica%ROWTYPE;

BEGIN
	
	LOOP
		pos := POSITION('+' IN SUBSTRING(Ids_page FROM oldpos));
		
		RAISE NOTICE '% | %', pos, oldpos;
		EXIT WHEN pos = 0;
		parola := SUBSTRING(Ids_page FROM oldpos FOR pos-1);
		oldpos := oldpos + pos;
		call CheckAutore(emailin,parola::INTEGER);
		commando := commando || parola || ' OR pagina_frase = ';
		
	END LOOP;
	
	parola := SUBSTRING(Ids_page FROM oldpos);
	commando := commando || parola || ');';
	RAISE NOTICE '%', parola;
	RAISE NOTICE '%', commando;
	parola := '';
	FOR u in EXECUTE commando LOOP
		--RAISE NOTICE '%', parola;
		IF(u.link_pagina is not null) THEN
			parola := parola || '+' || u.id_operazione || ';' || u.datar || ';' || u.posizioneins || ';' || u.modifica || ';' || u.link|| ';' || u.link_pagina || ';' || u.utente;
		ELSE
			parola := parola || '+' || u.id_operazione || ';' || u.datar || ';' || u.posizioneins || ';' || u.modifica || ';' || u.link|| ';' || 'NULL' || ';' || u.utente;
		END IF;
	END LOOP;
	
	
	RETURN parola;
	
END;
$$;
 Z   DROP FUNCTION public.getnotifiche(ids_page character varying, emailin character varying);
       public          filix820zec    false    4            �            1255    352256 *   getusermodpage(character varying, integer)    FUNCTION     �  CREATE FUNCTION public.getusermodpage(emailin character varying, paginain integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
    ListaUtenti TEXT := '';
	Flag bit(1) := 0::bit(1);
    sql_instr TEXT := 'select distinct utente from storicita_totale WHERE utente NOT LIKE ''' ||emailIn || ''' AND (id_pagina = ';
	pagina_rec pagina%ROWTYPE;
	user_rec storicita_totale.utente%TYPE;	
BEGIN
IF paginaIn = 0 THEN
    FOR pagina_rec IN SELECT id_pagina FROM pagina WHERE emailautore = emailIn LOOP
         IF flag = 1::bit(1) THEN sql_instr := sql_instr || ' OR id_pagina = ' || pagina_rec.id_pagina;
		 ELSE sql_instr := sql_instr || pagina_rec.id_pagina; Flag := 1::bit(1); END IF;
    END LOOP;
ELSE
	CALL CheckAutore(emailIn, paginaIn);
    sql_instr := sql_instr || paginaIn;
END IF;

sql_instr := sql_instr || ')';

FOR user_rec IN EXECUTE sql_instr LOOP
    ListaUtenti := ListaUtenti || user_rec || ';';
END LOOP;

RETURN ListaUtenti;

END;
$$;
 R   DROP FUNCTION public.getusermodpage(emailin character varying, paginain integer);
       public          filix820zec    false    4                       1255    491521 T   insertfraseautore(integer, character varying, text, bit, character varying, integer) 	   PROCEDURE     �  CREATE PROCEDURE public.insertfraseautore(IN id_pagina_in integer, IN emailautore character varying, IN testo text, IN link bit, IN titolo_pagina_link character varying, IN posizione integer)
    LANGUAGE plpgsql
    AS $$ 
DECLARE
	idpagina_link INTEGER;
BEGIN 
	CALL CheckAutore(EmailAutore, id_pagina_in);
	IF(link = 1::BIT(1)) then
		SELECT id_pagina INTO idpagina_link FROM pagina where  titolo_pagina_link = pagina.titolo;
		IF FOUND THEN
			INSERT INTO frase VALUES (Id_pagina_in, posizione,Testo,link,idpagina_link);
			
		else
			RAISE EXCEPTION 'E04: La pagina non esiste(link non valido)';
			ROLLBACK;
		END IF;
	ELSE
		INSERT INTO frase VALUES(Id_pagina_in, posizione,Testo,link,null);	
	END IF;

END;
$$;
 �   DROP PROCEDURE public.insertfraseautore(IN id_pagina_in integer, IN emailautore character varying, IN testo text, IN link bit, IN titolo_pagina_link character varying, IN posizione integer);
       public          filix820zec    false    4            �            1255    311382    modifica_proposta()    FUNCTION     �   CREATE FUNCTION public.modifica_proposta() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    RAISE EXCEPTION 'La proposta è gia stata visionata';
    RETURN NEW;
END;
$$;
 *   DROP FUNCTION public.modifica_proposta();
       public          filix820zec    false    4            �            1255    311410 V   modificafraseautore(integer, character varying, text, bit, character varying, integer) 	   PROCEDURE     T  CREATE PROCEDURE public.modificafraseautore(IN id_pagina_in integer, IN emailautore character varying, IN testo_in text, IN link_in bit, IN titolo_pagina_link character varying, IN posizione_in integer)
    LANGUAGE plpgsql
    AS $$
DECLARE
	idpagina_link INTEGER;
	
BEGIN 

	CALL CheckAutore(EmailAutore, id_pagina_in);
	IF(link_in = 1::BIT(1)) then
		SELECT id_pagina INTO idpagina_link FROM pagina where  titolo_pagina_link = pagina.titolo;
		IF FOUND THEN
			UPDATE frase SET testo = Testo_in , link = link_in, linkpagina = idpagina_link  where Id_pagina_in = pagina and posizione_in = posizione;   
		else
			RAISE EXCEPTION 'La pagina non esiste(link non valido)';
			ROLLBACK;
		END IF;
	ELSE
		UPDATE frase SET testo = Testo_in , link = link_in, linkpagina = NULL where Id_pagina_in = pagina and posizione_in = posizione;
	END IF;	
	
END;
$$;
 �   DROP PROCEDURE public.modificafraseautore(IN id_pagina_in integer, IN emailautore character varying, IN testo_in text, IN link_in bit, IN titolo_pagina_link character varying, IN posizione_in integer);
       public          filix820zec    false    4                       1255    425984 :   modificarichestaproposta(integer, character varying, text) 	   PROCEDURE     �  CREATE PROCEDURE public.modificarichestaproposta(IN id_operazione_in integer, IN email_in character varying, IN testo_in text)
    LANGUAGE plpgsql
    AS $$
BEGIN
	
	IF EXISTS(SELECT utente from operazione_utente where Email_in = utente and Id_operazione_in = id_operazione) THEN
		UPDATE operazione_utente SET testo = Testo_in where id_operazione = id_operazione_in;
	
	ELSE
		RAISE EXCEPTION 'utente non ha questa proposta';
	
	END IF;


END;
$$;
 ~   DROP PROCEDURE public.modificarichestaproposta(IN id_operazione_in integer, IN email_in character varying, IN testo_in text);
       public          filix820zec    false    4            �            1255    311414    operazioneautoreintegritains()    FUNCTION     0  CREATE FUNCTION public.operazioneautoreintegritains() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN
	IF NOT EXISTS(SELECT id_operazione from operazione_utente where new.pagina = pagina_frase and posizioneins = new.posizione) THEN
		INSERT INTO operazione_autore(data,testo,posizioneins,modifica,link,link_pagina,posizione_frase,pagina_frase,autore) VALUES(localtimestamp(0),new.testo,new.posizione,0::BIT(1),new.link,new.linkpagina,new.posizione,new.pagina,(select emailautore from pagina where new.pagina = id_pagina));
	END IF;
	RETURN NEW;
END;
$$;
 5   DROP FUNCTION public.operazioneautoreintegritains();
       public          filix820zec    false    4            �            1255    311420    operazioneautoreintegritamod()    FUNCTION     +  CREATE FUNCTION public.operazioneautoreintegritamod() RETURNS trigger
    LANGUAGE plpgsql
    AS $$

BEGIN

	IF NOT EXISTS(SELECT id_operazione from operazione_utente where new.pagina = pagina_frase and posizione_frase = new.posizione) THEN
		INSERT INTO operazione_autore(data,testo,posizioneins,modifica,link,link_pagina,posizione_frase,pagina_frase,autore) VALUES(localtimestamp(0),new.testo,NULL,0::BIT(1),new.link,new.linkpagina,new.posizione,new.pagina,(select emailautore from pagina where new.pagina = id_pagina));
	END IF;
	RETURN NEW;
END;
$$;
 5   DROP FUNCTION public.operazioneautoreintegritamod();
       public          filix820zec    false    4            �            1255    344064 `   operazioneutenterichiesta(character varying, text, integer, bit, integer, integer, bit, integer) 	   PROCEDURE       CREATE PROCEDURE public.operazioneutenterichiesta(IN utente_in character varying, IN testo_in text, IN posizioneins_in integer, IN modifica_in bit, IN pagina_in integer, IN posizione_frase_in integer, IN link_in bit, IN link_pagina integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
	IF EXISTS(SELECT id_pagina FROM pagina where pagina_in = pagina.id_pagina) THEN
		IF link_in = 1::BIT(1) and EXISTS(SELECT id_pagina FROM pagina where link_pagina = pagina.id_pagina) THEN
			IF EXISTS(select email from utente where utente_in like email) THEN
				IF modifica_in = 0::BIT(1) THEN
					INSERT INTO operazione_utente(dataA,dataR,testo,accettata,visionata,posizioneins,modifica,link,link_pagina,posizione_frase,pagina_frase,utente,autore_notificato)
					VALUES(NULL,LOCALTIMESTAMP(0),Testo_in,0::BIT(1),0::BIT(1),posizioneins_in,modifica_in,link_in,link_pagina,NULL,pagina_in,utente_in,(Select emailautore from pagina where pagina_in = id_pagina));

				ELSEIF EXISTS(select posizione from frase where pagina = pagina_in and posizione_frase_in = frase.posizione) THEN
					INSERT INTO operazione_utente(dataA,dataR,testo,accettata,visionata,posizioneins,modifica,link,link_pagina,posizione_frase,pagina_frase,utente,autore_notificato)
					VALUES(NULL,LOCALTIMESTAMP(0),Testo_in,0::BIT(1),0::BIT(1),posizioneins_in,modifica_in,link_in,link_pagina,posizione_frase_in,pagina_in,utente_in,(Select emailautore from pagina where pagina_in = id_pagina));
				ELSE
					RAISE EXCEPTION 'La frase non esiste';
					
				END IF;
			ELSE
				RAISE EXCEPTION 'Utente non corretto';
			END IF;
		ELSEIF link_in = 0::BIT(1) THEN
			IF EXISTS(select email from utente where utente_in like email) THEN
				IF modifica_in = 0::BIT(1) THEN
					INSERT INTO operazione_utente(dataA,dataR,testo,accettata,visionata,posizioneins,modifica,link,link_pagina,posizione_frase,pagina_frase,utente,autore_notificato)
					VALUES(NULL,LOCALTIMESTAMP(0),Testo_in,0::BIT(1),0::BIT(1),posizioneins_in,modifica_in,link_in,NULL,NULL,pagina_in,utente_in,(Select emailautore from pagina where pagina_in = id_pagina));

				ELSEIF EXISTS(select posizione from frase where pagina = pagina_in and posizione = posizione_frase_in) THEN
					INSERT INTO operazione_utente(dataA,dataR,testo,accettata,visionata,posizioneins,modifica,link,link_pagina,posizione_frase,pagina_frase,utente,autore_notificato)
					VALUES(NULL,LOCALTIMESTAMP(0),Testo_in,0::BIT(1),0::BIT(1),posizioneins_in,modifica_in,link_in,NULL,posizione_frase_in,pagina_in,utente_in,(Select emailautore from pagina where pagina_in = id_pagina));
				ELSE
					RAISE EXCEPTION 'La frase non esiste';

				END IF;
			ELSE
				RAISE EXCEPTION 'Utente non corretto';
			END IF;
		ELSE
			RAISE EXCEPTION 'La pagina non esiste(per il riferimento del link)';
		END IF;
	ELSE
		RAISE EXCEPTION 'La pagina non esiste';
	END IF;
END;
$$;
 �   DROP PROCEDURE public.operazioneutenterichiesta(IN utente_in character varying, IN testo_in text, IN posizioneins_in integer, IN modifica_in bit, IN pagina_in integer, IN posizione_frase_in integer, IN link_in bit, IN link_pagina integer);
       public          filix820zec    false    4                       1255    311412    positioncontroll()    FUNCTION     e  CREATE FUNCTION public.positioncontroll() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
DECLARE
	max_pos integer;
	min_pos integer;
	max_int_pos integer;

BEGIN

	SELECT MAX(posizione) into max_pos from frase where pagina = new.pagina;
	IF NOT FOUND THEN
		max_pos = 0;
	END IF;


	IF max_pos < new.posizione THEN
		new.posizione = max_pos + 200;


	ELSEIF max_pos >= new.posizione then

		IF new.posizione = 1 THEN
			CALL UpadatePosition(new.posizione,new.pagina,1::BIT(1));
			RETURN NEW;
		END IF;

		SELECT MIN(posizione) into min_pos  from frase where pagina = new.pagina and new.posizione <= posizione;
		SELECT MAX(posizione) into max_int_pos  from frase where pagina = new.pagina and new.posizione > posizione;
		new.posizione := (min_pos + max_int_pos)/2;
		--new.posizione := new.posizione/2;
		--RAISE NOTICE 'pos %|min % | max %', new.posizione, min_pos,max_int_pos;
		IF EXISTS(SELECT posizione from frase where new.pagina = pagina and new.posizione = posizione) THEN

			CALL UpadatePosition(new.posizione,new.pagina,0::BIT(1));
			new.posizione := (min_pos + 100);
		END IF;
	END IF;	

	RETURN NEW;
END;
$$;
 )   DROP FUNCTION public.positioncontroll();
       public          filix820zec    false    4            �            1255    311390    switchautore()    FUNCTION     $  CREATE FUNCTION public.switchautore() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
 	IF NOT EXISTS(SELECT email FROM utente where new.emailautore = email and autore = 1::BIT(1)) THEN
		UPDATE utente set autore = 1::BIT(1) where new.emailautore = email;
	END IF;
	RETURN NEW;
end;
$$;
 %   DROP FUNCTION public.switchautore();
       public          filix820zec    false    4            �            1255    311392    switchutente()    FUNCTION     .  CREATE FUNCTION public.switchutente() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
begin
 	IF NOT EXISTS(SELECT p1.Id_pagina FROM (pagina as p1 join pagina on old.emailautore = p1.emailautore)) THEN
		UPDATE utente set autore = 0::BIT(1) where old.emailautore = email;
	END IF;
	RETURN NEW;
end;
$$;
 %   DROP FUNCTION public.switchutente();
       public          filix820zec    false    4                       1255    401411    trovapagina(text)    FUNCTION       CREATE FUNCTION public.trovapagina(testoricerca text) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE

	stringaRicerca TEXT  := '%';--||testoRicerca||'%';
	
	pos INTEGER;
	oldPos INTEGER:= 1;
	parola TEXT;
	page pagina%ROWTYPE;
	
	idTrovati TEXT:= '';

BEGIN
	
	LOOP
	
		pos := POSITION(' ' IN SUBSTRING(testoRicerca FROM oldPos));
		RAISE NOTICE 'pos %', pos;
		EXIT WHEN pos = 0;
		parola := SUBSTRING (testoRicerca FROM oldPos FOR pos-1);
		stringaRicerca := stringaRicerca || parola ||'%';
		oldPos := oldPos + pos;
		
	END LOOP;
	
	parola := SUBSTRING(testoRicerca FROM oldPos);
	stringaRicerca := stringaRicerca || parola ||'%';
	
	RAISE NOTICE 'fine %', stringaRicerca;
	
	FOR page IN SELECT id_pagina FROM pagina WHERE titolo LIKE stringaRicerca LOOP
		RAISE NOTICE 'eseguito for';
		idTrovati:=idTrovati||page.id_pagina||'-';
	END LOOP;
	
	idTrovati:=RTRIM(idTrovati, '-');
	RAISE NOTICE 'page %', page;
	
	IF page IS NULL THEN
		RAISE NOTICE 'eseguito';
		idTrovati := '-1';
	END IF;
	
	RETURN idTrovati;

END;
$$;
 5   DROP FUNCTION public.trovapagina(testoricerca text);
       public          filix820zec    false    4            �            1255    335873 &   upadateposition(integer, integer, bit) 	   PROCEDURE     �  CREATE PROCEDURE public.upadateposition(IN posizione_in integer, IN pagina_in integer, IN caso bit)
    LANGUAGE plpgsql
    AS $$
DECLARE
	f frase%ROWTYPE;

BEGIN
	IF caso = 1::BIT THEN
		FOR f IN SELECT pagina,posizione FROM frase where pagina_in = pagina and posizione >= posizione_in order by posizione DESC LOOP
			UPDATE frase set posizione = posizione + 200 where f.pagina = pagina and posizione = f.posizione;
		END LOOP;
	ELSE
		FOR f IN SELECT pagina,posizione FROM frase where pagina_in = pagina and posizione > posizione_in order by posizione DESC LOOP
			UPDATE frase set posizione = posizione + 200 where f.pagina = pagina and posizione = f.posizione;
		END LOOP;
	END IF;
END;
$$;
 c   DROP PROCEDURE public.upadateposition(IN posizione_in integer, IN pagina_in integer, IN caso bit);
       public          filix820zec    false    4            �            1255    311386    utente_no_delete()    FUNCTION     �   CREATE FUNCTION public.utente_no_delete() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
	RAISE EXCEPTION 'Un utente non puo essere cancellato';
	RETURN NEW;
END;
$$;
 )   DROP FUNCTION public.utente_no_delete();
       public          filix820zec    false    4                       1255    385041 '   visualizzapropostaandconfronta(integer)    FUNCTION     X  CREATE FUNCTION public.visualizzapropostaandconfronta(idop integer) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE
	confronto TEXT := '';
	notifica_rec notifica%ROWTYPE;
	frase_rec frase%ROWTYPE;
	
BEGIN
	select * into notifica_rec from notifica where id_operazione = idOp; -- se esiste quella notifica
	raise notice '%', notifica_rec;
	if found then
		update operazione_utente set visionata = 1::bit(1) where id_operazione = idOp; --aggiorno il visualizzato
		
		select * into frase_rec from frase where pagina = notifica_rec.pagina_frase AND posizione = notifica_rec.posizione_frase;
		raise notice '%', frase_rec;
		if frase_rec.linkpagina is null then 
			confronto := frase_rec.posizione ||','|| frase_rec.testo ||',' || frase_rec.link || ','|| 'null' ||';'|| notifica_rec.testo;
		else
			confronto := frase_rec.posizione ||','|| frase_rec.testo ||',' || frase_rec.link || ','|| frase_rec.linkpagina ||';'|| notifica_rec.testo;
		end if;
	else
		raise exception 'non esisete una notifica con l''identificativo proposto';
	end if;
	raise notice 'confronto: %', confronto;
	
	RETURN confronto;
END;
$$;
 C   DROP FUNCTION public.visualizzapropostaandconfronta(idop integer);
       public          filix820zec    false    4                       1255    417798 :   visualizzapropostaandconfronta(integer, character varying)    FUNCTION     ?	  CREATE FUNCTION public.visualizzapropostaandconfronta(idop integer, emailautore character varying) RETURNS text
    LANGUAGE plpgsql
    AS $$
DECLARE

	confronto TEXT := '';
	notifica_rec notifica%ROWTYPE;
	frase_rec frase%ROWTYPE;
	
	NotificaLinkPagina INTEGER := 0;
	FraseLinkPagina INTEGER := 0;
	
	FraseTitolo VARCHAR(255);
	NotificaRefTitolo VARCHAR(255) := 'null' ;
	FraseRefTitolo VARCHAR(255) := 'null' ;
	
BEGIN
	
	select * into notifica_rec from notifica where id_operazione = idOp; -- se esiste quella notifica
	raise notice 'notifica rec %', notifica_rec;
	if found then
	
		if emailAutore != (Select autore_notificato from notifica where id_operazione  = idop) then
			raise exception 'l''autore inserito non e autorizzato a visualizzare questa notifica';
		end if;
		
		CALL checkautore(emailAutore, notifica_rec.pagina_frase);
			
		update operazione_utente set visionata = 1::bit(1) where id_operazione = idOp; --aggiorno il visualizzato
		
		if notifica_rec.link_pagina is not null then NotificaLinkPagina := notifica_rec.link_pagina; select titolo into NotificaRefTitolo from pagina where id_pagina = notifica_rec.link_pagina; end if;
		
		select titolo into FraseTitolo from pagina where id_pagina = notifica_rec.pagina_frase;
		
		if notifica_rec.modifica = 1::bit(1) then
			select * into frase_rec from frase where pagina = notifica_rec.pagina_frase AND posizione = notifica_rec.posizione_frase;
			raise notice '%', frase_rec;
			
			if notifica_rec.link_pagina is not null then FraseLinkPagina := frase_rec.linkpagina; select titolo into FraseRefTitolo from pagina where id_pagina = notifica_rec.link_pagina;end if;
            raise notice 'FraseRefTitolo: %', FraseRefTitolo;
			confronto := FraseTitolo ||'+'||frase_rec.testo ||'-'|| frase_rec.posizione ||'-' || frase_rec.link || '-'|| FraseLinkPagina || '-' || FraseRefTitolo ||'|'|| notifica_rec.testo || '-' || notifica_rec.posizioneins || '-' || notifica_rec.link || '-' || NotificaLinkPagina || '-' || NotificaRefTitolo;
		
		else
			confronto := FraseTitolo ||'+'||notifica_rec.testo || '-' || notifica_rec.posizioneins || '-' || notifica_rec.link || '-' || NotificaLinkPagina || '-' || NotificaRefTitolo;
		end if;

	else
		raise exception 'non esisete una notifica con l''identificativo proposto';
	end if;
	raise notice 'confronto hh: %', confronto;

	RETURN confronto;
END;
$$;
 b   DROP FUNCTION public.visualizzapropostaandconfronta(idop integer, emailautore character varying);
       public          filix820zec    false    4            �            1259    327867    frase    TABLE     �   CREATE TABLE public.frase (
    pagina integer NOT NULL,
    posizione integer NOT NULL,
    testo text NOT NULL,
    link bit(1) NOT NULL,
    linkpagina integer
);
    DROP TABLE public.frase;
       public         heap    filix820zec    false    4            �            1259    327911    operazione_autore    TABLE     �  CREATE TABLE public.operazione_autore (
    id_operazione integer NOT NULL,
    data timestamp without time zone NOT NULL,
    testo text NOT NULL,
    posizioneins integer,
    modifica bit(1) NOT NULL,
    link bit(1) NOT NULL,
    link_pagina integer,
    posizione_frase integer NOT NULL,
    pagina_frase integer NOT NULL,
    autore public.d_email NOT NULL,
    CONSTRAINT checklink CHECK ((((link = (1)::bit(1)) AND (link_pagina IS NOT NULL)) OR ((link_pagina IS NULL) AND (link = (0)::bit(1)))))
);
 %   DROP TABLE public.operazione_autore;
       public         heap    filix820zec    false    4    878            �            1259    327936    operazione_autore_ordered    VIEW     �   CREATE VIEW public.operazione_autore_ordered AS
 SELECT data,
    pagina_frase,
    testo,
    posizione_frase,
    link,
    link_pagina
   FROM public.operazione_autore
  ORDER BY pagina_frase, data;
 ,   DROP VIEW public.operazione_autore_ordered;
       public          filix820zec    false    222    222    222    222    222    222    4            �            1259    327885    operazione_utente    TABLE     �  CREATE TABLE public.operazione_utente (
    id_operazione integer NOT NULL,
    dataa timestamp without time zone,
    datar timestamp without time zone NOT NULL,
    testo text NOT NULL,
    accettata bit(1) NOT NULL,
    visionata bit(1) NOT NULL,
    posizioneins integer,
    modifica bit(1) NOT NULL,
    link bit(1) NOT NULL,
    link_pagina integer,
    posizione_frase integer,
    pagina_frase integer NOT NULL,
    utente public.d_email NOT NULL,
    autore_notificato public.d_email NOT NULL,
    CONSTRAINT checklink CHECK ((((link = (1)::bit(1)) AND (link_pagina IS NOT NULL)) OR ((link_pagina IS NULL) AND (link = (0)::bit(1)))))
);
 %   DROP TABLE public.operazione_utente;
       public         heap    filix820zec    false    878    4    878            �            1259    327940    operazione_utente_ordered    VIEW       CREATE VIEW public.operazione_utente_ordered AS
 SELECT dataa AS data,
    pagina_frase,
    testo,
    posizione_frase,
    link,
    link_pagina
   FROM public.operazione_utente
  WHERE ((dataa IS NOT NULL) AND (accettata = (1)::bit(1)))
  ORDER BY pagina_frase, dataa;
 ,   DROP VIEW public.operazione_utente_ordered;
       public          filix820zec    false    220    220    220    220    220    220    220    4            �            1259    327944    log_page    VIEW     g  CREATE VIEW public.log_page AS
 SELECT data,
    pagina_frase,
    testo,
    posizione_frase,
    link,
    link_pagina
   FROM ( SELECT operazione_autore_ordered.data,
            operazione_autore_ordered.pagina_frase,
            operazione_autore_ordered.testo,
            operazione_autore_ordered.posizione_frase,
            operazione_autore_ordered.link,
            operazione_autore_ordered.link_pagina
           FROM public.operazione_autore_ordered
        UNION
         SELECT operazione_utente_ordered.data,
            operazione_utente_ordered.pagina_frase,
            operazione_utente_ordered.testo,
            operazione_utente_ordered.posizione_frase,
            operazione_utente_ordered.link,
            operazione_utente_ordered.link_pagina
           FROM public.operazione_utente_ordered) unnamed_subquery
  ORDER BY pagina_frase, data;
    DROP VIEW public.log_page;
       public          filix820zec    false    224    224    224    224    224    224    223    223    223    223    223    223    4            �            1259    385033    notifica    VIEW     D  CREATE VIEW public.notifica AS
 SELECT id_operazione,
    datar,
    testo,
    accettata,
    visionata,
    posizioneins,
    modifica,
    link,
    link_pagina,
    posizione_frase,
    pagina_frase,
    utente,
    autore_notificato
   FROM public.operazione_utente
  WHERE (dataa IS NULL)
  ORDER BY datar, visionata;
    DROP VIEW public.notifica;
       public          filix820zec    false    220    220    220    220    220    220    220    220    220    220    220    220    220    220    878    4    878            �            1259    327910 #   operazione_autore_id_operazione_seq    SEQUENCE     �   CREATE SEQUENCE public.operazione_autore_id_operazione_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.operazione_autore_id_operazione_seq;
       public          filix820zec    false    222    4            z           0    0 #   operazione_autore_id_operazione_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.operazione_autore_id_operazione_seq OWNED BY public.operazione_autore.id_operazione;
          public          filix820zec    false    221            �            1259    327884 #   operazione_utente_id_operazione_seq    SEQUENCE     �   CREATE SEQUENCE public.operazione_utente_id_operazione_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 :   DROP SEQUENCE public.operazione_utente_id_operazione_seq;
       public          filix820zec    false    4    220            {           0    0 #   operazione_utente_id_operazione_seq    SEQUENCE OWNED BY     k   ALTER SEQUENCE public.operazione_utente_id_operazione_seq OWNED BY public.operazione_utente.id_operazione;
          public          filix820zec    false    219            �            1259    327852    pagina    TABLE     ?  CREATE TABLE public.pagina (
    id_pagina integer NOT NULL,
    titolo character varying(255) NOT NULL,
    generalita_autore character varying(41) NOT NULL,
    dataultimamodifica timestamp without time zone NOT NULL,
    datacreazione timestamp without time zone NOT NULL,
    emailautore public.d_email NOT NULL
);
    DROP TABLE public.pagina;
       public         heap    filix820zec    false    4    878            �            1259    327851    pagina_id_pagina_seq    SEQUENCE     �   CREATE SEQUENCE public.pagina_id_pagina_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 +   DROP SEQUENCE public.pagina_id_pagina_seq;
       public          filix820zec    false    4    217            |           0    0    pagina_id_pagina_seq    SEQUENCE OWNED BY     M   ALTER SEQUENCE public.pagina_id_pagina_seq OWNED BY public.pagina.id_pagina;
          public          filix820zec    false    216            �            1259    327956    storicita_totale    VIEW     W  CREATE VIEW public.storicita_totale AS
 SELECT unnamed_subquery.pagina_frase AS id_pagina,
    unnamed_subquery.dataa AS data_accettazione,
    unnamed_subquery.datar AS data_richiesta,
    unnamed_subquery.posizione_frase AS posizione,
    unnamed_subquery.testo,
    unnamed_subquery.utente,
    unnamed_subquery.accettata,
    unnamed_subquery.modifica,
    unnamed_subquery.link,
    unnamed_subquery.link_pagina
   FROM ( SELECT operazione_utente.pagina_frase,
            NULL::timestamp without time zone AS dataa,
            operazione_utente.datar,
            operazione_utente.posizione_frase,
            operazione_utente.testo,
            operazione_utente.utente,
            operazione_utente.accettata,
            operazione_utente.modifica,
            operazione_utente.link,
            operazione_utente.link_pagina
           FROM public.operazione_utente
          WHERE (operazione_utente.dataa IS NULL)) unnamed_subquery
UNION
 SELECT operazione_utente.pagina_frase AS id_pagina,
    operazione_utente.dataa AS data_accettazione,
    operazione_utente.datar AS data_richiesta,
    operazione_utente.posizione_frase AS posizione,
    operazione_utente.testo,
    operazione_utente.utente,
    operazione_utente.accettata,
    operazione_utente.modifica,
    operazione_utente.link,
    operazione_utente.link_pagina
   FROM public.operazione_utente
  WHERE (operazione_utente.dataa IS NOT NULL)
UNION
 SELECT operazione_autore.pagina_frase AS id_pagina,
    operazione_autore.data AS data_accettazione,
    NULL::timestamp without time zone AS data_richiesta,
    operazione_autore.posizione_frase AS posizione,
    operazione_autore.testo,
    operazione_autore.autore AS utente,
    NULL::"bit" AS accettata,
    NULL::"bit" AS modifica,
    operazione_autore.link,
    operazione_autore.link_pagina
   FROM public.operazione_autore
  ORDER BY 1, 2;
 #   DROP VIEW public.storicita_totale;
       public          filix820zec    false    222    222    222    222    222    222    222    220    220    220    220    220    220    220    220    220    220    4    878            �            1259    327843    utente    TABLE     ^  CREATE TABLE public.utente (
    email public.d_email NOT NULL,
    nome character varying(20) NOT NULL,
    cognome character varying(20) NOT NULL,
    password_utente character varying(50) NOT NULL,
    genere character(1) NOT NULL,
    autore bit(1) NOT NULL,
    CONSTRAINT checkgenere CHECK (((genere ~~ 'F'::text) OR (genere ~~ 'M'::text)))
);
    DROP TABLE public.utente;
       public         heap    filix820zec    false    4    878            �           2604    327914    operazione_autore id_operazione    DEFAULT     �   ALTER TABLE ONLY public.operazione_autore ALTER COLUMN id_operazione SET DEFAULT nextval('public.operazione_autore_id_operazione_seq'::regclass);
 N   ALTER TABLE public.operazione_autore ALTER COLUMN id_operazione DROP DEFAULT;
       public          filix820zec    false    222    221    222            �           2604    327888    operazione_utente id_operazione    DEFAULT     �   ALTER TABLE ONLY public.operazione_utente ALTER COLUMN id_operazione SET DEFAULT nextval('public.operazione_utente_id_operazione_seq'::regclass);
 N   ALTER TABLE public.operazione_utente ALTER COLUMN id_operazione DROP DEFAULT;
       public          filix820zec    false    220    219    220            �           2604    327855    pagina id_pagina    DEFAULT     t   ALTER TABLE ONLY public.pagina ALTER COLUMN id_pagina SET DEFAULT nextval('public.pagina_id_pagina_seq'::regclass);
 ?   ALTER TABLE public.pagina ALTER COLUMN id_pagina DROP DEFAULT;
       public          filix820zec    false    216    217    217            m          0    327867    frase 
   TABLE DATA           K   COPY public.frase (pagina, posizione, testo, link, linkpagina) FROM stdin;
    public          filix820zec    false    218   ��       q          0    327911    operazione_autore 
   TABLE DATA           �   COPY public.operazione_autore (id_operazione, data, testo, posizioneins, modifica, link, link_pagina, posizione_frase, pagina_frase, autore) FROM stdin;
    public          filix820zec    false    222   d�       o          0    327885    operazione_utente 
   TABLE DATA           �   COPY public.operazione_utente (id_operazione, dataa, datar, testo, accettata, visionata, posizioneins, modifica, link, link_pagina, posizione_frase, pagina_frase, utente, autore_notificato) FROM stdin;
    public          filix820zec    false    220   ��       l          0    327852    pagina 
   TABLE DATA           v   COPY public.pagina (id_pagina, titolo, generalita_autore, dataultimamodifica, datacreazione, emailautore) FROM stdin;
    public          filix820zec    false    217   ��       j          0    327843    utente 
   TABLE DATA           W   COPY public.utente (email, nome, cognome, password_utente, genere, autore) FROM stdin;
    public          filix820zec    false    215   �       }           0    0 #   operazione_autore_id_operazione_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public.operazione_autore_id_operazione_seq', 232, true);
          public          filix820zec    false    221            ~           0    0 #   operazione_utente_id_operazione_seq    SEQUENCE SET     S   SELECT pg_catalog.setval('public.operazione_utente_id_operazione_seq', 163, true);
          public          filix820zec    false    219                       0    0    pagina_id_pagina_seq    SEQUENCE SET     C   SELECT pg_catalog.setval('public.pagina_id_pagina_seq', 71, true);
          public          filix820zec    false    216            �           2606    327873    frase pk_frase 
   CONSTRAINT     [   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT pk_frase PRIMARY KEY (pagina, posizione);
 8   ALTER TABLE ONLY public.frase DROP CONSTRAINT pk_frase;
       public            filix820zec    false    218    218            �           2606    327919 !   operazione_autore pk_operazione_a 
   CONSTRAINT     j   ALTER TABLE ONLY public.operazione_autore
    ADD CONSTRAINT pk_operazione_a PRIMARY KEY (id_operazione);
 K   ALTER TABLE ONLY public.operazione_autore DROP CONSTRAINT pk_operazione_a;
       public            filix820zec    false    222            �           2606    327894 !   operazione_utente pk_operazione_u 
   CONSTRAINT     j   ALTER TABLE ONLY public.operazione_utente
    ADD CONSTRAINT pk_operazione_u PRIMARY KEY (id_operazione);
 K   ALTER TABLE ONLY public.operazione_utente DROP CONSTRAINT pk_operazione_u;
       public            filix820zec    false    220            �           2606    327859    pagina pk_pagina 
   CONSTRAINT     U   ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT pk_pagina PRIMARY KEY (id_pagina);
 :   ALTER TABLE ONLY public.pagina DROP CONSTRAINT pk_pagina;
       public            filix820zec    false    217            �           2606    327850    utente pk_utente 
   CONSTRAINT     Q   ALTER TABLE ONLY public.utente
    ADD CONSTRAINT pk_utente PRIMARY KEY (email);
 :   ALTER TABLE ONLY public.utente DROP CONSTRAINT pk_utente;
       public            filix820zec    false    215            �           2606    327861    pagina unique_titolo 
   CONSTRAINT     Q   ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT unique_titolo UNIQUE (titolo);
 >   ALTER TABLE ONLY public.pagina DROP CONSTRAINT unique_titolo;
       public            filix820zec    false    217            �           2620    327933 &   utente aggiornamento_generalita_pagina    TRIGGER     �   CREATE TRIGGER aggiornamento_generalita_pagina AFTER UPDATE OF nome, cognome ON public.utente FOR EACH ROW WHEN ((new.autore = (1)::bit(1))) EXECUTE FUNCTION public.aggiornamento_generalita_pagina();
 ?   DROP TRIGGER aggiornamento_generalita_pagina ON public.utente;
       public          filix820zec    false    215    243    215    215    215            �           2620    327931 &   operazione_utente aggiornamentodatamod    TRIGGER     �   CREATE TRIGGER aggiornamentodatamod BEFORE UPDATE OF testo ON public.operazione_utente FOR EACH ROW EXECUTE FUNCTION public.aggiornamentodatamod();
 ?   DROP TRIGGER aggiornamentodatamod ON public.operazione_utente;
       public          filix820zec    false    240    220    220            �           2620    409601 *   operazione_utente checkaggiornamentopagina    TRIGGER     �   CREATE TRIGGER checkaggiornamentopagina AFTER UPDATE OF dataa ON public.operazione_utente FOR EACH ROW EXECUTE FUNCTION public.checkaggiornamentopagina();
 C   DROP TRIGGER checkaggiornamentopagina ON public.operazione_utente;
       public          filix820zec    false    220    259    220            �           2620    393216    frase datamodficapagina    TRIGGER     x   CREATE TRIGGER datamodficapagina AFTER INSERT ON public.frase FOR EACH ROW EXECUTE FUNCTION public.datamodficapagina();
 0   DROP TRIGGER datamodficapagina ON public.frase;
       public          filix820zec    false    218    241            �           2620    434177    pagina deletefraseoputente    TRIGGER     }   CREATE TRIGGER deletefraseoputente AFTER DELETE ON public.pagina FOR EACH ROW EXECUTE FUNCTION public.deletefraseoputente();
 3   DROP TRIGGER deletefraseoputente ON public.pagina;
       public          filix820zec    false    217    261            �           2620    327930 #   operazione_utente modifica_proposta    TRIGGER     �   CREATE TRIGGER modifica_proposta BEFORE UPDATE OF testo ON public.operazione_utente FOR EACH ROW WHEN ((old.visionata = (1)::bit(1))) EXECUTE FUNCTION public.modifica_proposta();
 <   DROP TRIGGER modifica_proposta ON public.operazione_utente;
       public          filix820zec    false    239    220    220    220            �           2620    327950 "   frase operazioneautoreintegritains    TRIGGER     �   CREATE TRIGGER operazioneautoreintegritains AFTER INSERT ON public.frase FOR EACH ROW EXECUTE FUNCTION public.operazioneautoreintegritains();
 ;   DROP TRIGGER operazioneautoreintegritains ON public.frase;
       public          filix820zec    false    218    246            �           2620    327955 "   frase operazioneautoreintegritamod    TRIGGER     �   CREATE TRIGGER operazioneautoreintegritamod AFTER UPDATE OF testo ON public.frase FOR EACH ROW EXECUTE FUNCTION public.operazioneautoreintegritamod();
 ;   DROP TRIGGER operazioneautoreintegritamod ON public.frase;
       public          filix820zec    false    248    218    218            �           2620    327949    frase positioncontroll    TRIGGER     w   CREATE TRIGGER positioncontroll BEFORE INSERT ON public.frase FOR EACH ROW EXECUTE FUNCTION public.positioncontroll();
 /   DROP TRIGGER positioncontroll ON public.frase;
       public          filix820zec    false    218    262            �           2620    327934    pagina switchautore    TRIGGER     p   CREATE TRIGGER switchautore BEFORE INSERT ON public.pagina FOR EACH ROW EXECUTE FUNCTION public.switchautore();
 ,   DROP TRIGGER switchautore ON public.pagina;
       public          filix820zec    false    244    217            �           2620    327935    pagina switchutente    TRIGGER     o   CREATE TRIGGER switchutente AFTER DELETE ON public.pagina FOR EACH ROW EXECUTE FUNCTION public.switchutente();
 ,   DROP TRIGGER switchutente ON public.pagina;
       public          filix820zec    false    217    245            �           2620    327932    utente utente_no_delete    TRIGGER     x   CREATE TRIGGER utente_no_delete BEFORE DELETE ON public.utente FOR EACH ROW EXECUTE FUNCTION public.utente_no_delete();
 0   DROP TRIGGER utente_no_delete ON public.utente;
       public          filix820zec    false    242    215            �           2606    327879    frase fk_frase_pagina_link    FK CONSTRAINT     �   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT fk_frase_pagina_link FOREIGN KEY (pagina) REFERENCES public.pagina(id_pagina) ON UPDATE CASCADE ON DELETE CASCADE;
 D   ALTER TABLE ONLY public.frase DROP CONSTRAINT fk_frase_pagina_link;
       public          filix820zec    false    3257    218    217            �           2606    327874    frase fk_frase_pagina_ref    FK CONSTRAINT     �   ALTER TABLE ONLY public.frase
    ADD CONSTRAINT fk_frase_pagina_ref FOREIGN KEY (linkpagina) REFERENCES public.pagina(id_pagina) ON UPDATE CASCADE ON DELETE SET NULL;
 C   ALTER TABLE ONLY public.frase DROP CONSTRAINT fk_frase_pagina_ref;
       public          filix820zec    false    217    3257    218            �           2606    327925 (   operazione_autore fk_operazione_a_autore    FK CONSTRAINT     �   ALTER TABLE ONLY public.operazione_autore
    ADD CONSTRAINT fk_operazione_a_autore FOREIGN KEY (autore) REFERENCES public.utente(email) ON UPDATE CASCADE;
 R   ALTER TABLE ONLY public.operazione_autore DROP CONSTRAINT fk_operazione_a_autore;
       public          filix820zec    false    3255    222    215            �           2606    327920 8   operazione_autore fk_operazione_a_frase_posizione_pagina    FK CONSTRAINT     �   ALTER TABLE ONLY public.operazione_autore
    ADD CONSTRAINT fk_operazione_a_frase_posizione_pagina FOREIGN KEY (posizione_frase, pagina_frase) REFERENCES public.frase(posizione, pagina) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.operazione_autore DROP CONSTRAINT fk_operazione_a_frase_posizione_pagina;
       public          filix820zec    false    222    218    218    3261    222            �           2606    327905 .   operazione_utente fk_operazione_u_auotrepagina    FK CONSTRAINT     �   ALTER TABLE ONLY public.operazione_utente
    ADD CONSTRAINT fk_operazione_u_auotrepagina FOREIGN KEY (autore_notificato) REFERENCES public.utente(email) ON UPDATE CASCADE;
 X   ALTER TABLE ONLY public.operazione_utente DROP CONSTRAINT fk_operazione_u_auotrepagina;
       public          filix820zec    false    215    220    3255            �           2606    327895 8   operazione_utente fk_operazione_u_frase_posizione_pagina    FK CONSTRAINT     �   ALTER TABLE ONLY public.operazione_utente
    ADD CONSTRAINT fk_operazione_u_frase_posizione_pagina FOREIGN KEY (posizione_frase, pagina_frase) REFERENCES public.frase(posizione, pagina) ON UPDATE CASCADE ON DELETE CASCADE;
 b   ALTER TABLE ONLY public.operazione_utente DROP CONSTRAINT fk_operazione_u_frase_posizione_pagina;
       public          filix820zec    false    220    220    3261    218    218            �           2606    327900 (   operazione_utente fk_operazione_u_utente    FK CONSTRAINT     �   ALTER TABLE ONLY public.operazione_utente
    ADD CONSTRAINT fk_operazione_u_utente FOREIGN KEY (utente) REFERENCES public.utente(email) ON UPDATE CASCADE;
 R   ALTER TABLE ONLY public.operazione_utente DROP CONSTRAINT fk_operazione_u_utente;
       public          filix820zec    false    215    220    3255            �           2606    327862    pagina fk_pagina_autore    FK CONSTRAINT     �   ALTER TABLE ONLY public.pagina
    ADD CONSTRAINT fk_pagina_autore FOREIGN KEY (emailautore) REFERENCES public.utente(email) ON UPDATE CASCADE;
 A   ALTER TABLE ONLY public.pagina DROP CONSTRAINT fk_pagina_autore;
       public          filix820zec    false    3255    215    217            ;           826    516097     DEFAULT PRIVILEGES FOR SEQUENCES    DEFAULT ACL     {   ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON SEQUENCES TO neon_superuser WITH GRANT OPTION;
          public          cloud_admin    false    4            :           826    516096    DEFAULT PRIVILEGES FOR TABLES    DEFAULT ACL     x   ALTER DEFAULT PRIVILEGES FOR ROLE cloud_admin IN SCHEMA public GRANT ALL ON TABLES TO neon_superuser WITH GRANT OPTION;
          public          cloud_admin    false    4            m   z  x�}VKrG]S��8,R�(ʫ8q�V�슭d�����Q��=�:A��e��e�����Gٲ$�=h�x�\nW��/ٻV|p~�Y}|wv�]�o���'G��ꀣ����J���Z2m�h�so�ݗ���Z(5<��9�����zV�ݨ�&�ZC/�u>���������b�x��pH�^���C�h�r���AA�V����`v���x��ˣ�:�l��R�x=�$A�C�`m-v��[�`��RUd>gA|��������JLܑ�����ÿ&;��ޒ�Dh�O�����fȐ��"�w���P("���b�Qqه;I伡�4��j�@L�<�_���r6@����jz6�������ALǵ���S�X�)�
	��R [�����=�>�m��޻Hwb��w�Ca�5��\��7Y%�R1��y�J�Q�ɵ���5�V�$�ʲ�h	%ل���������]4I�i���c�q��Tx�M������UuV����|@:(B�����;'��Ezy�ի��74$1��B�|�G�I�q&֍
�Q�A�RRx�c��8U_�4`"�szD��B��������U����$G��1+k\-��J3L��u��q>��[� �4C�2�fx�J�W���_�J�p�>6 �X�粞�E:��M=�3]�8D� S����:߮nH��7��fנD��i)�Ҋ��h/�:�_��}F�Is�$�P݈�#D����D�}A��M��'E���{;�כ�E��{�A�")�L�'%�)�3����5gm�
�G=�@�w���	�9) "�|)|;���M%�;:J�j�;X���4�M.	pr��*ġJ:�H���X�A!�� {�'>k�Q��G�J�>�;˝�FP���ҟ��d�F�15{���e�Y�,�`�mBȴ��&DJ9䋔����s��GҴ&8ʀA��h N;D�LL��G-�>�D�(\�UoT�����~5��ܟcʵ�g��t-i��\c�����/�+���Ġ� "ˠ�βr��������U��ZFer��e�.���_����|��!̥'���f4�VY�h�ٝ�IoѪk}Ĉ�Zv��[��ۊ��?��3J����.@��묘��D�`���/�MZ��2Ȳ��k��iA�qQ@V�� ��3,2��$=�T����[�Oת2�ƥ
$Í�0��-��8 sT��n�A��XK����ţ�O]�a����1�G����h5��1.�������#i����h�r��A��^l~�a�<� ]&9�\nT��~{��ܝ��!�����`s�:�x����
�:�N.i�>�D����2�	q�Ls3���8�1-4ONj���0���֑��Js,yw��rQi�uq��,��hA-Ok������	��>      q   T  x��Xˮ�6]+_�H�a_[��M�H�6i7E6��; E*����~F�]w������d٦c�(r���9�9<s�Y�&�2+^,��Z�y�o˼H~�ٓu�&i�Ŀ�pq�&;m_�IzQ��Y�ٞ/��tS���;)ZG�;';%��uV��b�u�8��I���$��ݦѾY���ګ�K����R�^
G�u��ڑ!OVNt�E|���{+*��xu;p^��-���x���T+��^�5I�������XO��������JH���6�੝S_��
�8������N"�������ޕy�|R������"��y�U�:�ֵ��UJk���K~JT�x��Ҹ�1`�d��w}�Z�®O��߁~CߔY6,_`����5�h�2rA>I�������1'�m��pf:EB:� � ���������υ�*���d�q���A]�Jt��|�H���:�C��x!>2��� ��r��_��b�t0�|�놌�2-�����]CU��5�OG�������:���:y6�R�V2pA�N�Ǐ�Ǐ�^9�o���TI�F�H
�L�ԅ�P��t�".��-��A�9��%��W��9�JV?�{���ا���=������z�H�1B�Ҡ ���"�m�1{�s�&U�f,)��s�Sj[>�6�t�b��F��5�o��ٞC��I��B�@�a�b��iL�5ȓ�Z|bသ��e �э_�Zy (�3�i�bE�c�%�v 1��eI���0\��
P:�[w�3��p���u�}cs�b���z;F�'LP�J�J���5�7ׄD�jR�� �恵�U��D��^���3Xc��j���瓒�i��w��Yl�|��W��,xo���%��q��8�S]��hA��ƻ��`{��iL�b[B~&,�[$�����A����о�f�aϙ75=�r��(�$����18����T.Pl�,"�
��u9n�ή���_�{ w�z�T	is8Y���v��G�m������Yq��E1%*I�����3�b��^w�o,�I���I����x��r;�jy#�qy;^|o�����.�u����%���lqWdg(q;��2� ���������@E8�č#ET�����S��zy7���ňz�\����X5��i�dY��ok^D����2�Zp��Y�|����+�� �� �`l-�sN��B���F�W<��]s���sO�,�4�D#���س�_�	�1�'J9�Tc�V���y�{�Y�h�f�XLى��$֊�<�Z���<О��=����IX�βz������Hyt
��Y�ȣ��UPøcĳ�F�5�6�9��/��s����/�����7`c�ؐ����z�Ae�WWMa&�� �C䉨����J�g��Ou��N/y�0ߚ{��ݷ��g˘�yZ��q���F2&c��'��#����y^���dCv`�6�@��ieC<"_����t0�pJ�Z�5t�5�qo�Oa����C���|�M���2�n���r�Y$�	]>�.������sl��4�#�K3�S>�;��{PW��?��m1��'�7�5�=3rΞ�l@�g����ঈ�K-kG.���X�%$��x�q�j�aN9+k:_�4�WQ����?f�nL��l�<�)P�֚njS\��l7��3⌃���@Y4��H�����U=�AL��;�JD��iX9�4�kq��i��,g�-�W�.1���0���Zjz5���1�~���Ʉ�s�9�JG�Y�ݶ��/!�-)��"� ��,���&�r$�n�i����|��Q��n9�7����Xl6��g�V�ϋgϞ�\�b�      o     x����n�0���S�D�_�O����z��rMd�`�!���kC[��R�
	����5P��BZQ^��T���+р�1����x�W �SJ8Arh;\��?�y9_��v�_ �ն�A;=�"�D�y>CE%l0����%��ݏ��I�$3C&�J��kxu>���l�c"�cM~�O?����$�*lJ�(�0����)�Q;�p�?��Zuk1��J��

o6����t�t��ȋ�p�~총��?�k��c�
&e�:��x�E�	A$̞      l     x����j�0���)�3�Ϩ�M��B�梱\�D�§o�)���M�s�wo��#�'O��y�u�{$�	ub�$4��(fO4Y�H���G�ε�2������'t�,�66�`�0�'Wh[��^�����XQ���2� ���i۩Ic�^�v�_���,)�-N*�u�qË_c�my�O�/�l��KmK4^�\�_tt@�����������R����rmq�" ��`9rnT��K�=��m9&��r��%����+x?gY���>      j   �   x�m��
�0��s�0��@�A�(^B��`یdS��-c�"��O���"�s؅�7^��R����Dz�v�R5�g8� ƣ��^�]+:�S�{�H���.�<ʙ_ָ>�r��C�Rk���d�+Ю඀f2��]oV̞�'�C�<�q�}|kd     