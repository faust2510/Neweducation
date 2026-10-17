--
-- PostgreSQL database dump
--

\restrict QVklzVDbw4rgxuWN4ETiyvnk8MBeWmW9UH1z6LisGfzgVxmeCiKRJzjZUccel0O

-- Dumped from database version 16.15 (Debian 16.15-1.pgdg13+2)
-- Dumped by pg_dump version 16.15 (Debian 16.15-1.pgdg13+2)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: edu_eval_score; Type: TABLE; Schema: public; Owner: odoo
--

CREATE TABLE public.edu_eval_score (
    id integer NOT NULL,
    task_id integer NOT NULL,
    template_line_id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    score double precision NOT NULL
);


ALTER TABLE public.edu_eval_score OWNER TO odoo;

--
-- Name: TABLE edu_eval_score; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON TABLE public.edu_eval_score IS '评估打分明细';


--
-- Name: COLUMN edu_eval_score.task_id; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_score.task_id IS '评估任务';


--
-- Name: COLUMN edu_eval_score.template_line_id; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_score.template_line_id IS '评分项';


--
-- Name: COLUMN edu_eval_score.create_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_score.create_uid IS 'Created by';


--
-- Name: COLUMN edu_eval_score.write_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_score.write_uid IS 'Last Updated by';


--
-- Name: COLUMN edu_eval_score.create_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_score.create_date IS 'Created on';


--
-- Name: COLUMN edu_eval_score.write_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_score.write_date IS 'Last Updated on';


--
-- Name: COLUMN edu_eval_score.score; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_score.score IS '得分';


--
-- Name: edu_eval_score_id_seq; Type: SEQUENCE; Schema: public; Owner: odoo
--

CREATE SEQUENCE public.edu_eval_score_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.edu_eval_score_id_seq OWNER TO odoo;

--
-- Name: edu_eval_score_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: odoo
--

ALTER SEQUENCE public.edu_eval_score_id_seq OWNED BY public.edu_eval_score.id;


--
-- Name: edu_eval_task; Type: TABLE; Schema: public; Owner: odoo
--

CREATE TABLE public.edu_eval_task (
    id integer NOT NULL,
    template_id integer NOT NULL,
    student_id integer NOT NULL,
    approved_by integer,
    create_uid integer,
    write_uid integer,
    evaluator_type character varying NOT NULL,
    period character varying NOT NULL,
    state character varying NOT NULL,
    grade character varying,
    type_code character varying,
    approved_date date,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    total_score double precision
);


ALTER TABLE public.edu_eval_task OWNER TO odoo;

--
-- Name: TABLE edu_eval_task; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON TABLE public.edu_eval_task IS '评估任务';


--
-- Name: COLUMN edu_eval_task.template_id; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.template_id IS '评分模板';


--
-- Name: COLUMN edu_eval_task.student_id; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.student_id IS '被评估学生';


--
-- Name: COLUMN edu_eval_task.approved_by; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.approved_by IS '批准人';


--
-- Name: COLUMN edu_eval_task.create_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.create_uid IS 'Created by';


--
-- Name: COLUMN edu_eval_task.write_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.write_uid IS 'Last Updated by';


--
-- Name: COLUMN edu_eval_task.evaluator_type; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.evaluator_type IS '评估维度';


--
-- Name: COLUMN edu_eval_task.period; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.period IS '评估周期';


--
-- Name: COLUMN edu_eval_task.state; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.state IS '状态';


--
-- Name: COLUMN edu_eval_task.grade; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.grade IS '等级';


--
-- Name: COLUMN edu_eval_task.type_code; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.type_code IS '评估类型';


--
-- Name: COLUMN edu_eval_task.approved_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.approved_date IS '批准日期';


--
-- Name: COLUMN edu_eval_task.create_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.create_date IS 'Created on';


--
-- Name: COLUMN edu_eval_task.write_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.write_date IS 'Last Updated on';


--
-- Name: COLUMN edu_eval_task.total_score; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_task.total_score IS '总分';


--
-- Name: edu_eval_task_id_seq; Type: SEQUENCE; Schema: public; Owner: odoo
--

CREATE SEQUENCE public.edu_eval_task_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.edu_eval_task_id_seq OWNER TO odoo;

--
-- Name: edu_eval_task_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: odoo
--

ALTER SEQUENCE public.edu_eval_task_id_seq OWNED BY public.edu_eval_task.id;


--
-- Name: edu_eval_template; Type: TABLE; Schema: public; Owner: odoo
--

