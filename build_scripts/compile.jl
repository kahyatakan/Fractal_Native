using StaticCompiler
using StaticArrays

# ⏱️ KRONOMETRE BAŞLAT
t_start = time()

# Yolları belirle
SCRIPT_DIR = @__DIR__
ROOT_DIR = dirname(SCRIPT_DIR)
LIB_DIR = joinpath(ROOT_DIR, "libs")

# Düzeltme: StaticCompiler .so ekleyeceği için isimden çıkarıyoruz
TARGET_NAME = "generate_ifs" 
# Ama dosya yolunu kontrol ederken uzantıyı biz ekliyoruz
TARGET_PATH = joinpath(LIB_DIR, TARGET_NAME * ".so")

# Libs klasörü yoksa oluştur
if !isdir(LIB_DIR)
    mkdir(LIB_DIR)
end

# --- MOTOR KODU (SAF POINTER VERSİYONU) ---
# unsafe_wrap yerine doğrudan unsafe_load/store kullanarak
# Julia Runtime bağımlılığını tamamen ortadan kaldırıyoruz.

function generate_ifs(n_points::Int, seed::Int, rules::Ptr{Float64}, n_rules::Int, out_ptr::Ptr{Float64})
    rng_state = UInt64(seed)
    x, y = 0.0, 0.0
    
    for i in 1:n_points
        # Random (LCG)
        rng_state = 6364136223846793005 * rng_state + 1442695040888963407
        r = (rng_state >> 33) / 2147483648.0 

        # Kural Seçimi
        selected_rule = 0
        
        for k in 0:(n_rules-1)
            # Pointer Aritmetiği: rules[k*7 + 7]
            # Julia'da pointer erişimi 1 tabanlıdır (offset + 1)
            prob = unsafe_load(rules, k*7 + 7)
            if r <= prob
                selected_rule = k
                break
            end
        end

        # Hesaplama
        base_idx = selected_rule * 7
        # Verileri pointerdan doğrudan okuyoruz
        a = unsafe_load(rules, base_idx + 1)
        b = unsafe_load(rules, base_idx + 2)
        c = unsafe_load(rules, base_idx + 3)
        d = unsafe_load(rules, base_idx + 4)
        e = unsafe_load(rules, base_idx + 5)
        f = unsafe_load(rules, base_idx + 6)

        new_x = a * x + b * y + e
        new_y = c * x + d * y + f
        
        x, y = new_x, new_y

        # Kaydetme: out_ptr[2*i - 1] ve out_ptr[2*i]
        unsafe_store!(out_ptr, x, 2*i - 1)
        unsafe_store!(out_ptr, y, 2*i)
    end
    return 0
end

print("🚀 Derleme işlemi başlıyor (Saf Pointer Modu)...\n")

# Derle
compile_shlib(
    generate_ifs,
    (Int, Int, Ptr{Float64}, Int, Ptr{Float64}),
    LIB_DIR,
    TARGET_NAME
)

# --- DÜZELTME OTOMASYONU ---
# StaticCompiler çıktıyı bazen 'generate_ifs.so' adında bir KLASÖR olarak veriyor.
# İçindeki dosyayı kurtarıp temizlik yapıyoruz.

raw_output_path = joinpath(LIB_DIR, TARGET_NAME * ".so") # .so eklenmiş hali

if isdir(raw_output_path)
    # println("⚠️  StaticCompiler çıktıyı klasör içine gömdü. Düzeltiliyor...")
    
    # Klasörün içindeki asıl dosya (genelde aynı isimdedir ama bazen .so fazladan olabilir)
    # İçerideki dosyaları tarayalım
    files_in_folder = readdir(raw_output_path)
    # .so ile biten veya "generate_ifs" içeren dosyayı bul
    target_file = ""
    for f in files_in_folder
        if occursin(".so", f) && !occursin(".o", f) # .o dosyası değilse
            target_file = joinpath(raw_output_path, f)
            break
        end
    end

    if isfile(target_file)
        temp_file = joinpath(LIB_DIR, "temp_artifact.so")
        mv(target_file, temp_file, force=true) # Dışarı al
        rm(raw_output_path, recursive=true)    # Klasörü sil
        mv(temp_file, raw_output_path, force=true) # Yerine koy
        # println("✅ Dosya yapısı düzeltildi.")
    else
        println("❌ HATA: Klasör içinde uygun .so dosyası bulunamadı!")
    end
end

# ⏱️ KRONOMETRE BİTİR
t_end = time()
elapsed = round(t_end - t_start; digits=2)

println("✨ İşlem Tamam! Kütüphane hazır: $raw_output_path")
println("🕒 Toplam Süre: $elapsed saniye")
