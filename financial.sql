CREATE DATABASE financial_projects;

-- Membuat tabel users
CREATE TABLE users(
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    email VARCHAR(255) NOT NULL,
    password VARCHAR(255) NOT NULL,
    balance NUMERIC(12, 2) CHECK (balance >= 0)
);

-- Membuat tabel income (pemasukan)
CREATE TABLE income(
    income_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    sumber VARCHAR(255) NOT NULL,
    tanggal_transaksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255) NOT NULL
);

-- Membuat tabel expense (pengeluaran)
CREATE TABLE expense(
    expense_id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
    amount NUMERIC(12, 2) NOT NULL,
    sumber VARCHAR(255) NOT NULL,
    tanggal_transaksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    description VARCHAR(255) NOT NULL
);

-- Membuat VIEW untuk pengeluaran bulanan
CREATE VIEW monthly_expense AS
SELECT
    user_id,
    DATE_TRUNC('month', tanggal_transaksi) AS bulan,
    SUM(amount) AS total_pengeluaran
FROM expense
GROUP BY DATE_TRUNC('month', tanggal_transaksi), user_id
ORDER BY bulan;

-- Fungsi untuk peringatan saldo minimum
CREATE OR REPLACE FUNCTION peringatan_saldo()
RETURNS TRIGGER AS $$
BEGIN

	IF (SELECT balance FROM users WHERE user_id = NEW.user_id) < 100000 THEN
    	RAISE NOTICE 'Peringatan: Saldo pengguna % sudah di bawah saldo minimum (100000).', NEW.user_id;
	END IF;
	
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk memberikan peringatan jika saldo di bawah minimum setelah pengeluaran
CREATE TRIGGER trigger_minimum_balance_warning_expense
AFTER INSERT ON expense
FOR EACH ROW
EXECUTE FUNCTION peringatan_saldo();


-- Fungsi untuk mengurangi saldo ketika ada pengeluaran
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

    -- Lanjutkan penyisipan data ke tabel expense
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger untuk mengurangi saldo saat ada pengeluaran
CREATE TRIGGER trigger_reduce_balance
BEFORE INSERT ON expense
FOR EACH ROW
EXECUTE FUNCTION reduce_balance();

-- Fungsi untuk menambah saldo ketika ada pemasukan
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

-- Trigger untuk menambah saldo saat ada pemasukan
CREATE TRIGGER trigger_add_balance
BEFORE INSERT ON income
FOR EACH ROW
EXECUTE FUNCTION add_balance();


-- Insert data user
INSERT INTO users(name, email, password, balance) VALUES
('Vanesa', 'vanesa@gmail.com', 'vanesa123', 100000),
('James', 'james@gmail.com', 'james123', 1000000),
('Arnold', 'arnold@gmail.com', 'arnold123', 100000),
('Jessica', 'jessica@gmail.com', 'jessica123', 100000);


