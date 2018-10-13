CREATE TABLE users (
  id uuid NOT NULL
, created_at timestamp without time zone NOT NULL
, updated_at timestamp without time zone NOT NULL
, username character varying(255) NOT NULL
, first_name character varying(255) NOT NULL
, last_name character varying(255) NOT NULL
, email character varying(255) NOT NULL
, is_active boolean NOT NULL
, is_admin boolean NOT NULL
, PRIMARY KEY (id)
, UNIQUE (id)
, UNIQUE (username)
);
