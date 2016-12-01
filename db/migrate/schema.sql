--
-- PostgreSQL database dump
--

SET statement_timeout = 0;
SET lock_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SET check_function_bodies = false;
SET client_min_messages = warning;

--
-- Name: denormalization; Type: SCHEMA; Schema: -; Owner: -
--

CREATE SCHEMA denormalization;


SET search_path = denormalization, pg_catalog;

SET default_with_oids = false;

--
-- Name: events_log; Type: TABLE; Schema: denormalization; Owner: -
--

CREATE TABLE events_log (
    id integer NOT NULL,
    processed_at timestamp without time zone NOT NULL,
    consumer character varying(256) NOT NULL,
    event_id character varying(255) NOT NULL,
    event_type character varying(1) NOT NULL,
    event_time character varying(128) NOT NULL,
    event_txid character varying(128) NOT NULL,
    event_ev_data text NOT NULL,
    event_extra1 text NOT NULL,
    event_data text NOT NULL,
    event_prev_data text NOT NULL,
    event_data_changed boolean NOT NULL,
    message character varying(512),
    payload character varying(512),
    suspected boolean NOT NULL
);


--
-- Name: TABLE events_log; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON TABLE events_log IS 'Отладочный журнал событий';


--
-- Name: events_log_id_seq; Type: SEQUENCE; Schema: denormalization; Owner: -
--

CREATE SEQUENCE events_log_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: events_log_id_seq; Type: SEQUENCE OWNED BY; Schema: denormalization; Owner: -
--

ALTER SEQUENCE events_log_id_seq OWNED BY events_log.id;


--
-- Name: fields; Type: TABLE; Schema: denormalization; Owner: -
--

CREATE TABLE fields (
    id integer NOT NULL,
    title character varying(128) NOT NULL,
    "group" character varying(128) NOT NULL,
    field_class character varying(128) NOT NULL,
    active boolean DEFAULT false NOT NULL,
    need_terminate boolean DEFAULT false NOT NULL,
    state character varying(128) DEFAULT 'need_initialize'::character varying NOT NULL,
    progress character varying(128),
    snapshot_id character varying(4000),
    last_error character varying(4000),
    worker_id integer,
    oid integer NOT NULL,
    params character varying(4000),
    storage character varying(4000),
    pid integer
);


--
-- Name: TABLE fields; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON TABLE fields IS 'Поля';


--
-- Name: COLUMN fields.title; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.title IS 'Название поля';


--
-- Name: COLUMN fields."group"; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields."group" IS 'Группа поля';


--
-- Name: COLUMN fields.field_class; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.field_class IS 'Класс поля';


--
-- Name: COLUMN fields.active; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.active IS 'Активно/не активно';


--
-- Name: COLUMN fields.need_terminate; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.need_terminate IS 'Флаг необходимости прекращения текущей операции';


--
-- Name: COLUMN fields.state; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.state IS 'Состояние поля';


--
-- Name: COLUMN fields.progress; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.progress IS 'Прогресс иницилизации';


--
-- Name: COLUMN fields.snapshot_id; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.snapshot_id IS 'ИД снапшота БД, в котором проводилась иницилизация';


--
-- Name: COLUMN fields.last_error; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.last_error IS 'Последняя ошибка';


--
-- Name: COLUMN fields.worker_id; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.worker_id IS 'Ссылка на воркера (worker.id)';


--
-- Name: COLUMN fields.oid; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN fields.oid IS 'Порядковый номер поля';


--
-- Name: fields_id_seq; Type: SEQUENCE; Schema: denormalization; Owner: -
--

CREATE SEQUENCE fields_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: fields_id_seq; Type: SEQUENCE OWNED BY; Schema: denormalization; Owner: -
--

ALTER SEQUENCE fields_id_seq OWNED BY fields.id;


--
-- Name: processors; Type: TABLE; Schema: denormalization; Owner: -
--

