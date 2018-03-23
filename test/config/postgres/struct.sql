--
-- PostgreSQL database dump
--

-- Dumped from database version 10.3
-- Dumped by pg_dump version 10.3

-- Started on 2018-03-05 08:39:19

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
-- TOC entry 212 (class 1255 OID 16609)
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
-- TOC entry 221 (class 1255 OID 16610)
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
-- TOC entry 196 (class 1259 OID 16611)
-- Name: admin; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.admin (
    username character varying(255) NOT NULL,
    password character varying(255) DEFAULT ''::character varying NOT NULL,
    created timestamp with time zone DEFAULT now(),
    modified timestamp with time zone DEFAULT now(),
    active boolean DEFAULT true NOT NULL,
    superadmin boolean DEFAULT false NOT NULL
);


ALTER TABLE public.admin OWNER TO postfix;

--
-- TOC entry 2983 (class 0 OID 0)
-- Dependencies: 196
-- Name: TABLE admin; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.admin IS 'Postfix Admin - Virtual Admins';


--
-- TOC entry 197 (class 1259 OID 16622)
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
-- TOC entry 2984 (class 0 OID 0)
-- Dependencies: 197
-- Name: TABLE alias; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.alias IS 'Postfix Admin - Virtual Aliases';


--
-- TOC entry 198 (class 1259 OID 16631)
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
-- TOC entry 2985 (class 0 OID 0)
-- Dependencies: 198
-- Name: TABLE alias_domain; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.alias_domain IS 'Postfix Admin - Domain Aliases';


--
-- TOC entry 199 (class 1259 OID 16640)
-- Name: config; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.config (
    id integer NOT NULL,
    name character varying(20) NOT NULL,
    value character varying(20) NOT NULL
);


ALTER TABLE public.config OWNER TO postfix;

--
-- TOC entry 200 (class 1259 OID 16643)
-- Name: config_id_seq; Type: SEQUENCE; Schema: public; Owner: postfix
--

CREATE SEQUENCE public.config_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.config_id_seq OWNER TO postfix;

--
-- TOC entry 2986 (class 0 OID 0)
-- Dependencies: 200
-- Name: config_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postfix
--

ALTER SEQUENCE public.config_id_seq OWNED BY public.config.id;


--
-- TOC entry 201 (class 1259 OID 16645)
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
-- TOC entry 2987 (class 0 OID 0)
-- Dependencies: 201
-- Name: TABLE domain; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.domain IS 'Postfix Admin - Virtual Domains';


--
-- TOC entry 202 (class 1259 OID 16661)
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
-- TOC entry 2988 (class 0 OID 0)
-- Dependencies: 202
-- Name: TABLE domain_admins; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.domain_admins IS 'Postfix Admin - Domain Admins';


--
-- TOC entry 203 (class 1259 OID 16669)
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
    created timestamp with time zone DEFAULT '1999-12-31 22:00:00-02'::timestamp with time zone,
    modified timestamp with time zone DEFAULT now(),
    CONSTRAINT fetchmail_protocol_check CHECK (((protocol)::text = ANY (ARRAY[('POP3'::character varying)::text, ('IMAP'::character varying)::text, ('POP2'::character varying)::text, ('ETRN'::character varying)::text, ('AUTO'::character varying)::text]))),
    CONSTRAINT fetchmail_src_auth_check CHECK (((src_auth)::text = ANY (ARRAY[('password'::character varying)::text, ('kerberos_v5'::character varying)::text, ('kerberos'::character varying)::text, ('kerberos_v4'::character varying)::text, ('gssapi'::character varying)::text, ('cram-md5'::character varying)::text, ('otp'::character varying)::text, ('ntlm'::character varying)::text, ('msn'::character varying)::text, ('ssh'::character varying)::text, ('any'::character varying)::text])))
);


ALTER TABLE public.fetchmail OWNER TO postfix;

--
-- TOC entry 204 (class 1259 OID 16695)
-- Name: fetchmail_id_seq; Type: SEQUENCE; Schema: public; Owner: postfix
--

CREATE SEQUENCE public.fetchmail_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.fetchmail_id_seq OWNER TO postfix;

--
-- TOC entry 2989 (class 0 OID 0)
-- Dependencies: 204
-- Name: fetchmail_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postfix
--

ALTER SEQUENCE public.fetchmail_id_seq OWNED BY public.fetchmail.id;


--
-- TOC entry 205 (class 1259 OID 16697)
-- Name: log; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.log (
    "timestamp" timestamp with time zone DEFAULT now(),
    username character varying(255) DEFAULT ''::character varying NOT NULL,
    domain character varying(255) DEFAULT ''::character varying NOT NULL,
    action character varying(255) DEFAULT ''::character varying NOT NULL,
    data text DEFAULT ''::text NOT NULL
);


