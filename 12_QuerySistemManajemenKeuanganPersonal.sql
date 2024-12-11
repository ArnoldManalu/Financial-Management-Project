CREATE DATABASE financial_project;

CREATE TABLE users(
	user_id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	email VARCHAR(255) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	balance NUMERIC(12, 2) CHECK (balance >= 0)
);

CREATE TABLE source (
	source_id INT PRIMARY KEY,
	name VARCHAR(255) NOT NULL
);

CREATE TABLE income(
	income_id SERIAL PRIMARY KEY,
	user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
	amount NUMERIC(12, 2) NOT NULL,
	source INTEGER REFERENCES source(source_id) ON DELETE CASCADE,
	date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	description VARCHAR(255) NOT NULL
);

CREATE TABLE expense(
	expense_id SERIAL PRIMARY KEY,
	user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
	amount NUMERIC(12, 2) NOT NULL,
	source INTEGER REFERENCES source(source_id) ON DELETE CASCADE,
	date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	description VARCHAR(255) NOT NULL
);

CREATE TABLE currency (
    currency_id SERIAL PRIMARY KEY,          
    currency_code VARCHAR(10) NOT NULL,      
    exchange_rate NUMERIC(15, 2) NOT NULL
);

CREATE TABLE log_report (
    report_id SERIAL PRIMARY KEY,                
    user_id INTEGER REFERENCES users(user_id),   
    income NUMERIC(12, 2) NOT NULL,              
    expense NUMERIC(12, 2) NOT NULL,             
    net_profit NUMERIC(12, 2) GENERATED ALWAYS AS (income - expense) STORED,
    report_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    warning_message TEXT
);


-- Buat dummy data untuk tabel users
INSERT INTO users(name, email, password, balance) VALUES 
('Vanesa', 'vanesa@gmail.com', 'password123', 0),
('James', 'jems@gmail.com', 'password789', 0),
('Jessica', 'jess@gmail.com', 'password111', 0),
('Arnold', 'Arnold@gmail.com', 'password556', 0);

-- Buat dummy data untuk tabel source
INSERT INTO source (source_id, name) VALUES
(1, 'Gaji'),
(2, 'Trading'),
(3, 'Freelance'),
(4, 'Usaha'),
(5, 'Proyek'),
(6, 'Investasi'),
(7, 'Affiliate'),
(8, 'Lembur'),
(9, 'Dividen'),
(10, 'Transportasi'),
(11, 'Tagihan'),
(12, 'Belanja'),
(13, 'Hiburan'),
(14, 'Makanan'),
(15, 'Jual Barang'),
(16, 'Event'),
(17, 'Jasa'),
(18, 'Dropship'),
(19, 'Royalti'),
(20, 'Sewa Properti'),
(21, 'Hadiah'),
(22, 'Pembuatan Website');

