import ctypes
import numpy as np
import matplotlib.pyplot as plt
import time
import os

# --- AYARLAR ---
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
LIB_PATH = os.path.join(SCRIPT_DIR, "libs", "generate_ifs.so")

# Dragon detay sever, 1 Milyon nokta ile hakkını verelim
N_POINTS = 1_000_000 
SEED = 42

# --- MOTOR BAĞLANTISI ---
try:
    lib = ctypes.CDLL(LIB_PATH)
except OSError as e:
    print(f"HATA: {e}")
    exit(1)

lib.generate_ifs.argtypes = [ctypes.c_long, ctypes.c_long, ctypes.POINTER(ctypes.c_double), ctypes.c_long, ctypes.POINTER(ctypes.c_double)]

# --- HEIGHWAY DRAGON KURALLARI ---
# Bu fraktal 2 kuraldan oluşur.
# Kural 1: 45 derece döndür ve küçült
# Kural 2: 135 derece döndür, küçült ve kaydır

dragon_rules = [
    # Format: [a, b, c, d, e, f, probability]
    
    # Kural 1 (%50)
    # x' = 0.5*x - 0.5*y
    # y' = 0.5*x + 0.5*y
    0.5, -0.5, 0.5, 0.5, 0.0, 0.0, 0.5,
    
    # Kural 2 (%50) -> Kümülatif 1.0
    # x' = -0.5*x - 0.5*y + 1.0
    # y' =  0.5*x - 0.5*y
    -0.5, -0.5, 0.5, -0.5, 1.0, 0.0, 1.0
]

RuleArrayType = ctypes.c_double * len(dragon_rules)
c_rules = RuleArrayType(*dragon_rules)
n_rules = 2

# --- BELLEK & ÇALIŞTIRMA ---
data = np.zeros((N_POINTS * 2), dtype=np.float64)
data_ptr = data.ctypes.data_as(ctypes.POINTER(ctypes.c_double))

print(f"🐉 {N_POINTS} nokta ile Ejderha Eğrisi uyandırılıyor...")
t0 = time.time()

lib.generate_ifs(N_POINTS, SEED, c_rules, n_rules, data_ptr)

t1 = time.time()
print(f" Tamamlandı! Süre: {t1 - t0:.6f} saniye")

# --- GÖRSELLEŞTİRME ---
reshaped_data = data.reshape((N_POINTS, 2))
x = reshaped_data[:, 0]
y = reshaped_data[:, 1]

plt.figure(figsize=(12, 8), facecolor='black')
# Ejderha için ateş kırmızısı veya turuncu yakışır
plt.scatter(x, y, s=0.1, c='orangered', alpha=0.5, marker='.')
plt.axis('off')
plt.title(f"Heighway Dragon - {N_POINTS} Points", color='white')
plt.show()
