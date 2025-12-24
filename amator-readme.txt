LevyFractal_Native/
├── libs/                  # ÇIKTI: Derlenen .so dosyası buraya düşecek (Artifact)
├── src/                   # KAYNAK: Saf Julia matematik motoru
│   └── ifs_engine.jl      # (LLVM'siz, saf hesaplama kodu)
├── build_scripts/         # İNŞA: Derleme talimatları
│   └── compile.jl         # (StaticCompiler'ı çalıştıran script)
├── main.py                # SÜRÜCÜ: Python patron dosyası (Levy C katsayıları burada)
└── Project.toml           # ORTAM: Julia bağımlılıkları (StaticCompiler, StaticArrays)
