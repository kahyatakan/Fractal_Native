using StaticCompiler
using StaticArrays
t_start = time()
# Yolları belirle
SCRIPT_DIR = @__DIR__
ROOT_DIR = dirname(SCRIPT_DIR)
LIB_DIR = joinpath(ROOT_DIR, "libs")
TARGET_NAME = "generate_ifs.so"
TARGET_PATH = joinpath(LIB_DIR, TARGET_NAME)

# Libs klasörü yoksa oluştur
if !isdir(LIB_DIR)
    mkdir(LIB_DIR)
end

# --- MOTOR KODU (IFS ENGINE) ---
# Burası değişmedi, aynı matematik
function generate_ifs(n_points::Int, seed::Int, rules::Ptr{Float64}, n_rules::Int, out_ptr::Ptr{Float64})
    rng_state = UInt64(seed)
    x, y = 0.0, 0.0
    
    # Pointer'ı array gibi kullan
    output = unsafe_wrap(Array, out_ptr, n_points * 2)
    rule_array = unsafe_wrap(Array, rules, n_rules * 7)

    for i in 1:n_points
        # Random (LCG)
        rng_state = 6364136223846793005 * rng_state + 1442695040888963407
        r = (rng_state >> 33) / 2147483648.0 

        # Kural Seçimi
        current_prob = 0.0
        selected_rule = 0
        
        for k in 0:(n_rules-1)
            prob = rule_array[k*7 + 7] # 7. eleman olasılık
            if r <= prob
                selected_rule = k
                break
            end
        end

        # Hesaplama
        idx = selected_rule * 7
        a = rule_array[idx + 1]
        b = rule_array[idx + 2]
        c = rule_array[idx + 3]
        d = rule_array[idx + 4]
        e = rule_array[idx + 5]
        f = rule_array[idx + 6]

        new_x = a * x + b * y + e
        new_y = c * x + d * y + f
        
        x, y = new_x, new_y

        # Kaydet
        output[2*i - 1] = x
        output[2*i] = y
    end
    return 0
end

print("🚀 Derleme işlemi başlıyor...\n")

# Derle (Bu işlem 'generate_ifs.so' adında bir KLASÖR oluşturabilir)
compile_shlib(
    generate_ifs,
    (Int, Int, Ptr{Float64}, Int, Ptr{Float64}),
    LIB_DIR,
    TARGET_NAME
)

# --- DÜZELTME OTOMASYONU ---
# StaticCompiler bazen çıktı olarak dosya yerine klasör veriyor.
# Eğer çıktı bir klasörse, içindeki asıl dosyayı kurtarıp klasörü silelim.

if isdir(TARGET_PATH)
    println("⚠️  StaticCompiler çıktıyı klasör içine gömdü. Düzeltiliyor...")
    
    # Klasörün içindeki asıl dosya (genelde aynı isimdedir)
    inner_file = joinpath(TARGET_PATH, TARGET_NAME)
    
    if isfile(inner_file)
        # 1. İçerdeki dosyayı geçici bir isme taşı
        temp_file = joinpath(LIB_DIR, "temp_artifact.so")
        mv(inner_file, temp_file, force=true)
        
        # 2. O gereksiz klasörü sil
        rm(TARGET_PATH, recursive=true)
        
        # 3. Geçici dosyayı asıl ismine kavuştur
        mv(temp_file, TARGET_PATH, force=true)
        println("✅ Yapı düzeltildi: Dosya dışarı çıkarıldı.")
    else
        println("❌ HATA: Beklenen dosya klasör içinde bulunamadı!")
    end
end

t_end = time()
elapsed = round(t_end - t_start; digits=2)
println("✨ İşlem Tamam! Kütüphane hazır: $TARGET_PATH")
println("🕒 Total Compile Time: $elapsed sec")