CREATE TABLE processors (
    id integer NOT NULL,
    queue_id integer NOT NULL,
    field_id integer NOT NULL,
    processor_class character varying(128) NOT NULL,
    oid integer NOT NULL,
    params character varying(2000),
    consumer_name character varying(128) NOT NULL
);


--
-- Name: TABLE processors; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON TABLE processors IS 'Процессоры - обработчики';


--
-- Name: COLUMN processors.queue_id; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN processors.queue_id IS 'Ссылка на очередь (queues.id)';


--
-- Name: COLUMN processors.field_id; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN processors.field_id IS 'Ссылка на поле (fields.id)';


--
-- Name: COLUMN processors.processor_class; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN processors.processor_class IS 'Класс обработчика';


--
-- Name: COLUMN processors.oid; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN processors.oid IS 'Порядковый номер обработчика в рамках поля';


--
-- Name: COLUMN processors.params; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN processors.params IS 'Параметры обработчика';


--
-- Name: processors_id_seq; Type: SEQUENCE; Schema: denormalization; Owner: -
--

CREATE SEQUENCE processors_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: processors_id_seq; Type: SEQUENCE OWNED BY; Schema: denormalization; Owner: -
--

ALTER SEQUENCE processors_id_seq OWNED BY processors.id;


--
-- Name: queues; Type: TABLE; Schema: denormalization; Owner: -
--

CREATE TABLE queues (
    id integer NOT NULL,
    name character varying(128) NOT NULL,
    table_name character varying(256),
    trigger_code character varying(2000),
    db_link_class character varying(256)
);


--
-- Name: TABLE queues; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON TABLE queues IS 'Очереди';


--
-- Name: COLUMN queues.name; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN queues.name IS 'Название';


--
-- Name: COLUMN queues.table_name; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN queues.table_name IS 'Имя таблицы';


--
-- Name: COLUMN queues.trigger_code; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN queues.trigger_code IS 'Код триггера';


--
-- Name: COLUMN queues.db_link_class; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN queues.db_link_class IS 'Имя класс - модели ActiveRecord, обеспечивающего соединение с БД, в рамках которого обрабатывается очередь (опционально)';


--
-- Name: queues_id_seq; Type: SEQUENCE; Schema: denormalization; Owner: -
--

CREATE SEQUENCE queues_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: queues_id_seq; Type: SEQUENCE OWNED BY; Schema: denormalization; Owner: -
--

ALTER SEQUENCE queues_id_seq OWNED BY queues.id;


--
-- Name: supervisor_status; Type: TABLE; Schema: denormalization; Owner: -
--

CREATE TABLE supervisor_status (
    id integer NOT NULL,
    active boolean DEFAULT false NOT NULL,
    state character varying(128) DEFAULT 'stopped'::character varying NOT NULL,
    need_terminate boolean DEFAULT false NOT NULL,
    last_error character varying(4000),
    pid integer
);


--
-- Name: COLUMN supervisor_status.active; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN supervisor_status.active IS 'Активно/не активно';


--
-- Name: COLUMN supervisor_status.state; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN supervisor_status.state IS 'Состояние поля';


--
-- Name: COLUMN supervisor_status.need_terminate; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN supervisor_status.need_terminate IS 'Флаг необходимости прекращения текущей операции';


--
-- Name: supervisor_status_id_seq; Type: SEQUENCE; Schema: denormalization; Owner: -
--

CREATE SEQUENCE supervisor_status_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: supervisor_status_id_seq; Type: SEQUENCE OWNED BY; Schema: denormalization; Owner: -
--

ALTER SEQUENCE supervisor_status_id_seq OWNED BY supervisor_status.id;


--
-- Name: workers; Type: TABLE; Schema: denormalization; Owner: -
--

CREATE TABLE workers (
    id integer NOT NULL,
    active boolean DEFAULT false NOT NULL,
    state character varying(128) DEFAULT 'stopped'::character varying NOT NULL,
    need_terminate boolean DEFAULT false NOT NULL,
    last_error character varying(4000),
    name character varying(25) NOT NULL,
    pid integer
);


--
-- Name: TABLE workers; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON TABLE workers IS 'Воркеры';


