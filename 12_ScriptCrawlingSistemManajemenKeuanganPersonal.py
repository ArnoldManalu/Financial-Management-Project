# -*- coding: utf-8 -*-
"""12_ScriptCrawling[Sistem Manajemen Keuangan Personal].ipynb

Automatically generated by Colab.

Original file is located at
    https://colab.research.google.com/drive/1umMbiX3rg27iPmmGcoppGPD6A230xN3X
"""

!pip install requests beautifulsoup4 pandas

# Import library
import requests
from bs4 import BeautifulSoup
import pandas as pd
import csv

url = "https://www.bni.co.id/id-id/beranda/informasi-valas"

# Mengambil halaman HTML
response = requests.get(url)
if response.status_code == 200:
    print("Berhasil mengambil data dari situs!")
else:
    print(f"Gagal mengambil data. Kode status: {response.status_code}")

# Parsing HTML dengan BeautifulSoup
soup = BeautifulSoup(response.text, 'html.parser')

# Mencari tabel data kurs valas
table = soup.find('table')  # Mengambil elemen tabel pertama
if table:
    print("Tabel ditemukan!")
else:
    print("Tabel tidak ditemukan.")

# Ekstraksi isi tabeltabel tanpa kolom ketiga
rows = []
for row in table.find_all('tr')[1:]:  # Skip header
    cells = [cell.text.strip() for i, cell in enumerate(row.find_all('td')) if i != 2]
    if cells:
        cells[1] = cells[1].replace('.', '')
        cells[1] = cells[1].replace(',', '.')
        rows.append(cells)

# Membuat DataFrame dengan pandas
df = pd.DataFrame(rows)

# Menampilkan data dalam bentuk tabel
print("Data kurs valas:")
print(df)

# Menyimpan data ke file CSV
df.to_csv("kurs_valas_bni.csv", index=False, header=False, sep=';', quoting=csv.QUOTE_NONE, escapechar=' ')
print("Data berhasil disimpan ke file kurs_valas_bni.csv")
from google.colab import files
files.download('kurs_valas_bni.csv')