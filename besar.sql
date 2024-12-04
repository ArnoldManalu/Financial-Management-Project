CREATE DATABASE financial_project;

CREATE TABLE users(
	user_id SERIAL PRIMARY KEY,
	name VARCHAR(255) NOT NULL,
	email VARCHAR(255) NOT NULL UNIQUE,
	password VARCHAR(255) NOT NULL,
	balance NUMERIC(12, 2) CHECK (balance >= 0)
	
);

-- create users
INSERT INTO users(name, email, password, balance)
VALUES ('Vici', 'xixi@gmail.com', 'password123', 1000000),
	   ('James', 'jems@gmail.com', 'password789', 500000),
	   ('Jessica', 'jess@gmail.com', 'password111', 700000);

select * from users;

CREATE TABLE income(
	income_id SERIAL PRIMARY KEY,
	user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
	amount NUMERIC(12, 2) NOT NULL,
	sumber VARCHAR(255) NOT NULL,
	tanggal_transaksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	description VARCHAR(255) NOT NULL
);



CREATE TABLE expense(
	expense_id SERIAL PRIMARY KEY,
	user_id INTEGER REFERENCES users(user_id) ON DELETE CASCADE,
	amount NUMERIC(12, 2) NOT NULL,
	sumber VARCHAR(255) NOT NULL,
	tanggal_transaksi TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
	description VARCHAR(255) NOT NULL
);

-- Create View untuk menampilkan saldo pengguna
CREATE VIEW user_balance_view AS
SELECT
    u.user_id,
    u.name,
    u.email,
    u.balance AS current_balance,
    COALESCE(SUM(i.amount), 0) AS total_income,
    COALESCE(SUM(e.amount), 0) AS total_expense,
    (u.balance + COALESCE(SUM(i.amount), 0) - COALESCE(SUM(e.amount), 0)) AS updated_balance
FROM users u
LEFT JOIN income i ON u.user_id = i.user_id
LEFT JOIN expense e ON u.user_id = e.user_id
GROUP BY u.user_id;

/* Stored Procedure */

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

    -- Periksa apakah saldo pengguna sudah di bawah saldo minimum
    IF (SELECT balance FROM users WHERE user_id = NEW.user_id) < 
       (SELECT minimum_balance FROM users WHERE user_id = NEW.user_id) THEN
        RAISE NOTICE 'Peringatan: Saldo pengguna % sudah di bawah saldo minimum.', NEW.user_id;
    END IF;

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

    -- Periksa apakah saldo pengguna sudah di bawah saldo minimum
    IF (SELECT balance FROM users WHERE user_id = NEW.user_id) < 
       (SELECT minimum_balance FROM users WHERE user_id = NEW.user_id) THEN
        RAISE NOTICE 'Peringatan: Saldo pengguna % sudah di bawah saldo minimum.', NEW.user_id;
    END IF;

    -- Lanjutkan penyisipan data ke tabel income
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;




-- Fungsi Trigger Menambah dan Mengurangi saldo 
-- Trigger untuk mengurangi saldo sebelum menyisipkan data ke tabel expense
CREATE TRIGGER trigger_reduce_balance
BEFORE INSERT ON expense
FOR EACH ROW
EXECUTE FUNCTION reduce_balance();

-- Trigger untuk menambah saldo sebelum menyisipkan data ke tabel income
CREATE TRIGGER trigger_add_balance
BEFORE INSERT ON income
FOR EACH ROW
EXECUTE FUNCTION add_balance();

-- Stored Procedure untuk Melihat Saldo Pengguna
CREATE OR REPLACE PROCEDURE view_user_balance(
    p_user_id INTEGER
)
LANGUAGE plpgsql
AS
$$
BEGIN
    -- Menampilkan saldo terbaru pengguna berdasarkan view user_balance_view
    PERFORM * FROM user_balance_view WHERE user_id = p_user_id;
END;
$$;

-- pemanggilan 
CALL view_user_balance(1);  -- Untuk melihat saldo pengguna dengan user_id = 1
SELECT * FROM user_balance_view WHERE user_id = 1;


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

-- pemanggilan
SELECT * FROM total_income_expense_for_user(1);


--Cek Pengeluaran dengan Saldo Minimum
INSERT INTO expense(user_id, amount, sumber, description) 
VALUES (1, 50000, 'Transportasi', 'Naik taksi');

INSERT INTO expense(user_id, amount, sumber, description) 
VALUES (2, 500000, 'Investasi', 'Bitcoin');

INSERT INTO expense(user_id, amount, sumber, description) 
VALUES (3, 650000, 'Cicilan', 'Cicilan Iphone');

-- Cek Pemasukan dengan Saldo Minimum
INSERT INTO income(user_id, amount, sumber, description) 
VALUES (1, 100000, 'Gaji', 'Gaji bulan Desember');

INSERT INTO income(user_id, amount, sumber, description) 
VALUES (3, 100000, 'Lembur', 'Gaji Lembur November');


select * from expense;
select * from income ;
select * from users;