-- Buat dummy data untuk tabel income
INSERT INTO income(user_id, amount, source, description, date) VALUES 
(4, 5000000, 1, 'Gajian bulan Desember', '2023-11-01 09:00:00'),
(1, 250000, 2, 'Hasil dari trading', '2023-11-02 15:30:00'),
(1, 150000, 3, 'Proyek Freelance', '2023-10-03 14:15:00'),
(3, 400000, 4, 'Penjualan Produk', '2023-12-04 11:45:00'),
(2, 500000, 5, 'Pendapatan Proyek', '2023-08-01 13:20:00'),
(2, 160000, 6, 'Keuntungan investasi', '2023-10-02 10:50:00'),
(3, 120000, 7, 'Komisi penjualan online', '2023-02-03 16:30:00'),
(4, 110000, 8, 'Bonus lembur', '2023-03-04 19:00:00'),
(2, 115000, 9, 'Dividen saham', '2023-02-02 09:10:00'),
(3, 450000, 2, 'Hasil dari trading', '2023-01-03 20:00:00'),
(1, 105000, 6, 'keuntungan investasi', '2023-03-01 18:20:00'),
(3, 400000, 2, 'Hasil dari trading', '2023-04-02 12:10:00'),
(2, 3000000, 1, 'Gaji Bulanan', '2023-05-04 09:40:00'),
(4, 200000, 6, 'keuntungan investasi', '2023-06-01 14:50:00'),
(2, 100000, 5, 'Pendapatan Proyek', '2023-05-02 15:25:00'),
(3, 300000, 5, 'Pendapatan Proyek', '2023-06-03 10:40:00'),
(4, 200000, 8, 'Bonus lembur', '2023-04-04 16:00:00'),
(1, 310000, 6, 'Keuntungan investasi', '2023-02-01 11:30:00'),
(3, 4000000, 1, 'Gaji Bulanan', '2023-10-02 17:00:00'),
(2, 140000, 9, 'Diveden Saham', '2023-05-03 08:50:00'),
(4, 320000, 7, 'Komisi penjualan online', '2023-07-04 14:10:00'),
(1, 200000, 3, 'Proyek desain grafis', '2023-07-05 10:20:00'),
(2, 500000, 4, 'Hasil penjualan online', '2023-09-01 12:30:00'),
(3, 250000, 5, 'Pendapatan proyek jangka pendek', '2023-11-15 14:50:00'),
(4, 150000, 8, 'Bonus lembur tambahan', '2023-03-12 19:45:00'),
(1, 300000, 6, 'Hasil investasi saham', '2023-01-05 09:15:00'),
(2, 600000, 1, 'Gaji Bulanan', '2023-04-01 09:00:00'),
(3, 200000, 2, 'Hasil trading forex', '2023-06-05 16:30:00'),
(4, 350000, 7, 'Komisi dari penjualan', '2023-08-10 10:40:00'),
(1, 120000, 5, 'Pendapatan proyek freelance', '2023-09-01 13:20:00'),
(2, 450000, 6, 'Keuntungan dari properti', '2023-12-01 11:50:00'),
(3, 800000, 4, 'Pendapatan usaha online', '2023-01-01 14:00:00'),
(4, 300000, 1, 'Gaji tambahan bulan ini', '2023-02-01 09:30:00'),
(1, 70000, 8, 'Bonus lembur malam', '2023-03-10 19:20:00'),
(2, 160000, 9, 'Hasil investasi reksa dana', '2023-04-15 08:30:00'),
(3, 300000, 2, 'Keuntungan trading crypto', '2023-05-20 18:50:00'),
(4, 250000, 7, 'Komisi produk digital', '2023-06-01 10:00:00'),
(1, 50000, 5, 'Pendapatan proyek kecil', '2023-07-01 11:20:00'),
(2, 200000, 3, 'Proyek pengembangan web', '2023-08-05 13:15:00'),
(3, 100000, 6, 'Hasil investasi emas', '2023-09-10 14:40:00'),
(4, 550000, 1, 'Gaji Bulanan', '2023-10-01 09:50:00'),
(1, 180000, 5, 'Pendapatan proyek penulisan', '2023-11-01 15:10:00'),
(2, 420000, 4, 'Hasil penjualan produk', '2023-11-15 16:20:00'),
(3, 750000, 1, 'Gaji tambahan', '2023-12-01 09:40:00'),
(4, 300000, 7, 'Komisi dari toko online', '2023-12-05 14:30:00'),
(1, 400000, 3, 'Pendapatan desain logo', '2023-12-04 13:20:00'),
(2, 120000, 2, 'Keuntungan trading kecil', '2023-08-01 10:00:00'),
(3, 200000, 6, 'Hasil investasi kecil', '2023-01-20 15:45:00'),
(4, 150000, 5, 'Pendapatan proyek desain', '2023-02-15 18:30:00'),
(1, 300000, 3, 'Proyek aplikasi mobile', '2023-03-20 16:20:00'),
(2, 400000, 1, 'Pendapatan bulanan', '2023-05-01 09:00:00');