ALTER TABLE public.log OWNER TO postfix;

--
-- TOC entry 2990 (class 0 OID 0)
-- Dependencies: 205
-- Name: TABLE log; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.log IS 'Postfix Admin - Log';


--
-- TOC entry 206 (class 1259 OID 16708)
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
    local_part character varying(255) NOT NULL
);


ALTER TABLE public.mailbox OWNER TO postfix;

--
-- TOC entry 2991 (class 0 OID 0)
-- Dependencies: 206
-- Name: TABLE mailbox; Type: COMMENT; Schema: public; Owner: postfix
--

COMMENT ON TABLE public.mailbox IS 'Postfix Admin - Virtual Mailboxes';


--
-- TOC entry 207 (class 1259 OID 16721)
-- Name: quota; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.quota (
    username character varying(255) NOT NULL,
    path character varying(100) NOT NULL,
    current bigint DEFAULT 0 NOT NULL
);


ALTER TABLE public.quota OWNER TO postfix;

--
-- TOC entry 208 (class 1259 OID 16725)
-- Name: quota2; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.quota2 (
    username character varying(100) NOT NULL,
    bytes bigint DEFAULT 0 NOT NULL,
    messages integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.quota2 OWNER TO postfix;

--
-- TOC entry 209 (class 1259 OID 16730)
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
    activefrom timestamp with time zone DEFAULT '1999-12-31 22:00:00-02'::timestamp with time zone,
    activeuntil timestamp with time zone DEFAULT '1999-12-31 22:00:00-02'::timestamp with time zone,
    interval_time integer DEFAULT 0 NOT NULL
);


ALTER TABLE public.vacation OWNER TO postfix;

--
-- TOC entry 210 (class 1259 OID 16743)
-- Name: vacation_notification; Type: TABLE; Schema: public; Owner: postfix
--

CREATE TABLE public.vacation_notification (
    on_vacation character varying(255) NOT NULL,
    notified character varying(255) NOT NULL,
    notified_at timestamp with time zone DEFAULT now() NOT NULL
);


ALTER TABLE public.vacation_notification OWNER TO postfix;

--
-- TOC entry 2743 (class 2604 OID 16750)
-- Name: config id; Type: DEFAULT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.config ALTER COLUMN id SET DEFAULT nextval('public.config_id_seq'::regclass);


--
-- TOC entry 2774 (class 2604 OID 16751)
-- Name: fetchmail id; Type: DEFAULT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.fetchmail ALTER COLUMN id SET DEFAULT nextval('public.fetchmail_id_seq'::regclass);


--
-- TOC entry 2962 (class 0 OID 16611)
-- Dependencies: 196
-- Data for Name: admin; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.admin VALUES ('admin@domain.tld', '{SHA512-CRYPT}$6$Wt7uQEnB6HPP6mM0$lOP8IKtEUJKWSwczEC5/g6aYamkwh5rx3ztnRuqcRLJjGTXiLpUnxzUgy2rfNieH9C8x7M6Nr9q19SG6njUj//', '2016-11-28 08:53:31-03', '2016-11-28 08:53:31-03', true, true);


--
-- TOC entry 2963 (class 0 OID 16622)
-- Dependencies: 197
-- Data for Name: alias; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.alias VALUES ('postmaster@domain.tld', 'john.doe@domain.tld', 'domain.tld', '2016-11-28 08:54:26-03', '2016-11-28 08:58:19-03', true);
INSERT INTO public.alias VALUES ('hostmaster@domain.tld', 'john.doe@domain.tld', 'domain.tld', '2016-11-28 08:54:26-03', '2016-11-28 08:58:19-03', true);
INSERT INTO public.alias VALUES ('john.doe@domain.tld', 'john.doe@domain.tld', 'domain.tld', '2016-11-28 08:56:47-03', '2016-11-28 08:56:47-03', true);
INSERT INTO public.alias VALUES ('sarah.connor@domain.tld', 'sarah.connor@domain.tld', 'domain.tld', '2016-11-28 08:57:51-03', '2016-11-28 08:57:51-03', true);


--
-- TOC entry 2964 (class 0 OID 16631)
-- Dependencies: 198
-- Data for Name: alias_domain; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- TOC entry 2965 (class 0 OID 16640)
-- Dependencies: 199
-- Data for Name: config; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.config VALUES (1, 'version', '1836');


--
-- TOC entry 2967 (class 0 OID 16645)
-- Dependencies: 201
-- Data for Name: domain; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.domain VALUES ('ALL', '', 0, 0, 0, 0, '', false, '2016-11-28 08:53:31-03', '2016-11-28 08:53:31-03', true);
INSERT INTO public.domain VALUES ('domain.tld', 'Test domain', 0, 0, 1, 0, 'virtual', false, '2016-11-28 08:54:26-03', '2016-11-28 08:54:26-03', true);


