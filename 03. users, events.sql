-- DROP SCHEMA IF EXISTS USERS CASCADE; 
-- DROP SCHEMA IF EXISTS events CASCADE; 


CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE EXTENSION IF NOT EXISTS "hstore";


/*************************************************************************************************
					UŻYTKOWNICY
**************************************************************************************************/

CREATE SCHEMA IF NOT EXISTS users;

CREATE TABLE users.user_status
(
	id		CHAR PRIMARY KEY NOT NULL, 
	name		VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO users.user_status (id, name) 
VALUES 
	('R', 'Usunięty'),
	('D', 'Nieaktywny'),
	('A', 'Aktywny'),
	('E', 'Weryfikacja adresu e-mail'),
	('M', 'Moderacja');

--------------------------------------------------------------------------------

CREATE TABLE users.user_type
(
	id		CHAR PRIMARY KEY NOT NULL, 
	name		VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO users.user_type (id, name) 
VALUES 
	('N', 'Standardowy'),
	('V', 'Wirtualny'),
	('A', 'API');

--------------------------------------------------------------------------------

CREATE TABLE users.group_type
(
	id 		CHAR PRIMARY KEY NOT NULL, 
	name 		VARCHAR(100) UNIQUE NOT NULL
);

INSERT INTO users.group_type (id, name) 
VALUES 
	('N', 'Standardowa');



--------------------------------------------------------------------------------

CREATE TABLE users.users
(
	id 		SERIAL PRIMARY KEY, 
	external_token 	VARCHAR(100) UNIQUE default(uuid_generate_v4()), 
	username 	VARCHAR(100) UNIQUE NOT NULL, 
	display_name 	VARCHAR(200) NOT NULL, 
	password 	VARCHAR(100), 
	status 		CHAR NOT NULL REFERENCES users.user_status (id) DEFAULT('A'), 
	type 		CHAR NOT NULL REFERENCES users.user_type (id) DEFAULT('N'), 
	created 	TIMESTAMP NOT NULL DEFAULT (CURRENT_TIMESTAMP), 
	created_by 	VARCHAR(100), 
	email 		VARCHAR(100) UNIQUE, 
	first_name 	VARCHAR(100), 
	last_name 	VARCHAR(100), 
	ldap_auth 	BOOLEAN, 
	password_expire TIMESTAMP WITHOUT TIME ZONE, 
	password_changed TIMESTAMP WITHOUT TIME ZONE, 
	last_login 	TIMESTAMP WITHOUT TIME ZONE, 
	config 		TEXT
);

--------------------------------------------------------------------------------

CREATE TABLE users.rights
(
	id 		VARCHAR(100) PRIMARY KEY, 
	name 		VARCHAR(300) NOT NULL UNIQUE, 
	description 	VARCHAR, 
	parent_right 	VARCHAR(100) REFERENCES users.rights (id)
);

--------------------------------------------------------------------------------

CREATE TABLE users.groups
(
	id 		VARCHAR(100) PRIMARY KEY, 
	type 		CHAR NOT NULL REFERENCES users.group_type (id) DEFAULT('N'),
	parent 		VARCHAR(100) REFERENCES users.groups (id),
	name 		TEXT NOT NULL, 
	description 	TEXT,
	embedded 	BOOLEAN NOT NULL, 
	enabled 	BOOLEAN NOT NULL DEFAULT true
);

--------------------------------------------------------------------------------

CREATE TABLE users.group_rights
(
	group_key 	VARCHAR(100) REFERENCES users.groups (id), 
	right_key 	VARCHAR(100) REFERENCES users.rights (id), 
	refused 	BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY (group_key, right_key)
);

--------------------------------------------------------------------------------

CREATE TABLE users.user_rights
(
	user_id 	INTEGER NOT NULL REFERENCES users.users (id), 
	right_key 	VARCHAR(100) REFERENCES users.rights (id), 
	refused 	BOOLEAN NOT NULL DEFAULT false,
	PRIMARY KEY (user_id, right_key)
);

--------------------------------------------------------------------------------

CREATE TABLE users.user_groups
(
	user_id 	INTEGER NOT NULL REFERENCES users.users (id), 
	group_key 	VARCHAR(100) NOT NULL REFERENCES users.groups (id),
	PRIMARY KEY (user_id, group_key)
);

--------------------------------------------------------------------------------

CREATE TABLE users.user_attributes
(
	user_id 	INTEGER NOT NULL REFERENCES users.users (id), 
	key 		VARCHAR(100) NOT NULL,
	name 		VARCHAR(200) NOT NULL,
	value 		TEXT,
	PRIMARY KEY (user_id, key)
);







/*************************************************************************************************
					 ZDARZENIA 
**************************************************************************************************/

CREATE SCHEMA IF NOT EXISTS events;

--------------------------------------------------------------------------------

CREATE TABLE events.events
(
	id 		SERIAL PRIMARY KEY,
	date 		TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	type 		CHAR NOT NULL CHECK (type IN ('I','E','W')), -- Info, Error, Warning
	tags 		VARCHAR(100)[] NOT NULL,
	source 		VARCHAR(100),
	event 		TEXT,
	username 	VARCHAR(100),
	address 	VARCHAR(100),
	pid 		INTEGER NOT NULL DEFAULT pg_backend_pid(), -- idenyfikator procesu bazy danych 
	tid 		BIGINT NOT NULL DEFAULT txid_current(), -- identyfikator transakcji
	user_id 	INTEGER REFERENCES users.users (id),
	url 		TEXT
);

CREATE TABLE events.foreign_keys
(
	event_id 	INTEGER NOT NULL REFERENCES events.events (id),
	column_name 	TEXT NOT NULL,
	keys 		INTEGER[],
	PRIMARY KEY (event_id, column_name)
);

CREATE TABLE events.details
(
	id 		SERIAL PRIMARY KEY,
	event_id 	INTEGER NOT NULL REFERENCES events.events (id),
	tags 		TEXT[],
	name 		TEXT,
	value 		TEXT,
	content_type 	TEXT
);

CREATE TABLE events.attributes
(
	id 		SERIAL PRIMARY KEY,
	event_id 	INTEGER NOT NULL REFERENCES events.events (id),
	tags 		TEXT[],
	name 		TEXT,
	value 		TEXT
);

CREATE TABLE events.trucking 
(
	id 		SERIAL NOT NULL PRIMARY KEY,
	--event_id integer,
	pid 		INTEGER NOT NULL DEFAULT pg_backend_pid(), -- idenyfikator procesu bazy danych 
	tid 		BIGINT NOT NULL DEFAULT txid_current(), -- identyfikator transakcji
	date 		TIMESTAMP WITHOUT TIME ZONE default(now()),
	action 		CHAR NOT NULL CHECK (action IN ('I','D','U')),
	"schema" 	VARCHAR(30),
	"table" 	VARCHAR(80),
	rel_id 		OID,
	old_values 	HSTORE,
	changed 	HSTORE
);

CREATE OR REPLACE FUNCTION events.trucking_trigger() 
RETURNS TRIGGER AS $$
DECLARE
	old_values hstore;
	values hstore;
BEGIN	  

	IF (TG_OP = 'UPDATE') THEN

		old_values = hstore(OLD.*);
		values = hstore(NEW.*);

		values = (values - old_values);
		
		IF values = hstore('') THEN
			RETURN NULL;
		END IF;
		
		INSERT INTO events.trucking(rel_id, action, "schema", "table", old_values, changed)
		VALUES(TG_RELID, 'U', TG_TABLE_SCHEMA, TG_TABLE_NAME, old_values, values);
  
	ELSIF (TG_OP = 'DELETE') THEN

		INSERT INTO events.trucking(rel_id, action, "schema", "table", old_values, changed)
		VALUES(TG_RELID, 'D', TG_TABLE_SCHEMA, TG_TABLE_NAME, hstore(OLD.*), values);
  
	ELSIF (TG_OP = 'INSERT') THEN

		INSERT INTO events.trucking(rel_id, action, "schema", "table", old_values, changed)
		VALUES(TG_RELID, 'I', TG_TABLE_SCHEMA, TG_TABLE_NAME, hstore(NEW.*), values);

	END IF;

		RETURN NULL;

END;
$$
LANGUAGE plpgsql;






/*************************************************************************************************
					TRIGGERY ZDARZEŃ 
**************************************************************************************************/


CREATE TRIGGER change_trucking
	AFTER INSERT OR UPDATE OR DELETE ON users.users
	FOR EACH ROW EXECUTE PROCEDURE events.trucking_trigger();

CREATE TRIGGER change_trucking
	AFTER INSERT OR UPDATE OR DELETE ON users.groups
	FOR EACH ROW EXECUTE PROCEDURE events.trucking_trigger();

CREATE TRIGGER change_trucking
	AFTER INSERT OR UPDATE OR DELETE ON users.user_rights
	FOR EACH ROW EXECUTE PROCEDURE events.trucking_trigger();

CREATE TRIGGER change_trucking
	AFTER INSERT OR UPDATE OR DELETE ON users.group_rights
	FOR EACH ROW EXECUTE PROCEDURE events.trucking_trigger();