CREATE TABLE public.edu_eval_template (
    id integer NOT NULL,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    type_code character varying NOT NULL,
    visible_to_student boolean,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    total double precision NOT NULL,
    pass_line double precision NOT NULL,
    excellent_line double precision NOT NULL
);


ALTER TABLE public.edu_eval_template OWNER TO odoo;

--
-- Name: TABLE edu_eval_template; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON TABLE public.edu_eval_template IS '评估模板';


--
-- Name: COLUMN edu_eval_template.create_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.create_uid IS 'Created by';


--
-- Name: COLUMN edu_eval_template.write_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.write_uid IS 'Last Updated by';


--
-- Name: COLUMN edu_eval_template.name; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.name IS '模板名称';


--
-- Name: COLUMN edu_eval_template.type_code; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.type_code IS '评估类型';


--
-- Name: COLUMN edu_eval_template.visible_to_student; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.visible_to_student IS '结果对学生可见';


--
-- Name: COLUMN edu_eval_template.create_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.create_date IS 'Created on';


--
-- Name: COLUMN edu_eval_template.write_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.write_date IS 'Last Updated on';


--
-- Name: COLUMN edu_eval_template.total; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.total IS '满分';


--
-- Name: COLUMN edu_eval_template.pass_line; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.pass_line IS '及格线';


--
-- Name: COLUMN edu_eval_template.excellent_line; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template.excellent_line IS '优秀线';


--
-- Name: edu_eval_template_id_seq; Type: SEQUENCE; Schema: public; Owner: odoo
--

CREATE SEQUENCE public.edu_eval_template_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.edu_eval_template_id_seq OWNER TO odoo;

--
-- Name: edu_eval_template_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: odoo
--

ALTER SEQUENCE public.edu_eval_template_id_seq OWNED BY public.edu_eval_template.id;


--
-- Name: edu_eval_template_line; Type: TABLE; Schema: public; Owner: odoo
--

CREATE TABLE public.edu_eval_template_line (
    id integer NOT NULL,
    template_id integer NOT NULL,
    sequence integer,
    create_uid integer,
    write_uid integer,
    name character varying NOT NULL,
    create_date timestamp without time zone,
    write_date timestamp without time zone,
    max_score double precision NOT NULL
);


ALTER TABLE public.edu_eval_template_line OWNER TO odoo;

--
-- Name: TABLE edu_eval_template_line; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON TABLE public.edu_eval_template_line IS '评估评分项';


--
-- Name: COLUMN edu_eval_template_line.template_id; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.template_id IS '模板';


--
-- Name: COLUMN edu_eval_template_line.sequence; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.sequence IS '排序';


--
-- Name: COLUMN edu_eval_template_line.create_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.create_uid IS 'Created by';


--
-- Name: COLUMN edu_eval_template_line.write_uid; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.write_uid IS 'Last Updated by';


--
-- Name: COLUMN edu_eval_template_line.name; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.name IS '评分项';


--
-- Name: COLUMN edu_eval_template_line.create_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.create_date IS 'Created on';


--
-- Name: COLUMN edu_eval_template_line.write_date; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.write_date IS 'Last Updated on';


--
-- Name: COLUMN edu_eval_template_line.max_score; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON COLUMN public.edu_eval_template_line.max_score IS '满分';


--
-- Name: edu_eval_template_line_id_seq; Type: SEQUENCE; Schema: public; Owner: odoo
--

CREATE SEQUENCE public.edu_eval_template_line_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.edu_eval_template_line_id_seq OWNER TO odoo;

--
-- Name: edu_eval_template_line_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: odoo
--

ALTER SEQUENCE public.edu_eval_template_line_id_seq OWNED BY public.edu_eval_template_line.id;


--
-- Name: edu_eval_score id; Type: DEFAULT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_score ALTER COLUMN id SET DEFAULT nextval('public.edu_eval_score_id_seq'::regclass);


--
-- Name: edu_eval_task id; Type: DEFAULT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_task ALTER COLUMN id SET DEFAULT nextval('public.edu_eval_task_id_seq'::regclass);


--
-- Name: edu_eval_template id; Type: DEFAULT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template ALTER COLUMN id SET DEFAULT nextval('public.edu_eval_template_id_seq'::regclass);


--
-- Name: edu_eval_template_line id; Type: DEFAULT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template_line ALTER COLUMN id SET DEFAULT nextval('public.edu_eval_template_line_id_seq'::regclass);


--
-- Data for Name: edu_eval_score; Type: TABLE DATA; Schema: public; Owner: odoo
--

