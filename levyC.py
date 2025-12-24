import ctypes
import numpy as np
import matplotlib.pyplot as plt
import time
import os

# --- 1. AYARLAR ---
# Dosya yollarını sağlama alalım
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
# Dikkat: Terminal çıktına göre dosya adı 'generate_ifs.so' olmuş.
LIB_PATH = os.path.join(SCRIPT_DIR, "libs", "generate_ifs.so")

# Fraktal Ayarları (Levy C Curve)
N_POINTS = 500_000  # Yarım milyon nokta!
SEED = 42

# --- 2. KÜTÜPHANEYİ YÜKLE ---
try:
    # Linux için CDLL
    lib = ctypes.CDLL(LIB_PATH)
except OSError as e:
    print(f"HATA: Kütüphane bulunamadı veya yüklenemedi!\nYol: {LIB_PATH}\nHata: {e}")
    exit(1)

# Fonksiyon imzasını C tipleriyle tanımlıyoruz:
# generate_ifs(n_points::Int, seed::Int, rules::Ptr, n_rules::Int, buffer::Ptr)
lib.generate_ifs.argtypes = [
    ctypes.c_long,                  # n_points
    ctypes.c_long,                  # seed
    ctypes.POINTER(ctypes.c_double),# rules array pointer
    ctypes.c_long,                  # n_rules
    ctypes.POINTER(ctypes.c_double) # output buffer pointer
]
lib.generate_ifs.restype = ctypes.c_long

# --- 3. FRAKTAL KURALLARI (LEVY C CURVE) ---
# Kurallar: [a, b, c, d, e, f, probability]
# Levy C Curve 2 kuraldan oluşur, her ikisi de %50 olasılıklıdır.
levy_rules = [
    # Kural 1:
    0.5, -0.5, 0.5, 0.5, 0.0, 0.0, 0.50,
    # Kural 2: (Olasılık kümülatif artar -> 0.50 + 0.50 = 1.0)
    0.5,  0.5, -0.5, 0.5, 0.5, 0.5, 1.00
]

# Python listesini C array'ine (ctype) çevir
RuleArrayType = ctypes.c_double * len(levy_rules)
c_rules = RuleArrayType(*levy_rules)

# --- 4. BELLEK HAZIRLIĞI ---
# Çıktı için boş bir Numpy array oluşturuyoruz (x ve y için 2 sütun)
# Bu array bellekte bitişik (contiguous) olmalı.
data = np.zeros((N_POINTS * 2), dtype=np.float64)
# Verinin bellek adresini (pointer) al
data_ptr = data.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

# --- 5. MOTORU ÇALIŞTIR ---
print(f" {N_POINTS} nokta üretiliyor (Native Julia Motoru)...")
t0 = time.time()

# SİHİRLİ AN: Python, Julia binary'sini çağırıyor
lib.generate_ifs(N_POINTS, SEED, c_rules, 2, data_ptr)

t1 = time.time()
print(f" Tamamlandı! Süre: {t1 - t0:.6f} saniye")

# --- 6. GÖRSELLEŞTİRME ---
# Düz array'i (x1, y1, x2, y2...) tekrar (N, 2) matrisine çevirip ayıralım
reshaped_data = data.reshape((N_POINTS, 2))
x = reshaped_data[:, 0]
y = reshaped_data[:, 1]

print(" Çizim yapılıyor...")
plt.figure(figsize=(10, 10), facecolor='black')
# Siyah üzerine beyaz/camgöbeği noktalar
plt.scatter(x, y, s=0.1, c='cyan', alpha=0.5, marker='.')
plt.axis('off') # Eksenleri kapat
plt.title(f"Levy C Curve - {N_POINTS} Points", color='white')
plt.show()
