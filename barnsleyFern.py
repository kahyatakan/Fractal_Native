import ctypes
import numpy as np
import matplotlib.pyplot as plt
import time
import os

# --- AYNI MOTORU KULLANIYORUZ ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_PATH = os.path.join(SCRIPT_DIR, "libs", "generate_ifs.so") # Aynı .so dosyası!

# Nokta sayısını biraz daha artıralım, Fern detay sever
N_POINTS = 1_000_000 
SEED = 12345

# Kütüphaneyi yükle
try:
    lib = ctypes.CDLL(LIB_PATH)
except OSError as e:
    print(f"HATA: {e}")
    exit(1)

lib.generate_ifs.argtypes = [ctypes.c_long, ctypes.c_long, ctypes.POINTER(ctypes.c_double), ctypes.c_long, ctypes.POINTER(ctypes.c_double)]

# --- TEK DEĞİŞEN YER BURASI: KURALLAR ---
# Barnsley Fern Katsayıları
# Format: [a, b, c, d, e, f, kümülatif_olasılık]
fern_rules = [
    # 1. Gövde (%1 olasılık) -> 0.01
    0.0, 0.0, 0.0, 0.16, 0.0, 0.0, 0.01,
    
    # 2. Küçük Yapraklar (%85 olasılık) -> 0.01 + 0.85 = 0.86
    0.85, 0.04, -0.04, 0.85, 0.0, 1.6, 0.86,
    
    # 3. Sol Büyük Yaprak (%7 olasılık) -> 0.86 + 0.07 = 0.93
    0.20, -0.26, 0.23, 0.22, 0.0, 1.6, 0.93,
    
    # 4. Sağ Büyük Yaprak (%7 olasılık) -> 0.93 + 0.07 = 1.00
    -0.15, 0.28, 0.26, 0.24, 0.0, 0.44, 1.00
]

RuleArrayType = ctypes.c_double * len(fern_rules)
c_rules = RuleArrayType(*fern_rules)
n_rules = 4 # Fern için 4 kural var

# Bellek Hazırlığı
data = np.zeros((N_POINTS * 2), dtype=np.float64)
data_ptr = data.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

print(f"🌿 {N_POINTS} nokta ile Eğrelti Otu üretiliyor...")
t0 = time.time()

# Motoru Ateşle!
lib.generate_ifs(N_POINTS, SEED, c_rules, n_rules, data_ptr)

t1 = time.time()
print(f"✅ Tamamlandı! Süre: {t1 - t0:.6f} saniye")

# Görselleştirme
reshaped_data = data.reshape((N_POINTS, 2))
x = reshaped_data[:, 0]
y = reshaped_data[:, 1]

plt.figure(figsize=(10, 10), facecolor='black')
# Eğrelti otuna yeşil yakışır
plt.scatter(x, y, s=0.1, c='lime', alpha=0.3, marker='.')
plt.axis('off')
plt.title(f"Barnsley Fern (Native Engine) - {t1 - t0:.4f} sec", color='white')
plt.show()
