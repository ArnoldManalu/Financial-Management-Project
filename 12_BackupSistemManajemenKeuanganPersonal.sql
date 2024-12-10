--
-- PostgreSQL database dump
--

-- Dumped from database version 16.4
-- Dumped by pg_dump version 16.4

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

--
-- Name: add_balance(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.add_balance() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Tambah saldo pengguna
    UPDATE users
    SET balance = balance + NEW.amount
    WHERE user_id = NEW.user_id;

    -- Lanjutkan penyisipan data ke tabel income
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.add_balance() OWNER TO postgres;

--
-- Name: balance_warning(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.balance_warning() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF (SELECT balance FROM users WHERE user_id = NEW.user_id) < 50000 THEN
    	RAISE NOTICE 'Peringatan: Saldo pengguna % sudah di bawah saldo minimum (5000).', NEW.user_id;
	END IF;
	
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.balance_warning() OWNER TO postgres;

--
-- Name: insert_log_report(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.insert_log_report() RETURNS void
    LANGUAGE plpgsql
    AS $$
BEGIN
	DELETE FROM log_report;
	
    INSERT INTO log_report (user_id, income, expense)
	SELECT 
	    u.user_id, 
	    COALESCE(SUM(i.amount), 0) AS income,   
	    COALESCE(SUM(e.amount), 0) AS expense
	FROM 
	    users u
	LEFT JOIN 
	    income i ON u.user_id = i.user_id  
	LEFT JOIN 
	    expense e ON u.user_id = e.user_id  
	GROUP BY 
	    u.user_id;
	
	-- Memperbarui kolom warning_message jika net_profit kurang dari 0
	UPDATE log_report
	SET warning_message = 'Peringatan: Pengeluaran lebih besar dari pemasukan.'
	WHERE net_profit < 0;
END;
$$;


ALTER FUNCTION public.insert_log_report() OWNER TO postgres;

--
-- Name: peringatan_saldo(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.peringatan_saldo() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN

	IF (SELECT balance FROM users WHERE user_id = NEW.user_id) < 100000 THEN
    	RAISE NOTICE 'Peringatan: Saldo pengguna % sudah di bawah saldo minimum (100000).', NEW.user_id;
	END IF;
	
    RETURN NULL;
END;
$$;


ALTER FUNCTION public.peringatan_saldo() OWNER TO postgres;

--
-- Name: reduce_balance(); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reduce_balance() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Periksa apakah saldo mencukupi
    IF (SELECT balance FROM users WHERE user_id = NEW.user_id) < NEW.amount THEN
        RAISE EXCEPTION 'Saldo tidak mencukupi untuk transaksi ini.';
    END IF;

    -- Kurangi saldo pengguna
    UPDATE users
    SET balance = balance - NEW.amount
    WHERE user_id = NEW.user_id;

    -- penyisipan data ke tabel expense
    RETURN NEW;
END;
$$;


ALTER FUNCTION public.reduce_balance() OWNER TO postgres;

--
-- Name: reduce_balance(integer, numeric); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.reduce_balance(IN user_id_to_check integer, IN pengeluaran numeric)
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_balance NUMERIC(12, 2);
BEGIN
    -- Mulai transaksi
    BEGIN
        -- Periksa saldo pengguna
        SELECT balance INTO user_balance
        FROM users
        WHERE user_id = user_id_to_check;

        -- Cek apakah saldo mencukupi
        IF user_balance < pengeluaran THEN
            RAISE EXCEPTION 'Saldo tidak mencukupi untuk user_id %!', user_id_to_check;
        END IF;

        -- Kurangi saldo pengguna
        UPDATE users
        SET balance = balance - pengeluaran
        WHERE user_id = user_id_to_check;

        -- Commit transaksi jika berhasil
        COMMIT;
        RAISE NOTICE 'Saldo berhasil dikurangi untuk user_id %!', user_id_to_check;

    EXCEPTION
        WHEN OTHERS THEN
            -- Rollback transaksi jika terjadi kesalahan
            ROLLBACK;
            RAISE NOTICE 'Transaksi gagal: %', SQLERRM;
    END;
END;
$$;


ALTER PROCEDURE public.reduce_balance(IN user_id_to_check integer, IN pengeluaran numeric) OWNER TO postgres;

--
-- Name: reduce_balance(integer, numeric, text, text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.reduce_balance(user_id_to_check integer, pengeluaran numeric, sumber text, deskripsi text) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_balance NUMERIC(12, 2);
BEGIN
    -- Ambil saldo pengguna
    SELECT balance INTO user_balance
    FROM users
    WHERE user_id = user_id_to_check;

    -- Periksa apakah saldo cukup
    IF user_balance < pengeluaran THEN
        RAISE EXCEPTION 'Saldo tidak mencukupi untuk user_id %!', user_id_to_check;
    END IF;

    -- Tambahkan pengeluaran ke tabel expense
    INSERT INTO expense(user_id, amount, sumber, description)
    VALUES (user_id_to_check, pengeluaran, sumber, deskripsi);

    -- Kurangi saldo pengguna
    UPDATE users
    SET balance = balance - pengeluaran
    WHERE user_id = user_id_to_check;
END;
$$;


ALTER FUNCTION public.reduce_balance(user_id_to_check integer, pengeluaran numeric, sumber text, deskripsi text) OWNER TO postgres;

--
-- Name: show_exchange_rate(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.show_exchange_rate(user_num integer) RETURNS void
    LANGUAGE plpgsql
    AS $$
DECLARE
    user_balance NUMERIC(12, 2);
    exchange_value NUMERIC(15, 2);
    exchange_code VARCHAR(10);
BEGIN
    -- Mendapatkan balance dari tabel users berdasarkan user_id
    SELECT balance INTO user_balance
    FROM users
    WHERE user_id = user_num;

    -- Mengecek jika user tidak ditemukan
    IF user_balance IS NULL THEN
        RAISE NOTICE 'User with ID % not found.', user_num;
        RETURN;
    END IF;

    -- Menampilkan balance user
    RAISE NOTICE 'User balance: Rp.%', user_balance;

    -- Mendapatkan exchange_rate dan currency_code dari tabel currency
    FOR exchange_code, exchange_value IN 
        SELECT currency_code, exchange_rate FROM currency
    LOOP
        -- Menampilkan hasil pembagian antara balance dan exchange_rate
        RAISE NOTICE 'For currency %, the exchange rate is %. Balance divided by exchange rate: %.', 
            exchange_code, 
            exchange_value, 
            ROUND(user_balance / exchange_value, 3);
    END LOOP;
END;
$$;


ALTER FUNCTION public.show_exchange_rate(user_num integer) OWNER TO postgres;

--
-- Name: total_income_expense_for_user(integer); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.total_income_expense_for_user(p_user_id integer) RETURNS TABLE(total_income numeric, total_expense numeric)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Menghitung total pemasukan
    SELECT COALESCE(SUM(amount), 0) INTO total_income
    FROM income
    WHERE user_id = p_user_id;

    -- Menghitung total pengeluaran
    SELECT COALESCE(SUM(amount), 0) INTO total_expense
    FROM expense
    WHERE user_id = p_user_id;

    -- Mengembalikan hasil
    RETURN NEXT;
END;
$$;


ALTER FUNCTION public.total_income_expense_for_user(p_user_id integer) OWNER TO postgres;

--
-- Name: view_user_balance(integer); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.view_user_balance(IN p_user_id integer)
    LANGUAGE plpgsql
    AS $$
BEGIN
    -- Menampilkan saldo terbaru pengguna berdasarkan view user_balance_view
    PERFORM * FROM monthly_expense WHERE user_id = p_user_id;
END;
$$;


ALTER PROCEDURE public.view_user_balance(IN p_user_id integer) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: currency; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.currency (
    currency_id integer NOT NULL,
    currency_code character varying(10) NOT NULL,
    exchange_rate numeric(15,2) NOT NULL
);


ALTER TABLE public.currency OWNER TO postgres;

--
-- Name: currency_currency_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.currency_currency_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.currency_currency_id_seq OWNER TO postgres;

--
-- Name: currency_currency_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.currency_currency_id_seq OWNED BY public.currency.currency_id;


--
-- Name: expense; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.expense (
    expense_id integer NOT NULL,
    user_id integer,
    amount numeric(12,2) NOT NULL,
    source integer,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    description character varying(255) NOT NULL
);


ALTER TABLE public.expense OWNER TO postgres;

--
-- Name: expense_expense_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.expense_expense_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.expense_expense_id_seq OWNER TO postgres;

--
-- Name: expense_expense_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.expense_expense_id_seq OWNED BY public.expense.expense_id;


--
-- Name: income; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.income (
    income_id integer NOT NULL,
    user_id integer,
    amount numeric(12,2) NOT NULL,
    source integer,
    date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    description character varying(255) NOT NULL
);


ALTER TABLE public.income OWNER TO postgres;

--
-- Name: income_income_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.income_income_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.income_income_id_seq OWNER TO postgres;

--
-- Name: income_income_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.income_income_id_seq OWNED BY public.income.income_id;


--
-- Name: log_report; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.log_report (
    report_id integer NOT NULL,
    user_id integer,
    income numeric(12,2) NOT NULL,
    expense numeric(12,2) NOT NULL,
    net_profit numeric(12,2) GENERATED ALWAYS AS ((income - expense)) STORED,
    report_date timestamp without time zone DEFAULT CURRENT_TIMESTAMP,
    warning_message text
);


ALTER TABLE public.log_report OWNER TO postgres;

--
-- Name: log_report_report_id_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.log_report_report_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.log_report_report_id_seq OWNER TO postgres;

--
-- Name: log_report_report_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.log_report_report_id_seq OWNED BY public.log_report.report_id;


--
-- Name: monthly_financial_summary; Type: VIEW; Schema: public; Owner: postgres
--

CREATE VIEW public.monthly_financial_summary AS
 SELECT expense.user_id,
    date_trunc('month'::text, expense.date) AS bulan,
    'expense'::text AS kategori,
    sum(expense.amount) AS total
   FROM public.expense
  GROUP BY expense.user_id, (date_trunc('month'::text, expense.date))
UNION ALL
 SELECT income.user_id,
    date_trunc('month'::text, income.date) AS bulan,
    'income'::text AS kategori,
    sum(income.amount) AS total
   FROM public.income
  GROUP BY income.user_id, (date_trunc('month'::text, income.date))
  ORDER BY 1, 2, 3;


ALTER VIEW public.monthly_financial_summary OWNER TO postgres;

--
-- Name: source; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.source (
    source_id integer NOT NULL,
    name character varying(255) NOT NULL
);


ALTER TABLE public.source OWNER TO postgres;

--
-- Name: users; Type: TABLE; Schema: public; Owner: vanesa
--

CREATE TABLE public.users (
    user_id integer NOT NULL,
    name character varying(255) NOT NULL,
    email character varying(255) NOT NULL,
    password character varying(255) NOT NULL,
    balance numeric(12,2),
    CONSTRAINT users_balance_check CHECK ((balance >= (0)::numeric))
);


ALTER TABLE public.users OWNER TO vanesa;

--
-- Name: users_user_id_seq; Type: SEQUENCE; Schema: public; Owner: vanesa
--

CREATE SEQUENCE public.users_user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER SEQUENCE public.users_user_id_seq OWNER TO vanesa;

--
-- Name: users_user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: vanesa
--

ALTER SEQUENCE public.users_user_id_seq OWNED BY public.users.user_id;


--
-- Name: currency currency_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currency ALTER COLUMN currency_id SET DEFAULT nextval('public.currency_currency_id_seq'::regclass);


--
-- Name: expense expense_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense ALTER COLUMN expense_id SET DEFAULT nextval('public.expense_expense_id_seq'::regclass);


--
-- Name: income income_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.income ALTER COLUMN income_id SET DEFAULT nextval('public.income_income_id_seq'::regclass);


--
-- Name: log_report report_id; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_report ALTER COLUMN report_id SET DEFAULT nextval('public.log_report_report_id_seq'::regclass);


--
-- Name: users user_id; Type: DEFAULT; Schema: public; Owner: vanesa
--

ALTER TABLE ONLY public.users ALTER COLUMN user_id SET DEFAULT nextval('public.users_user_id_seq'::regclass);


--
-- Data for Name: currency; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.currency (currency_id, currency_code, exchange_rate) FROM stdin;
50	USD	15851.00
51	SGD	11775.00
52	AUD	10071.00
53	EUR	16669.00
54	GBP	20150.00
55	CAD	11125.00
56	CHF	17979.00
57	HKD	2019.00
58	JPY	103.26
59	SAR	4199.00
60	MYR	3575.00
61	THB	468.48
62	NZD	9158.00
\.


--
-- Data for Name: expense; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.expense (expense_id, user_id, amount, source, date, description) FROM stdin;
2	1	250000.00	10	2023-12-03 08:40:02	Naik taksi
3	1	40000.00	11	2023-09-01 10:15:20	Tagihan Listrik
4	3	100000.00	12	2023-10-02 14:20:35	Belanja Bulanan
5	2	75000.00	13	2023-03-03 18:50:00	Tiket Bioskop
6	3	120000.00	14	2023-03-04 12:30:25	Makan Siang
7	2	85000.00	7	2023-10-30 09:00:10	Komisi penjualan online
8	4	25000.00	15	2023-06-02 17:45:50	Penjualan laptop bekas
9	2	60000.00	19	2023-04-01 11:25:40	Royalti dari buku yang diterbitkan
10	4	250000.00	4	2023-03-03 19:20:15	Keuntungan dari penjualan makanan ringan
11	1	50000.00	17	2023-02-04 08:10:05	Penghasilan dari jasa penulisan artikel
12	2	90000.00	18	2023-10-03 15:25:35	Keuntungan dari dropship produk kecantikan
13	4	250000.00	1	2023-12-02 10:40:50	Pendapatan kerja part-time
14	1	300000.00	16	2023-01-30 14:50:30	Pendapatan dari event organizer
15	1	45000.00	20	2023-02-01 20:15:20	Hadiah dari lomba coding
16	2	65000.00	6	2023-03-02 16:35:25	Keuntungan investasi emas
17	4	180000.00	3	2023-04-03 13:40:45	Proyek desain logo perusahaan
18	2	150000.00	21	2023-12-04 09:30:10	Pendapatan dari menyewakan rumah
19	3	70000.00	15	2023-05-02 18:50:00	Penjualan ponsel bekas
20	2	275000.00	1	2023-06-01 08:25:15	Pendapatan dari pekerjaan kontrak
21	3	125000.00	2	2023-07-03 07:50:20	Keuntungan dari trading forex
22	4	100000.00	22	2023-08-04 11:00:30	Penghasilan dari membuat website perusahaan
23	1	30000.00	14	2023-01-05 07:45:00	Sarapan pagi
24	2	45000.00	10	2023-01-10 09:20:00	Naik ojek online
25	3	125000.00	12	2023-01-15 13:30:00	Belanja pakaian
26	4	65000.00	13	2023-01-20 19:15:00	Beli tiket konser
27	1	40000.00	11	2023-02-05 08:10:00	Tagihan air
28	2	90000.00	3	2023-02-15 14:25:00	Desain kartu nama
29	3	200000.00	6	2023-03-01 09:30:00	Keuntungan reksa dana
30	4	30000.00	14	2023-03-05 15:50:00	Beli cemilan
31	1	75000.00	15	2023-03-10 10:15:00	Penjualan kamera bekas
32	2	40000.00	13	2023-03-15 12:45:00	Beli buku
33	3	150000.00	4	2023-04-10 18:20:00	Hasil penjualan online shop
34	4	120000.00	2	2023-04-15 08:10:00	Keuntungan trading saham
35	1	50000.00	10	2023-05-05 06:50:00	Naik bus antar kota
36	2	80000.00	11	2023-05-10 11:00:00	Tagihan internet
37	3	90000.00	16	2023-06-20 14:40:00	Honor sebagai pembicara
38	4	60000.00	14	2023-07-05 20:15:00	Makan malam di restoran
39	1	70000.00	18	2023-07-15 16:30:00	Keuntungan penjualan produk
40	2	140000.00	1	2023-08-01 09:20:00	Pendapatan kerja part-time
41	3	115000.00	7	2023-09-10 10:50:00	Komisi dari promosi produk
42	4	200000.00	3	2023-10-01 13:15:00	Proyek editing video
43	1	90000.00	17	2023-10-10 08:00:00	Penghasilan sebagai fotografer
44	2	55000.00	12	2023-10-20 17:30:00	Belanja bahan makanan
45	3	100000.00	11	2023-11-05 09:10:00	Tagihan listrik dan air
46	4	85000.00	4	2023-11-15 12:00:00	Keuntungan dari penjualan makanan ringan
47	1	110000.00	16	2023-12-01 18:50:00	Pendapatan dari acara komunitas
48	2	60000.00	10	2023-12-03 07:30:00	Biaya parkir bulanan
49	3	150000.00	2	2023-12-04 20:00:00	Hasil investasi crypto
\.


--
-- Data for Name: income; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.income (income_id, user_id, amount, source, date, description) FROM stdin;
1	4	5000000.00	1	2023-11-01 09:00:00	Gajian bulan Desember
2	1	250000.00	2	2023-11-02 15:30:00	Hasil dari trading
3	1	150000.00	3	2023-10-03 14:15:00	Proyek Freelance
4	3	400000.00	4	2023-12-04 11:45:00	Penjualan Produk
5	2	500000.00	5	2023-08-01 13:20:00	Pendapatan Proyek
6	2	160000.00	6	2023-10-02 10:50:00	Keuntungan investasi
7	3	120000.00	7	2023-02-03 16:30:00	Komisi penjualan online
8	4	110000.00	8	2023-03-04 19:00:00	Bonus lembur
9	2	115000.00	9	2023-02-02 09:10:00	Dividen saham
10	3	450000.00	2	2023-01-03 20:00:00	Hasil dari trading
11	1	105000.00	6	2023-03-01 18:20:00	keuntungan investasi
12	3	400000.00	2	2023-04-02 12:10:00	Hasil dari trading
13	2	3000000.00	1	2023-05-04 09:40:00	Gaji Bulanan
14	4	200000.00	6	2023-06-01 14:50:00	keuntungan investasi
15	2	100000.00	5	2023-05-02 15:25:00	Pendapatan Proyek
16	3	300000.00	5	2023-06-03 10:40:00	Pendapatan Proyek
17	4	200000.00	8	2023-04-04 16:00:00	Bonus lembur
18	1	310000.00	6	2023-02-01 11:30:00	Keuntungan investasi
19	3	4000000.00	1	2023-10-02 17:00:00	Gaji Bulanan
20	2	140000.00	9	2023-05-03 08:50:00	Diveden Saham
21	4	320000.00	7	2023-07-04 14:10:00	Komisi penjualan online
22	1	200000.00	3	2023-07-05 10:20:00	Proyek desain grafis
23	2	500000.00	4	2023-09-01 12:30:00	Hasil penjualan online
24	3	250000.00	5	2023-11-15 14:50:00	Pendapatan proyek jangka pendek
25	4	150000.00	8	2023-03-12 19:45:00	Bonus lembur tambahan
26	1	300000.00	6	2023-01-05 09:15:00	Hasil investasi saham
27	2	600000.00	1	2023-04-01 09:00:00	Gaji Bulanan
28	3	200000.00	2	2023-06-05 16:30:00	Hasil trading forex
29	4	350000.00	7	2023-08-10 10:40:00	Komisi dari penjualan
30	1	120000.00	5	2023-09-01 13:20:00	Pendapatan proyek freelance
31	2	450000.00	6	2023-12-01 11:50:00	Keuntungan dari properti
32	3	800000.00	4	2023-01-01 14:00:00	Pendapatan usaha online
33	4	300000.00	1	2023-02-01 09:30:00	Gaji tambahan bulan ini
34	1	70000.00	8	2023-03-10 19:20:00	Bonus lembur malam
35	2	160000.00	9	2023-04-15 08:30:00	Hasil investasi reksa dana
36	3	300000.00	2	2023-05-20 18:50:00	Keuntungan trading crypto
37	4	250000.00	7	2023-06-01 10:00:00	Komisi produk digital
38	1	50000.00	5	2023-07-01 11:20:00	Pendapatan proyek kecil
39	2	200000.00	3	2023-08-05 13:15:00	Proyek pengembangan web
40	3	100000.00	6	2023-09-10 14:40:00	Hasil investasi emas
41	4	550000.00	1	2023-10-01 09:50:00	Gaji Bulanan
42	1	180000.00	5	2023-11-01 15:10:00	Pendapatan proyek penulisan
43	2	420000.00	4	2023-11-15 16:20:00	Hasil penjualan produk
44	3	750000.00	1	2023-12-01 09:40:00	Gaji tambahan
45	4	300000.00	7	2023-12-05 14:30:00	Komisi dari toko online
46	1	400000.00	3	2023-12-04 13:20:00	Pendapatan desain logo
47	2	120000.00	2	2023-08-01 10:00:00	Keuntungan trading kecil
48	3	200000.00	6	2023-01-20 15:45:00	Hasil investasi kecil
49	4	150000.00	5	2023-02-15 18:30:00	Pendapatan proyek desain
50	1	300000.00	3	2023-03-20 16:20:00	Proyek aplikasi mobile
51	2	400000.00	1	2023-05-01 09:00:00	Pendapatan bulanan
\.


--
-- Data for Name: log_report; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.log_report (report_id, user_id, income, expense, report_date, warning_message) FROM stdin;
9	1	29220000.00	13800000.00	2024-12-10 11:10:07.153383	\N
10	3	90970000.00	17485000.00	2024-12-10 11:10:07.153383	\N
11	2	96110000.00	18340000.00	2024-12-10 11:10:07.153383	\N
12	4	86680000.00	16380000.00	2024-12-10 11:10:07.153383	\N
\.


--
-- Data for Name: source; Type: TABLE DATA; Schema: public; Owner: postgres
--

COPY public.source (source_id, name) FROM stdin;
1	Gaji
2	Trading
3	Freelance
4	Usaha
5	Proyek
6	Investasi
7	Affiliate
8	Lembur
9	Dividen
10	Transportasi
11	Tagihan
12	Belanja
13	Hiburan
14	Makanan
15	Jual Barang
16	Event
17	Jasa
18	Dropship
19	Royalti
20	Sewa Properti
21	Hadiah
22	Pembuatan Website
\.


--
-- Data for Name: users; Type: TABLE DATA; Schema: public; Owner: vanesa
--

COPY public.users (user_id, name, email, password, balance) FROM stdin;
4	Arnold	Arnold@gmail.com	password556	6515000.00
1	Vanesa	vanesa@gmail.com	password123	1285000.00
2	James	jems@gmail.com	password789	5555000.00
3	Jessica	jess@gmail.com	password111	6925000.00
5	User One	user1@example.com	password1	100.00
6	User Two	user2@example.com	password2	200.00
7	User Three	user3@example.com	password3	300.00
8	User Four	user4@example.com	password4	400.00
\.


--
-- Name: currency_currency_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.currency_currency_id_seq', 62, true);


--
-- Name: expense_expense_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.expense_expense_id_seq', 49, true);


--
-- Name: income_income_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.income_income_id_seq', 51, true);


--
-- Name: log_report_report_id_seq; Type: SEQUENCE SET; Schema: public; Owner: postgres
--

SELECT pg_catalog.setval('public.log_report_report_id_seq', 12, true);


--
-- Name: users_user_id_seq; Type: SEQUENCE SET; Schema: public; Owner: vanesa
--

SELECT pg_catalog.setval('public.users_user_id_seq', 8, true);


--
-- Name: currency currency_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.currency
    ADD CONSTRAINT currency_pkey PRIMARY KEY (currency_id);


--
-- Name: expense expense_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense
    ADD CONSTRAINT expense_pkey PRIMARY KEY (expense_id);


--
-- Name: income income_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.income
    ADD CONSTRAINT income_pkey PRIMARY KEY (income_id);


--
-- Name: log_report log_report_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_report
    ADD CONSTRAINT log_report_pkey PRIMARY KEY (report_id);


--
-- Name: source source_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.source
    ADD CONSTRAINT source_pkey PRIMARY KEY (source_id);


--
-- Name: users users_email_key; Type: CONSTRAINT; Schema: public; Owner: vanesa
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_email_key UNIQUE (email);


--
-- Name: users users_pkey; Type: CONSTRAINT; Schema: public; Owner: vanesa
--

ALTER TABLE ONLY public.users
    ADD CONSTRAINT users_pkey PRIMARY KEY (user_id);


--
-- Name: income trigger_add_balance; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_add_balance BEFORE INSERT ON public.income FOR EACH ROW EXECUTE FUNCTION public.add_balance();


--
-- Name: expense trigger_minimum_balance_warning_expense; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_minimum_balance_warning_expense AFTER INSERT ON public.expense FOR EACH ROW EXECUTE FUNCTION public.balance_warning();


--
-- Name: expense trigger_reduce_balance; Type: TRIGGER; Schema: public; Owner: postgres
--

CREATE TRIGGER trigger_reduce_balance BEFORE INSERT ON public.expense FOR EACH ROW EXECUTE FUNCTION public.reduce_balance();


--
-- Name: expense expense_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense
    ADD CONSTRAINT expense_source_fkey FOREIGN KEY (source) REFERENCES public.source(source_id) ON DELETE CASCADE;


--
-- Name: expense expense_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.expense
    ADD CONSTRAINT expense_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: income income_source_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.income
    ADD CONSTRAINT income_source_fkey FOREIGN KEY (source) REFERENCES public.source(source_id) ON DELETE CASCADE;


--
-- Name: income income_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.income
    ADD CONSTRAINT income_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id) ON DELETE CASCADE;


--
-- Name: log_report log_report_user_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.log_report
    ADD CONSTRAINT log_report_user_id_fkey FOREIGN KEY (user_id) REFERENCES public.users(user_id);


--
-- Name: log_report; Type: ROW SECURITY; Schema: public; Owner: postgres
--

ALTER TABLE public.log_report ENABLE ROW LEVEL SECURITY;

--
-- Name: users user1_see_own_data; Type: POLICY; Schema: public; Owner: vanesa
--

CREATE POLICY user1_see_own_data ON public.users FOR SELECT USING ((user_id = 1));


--
-- Name: users user2_see_own_data; Type: POLICY; Schema: public; Owner: vanesa
--

CREATE POLICY user2_see_own_data ON public.users FOR SELECT USING ((user_id = 2));


--
-- Name: users user3_see_own_data; Type: POLICY; Schema: public; Owner: vanesa
--

CREATE POLICY user3_see_own_data ON public.users FOR SELECT USING ((user_id = 3));


--
-- Name: users user4_see_own_data; Type: POLICY; Schema: public; Owner: vanesa
--

CREATE POLICY user4_see_own_data ON public.users FOR SELECT USING ((user_id = 4));


--
-- Name: users user_see_own_data; Type: POLICY; Schema: public; Owner: vanesa
--

CREATE POLICY user_see_own_data ON public.users FOR SELECT USING ((user_id = (CURRENT_USER)::integer));


--
-- Name: log_report user_transaction_policy; Type: POLICY; Schema: public; Owner: postgres
--

CREATE POLICY user_transaction_policy ON public.log_report FOR SELECT USING (((user_id)::text = CURRENT_USER));


--
-- Name: users; Type: ROW SECURITY; Schema: public; Owner: vanesa
--

ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;

--
-- Name: TABLE log_report; Type: ACL; Schema: public; Owner: postgres
--

GRANT SELECT ON TABLE public.log_report TO read_only_user;


--
-- Name: TABLE users; Type: ACL; Schema: public; Owner: vanesa
--

GRANT SELECT ON TABLE public.users TO user1;
GRANT SELECT ON TABLE public.users TO user2;
GRANT SELECT ON TABLE public.users TO user3;
GRANT SELECT ON TABLE public.users TO user4;
GRANT SELECT ON TABLE public.users TO jessica;
GRANT SELECT ON TABLE public.users TO arnold;
GRANT SELECT ON TABLE public.users TO "1";
GRANT SELECT ON TABLE public.users TO "2";
GRANT SELECT ON TABLE public.users TO "5";


--
-- PostgreSQL database dump complete
--

