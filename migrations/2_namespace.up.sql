CREATE TABLE namespaces (
  id uuid NOT NULL
, created_at timestamp without time zone NOT NULL
, updated_at timestamp without time zone NOT NULL
, name character varying(255) NOT NULL
, owner_id uuid REFERENCES users(id) ON DELETE CASCADE
, PRIMARY KEY (id)
, UNIQUE (id)
, UNIQUE (name)
);