--
-- TOC entry 2968 (class 0 OID 16661)
-- Dependencies: 202
-- Data for Name: domain_admins; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.domain_admins VALUES ('admin@domain.tld', 'ALL', '2016-11-28 08:53:31-03', true);


--
-- TOC entry 2969 (class 0 OID 16669)
-- Dependencies: 203
-- Data for Name: fetchmail; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.fetchmail VALUES (1, 'sarah.connor@domain.tld', '127.0.0.1', 'password', 'john.doe@domain.tld', 'dGVzdHBhc3N3ZDEy', '', 10, true, true, 'IMAP', '', '', '', '2016-12-05 11:59:01-03', true, false, '', '', 'domain.tld', true, '2016-12-05 11:58:53-03', '2016-12-05 11:58:53-03');


--
-- TOC entry 2971 (class 0 OID 16697)
-- Dependencies: 205
-- Data for Name: log; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- TOC entry 2972 (class 0 OID 16708)
-- Dependencies: 206
-- Data for Name: mailbox; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.mailbox VALUES ('john.doe@domain.tld', '{SHA512-CRYPT}$6$v1LkarodHyGGmfoy$ZszVBzfEZ0CaVnYaBasgvaHJUCNfxwD/E0eNy3iuix56Vl1ZcuDvG9PVr9JRZx5k.7wp1nMb5M1V4aZXo2yfn0', 'John DOE', 'domain.tld/john.doe/', 1024000, '2016-11-28 08:56:47-03', '2016-11-28 08:56:47-03', true, 'domain.tld', 'john.doe');
INSERT INTO public.mailbox VALUES ('sarah.connor@domain.tld', '{SHA512-CRYPT}$6$ub.zCcyeaM7Mhs6S$rL4Yj2.Zsk8aFoF5l1mAddVrPo.UZ/1UrNwBC7UTBrX47cViSHo5eepEes6jMqC21P3cBm82adqJZvo91Ekme0', 'Sarah CONNOR', 'domain.tld/sarah.connor/', 1024000, '2016-11-28 08:57:51-03', '2016-11-28 08:57:51-03', true, 'domain.tld', 'sarah.connor');


--
-- TOC entry 2973 (class 0 OID 16721)
-- Dependencies: 207
-- Data for Name: quota; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- TOC entry 2974 (class 0 OID 16725)
-- Dependencies: 208
-- Data for Name: quota2; Type: TABLE DATA; Schema: public; Owner: postfix
--

INSERT INTO public.quota2 VALUES ('john.doe@domain.tld', 0, 0);
INSERT INTO public.quota2 VALUES ('sarah.connor@domain.tld', 0, 0);


--
-- TOC entry 2975 (class 0 OID 16730)
-- Dependencies: 209
-- Data for Name: vacation; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- TOC entry 2976 (class 0 OID 16743)
-- Dependencies: 210
-- Data for Name: vacation_notification; Type: TABLE DATA; Schema: public; Owner: postfix
--



--
-- TOC entry 2992 (class 0 OID 0)
-- Dependencies: 200
-- Name: config_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postfix
--

SELECT pg_catalog.setval('public.config_id_seq', 1, true);


--
-- TOC entry 2993 (class 0 OID 0)
-- Dependencies: 204
-- Name: fetchmail_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postfix
--

SELECT pg_catalog.setval('public.fetchmail_id_seq', 1, true);


--
-- TOC entry 2801 (class 2606 OID 16753)
-- Name: admin admin_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.admin
    ADD CONSTRAINT admin_key PRIMARY KEY (username);


--
-- TOC entry 2808 (class 2606 OID 16755)
-- Name: alias_domain alias_domain_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias_domain
    ADD CONSTRAINT alias_domain_pkey PRIMARY KEY (alias_domain);


--
-- TOC entry 2805 (class 2606 OID 16757)
-- Name: alias alias_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias
    ADD CONSTRAINT alias_key PRIMARY KEY (address);


--
-- TOC entry 2810 (class 2606 OID 16759)
-- Name: config config_name_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_name_key UNIQUE (name);


--
-- TOC entry 2812 (class 2606 OID 16761)
-- Name: config config_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.config
    ADD CONSTRAINT config_pkey PRIMARY KEY (id);


--
-- TOC entry 2815 (class 2606 OID 16763)
-- Name: domain domain_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.domain
    ADD CONSTRAINT domain_key PRIMARY KEY (domain);


--
-- TOC entry 2817 (class 2606 OID 16765)
-- Name: fetchmail fetchmail_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.fetchmail
    ADD CONSTRAINT fetchmail_pkey PRIMARY KEY (id);


--
-- TOC entry 2821 (class 2606 OID 16767)
-- Name: mailbox mailbox_key; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.mailbox
    ADD CONSTRAINT mailbox_key PRIMARY KEY (username);


