--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: plpgsql; Type: EXTENSION; Schema: -; Owner:
--

CREATE EXTENSION IF NOT EXISTS plpgsql WITH SCHEMA pg_catalog;


--
-- Name: EXTENSION plpgsql; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION plpgsql IS 'PL/pgSQL procedural language';


--
-- Name: merge_quota(); Type: FUNCTION; Schema: public; Owner: postfix
--

CREATE FUNCTION public.merge_quota() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            UPDATE quota SET current = NEW.current + current WHERE username = NEW.username AND path = NEW.path;
            IF found THEN
                RETURN NULL;
            ELSE
                RETURN NEW;
            END IF;
      END;
      $$;


ALTER FUNCTION public.merge_quota() OWNER TO postfix;

--
-- Name: merge_quota2(); Type: FUNCTION; Schema: public; Owner: postfix
--

CREATE FUNCTION public.merge_quota2() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
        BEGIN
            IF NEW.messages < 0 OR NEW.messages IS NULL THEN
                -- ugly kludge: we came here from this function, really do try to insert
                IF NEW.messages IS NULL THEN
                    NEW.messages = 0;
                ELSE
                    NEW.messages = -NEW.messages;
                END IF;
                return NEW;
            END IF;

            LOOP
                UPDATE quota2 SET bytes = bytes + NEW.bytes,
                    messages = messages + NEW.messages
                    WHERE username = NEW.username;
                IF found THEN
                    RETURN NULL;
                END IF;

                BEGIN
                    IF NEW.messages = 0 THEN
                    INSERT INTO quota2 (bytes, messages, username) VALUES (NEW.bytes, NULL, NEW.username);
                    ELSE
                        INSERT INTO quota2 (bytes, messages, username) VALUES (NEW.bytes, -NEW.messages, NEW.username);
                    END IF;
                    return NULL;
                    EXCEPTION WHEN unique_violation THEN
                    -- someone just inserted the record, update it
                END;
            END LOOP;
        END;
        $$;


ALTER FUNCTION public.merge_quota2() OWNER TO postfix;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: admin; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.admin (
    username character varying(255) NOT NULL,
    password character varying(255) DEFAULT ''::character varying NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    superadmin boolean DEFAULT false NOT NULL,
    phone character varying(30) DEFAULT ''::character varying NOT NULL,
    email_other character varying(255) DEFAULT ''::character varying NOT NULL,
    token character varying(255) DEFAULT ''::character varying NOT NULL,
    token_validity timestamp with time zone DEFAULT '2000-01-01 00:00:00+00'::timestamp with time zone
);


ALTER TABLE public.admin OWNER TO postfix;

--
-- Name: TABLE admin; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.admin IS 'Postfix Admin - Virtual Admins';


