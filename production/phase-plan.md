# Sector 9 — Geliştirme fazları

2026-10-22 • Kullanıcının onayladığı mekanik-önce geliştirme sırası.
Kaynak: [oyun özeti](../design/game-brief.md). Bu belge orijinal tasarımdaki eksik gömülü yol haritasının yerine geliştirme sırasını belirler; oyunun co-op hedefini değiştirmez.

## Faz 1 — Tek oyunculu mekanik laboratuvarı

**Amaç:** bütün oynanış davranışlarının işlevsel örneklerini aynı test ortamında deneyebilmek. Yalnız hareket/ateş demosu değil; roller, eşyalar, AI, engeller, Yönetmen ve takım eylemlerinin solo tetiklenebilir karşılıkları da kapsamda.

**Teslim:** ayarlanabilir değerler, tekrar kurulabilir test senaryoları, dört role erişim, kontrollü yardımcı karakterler, kısa çekirdek/tahliye provası. Sanat sade; mekanik geri bildirimi okunabilir.

**Çıkış kapısı:** [mekanik listesinde](phase-1-mechanics.md) bütün kapsam satırları kanıtla değerlendirilir; bloke/bilinmeyen satırlar açıkça görünür. Kullanıcı alışılabilirlik ve hissiyatı açıkça onaylar. Yardımcıyla test, gerçek co-op eğlencesinin/ağ davranışının kanıtı değildir. Onay olmadan Faz 2 başlamaz.

**Şu an:** P1-01 hareket/kamera temeli kodlandı; ana projede import ve 67 birim kontrolü geçti. Gerçek görüntülü çalıştırma araç zaman aşımı nedeniyle NOT ASSESSED; ekran görüntüsü ve kullanıcı hissiyat onayı yok. P1-01 kapatılmadı; Faz 1 bütünü tamamlanmadı.

## Faz 2 — Gerçek co-op doğrulaması

**Amaç:** 2/3/4 gerçek oyuncu ile oynanışı ve host yetkisini doğrulamak./resume

**İş:** ENet, istek doğrulama, spawn/senkronizasyon, girdi ve hedefleme, kopma/yeniden bağlanma; iki kişilik melez roller, üç kişilik eksik-rol alternatifleri; gerçek ortak eylem, ping ve sürtüşme. Faz 1 kodu girdi/oyun durumu ayrımıyla taşınır; ağın sıfır maliyetli ekleneceği varsayılmaz.

**Çıkış:** bütün oyuncu sayılarıyla kritik yollar tamamlanır; gecikme/kopma senaryoları test edilir. Host düşmesinde tur sonu davranışı açıktır. İletişim ve gerçek takım hissi kullanıcı tarafından değerlendirilir.

## Faz 3 — Tam operasyon döngüsü

**Amaç:** mekanikleri 20–25 dakikalık operasyon bağlamında doğrulamak.

**İş:** koridor/kapı kartları/oylama, dört oda + Çekirdek Odası + tahliye, güvenli noktalar, rol alternatifleri; Faz 1 üretim/tempo sistemlerinin operasyon ölçeğine taşınması; hedef süre ve risk/ödül dengesi.

**Çıkış:** baştan sona tekrar oynanabilir ve seed ile yeniden üretilebilir operasyon; iki kişilik takımda zorunlu rol kilidi yok; döngü ve kaynak dengesi playtest ile değerlendirilir.

## Faz 4 — İçerik ve sunum

**Amaç:** doğrulanmış mekanikleri hedef kimlikte, yeterli içerikle sunmak.

**İş:** oda konseptleri ve iskelet çeşitleri, karakterler, animasyonlar, dreamcore mekanlar, nihai ses/VFX, görsel dil, tam UI/erişilebil/resume
irlik ve performans iyileştirmeleri. Temel okunabilirlik ve gerekli erişilebilirlik bu faza kadar ertelenmez.

**Çıkış:** içerik hedefleri ve sanat/ses standartları karşılanır; efektler mekanik bilgiyi örtmez; hedef donanımda performans ölçülür.

## Faz 5 — Steam ve yayın hazırlığı

**İş:** GodotSteam bağlantısı/lobi/ses, kalıcı Parça ve yan seçenek modülleri, kayıt ve başarımlar, platform entegrasyonu; regresyon, güvenlik, performans ve yayın kontrol listesi. Günlük seed/kozmetik/üst Protokoller kapsam onayıyla ele alınır; hepsi ilk yayın için otomatik taahhüt değildir.

**Çıkış:** yayın adayı gerçek hedef donanım/platform üzerinde doğrulanır; başarısız ve çalıştırılamayan kontroller açıkça raporlanır.

## Durum dili

- **Planlandı:** uygulama yok.
- **Uygulanıyor:** kodlama sürüyor; tamamlanma iddiası değil.
- **Doğrulama bekliyor:** kod var, gerekli test/gözlem eksik.
- **Kullanıcı hissiyat onayı bekliyor:** teknik kanıt var, öznel değerlendirme açık.
- **Onaylandı:** ilgili kanıtlar ve gerekli kullanıcı kararı mevcut.
- **NOT ASSESSED:** kontrol gerçekleştirilemedi; nedeni yazılır. Başarılı sayılmaz.

Bu oyun fazları, stüdyo iş akışının `Concept`/`Systems Design` aşamalarıyla aynı şey değildir; dosya sayısından otomatik üretim olgunluğu çıkarılmaz.