--
-- TOC entry 2826 (class 2606 OID 16769)
-- Name: quota2 quota2_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.quota2
    ADD CONSTRAINT quota2_pkey PRIMARY KEY (username);


--
-- TOC entry 2824 (class 2606 OID 16771)
-- Name: quota quota_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.quota
    ADD CONSTRAINT quota_pkey PRIMARY KEY (username, path);


--
-- TOC entry 2831 (class 2606 OID 16773)
-- Name: vacation_notification vacation_notification_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation_notification
    ADD CONSTRAINT vacation_notification_pkey PRIMARY KEY (on_vacation, notified);


--
-- TOC entry 2829 (class 2606 OID 16775)
-- Name: vacation vacation_pkey; Type: CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation
    ADD CONSTRAINT vacation_pkey PRIMARY KEY (email);


--
-- TOC entry 2802 (class 1259 OID 16776)
-- Name: alias_address_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX alias_address_active ON public.alias USING btree (address, active);


--
-- TOC entry 2806 (class 1259 OID 16777)
-- Name: alias_domain_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX alias_domain_active ON public.alias_domain USING btree (alias_domain, active);


--
-- TOC entry 2803 (class 1259 OID 16778)
-- Name: alias_domain_idx; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX alias_domain_idx ON public.alias USING btree (domain);


--
-- TOC entry 2813 (class 1259 OID 16779)
-- Name: domain_domain_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX domain_domain_active ON public.domain USING btree (domain, active);


--
-- TOC entry 2818 (class 1259 OID 16780)
-- Name: log_domain_timestamp_idx; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX log_domain_timestamp_idx ON public.log USING btree (domain, "timestamp");


--
-- TOC entry 2819 (class 1259 OID 16781)
-- Name: mailbox_domain_idx; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX mailbox_domain_idx ON public.mailbox USING btree (domain);


--
-- TOC entry 2822 (class 1259 OID 16782)
-- Name: mailbox_username_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX mailbox_username_active ON public.mailbox USING btree (username, active);


--
-- TOC entry 2827 (class 1259 OID 16783)
-- Name: vacation_email_active; Type: INDEX; Schema: public; Owner: postfix
--

CREATE INDEX vacation_email_active ON public.vacation USING btree (email, active);


--
-- TOC entry 2839 (class 2620 OID 16784)
-- Name: quota mergequota; Type: TRIGGER; Schema: public; Owner: postfix
--

CREATE TRIGGER mergequota BEFORE INSERT ON public.quota FOR EACH ROW EXECUTE PROCEDURE public.merge_quota();


--
-- TOC entry 2840 (class 2620 OID 16785)
-- Name: quota2 mergequota2; Type: TRIGGER; Schema: public; Owner: postfix
--

CREATE TRIGGER mergequota2 BEFORE INSERT ON public.quota2 FOR EACH ROW EXECUTE PROCEDURE public.merge_quota2();


--
-- TOC entry 2833 (class 2606 OID 16786)
-- Name: alias_domain alias_domain_alias_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias_domain
    ADD CONSTRAINT alias_domain_alias_domain_fkey FOREIGN KEY (alias_domain) REFERENCES public.domain(domain) ON DELETE CASCADE;


--
-- TOC entry 2832 (class 2606 OID 16791)
-- Name: alias alias_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias
    ADD CONSTRAINT alias_domain_fkey FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- TOC entry 2834 (class 2606 OID 16796)
-- Name: alias_domain alias_domain_target_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.alias_domain
    ADD CONSTRAINT alias_domain_target_domain_fkey FOREIGN KEY (target_domain) REFERENCES public.domain(domain) ON DELETE CASCADE;


--
-- TOC entry 2835 (class 2606 OID 16801)
-- Name: domain_admins domain_admins_domain_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.domain_admins
    ADD CONSTRAINT domain_admins_domain_fkey FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- TOC entry 2836 (class 2606 OID 16806)
-- Name: mailbox mailbox_domain_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.mailbox
    ADD CONSTRAINT mailbox_domain_fkey1 FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- TOC entry 2837 (class 2606 OID 16811)
-- Name: vacation vacation_domain_fkey1; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation
    ADD CONSTRAINT vacation_domain_fkey1 FOREIGN KEY (domain) REFERENCES public.domain(domain);


--
-- TOC entry 2838 (class 2606 OID 16816)
-- Name: vacation_notification vacation_notification_on_vacation_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postfix
--

ALTER TABLE ONLY public.vacation_notification
    ADD CONSTRAINT vacation_notification_on_vacation_fkey FOREIGN KEY (on_vacation) REFERENCES public.vacation(email) ON DELETE CASCADE;


-- Completed on 2018-03-05 08:39:19

--
-- PostgreSQL database dump complete
--

