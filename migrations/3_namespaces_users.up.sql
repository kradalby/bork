CREATE TABLE namespaces_users (
  namespace_id uuid REFERENCES namespaces(id) ON UPDATE CASCADE ON DELETE CASCADE 
, user_id uuid REFERENCES users(id) ON UPDATE CASCADE ON DELETE CASCADE 
, PRIMARY KEY (namespace_id, user_id)
, UNIQUE (namespace_id, user_id)
);