COPY public.edu_eval_score (id, task_id, template_line_id, create_uid, write_uid, create_date, write_date, score) FROM stdin;
1	1	1	11	11	2026-08-24 08:59:10.758137	2026-08-24 08:59:11.518421	18
2	1	2	11	11	2026-08-24 08:59:10.758137	2026-08-24 08:59:11.518421	18
3	1	3	11	11	2026-08-24 08:59:10.758137	2026-08-24 08:59:11.518421	18
4	1	4	11	11	2026-08-24 08:59:10.758137	2026-08-24 08:59:11.518421	18
5	1	5	11	11	2026-08-24 08:59:10.758137	2026-08-24 08:59:11.518421	18
\.


--
-- Data for Name: edu_eval_task; Type: TABLE DATA; Schema: public; Owner: odoo
--

COPY public.edu_eval_task (id, template_id, student_id, approved_by, create_uid, write_uid, evaluator_type, period, state, grade, type_code, approved_date, create_date, write_date, total_score) FROM stdin;
1	1	5	1	11	1	teacher	2026秋	done	excellent	student	2026-08-24	2026-08-24 08:59:10.758137	2026-08-24 09:26:37.107463	90
\.


--
-- Data for Name: edu_eval_template; Type: TABLE DATA; Schema: public; Owner: odoo
--

COPY public.edu_eval_template (id, create_uid, write_uid, name, type_code, visible_to_student, create_date, write_date, total, pass_line, excellent_line) FROM stdin;
1	1	1	学生综合评估记分表【演示】	student	t	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	100	60	90
2	1	1	实习同工评估表【演示】	intern	f	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	100	60	80
3	1	1	新生综合测评表【演示】	freshman	t	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	100	60	90
\.


--
-- Data for Name: edu_eval_template_line; Type: TABLE DATA; Schema: public; Owner: odoo
--

COPY public.edu_eval_template_line (id, template_id, sequence, create_uid, write_uid, name, create_date, write_date, max_score) FROM stdin;
1	1	10	1	1	出勤与纪律	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	20
2	1	20	1	1	课堂参与	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	20
3	1	30	1	1	灵修生活	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	20
4	1	40	1	1	学业表现	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	20
5	1	50	1	1	服事态度	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	20
6	2	10	1	1	事奉忠心	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	25
7	2	20	1	1	团队配搭	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	25
8	2	30	1	1	属灵榜样	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	25
9	2	40	1	1	专业能力	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	25
10	3	10	1	1	基础信仰笔试	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	40
11	3	20	1	1	面试表现	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	30
12	3	30	1	1	写作测试	2026-08-24 08:58:30.846187	2026-08-24 08:58:30.846187	30
\.


--
-- Name: edu_eval_score_id_seq; Type: SEQUENCE SET; Schema: public; Owner: odoo
--

SELECT pg_catalog.setval('public.edu_eval_score_id_seq', 5, true);


--
-- Name: edu_eval_task_id_seq; Type: SEQUENCE SET; Schema: public; Owner: odoo
--

SELECT pg_catalog.setval('public.edu_eval_task_id_seq', 1, true);


--
-- Name: edu_eval_template_id_seq; Type: SEQUENCE SET; Schema: public; Owner: odoo
--

SELECT pg_catalog.setval('public.edu_eval_template_id_seq', 3, true);


--
-- Name: edu_eval_template_line_id_seq; Type: SEQUENCE SET; Schema: public; Owner: odoo
--

SELECT pg_catalog.setval('public.edu_eval_template_line_id_seq', 12, true);


--
-- Name: edu_eval_score edu_eval_score_pkey; Type: CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_score
    ADD CONSTRAINT edu_eval_score_pkey PRIMARY KEY (id);


--
-- Name: edu_eval_score edu_eval_score_score_task_line_uniq; Type: CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_score
    ADD CONSTRAINT edu_eval_score_score_task_line_uniq UNIQUE (task_id, template_line_id);


--
-- Name: CONSTRAINT edu_eval_score_score_task_line_uniq ON edu_eval_score; Type: COMMENT; Schema: public; Owner: odoo
--

COMMENT ON CONSTRAINT edu_eval_score_score_task_line_uniq ON public.edu_eval_score IS 'UNIQUE (task_id, template_line_id)';


--
-- Name: edu_eval_task edu_eval_task_pkey; Type: CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_task
    ADD CONSTRAINT edu_eval_task_pkey PRIMARY KEY (id);


--
-- Name: edu_eval_template_line edu_eval_template_line_pkey; Type: CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template_line
    ADD CONSTRAINT edu_eval_template_line_pkey PRIMARY KEY (id);


--
-- Name: edu_eval_template edu_eval_template_pkey; Type: CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template
    ADD CONSTRAINT edu_eval_template_pkey PRIMARY KEY (id);