-- Insert data Income
INSERT INTO income(user_id, amount, sumber, description, tanggal_transaksi) VALUES 
(4, 5000000, 'Gaji', 'Gajian bulan Desember', '2022-11-01 09:00:00'),
(1, 250000, 'Trading', 'Hasil dari trading', '2020-11-02 15:30:00'),
(1, 150000, 'Freelance', 'Proyek Freelance', '2021-10-03 14:15:00'),
(3, 400000, 'Usaha', 'Penjualan Produk', '2024-12-04 11:45:00'),
(2, 500000, 'Proyek', 'Pendapatan Proyek', '2022-08-01 13:20:00'),
(2, 160000, 'Investasi', 'Keuntungan investasi', '2021-10-02 10:50:00'),
(3, 120000, 'Affiliate', 'Komisi penjualan online', '2022-02-03 16:30:00'),
(4, 110000, 'Lembur', 'Bonus lembur', '2024-03-04 19:00:00'),
(2, 115000, 'Dividen', 'Dividen saham', '2022-02-02 09:10:00'),
(3, 450000, 'Trading', 'Hasil dari trading', '2023-01-03 20:00:00'),
(1, 105000, 'Investasi', 'keuntungan investasi', '2021-03-01 18:20:00'),
(3, 400000, 'Trading', 'Hasil dari trading', '2022-04-02 12:10:00'),
(2, 3000000, 'Gaji', 'Gaji Bulanan', '2024-05-04 09:40:00'),
(4, 200000, 'Investasi', 'keuntungan investasi', '2022-06-01 14:50:00'),
(2, 100000, 'Proyek', 'Pendapatan Proyek', '2024-05-02 15:25:00'),
(3, 300000, 'Proyek', 'Pendapatan Proyek', '2021-06-03 10:40:00'),
(4, 200000, 'Lembur', 'Bonus lembur', '2021-04-04 16:00:00'),
(1, 310000, 'Investasi', 'Keuntungan investasi', '2022-02-01 11:30:00'),
(3, 4000000, 'Gaji', 'Gaji Bulanan', '2024-10-02 17:00:00'),
(2, 140000, 'Dividen', 'Diveden Saham', '2022-05-03 08:50:00'),
(4, 320000, 'Affiliate', 'Komisi penjualan online', '2021-07-04 14:10:00');


-- Insert data expense
INSERT INTO expense(user_id, amount, sumber, description, tanggal_transaksi) VALUES 
(1, 250000, 'Transportasi', 'Naik taksi', '2023-12-03 08:40:02');
(1, 40000, 'Tagihan', 'Tagihan Listrik', '2023-09-01 10:15:20'),
(3, 100000, 'Belanja', 'Belanja Bulanan', '2023-10-02 14:20:35'),
(2, 75000, 'Hiburan', 'Tiket Bioskop', '2023-03-03 18:50:00'),
(3, 120000, 'Makanan', 'Makan Siang', '2023-03-04 12:30:25'),
(2, 85000, 'Affiliate', 'Komisi penjualan online', '2023-10-30 09:00:10'),
(4, 25000, 'Jual Barang', 'Penjualan laptop bekas', '2023-06-02 17:45:50'),
(2, 60000, 'Royalti', 'Royalti dari buku yang diterbitkan', '2023-04-01 11:25:40'),
(4, 250000, 'Usaha', 'Keuntungan dari penjualan makanan ringan', '2023-03-03 19:20:15'),
(1, 50000, 'Jasa', 'Penghasilan dari jasa penulisan artikel', '2023-02-04 08:10:05'),
(2, 90000, 'Dropship', 'Keuntungan dari dropship produk kecantikan', '2023-10-03 15:25:35'),
(3, 250000, 'Gaji', 'Pendapatan kerja part-time', '2023-12-02 10:40:50'),
(1, 300000, 'Event', 'Pendapatan dari event organizer', '2023-01-30 14:50:30'),
(1, 45000, 'Hadiah', 'Hadiah dari lomba coding', '2023-02-01 20:15:20'),
(2, 65000, 'Investasi', 'Keuntungan investasi emas', '2023-03-02 16:35:25'),
(4, 180000, 'Freelance', 'Proyek desain logo perusahaan', '2023-04-03 13:40:45'),
(2, 150000, 'Sewa Properti', 'Pendapatan dari menyewakan rumah', '2023-12-04 09:30:10'),
(3, 70000, 'Jual Barang', 'Penjualan ponsel bekas', '2023-05-02 18:50:00'),
(2, 275000, 'Gaji', 'Pendapatan dari pekerjaan kontrak', '2023-06-01 08:25:15'),
(3, 125000, 'Trading', 'Keuntungan dari trading forex', '2023-07-03 07:50:20'),
(4, 100000, 'Pembuatan Website', 'Penghasilan dari membuat website perusahaan', '2023-08-04 11:00:30');


-- Ekspor data ke csv
COPY (SELECT * FROM monthly_expense) to 'D:/financial.csv' DELIMITER ',' CSV HEADER;