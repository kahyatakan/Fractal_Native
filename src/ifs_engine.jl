# Bu dosya, StaticCompiler ile derlenecek olan saf Julia kodudur.
# Standart kütüphaneler (Base) dışında hiçbir ağır bağımlılık kullanmaz.

# --- 1. Rastgele Sayı Üreteci (Xorshift RNG) ---
# Julia'nın rand() fonksiyonu çok karmaşık olduğu için (ve GC kullandığı için)
# buraya C seviyesinde çalışan, çok hızlı ve basit bir RNG yazıyoruz.
function next_rand(state::UInt64)::Tuple{UInt64, Float64}
    x = state
    x ⊻= x << 13
    x ⊻= x >> 7
    x ⊻= x << 17
    # 0.0 ile 1.0 arasında bir Float üretir
    # typemax(UInt64) bir sabittir, bölme işlemi bize oranı verir.
    return x, Float64(x) / 1.8446744073709552e19 
end

# --- 2. Ana Motor Fonksiyonu ---
# Python'dan çağrılacak olan fonksiyon budur.
# n_points: Üretilecek nokta sayısı
# seed: Rastgelelik tohumu (farklı şekiller için değiştirilebilir)
# rules: Fraktal kurallarını içeren düzleştirilmiş dizi (Pointer)
# n_rules: Kaç tane kural olduğu
# buffer: Sonuçların (x, y) yazılacağı bellek alanı (Pointer)

function generate_ifs(n_points::Int, seed::Int, rules::Ptr{Float64}, n_rules::Int, buffer::Ptr{Float64})
    
    # Seed 0 gelirse varsayılan bir değer ata, yoksa hepsi 0 olur :)
    rng_state = UInt64(seed == 0 ? 123456789 : seed)
    
    # Başlangıç koordinatları
    x = 0.0
    y = 0.0
    
    # Buffer'a yazmak için indeks (1'den başlar çünkü pointer aritmetiği yapacağız)
    ptr_idx = 1
    
    for i in 1:n_points
        # Yeni rastgele sayı çek
        rng_state, r = next_rand(rng_state)
        
        # Hangi kuralı uygulayacağımızı seçelim.
        # Python tarafında olasılıkları "kümülatif" (birikimli) olarak göndereceğiz.
        # Örn: [0.01, 0.86, 0.93, 1.0] gibi.
        
        # Her kural 7 sayıdan oluşur: [a, b, c, d, e, f, threshold]
        # Memory Layout:
        # Kural 0: rules[1]..rules[7]
        # Kural 1: rules[8]..rules[14]
        
        for k in 0:(n_rules-1)
            offset = k * 7
            
            # Kuralın eşik değerini (threshold) oku (7. eleman)
            # unsafe_load: C dilindeki pointer dereference (*) gibidir.
            threshold = unsafe_load(rules, offset + 7)
            
            if r <= threshold
                # Bingo! Kuralı bulduk. Şimdi katsayıları yükleyelim.
                a = unsafe_load(rules, offset + 1)
                b = unsafe_load(rules, offset + 2)
                c = unsafe_load(rules, offset + 3)
                d = unsafe_load(rules, offset + 4)
                e = unsafe_load(rules, offset + 5)
                f = unsafe_load(rules, offset + 6)
                
                # IFS Matris İşlemi:
                # x' = ax + by + e
                # y' = cx + dy + f
                new_x = (a * x) + (b * y) + e
                new_y = (c * x) + (d * y) + f
                
                x = new_x
                y = new_y
                
                # Döngüden çık, sonraki noktaya geç
                break 
            end
        end
        
        # Hesaplanan noktayı Python'un verdiği belleğe yaz
        # Buffer yapısı: [x1, y1, x2, y2, x3, y3, ...]
        unsafe_store!(buffer, x, ptr_idx)
        unsafe_store!(buffer, y, ptr_idx + 1)
        ptr_idx += 2
    end
    
    return 0 # Başarılı dönüş kodu (C tarzı)
end