--
-- Name: edu_eval_score__task_id_index; Type: INDEX; Schema: public; Owner: odoo
--

CREATE INDEX edu_eval_score__task_id_index ON public.edu_eval_score USING btree (task_id);


--
-- Name: edu_eval_task__grade_index; Type: INDEX; Schema: public; Owner: odoo
--

CREATE INDEX edu_eval_task__grade_index ON public.edu_eval_task USING btree (grade);


--
-- Name: edu_eval_task__state_index; Type: INDEX; Schema: public; Owner: odoo
--

CREATE INDEX edu_eval_task__state_index ON public.edu_eval_task USING btree (state);


--
-- Name: edu_eval_task__student_id_index; Type: INDEX; Schema: public; Owner: odoo
--

CREATE INDEX edu_eval_task__student_id_index ON public.edu_eval_task USING btree (student_id);


--
-- Name: edu_eval_task__template_id_index; Type: INDEX; Schema: public; Owner: odoo
--

CREATE INDEX edu_eval_task__template_id_index ON public.edu_eval_task USING btree (template_id);


--
-- Name: edu_eval_template__type_code_index; Type: INDEX; Schema: public; Owner: odoo
--

CREATE INDEX edu_eval_template__type_code_index ON public.edu_eval_template USING btree (type_code);


--
-- Name: edu_eval_template_line__template_id_index; Type: INDEX; Schema: public; Owner: odoo
--

CREATE INDEX edu_eval_template_line__template_id_index ON public.edu_eval_template_line USING btree (template_id);


--
-- Name: edu_eval_score edu_eval_score_create_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_score
    ADD CONSTRAINT edu_eval_score_create_uid_fkey FOREIGN KEY (create_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_score edu_eval_score_task_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_score
    ADD CONSTRAINT edu_eval_score_task_id_fkey FOREIGN KEY (task_id) REFERENCES public.edu_eval_task(id) ON DELETE CASCADE;


--
-- Name: edu_eval_score edu_eval_score_template_line_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_score
    ADD CONSTRAINT edu_eval_score_template_line_id_fkey FOREIGN KEY (template_line_id) REFERENCES public.edu_eval_template_line(id) ON DELETE CASCADE;


--
-- Name: edu_eval_score edu_eval_score_write_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_score
    ADD CONSTRAINT edu_eval_score_write_uid_fkey FOREIGN KEY (write_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_task edu_eval_task_approved_by_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_task
    ADD CONSTRAINT edu_eval_task_approved_by_fkey FOREIGN KEY (approved_by) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_task edu_eval_task_create_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_task
    ADD CONSTRAINT edu_eval_task_create_uid_fkey FOREIGN KEY (create_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_task edu_eval_task_student_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_task
    ADD CONSTRAINT edu_eval_task_student_id_fkey FOREIGN KEY (student_id) REFERENCES public.op_student(id) ON DELETE CASCADE;


--
-- Name: edu_eval_task edu_eval_task_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_task
    ADD CONSTRAINT edu_eval_task_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.edu_eval_template(id) ON DELETE RESTRICT;


--
-- Name: edu_eval_task edu_eval_task_write_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_task
    ADD CONSTRAINT edu_eval_task_write_uid_fkey FOREIGN KEY (write_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_template edu_eval_template_create_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template
    ADD CONSTRAINT edu_eval_template_create_uid_fkey FOREIGN KEY (create_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_template_line edu_eval_template_line_create_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template_line
    ADD CONSTRAINT edu_eval_template_line_create_uid_fkey FOREIGN KEY (create_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_template_line edu_eval_template_line_template_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template_line
    ADD CONSTRAINT edu_eval_template_line_template_id_fkey FOREIGN KEY (template_id) REFERENCES public.edu_eval_template(id) ON DELETE CASCADE;


--
-- Name: edu_eval_template_line edu_eval_template_line_write_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template_line
    ADD CONSTRAINT edu_eval_template_line_write_uid_fkey FOREIGN KEY (write_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- Name: edu_eval_template edu_eval_template_write_uid_fkey; Type: FK CONSTRAINT; Schema: public; Owner: odoo
--

ALTER TABLE ONLY public.edu_eval_template
    ADD CONSTRAINT edu_eval_template_write_uid_fkey FOREIGN KEY (write_uid) REFERENCES public.res_users(id) ON DELETE SET NULL;


--
-- PostgreSQL database dump complete
--

\unrestrict QVklzVDbw4rgxuWN4ETiyvnk8MBeWmW9UH1z6LisGfzgVxmeCiKRJzjZUccel0O

