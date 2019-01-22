--
-- PostgreSQL database dump
--

-- Dumped from database version 10.6 (Ubuntu 10.6-1.pgdg18.04+1)
-- Dumped by pg_dump version 11.1

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: namespaces; Type: TABLE; Schema: public; Owner: bork
--

CREATE TABLE public.namespaces (
    id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    name character varying(255) NOT NULL,
    owner_id uuid NOT NULL
);


ALTER TABLE public.namespaces OWNER TO bork;

--
-- Name: namespaces_users; Type: TABLE; Schema: public; Owner: bork
--

CREATE TABLE public.namespaces_users (
    namespace_id uuid NOT NULL,
    user_id uuid NOT NULL
);


ALTER TABLE public.namespaces_users OWNER TO bork;

--
-- Name: schema_migration; Type: TABLE; Schema: public; Owner: bork
--

CREATE TABLE public.schema_migration (
    version character varying(255) NOT NULL
);


ALTER TABLE public.schema_migration OWNER TO bork;

--
-- Name: users; Type: TABLE; Schema: public; Owner: bork
--

CREATE TABLE public.users (
    id uuid NOT NULL,
    created_at timestamp without time zone NOT NULL,
    updated_at timestamp without time zone NOT NULL,
    username character varying(255) NOT NULL,
    first_name character varying(255) NOT NULL,
    last_name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    is_active boolean NOT NULL,
    is_admin boolean NOT NULL,
    provider character varying(255) NOT NULL,
    provider_id character varying(255) NOT NULL
);


ALTER TABLE public.users OWNER TO bork;

--
-- Name: namespaces namespaces_name_key; Type: CONSTRAINT; Schema: public; Owner: bork
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_name_key UNIQUE (name);


--
-- Name: namespaces namespaces_pkey; Type: CONSTRAINT; Schema: public; Owner: bork
--

ALTER TABLE ONLY public.namespaces
    ADD CONSTRAINT namespaces_pkey PRIMARY KEY (id);


--
-- Name: namespaces_users namespaces_users_pkey; Type: CONSTRAINT; Schema: public; Owner: bork
--

ALTER TABLE ONLY public.namespaces_users
    ADD CONSTRAINT namespaces_users_pkey PRIMARY KEY (namespace_id, user_id);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: bork
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (id);


--
-- Name: users users_username_key; Type: CONSTRAINT; Schema: public; Owner: bork
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_username_key UNIQUE (username);


--
-- Name: schema_migration_version_idx; Type: INDEX; Schema: public; Owner: bork
--

CREATE UNIQUE INDEX schema_migration_version_idx ON public.schema_migration USING btree (version);


--
-- PostgreSQL database dump complete
--