--
-- Name: alias; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.alias (
    address character varying(255) NOT NULL,
    goto text NOT NULL,
    domain character varying(255) NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.alias OWNER TO postfix;

--
-- Name: TABLE alias; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.alias IS 'Postfix Admin - Virtual Aliases';


--
-- Name: alias_domain; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.alias_domain (
    alias_domain character varying(255) NOT NULL,
    target_domain character varying(255) NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.alias_domain OWNER TO postfix;

--
-- Name: TABLE alias_domain; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.alias_domain IS 'Postfix Admin - Domain Aliases';


--
-- Name: config; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.config (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    value character varying(20) NOT NULL
);


ALTER TABLE public.config OWNER TO postfix;

--
-- Name: config_id_seq; Type: SEQUENCE; Schema: public; Owner: postfix
--

CREATE SEQUENCE public.config_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.config_id_seq OWNER TO postfix;

--
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postfix
--

ALTER SEQUENCE public.config_id_seq OWNED BY public.config.id;


--
-- Name: domain; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.domain (
    domain character varying(255) NOT NULL,
    description character varying(255) DEFAULT ''::character varying NOT NULL,
    aliases integer DEFAULT 0 NOT NULL,
    mailboxes integer DEFAULT 0 NOT NULL,
    maxquota bigint DEFAULT 0 NOT NULL,
    quota bigint DEFAULT 0 NOT NULL,
    transport character varying(255) DEFAULT NULL::character varying,
    backupmx boolean DEFAULT false NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.domain OWNER TO postfix;

--
-- Name: TABLE domain; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.domain IS 'Postfix Admin - Virtual Domains';


--
-- Name: domain_admins; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.domain_admins (
    username character varying(255) NOT NULL,
    domain character varying(255) NOT NULL,
    created timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL
);


ALTER TABLE public.domain_admins OWNER TO postfix;

--
-- Name: TABLE domain_admins; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.domain_admins IS 'Postfix Admin - Domain Admins';


--
-- Name: fetchmail; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.fetchmail (
    id integer NOT NULL,
    mailbox character varying(255) DEFAULT ''::character varying NOT NULL,
    src_server character varying(255) DEFAULT ''::character varying NOT NULL,
    src_auth character varying(15) NOT NULL,
    src_user character varying(255) DEFAULT ''::character varying NOT NULL,
    src_password character varying(255) DEFAULT ''::character varying NOT NULL,
    src_folder character varying(255) DEFAULT ''::character varying NOT NULL,
    poll_time integer DEFAULT 10 NOT NULL,
    fetchall boolean DEFAULT false NOT NULL,
    keep boolean DEFAULT false NOT NULL,
    protocol character varying(15) NOT NULL,
    extra_options text,
    returned_text text,
    mda character varying(255) DEFAULT ''::character varying NOT NULL,
    date timestamp with time zone DEFAULT now(),
    usessl boolean DEFAULT false NOT NULL,
    sslcertck boolean DEFAULT false NOT NULL,
    sslcertpath character varying(255) DEFAULT ''::character varying,
    sslfingerprint character varying(255) DEFAULT ''::character varying,
    domain character varying(255) DEFAULT ''::character varying,
    active boolean DEFAULT false NOT NULL,
    created timestamp with time zone DEFAULT '2000-01-01 00:00:00+00'::timestamp with time zone,
    modified timestamp with time zone DEFAULT now(),
    CONSTRAINT fetchmail_protocol_check CHECK (((protocol)::text = ANY ((ARRAY['POP3'::character varying, 'IMAP'::character varying, 'POP2'::character varying, 'ETRN'::character varying, 'AUTO'::character varying])::text[]))),
    CONSTRAINT fetchmail_src_auth_check CHECK (((src_auth)::text = ANY ((ARRAY['password'::character varying, 'kerberos_v5'::character varying, 'kerberos'::character varying, 'kerberos_v4'::character varying, 'gssapi'::character varying, 'cram-md5'::character varying, 'otp'::character varying, 'ntlm'::character varying, 'msn'::character varying, 'ssh'::character varying, 'any'::character varying])::text[])))
);


ALTER TABLE public.fetchmail OWNER TO postfix;

--
-- Name: fetchmail_id_seq; Type: SEQUENCE; Schema: public; Owner: postfix
--

CREATE SEQUENCE public.fetchmail_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fetchmail_id_seq OWNER TO postfix;

--
-- Name: fetchmail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postfix
--

ALTER SEQUENCE public.fetchmail_id_seq OWNED BY public.fetchmail.id;


--
-- Name: log; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.log (
    "timestamp" timestamp with time zone DEFAULT now(),
    username character varying(255) DEFAULT ''::character varying NOT NULL,
    domain character varying(255) DEFAULT ''::character varying NOT NULL,
    action character varying(255) DEFAULT ''::character varying NOT NULL,
    data text DEFAULT ''::text NOT NULL,
    id integer NOT NULL
);


ALTER TABLE public.log OWNER TO postfix;

--
-- Name: TABLE log; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.log IS 'Postfix Admin - Log';


--
-- Name: log_id_seq; Type: SEQUENCE; Schema: public; Owner: postfix
--

CREATE SEQUENCE public.log_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.log_id_seq OWNER TO postfix;

--
-- Name: log_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postfix
--

ALTER SEQUENCE public.log_id_seq OWNED BY public.log.id;


--
-- Name: mailbox; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.mailbox (
    username character varying(255) NOT NULL,
    password character varying(255) DEFAULT ''::character varying NOT NULL,
    name character varying(255) DEFAULT ''::character varying NOT NULL,
    maildir character varying(255) DEFAULT ''::character varying NOT NULL,
    quota bigint DEFAULT 0 NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    domain character varying(255),
    local_part character varying(255) NOT NULL,
    phone character varying(30) DEFAULT ''::character varying NOT NULL,
    email_other character varying(255) DEFAULT ''::character varying NOT NULL,
    token character varying(255) DEFAULT ''::character varying NOT NULL,
    token_validity timestamp with time zone DEFAULT '2000-01-01 00:00:00+00'::timestamp with time zone
);


ALTER TABLE public.mailbox OWNER TO postfix;

--
-- Name: TABLE mailbox; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.mailbox IS 'Postfix Admin - Virtual Mailboxes';


--
-- Name: quota; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.quota (
    username character varying(255) NOT NULL,
    path character varying(100) NOT NULL,
    current bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.quota OWNER TO postfix;

--
-- Name: quota2; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.quota2 (
    username character varying(100) NOT NULL,
    bytes bigint DEFAULT 0 NOT NULL,
    messages integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.quota2 OWNER TO postfix;

--
-- Name: vacation; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.vacation (
    email character varying(255) NOT NULL,
    subject character varying(255) NOT NULL,
    body text DEFAULT ''::text NOT NULL,
    created timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    domain character varying(255),
    modified timestamp with time zone DEFAULT now(),
    activefrom timestamp with time zone DEFAULT '2000-01-01 00:00:00+00'::timestamp with time zone,
    activeuntil timestamp with time zone DEFAULT '2038-01-18 00:00:00+00'::timestamp with time zone,
    interval_time integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.vacation OWNER TO postfix;

--
-- Name: vacation_notification; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.vacation_notification (
    on_vacation character varying(255) NOT NULL,
    notified character varying(255) NOT NULL,
    notified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.vacation_notification OWNER TO postfix;

--
-- Name: config id; Type: DEFAULT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.config ALTER COLUMN id SET DEFAULT nextval('public.config_id_seq'::regclass);


--
-- Name: fetchmail id; Type: DEFAULT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.fetchmail ALTER COLUMN id SET DEFAULT nextval('public.fetchmail_id_seq'::regclass);


--
-- Name: log id; Type: DEFAULT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.log ALTER COLUMN id SET DEFAULT nextval('public.log_id_seq'::regclass);


--
-- Data for Name: admin; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.admin VALUES ('admin@domain.tld', '{SHA512-CRYPT}$6$Wt7uQEnB6HPP6mM0$lOP8IKtEUJKWSwczEC5/g6aYamkwh5rx3ztnRuqcRLJjGTXiLpUnxzUgy2rfNieH9C8x7M6Nr9q19SG6njUj//', '2016-11-28 08:53:31-03', '2016-11-28 08:53:31-03', true, true, '', '', '', '2018-05-15 08:03:01+00');


--
-- Data for Name: alias; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.alias VALUES ('postmaster@domain.tld', 'john.doe@domain.tld', 'domain.tld', '2016-11-28 08:54:26-03', '2016-11-28 08:58:19-03', true);
INSERT INTO public.alias VALUES ('hostmaster@domain.tld', 'john.doe@domain.tld', 'domain.tld', '2016-11-28 08:54:26-03', '2016-11-28 08:58:19-03', true);
INSERT INTO public.alias VALUES ('john.doe@domain.tld', 'john.doe@domain.tld', 'domain.tld', '2016-11-28 08:56:47-03', '2016-11-28 08:56:47-03', true);
INSERT INTO public.alias VALUES ('sarah.connor@domain.tld', 'sarah.connor@domain.tld', 'domain.tld', '2016-11-28 08:57:51-03', '2016-11-28 08:57:51-03', true);


--
-- Data for Name: alias_domain; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- Data for Name: config; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.config VALUES (1, 'version', '1840');


--
-- Data for Name: domain; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.domain VALUES ('ALL', '', 0, 0, 0, 0, '', false, '2016-11-28 08:53:31-03', '2016-11-28 08:53:31-03', true);
INSERT INTO public.domain VALUES ('domain.tld', 'Test domain', 0, 0, 1, 0, 'virtual', false, '2016-11-28 08:54:26-03', '2016-11-28 08:54:26-03', true);


--
-- Data for Name: domain_admins; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.domain_admins VALUES ('admin@domain.tld', 'ALL', '2016-11-28 08:53:31-03', true);


--
-- Data for Name: fetchmail; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: postfix
--

--
-- Data for Name: mailbox; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.mailbox VALUES ('john.doe@domain.tld', '{SHA512-CRYPT}$6$v1LkarodHyGGmfoy$ZszVBzfEZ0CaVnYaBasgvaHJUCNfxwD/E0eNy3iuix56Vl1ZcuDvG9PVr9JRZx5k.7wp1nMb5M1V4aZXo2yfn0', 'John DOE', 'domain.tld/john.doe/', 1024000, '2016-11-28 08:56:47-03', '2016-11-28 08:56:47-03', true, 'domain.tld', 'john.doe', '', '', '', '2018-05-15 08:06:38+00');
INSERT INTO public.mailbox VALUES ('sarah.connor@domain.tld', '{SHA512-CRYPT}$6$ub.zCcyeaM7Mhs6S$rL4Yj2.Zsk8aFoF5l1mAddVrPo.UZ/1UrNwBC7UTBrX47cViSHo5eepEes6jMqC21P3cBm82adqJZvo91Ekme0', 'Sarah CONNOR', 'domain.tld/sarah.connor/', 1024000, '2016-11-28 08:57:51-03', '2016-11-28 08:57:51-03', true, 'domain.tld', 'sarah.connor', '', '', '', '2018-05-15 08:05:44+00');


--
-- Data for Name: quota; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- Data for Name: quota2; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.quota2 VALUES ('john.doe@domain.tld', 0, 0);
INSERT INTO public.quota2 VALUES ('sarah.connor@domain.tld', 0, 0);


--
-- Data for Name: vacation; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- Data for Name: vacation_notification; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- Name: config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postfix
--

SELECT pg_catalog.setval('public.config_id_seq', 1, true);


--
-- Name: fetchmail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postfix
--

SELECT pg_catalog.setval('public.fetchmail_id_seq', 1, true);


--
-- Name: log_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postfix
--

SELECT pg_catalog.setval('public.log_id_seq', 10, true);


--
-- Name: admin admin_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.admin
    ADD CONSTRAINT admin_key PRIMARY KEY (username);


--
-- Name: alias_domain alias_domain_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias_domain
    ADD CONSTRAINT alias_domain_pkey PRIMARY KEY (alias_domain);


--
-- Name: alias alias_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias
    ADD CONSTRAINT alias_key PRIMARY KEY (address);


--
-- Name: config config_name_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_name_key UNIQUE (name);


--
-- Name: config config_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- Name: domain domain_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.domain
    ADD CONSTRAINT domain_key PRIMARY KEY (domain);


--
-- Name: fetchmail fetchmail_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.fetchmail
    ADD CONSTRAINT fetchmail_pkey PRIMARY KEY (id);


--
-- Name: log log_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.log
    ADD CONSTRAINT log_pkey PRIMARY KEY (id);


--
-- Name: mailbox mailbox_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.mailbox
    ADD CONSTRAINT mailbox_key PRIMARY KEY (username);


--
-- Name: quota2 quota2_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.quota2
    ADD CONSTRAINT quota2_pkey PRIMARY KEY (username);


--
-- Name: quota quota_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.quota
    ADD CONSTRAINT quota_pkey PRIMARY KEY (username, path);


--
-- Name: vacation_notification vacation_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation_notification
    ADD CONSTRAINT vacation_notification_pkey PRIMARY KEY (on_vacation, notified);


--
-- Name: vacation vacation_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation
    ADD CONSTRAINT vacation_pkey PRIMARY KEY (email);


--
-- Name: alias_address_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX alias_address_active ON public.alias USING btree (address, active);


--
-- Name: alias_domain_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX alias_domain_active ON public.alias_domain USING btree (alias_domain, active);


--
-- Name: alias_domain_idx; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX alias_domain_idx ON public.alias USING btree (domain);


--
-- Name: domain_domain_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX domain_domain_active ON public.domain USING btree (domain, active);


--
-- Name: log_domain_timestamp_idx; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX log_domain_timestamp_idx ON public.log USING btree (domain, "timestamp");


--
-- Name: mailbox_domain_idx; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX mailbox_domain_idx ON public.mailbox USING btree (domain);


--
-- Name: mailbox_username_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX mailbox_username_active ON public.mailbox USING btree (username, active);


--
-- Name: vacation_email_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX vacation_email_active ON public.vacation USING btree (email, active);


--
-- Name: quota mergequota; Type: TRIGGER; Schema: public; Owner: postfix
--

CREATE TRIGGER mergequota BEFORE INSERT ON public.quota FOR EACH ROW EXECUTE PROCEDURE public.merge_quota();


--
-- Name: quota2 mergequota2; Type: TRIGGER; Schema: public; Owner: postfix
--

CREATE TRIGGER mergequota2 BEFORE INSERT ON public.quota2 FOR EACH ROW EXECUTE PROCEDURE public.merge_quota2();


--
-- Name: alias_domain alias_domain_alias_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias_domain
    ADD CONSTRAINT alias_domain_alias_domain_fkey FOREIGN KEY (alias_domain) REFERENCES public.domain(domain) ON DELETE CASCADE;


--
-- Name: alias alias_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias
    ADD CONSTRAINT alias_domain_fkey FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- Name: alias_domain alias_domain_target_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias_domain
    ADD CONSTRAINT alias_domain_target_domain_fkey FOREIGN KEY (target_domain) REFERENCES public.domain(domain) ON DELETE CASCADE;


--
-- Name: domain_admins domain_admins_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.domain_admins
    ADD CONSTRAINT domain_admins_domain_fkey FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- Name: mailbox mailbox_domain_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.mailbox
    ADD CONSTRAINT mailbox_domain_fkey1 FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- Name: vacation vacation_domain_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation
    ADD CONSTRAINT vacation_domain_fkey1 FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- Name: vacation_notification vacation_notification_on_vacation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation_notification
    ADD CONSTRAINT vacation_notification_on_vacation_fkey FOREIGN KEY (on_vacation) REFERENCES public.vacation(email) ON DELETE CASCADE;


--
-- PostgreSQL database dump complete
--
