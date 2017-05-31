-- DROP SCHEMA public cascade;


CREATE SCHEMA IF NOT EXISTS public;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "hstore";


-----------------------------------------------------------------------------------------------------------

CREATE TABLE codec
(
	id          VARCHAR(30) PRIMARY KEY,
    keys        VARCHAR(30)[] NOT NULL,
	name		VARCHAR(100) NOT NULL,
	type		CHAR NOT NULL 
				CHECK (type IN (
					'A', 	-- audio
					'V', 	-- video
					'T'	-- text
				)),
	quality		SMALLINT CHECK (quality in (1, 2, 3)),
	description	TEXT
);

CREATE TABLE phone_model
(
	id          SERIAL PRIMARY KEY,
	name		VARCHAR(300) NOT NULL,
	parent      INTEGER REFERENCES phone_model(id)		
);


CREATE TABLE phone
(
	id          SERIAL PRIMARY KEY,
	model 		INTEGER REFERENCES phone_model (id),
	active 		BOOLEAN NOT NULL DEFAULT true,
	added 		TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	ip          VARCHAR (30),       -- ip ostatniego logowania
	port 		INTEGER,            -- port ostatniego logowania
	mac 		VARCHAR (100),
	last_login 	TIMESTAMP WITHOUT TIME ZONE,
	logged 		BOOLEAN,
	user_agent 	TEXT,
	login 		TEXT,       -- login konta admina urządzenia
	password 	TEXT,       -- hasło konta admina urządzenia
	info 		HSTORE NOT NULL DEFAULT ''		 -- informacje z asteriska
);


CREATE TRIGGER phone_trucking
	AFTER INSERT OR UPDATE OR DELETE ON phone
	FOR EACH ROW EXECUTE PROCEDURE events.trucking_trigger();



-----------------------------------------------------------------------------------------------------------


CREATE TABLE location 
(
	id          SERIAL PRIMARY KEY,
	name 		TEXT NOT NULL UNIQUE,
	parent 		INTEGER REFERENCES location (id)
);

--------- peer - konto sipowe ----------------
CREATE TABLE peer 
(
	id                  SERIAL PRIMARY KEY,
	enabled             BOOLEAN NOT NULL DEFAULT true,
	phone_id            INTEGER REFERENCES phone (id), -- telefon przypisany do danego konta sip
	number              VARCHAR (30) NOT NULL UNIQUE,		
	password            VARCHAR (100) NOT NULL,
	address             VARCHAR (100),  -- adres IP, z którego zalogował się peer
	caller_id           VARCHAR (100),
	added               TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	codecs_allowed      VARCHAR(30)[] NOT NULL DEFAULT '{all}',
	codecs_denied       VARCHAR(30)[] NOT NULL DEFAULT '{all}',
		--------------- właściciel konta: może num być użytkownik lub lokalizacja
	user_id             INTEGER REFERENCES users.users (id)  
                        CHECK (notNullArgs(ARRAY[user_id, location_id]) < 2),
	location_id         INTEGER REFERENCES location (id)
                        CHECK (notNullArgs(ARRAY[user_id, location_id]) < 2),
	registered          BOOLEAN NOT NULL DEFAULT false, -- czy zalogowany do asteriska: dany telefon może być zalogowany tylko do jednego użytkownika
	last_registered     TIMESTAMP WITHOUT TIME ZONE,
	last_unregistered   TIMESTAMP WITHOUT TIME ZONE,
	description         TEXT
);



CREATE TRIGGER peer_trucking
	AFTER INSERT OR UPDATE OR DELETE ON peer
	FOR EACH ROW EXECUTE PROCEDURE events.trucking_trigger();


CREATE OR REPLACE FUNCTION single_active_peer() 
RETURNS TRIGGER AS $$
BEGIN
	IF NEW.registered AND (SELECT COUNT(1) FROM peer WHERE phone_id = NEW.phone_id AND registered) > 1
	THEN	
		RAISE EXCEPTION 'Telefon (id = %) jest już aktywny', NEW.phone_id;
	END IF;
RETURN NULL; -- result is ignored since this is an AFTER trigger
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER single_active_peer
	AFTER INSERT OR UPDATE OR DELETE ON peer
	FOR EACH ROW EXECUTE PROCEDURE single_active_peer();





