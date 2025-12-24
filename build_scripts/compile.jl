using StaticCompiler
using StaticArrays

# Scriptin bulunduğu klasörü baz alıyoruz (@__DIR__)
# Böylece komutu nereden çalıştırdığının önemi kalmıyor.
SCRIPT_DIR = @__DIR__
PROJECT_ROOT = dirname(SCRIPT_DIR) # Bir üst klasör (LevyFractal_Native)

# Kaynak kod yolu
src_path = joinpath(PROJECT_ROOT, "src", "ifs_engine.jl")
include(src_path)

println("🚀 Derleme işlemi başlıyor...")
println("📂 Kaynak: $src_path")

# Çıktı yolu (Tam yol - Absolute Path)
lib_path = joinpath(PROJECT_ROOT, "libs", "lib_fractal.so")

# Klasör yoksa oluştur (Garanti olsun)
if !isdir(dirname(lib_path))
    mkdir(dirname(lib_path))
end

# Derle
compile_shlib(
    generate_ifs, 
    (Int, Int, Ptr{Float64}, Int, Ptr{Float64}), 
    lib_path
)

println("✅ İşlem tamamlandı!")
println("📍 Dosya şuraya kaydedildi: $lib_path")