-- Buat dummy data untuk tabel expense
INSERT INTO expense(user_id, amount, source, description, date) VALUES 
(1, 250000, 10, 'Naik taksi', '2023-12-03 08:40:02'),
(1, 40000, 11, 'Tagihan Listrik', '2023-09-01 10:15:20'),
(3, 100000, 12, 'Belanja Bulanan', '2023-10-02 14:20:35'),
(2, 75000, 13, 'Tiket Bioskop', '2023-03-03 18:50:00'),
(3, 120000, 14, 'Makan Siang', '2023-03-04 12:30:25'),
(2, 85000, 7, 'Komisi penjualan online', '2023-10-30 09:00:10'),
(4, 25000, 15, 'Penjualan laptop bekas', '2023-06-02 17:45:50'),
(2, 60000, 19, 'Royalti dari buku yang diterbitkan', '2023-04-01 11:25:40'),
(4, 250000, 4, 'Keuntungan dari penjualan makanan ringan', '2023-03-03 19:20:15'),
(1, 50000, 17, 'Penghasilan dari jasa penulisan artikel', '2023-02-04 08:10:05'),
(2, 90000, 18, 'Keuntungan dari dropship produk kecantikan', '2023-10-03 15:25:35'),
(4, 250000, 1, 'Pendapatan kerja part-time', '2023-12-02 10:40:50'),
(1, 300000, 16, 'Pendapatan dari event organizer', '2023-01-30 14:50:30'),
(1, 45000, 20, 'Hadiah dari lomba coding', '2023-02-01 20:15:20'),
(2, 65000, 6, 'Keuntungan investasi emas', '2023-03-02 16:35:25'),
(4, 180000, 3, 'Proyek desain logo perusahaan', '2023-04-03 13:40:45'),
(2, 150000, 21, 'Pendapatan dari menyewakan rumah', '2023-12-04 09:30:10'),
(3, 70000, 15, 'Penjualan ponsel bekas', '2023-05-02 18:50:00'),
(2, 275000, 1, 'Pendapatan dari pekerjaan kontrak', '2023-06-01 08:25:15'),
(3, 125000, 2, 'Keuntungan dari trading forex', '2023-07-03 07:50:20'),
(4, 100000, 22, 'Penghasilan dari membuat website perusahaan', '2023-08-04 11:00:30'),
(1, 30000, 14, 'Sarapan pagi', '2023-01-05 07:45:00'),
(2, 45000, 10, 'Naik ojek online', '2023-01-10 09:20:00'),
(3, 125000, 12, 'Belanja pakaian', '2023-01-15 13:30:00'),
(4, 65000, 13, 'Beli tiket konser', '2023-01-20 19:15:00'),
(1, 40000, 11, 'Tagihan air', '2023-02-05 08:10:00'),
(2, 90000, 3, 'Desain kartu nama', '2023-02-15 14:25:00'),
(3, 200000, 6, 'Keuntungan reksa dana', '2023-03-01 09:30:00'),
(4, 30000, 14, 'Beli cemilan', '2023-03-05 15:50:00'),
(1, 75000, 15, 'Penjualan kamera bekas', '2023-03-10 10:15:00'),
(2, 40000, 13, 'Beli buku', '2023-03-15 12:45:00'),
(3, 150000, 4, 'Hasil penjualan online shop', '2023-04-10 18:20:00'),
(4, 120000, 2, 'Keuntungan trading saham', '2023-04-15 08:10:00'),
(1, 50000, 10, 'Naik bus antar kota', '2023-05-05 06:50:00'),
(2, 80000, 11, 'Tagihan internet', '2023-05-10 11:00:00'),
(3, 90000, 16, 'Honor sebagai pembicara', '2023-06-20 14:40:00'),
(4, 60000, 14, 'Makan malam di restoran', '2023-07-05 20:15:00'),
(1, 70000, 18, 'Keuntungan penjualan produk', '2023-07-15 16:30:00'),
(2, 140000, 1, 'Pendapatan kerja part-time', '2023-08-01 09:20:00'),
(3, 115000, 7, 'Komisi dari promosi produk', '2023-09-10 10:50:00'),
(4, 200000, 3, 'Proyek editing video', '2023-10-01 13:15:00'),
(1, 90000, 17, 'Penghasilan sebagai fotografer', '2023-10-10 08:00:00'),
(2, 55000, 12, 'Belanja bahan makanan', '2023-10-20 17:30:00'),
(3, 100000, 11, 'Tagihan listrik dan air', '2023-11-05 09:10:00'),
(4, 85000, 4, 'Keuntungan dari penjualan makanan ringan', '2023-11-15 12:00:00'),
(1, 110000, 16, 'Pendapatan dari acara komunitas', '2023-12-01 18:50:00'),
(2, 60000, 10, 'Biaya parkir bulanan', '2023-12-03 07:30:00'),
(3, 150000, 2, 'Hasil investasi crypto', '2023-12-04 20:00:00');


-- Create View untuk menampilkan saldo pengguna
CREATE VIEW monthly_financial_summary AS
SELECT
    user_id,
    DATE_TRUNC('month', date) AS bulan,
    'expense' AS kategori,
    SUM(amount) AS total
FROM expense
GROUP BY user_id, DATE_TRUNC('month', date)

UNION ALL

SELECT
    user_id,
    DATE_TRUNC('month', date) AS bulan,
    'income' AS kategori,
    SUM(amount) AS total
FROM income
GROUP BY user_id, DATE_TRUNC('month', date)

ORDER BY user_id, bulan, kategori;


/* Authorization */
-- Membuat pengguna
CREATE USER "1";
CREATE USER "2";
CREATE USER "3";
CREATE USER "4";

-- Mengaktifkan Row Level Security
ALTER TABLE users ENABLE ROW LEVEL SECURITY;

-- Membuat kebijakan agar pengguna hanya bisa mengakses data yang sesuai dengan user_id mereka
CREATE POLICY user_see_own_data ON users
    FOR SELECT
    USING (user_id = CAST(current_user AS INT)); 

-- Menghapus kebijakan jika perlu
-- DROP POLICY user_see_own_data ON users;

-- Memberikan akses SELECT kepada pengguna "1"
GRANT SELECT ON users TO "1";

-- Menggunakan peran pengguna "1"
SET ROLE "1";

-- Melakukan SELECT untuk memastikan hanya data dengan user_id sesuai yang muncul
SELECT * FROM users;

-- Kembalikan role ke admin
SET ROLE postgres;


