INSERT INTO public.codec (id, keys, name, type, quality)
VALUES
    ('all', '{}', 'Wszystkie', 'A', 1),
    ('alaw', '{ALAW, G711}', 'G.711 alaw (as used in Europe)', 'A', 1),
    ('ulaw', '{ULAW, G711}', 'G.711 alaw (as used in Europe)', 'A', 1),
    ('g722', '{G722}', '16 kHz wideband codec; passthrough, playback ', 'A', 2),
    ('speex', '{SPEEX}', 'configurable 4-48kbps, VBR, ABR, etc. ', 'A', 2),
    ('h264', '{H264}', 'video h264 (H.264 Video)', 'V', 2);


INSERT INTO peer (number, password, codecs_allowed, codecs_denied, description)
VALUES
    ('300', '1234', '{g722}', '{all}', 'Jitsi'),
    ('301', '1234', '{g722}', '{all}', 'X-Lite'),
    ('302', '1234', '{g722}', '{all}', ''),
    ('303', '1234', '{g722}', '{all}', ''),
    ('304', '1234', '{g722}', '{all}', 'Yelink');


/*
	id              SERIAL PRIMARY KEY,
	enabled         BOOLEAN NOT NULL DEFAULT true,
	phone_id        INTEGER REFERENCES phone (id), -- telefon przypisany do danego konta sip
	number          VARCHAR (30) NOT NULL UNIQUE,		
	password        VARCHAR (100) NOT NULL,
	address         VARCHAR (100),  -- adres IP, z którego zalogował się peer
	caller_id       VARCHAR (100),
	added           TIMESTAMP WITHOUT TIME ZONE NOT NULL DEFAULT now(),
	codecs_allowed	VARCHAR(30)[] NOT NULL DEFAULT '{all}',
	codecs_denied	VARCHAR(30)[] NOT NULL DEFAULT '{all}',
		--------------- właściciel konta: może num być użytkownik lub lokalizacja
	user_id         INTEGER REFERENCES users.users (id),
	location_id 	INTEGER REFERENCES location (id),

	registered      BOOLEAN NOT NULL, -- czy zalogowany do asteriska: dany telefon może być zalogowany tylko do jednego użytkownika
	last_registered TIMESTAMP WITHOUT TIME ZONE,
	last_unregistered TIMESTAMP WITHOUT TIME ZONE,
	description 	TEXT

*/