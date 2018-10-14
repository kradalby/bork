CREATE TABLE namespaces_users (
  namespace_id uuid NOT NULL
, user_id uuid NOT NULL
, PRIMARY KEY (namespace_id, user_id)
, UNIQUE (namespace_id, user_id)
);