/* Trigger */
-- Fungsi untuk mengurangi saldo saat ada pengeluaran
CREATE OR REPLACE FUNCTION reduce_balance()
RETURNS TRIGGER AS $$
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
$$ LANGUAGE plpgsql;

-- Trigger untuk Pemasukan (Income)
-- Fungsi untuk menambah saldo saat ada pemasukan
CREATE OR REPLACE FUNCTION add_balance()
RETURNS TRIGGER AS $$
BEGIN
    -- Tambah saldo pengguna
    UPDATE users
    SET balance = balance + NEW.amount
    WHERE user_id = NEW.user_id;

    -- Lanjutkan penyisipan data ke tabel income
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;  

CREATE OR REPLACE FUNCTION balance_warning()
RETURNS TRIGGER AS $$
BEGIN

	IF (SELECT balance FROM users WHERE user_id = NEW.user_id) < 50000 THEN
    	RAISE NOTICE 'Peringatan: Saldo pengguna % sudah di bawah saldo minimum (5000).', NEW.user_id;
	END IF;
	
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;


-- Trigger untuk memberikan peringatan jika saldo di bawah minimum setelah pengeluaran
CREATE TRIGGER trigger_minimum_balance_warning_expense
AFTER INSERT ON expense
FOR EACH ROW
EXECUTE FUNCTION balance_warning();

-- Trigger untuk mengurangi saldo sebelum memasukkan data ke tabel expense
CREATE TRIGGER trigger_reduce_balance
BEFORE INSERT ON expense
FOR EACH ROW
EXECUTE FUNCTION reduce_balance();

-- Trigger untuk menambah saldo sebelum memasukkan data ke tabel income
CREATE TRIGGER trigger_add_balance
BEFORE INSERT ON income
FOR EACH ROW
EXECUTE FUNCTION add_balance();


-- Import data hasil scraping kedalam tabel currency
COPY currency (currency_code, exchange_rate)
FROM 'D:/D-III Teknologi Informasi/Semester 3/Sistem Basis Data/Proyek/Artefak/12_HasilCrawlingSistemManajemenKeuanganPersonal.csv'
DELIMITER ';';


-- Stored Procedure untuk Melihat Saldo Pengguna
CREATE OR REPLACE PROCEDURE view_user_balance(
    p_user_id INTEGER
)
LANGUAGE plpgsql
AS
$$
BEGIN
    -- Menampilkan saldo terbaru pengguna berdasarkan view user_balance_view
    PERFORM * FROM monthly_financial_summary WHERE user_id = p_user_id;
END;
$$;

-- pemanggilan 
CALL view_user_balance(1);

-- stored procedure menghitung total pemasukan pengeluaran user
CREATE OR REPLACE FUNCTION total_income_expense_for_user(p_user_id INTEGER)
RETURNS TABLE(total_income NUMERIC(12, 2), total_expense NUMERIC(12, 2))
LANGUAGE plpgsql
AS
$$
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

-- stored procedure memasukkan data ke dalam log report
CREATE OR REPLACE FUNCTION insert_log_report()
RETURNS VOID AS $$
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
$$ LANGUAGE plpgsql;

-- pemanggilan
SELECT * FROM total_income_expense_for_user(1);
SELECT * FROM insert_log_report();
SELECT * FROM log_report;
SELECT * FROM income;
SELECT * FROM expense;
SELECT * FROM currency;
SELECT * FROM users;

-- Function konversi saldo ke masing-masing kurs
CREATE OR REPLACE FUNCTION show_exchange_rate(user_num INT) 
RETURNS VOID AS $$
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
        RAISE NOTICE 'Mata Uang % memiliki nilai tukar sebesar %. Total saldo jika dikonversi: %.', 
            exchange_code, 
            exchange_value, 
            ROUND(user_balance / exchange_value, 3);
    END LOOP;
END;
$$ LANGUAGE plpgsql;

-- Panggil function untuk konversi kurs mata uang
DO $$
BEGIN
    PERFORM show_exchange_rate(1);
END;
$$;


-- Insert into income
INSERT INTO income (user_id, amount, source, description) VALUES
(4, 125000, 6, 'Penjualan Saham')

-- Insert into expense
INSERT INTO expense (user_id, amount, source, description) VALUES
(4, 125000, 6, 'Pembelian Saham Saham')

-- Backup data dan jalankan pada terminal
pg_dump -U postgres -d financial_project -f "12_BackupSistemManajemenKeuanganPersonal.sql"

-- Restore data dan jalankan pada terminal
psql -U postgres -d financial_project -f "12_BackupSistemManajemenKeuanganPersonal.sql"

-- Ekspor data ke csv
COPY (SELECT * FROM monthly_financial_summary) to 'D:/D-III Teknologi Informasi/Semester 3/Sistem Basis Data/Proyek/financial.csv' DELIMITER ',' CSV HEADER;