--
-- Name: COLUMN workers.active; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN workers.active IS 'Активно/не активно';


--
-- Name: COLUMN workers.state; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN workers.state IS 'Состояние поля';


--
-- Name: COLUMN workers.need_terminate; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN workers.need_terminate IS 'Флаг необходимости прекращения текущей операции';


--
-- Name: COLUMN workers.last_error; Type: COMMENT; Schema: denormalization; Owner: -
--

COMMENT ON COLUMN workers.last_error IS 'Последняя ошибка';


--
-- Name: workers_id_seq; Type: SEQUENCE; Schema: denormalization; Owner: -
--

CREATE SEQUENCE workers_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


--
-- Name: workers_id_seq; Type: SEQUENCE OWNED BY; Schema: denormalization; Owner: -
--

ALTER SEQUENCE workers_id_seq OWNED BY workers.id;


--
-- Name: id; Type: DEFAULT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY events_log ALTER COLUMN id SET DEFAULT nextval('events_log_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY fields ALTER COLUMN id SET DEFAULT nextval('fields_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY processors ALTER COLUMN id SET DEFAULT nextval('processors_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY queues ALTER COLUMN id SET DEFAULT nextval('queues_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY supervisor_status ALTER COLUMN id SET DEFAULT nextval('supervisor_status_id_seq'::regclass);


--
-- Name: id; Type: DEFAULT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY workers ALTER COLUMN id SET DEFAULT nextval('workers_id_seq'::regclass);


--
-- Name: events_log_pkey; Type: CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY events_log
    ADD CONSTRAINT events_log_pkey PRIMARY KEY (id);


--
-- Name: fields_pkey; Type: CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY fields
    ADD CONSTRAINT fields_pkey PRIMARY KEY (id);


--
-- Name: processors_pkey; Type: CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY processors
    ADD CONSTRAINT processors_pkey PRIMARY KEY (id);


--
-- Name: queues_pkey; Type: CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY queues
    ADD CONSTRAINT queues_pkey PRIMARY KEY (id);


--
-- Name: supervisor_status_pkey; Type: CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY supervisor_status
    ADD CONSTRAINT supervisor_status_pkey PRIMARY KEY (id);


--
-- Name: workers_pkey; Type: CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY workers
    ADD CONSTRAINT workers_pkey PRIMARY KEY (id);


--
-- Name: uq_fields_class; Type: INDEX; Schema: denormalization; Owner: -
--

CREATE UNIQUE INDEX uq_fields_class ON fields USING btree (field_class);


--
-- Name: uq_fields_consumer_name; Type: INDEX; Schema: denormalization; Owner: -
--

CREATE UNIQUE INDEX uq_fields_consumer_name ON processors USING btree (consumer_name);


--
-- Name: uq_fields_title; Type: INDEX; Schema: denormalization; Owner: -
--

CREATE UNIQUE INDEX uq_fields_title ON fields USING btree (title);


--
-- Name: uq_processors; Type: INDEX; Schema: denormalization; Owner: -
--

CREATE UNIQUE INDEX uq_processors ON processors USING btree (processor_class, params);


--
-- Name: uq_queues; Type: INDEX; Schema: denormalization; Owner: -
--

CREATE UNIQUE INDEX uq_queues ON queues USING btree (name, table_name);


--
-- Name: uq_workers_name; Type: INDEX; Schema: denormalization; Owner: -
--

CREATE UNIQUE INDEX uq_workers_name ON workers USING btree (name);


--
-- Name: fk_processors_field; Type: FK CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY processors
    ADD CONSTRAINT fk_processors_field FOREIGN KEY (field_id) REFERENCES fields(id) DEFERRABLE;


--
-- Name: fk_processors_queue; Type: FK CONSTRAINT; Schema: denormalization; Owner: -
--

ALTER TABLE ONLY processors
    ADD CONSTRAINT fk_processors_queue FOREIGN KEY (queue_id) REFERENCES queues(id) DEFERRABLE;


--
-- PostgreSQL database dump complete
--
