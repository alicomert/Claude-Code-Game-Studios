# Faz 1 — Mekanik kapsam ve doğrulama

2026-10-22 • Solo laboratuvar. Kaynak tasarımdaki her mekanik aşağıdaki gruplardan birine bağlanır. Yeni mekanik eklendiğinde bu listeye de eklenir. **Bir başlığın uygulanması, altındaki her davranışın doğrulandığı anlamına gelmez.**

## Güncel teslim

### 2026-10-26 — Seçilen paketlerin güncellemesi

P1-01A teknik hareket/zıplama kabulü ve 45/75 cm engel aşma senaryoları geçti; kullanıcı hissiyat onayı bekliyor. Space zıplama, genel atılma yok. P1-02'de dört silah profili, raycast isabet/hasar, kalkan/sersemleme, siper, hasar alanı, sınırsız R (varsayılan) ve ayrı sınırlı mermi örneği eklendi. P1-04A'da E kısa/uzun/iptal, T aç-kapa, menzil/LOS ve terminal/kapı/kalkan istasyonu çalışıyor. Envanter, kasa ve roller bu teslim değil.

Kanıt ve açık kalan sunum işleri: [paket doğrulama kaydı](qa/phase-packages-2026-10-26.md). P1-02'nin nihai silah modelleri, süreli doldurma animasyonu ve production ses katmanları tamamlandı sayılmaz; prototip siluetleri, yalnız silah pozunu donduran yerel hit-stop ve dinamik namlu ışığı eklenmiştir. Aşağıdaki eski teslim kaydı tarihsel bilgidir; atılma/V ve eski test durumları güncel kontrol kararı değildir.

**P1-01 (2026-10-23):** yarım kalan zıplama entegrasyonu tamamlandı; `jumped`/`landed` sinyalleri, düşey simülasyon ve animasyon ayarları ana projede mevcut. Dönüş katsayısı13,2; zıplama yüksekliği1 m. Hata öncesi test81 kontrolde12 hata verdi (eksik sinyaller dahil); entegrasyon sonrası **124 kontrol,0 hata**. Gerçek sahnede keşfedilen alternatif karelerde yer teması kaybı için yeni regresyon önce başarısız oldu; yerde küçük yerçekimi adımı korunarak düzeltildi ve124 kontrol yeniden geçti. Godot4.7.2 import temiz.

**Run result: PARTIAL —** gerçek pencereli ana sahne NVIDIA/Vulkan Forward+ ile açıldı, `jumped` erişim hatası tekrar oluşmadı ve `production/qa/evidence/p1-01-jump/repaired-scene.png` kaydedildi. Görsel okuma aracı görüntüyü bu oturumda görünür olarak sunmadığından görsel onay iddia edilmez. İlk `--verify-jump` koşusu12 kontrolde5 hata verdi; yer teması düzeltmesi sonrası tekrar koşuları pencere odağı kesildiği için **NOT ASSESSED (çıkış2)** oldu. Havada/inişte eski görüntüler başarısız koşudan kalmıştır, geçerli zıplama kanıtı değildir. Gerçek tuş etkileşimi, engel aşma ve animasyonun görsel doğrulaması bekliyor; otomatik testte odak koruması devre dışı bırakılmadı.

Hissiyat **kullanıcı onayı bekliyor**. Diğer blokların tamamı **Planlandı**. `git diff --check` geçti. Commit/push yapılmadı.

## Kontrol listesi
/
| Blok | İşlevsel kapsam | Laboratuvar doğrulaması | Durum |
|---|---|---|---|
| P1-01 hareket | WASD, normalize çapraz hareket, hızlanma/durma, fareye dönüş, Shift, süre/bekleme sınırlı atılma, çarpışma | Açık alan/slalom/dar geçit/duvar; sıfırlama; odak kaybı | Uygulanıyor |
| P1-01 zıplama | V, yerde tek sıçrama, 1 m tepe, havada tekrar yok, dash etkileşimi; kalkış/uçuş/iniş prosedürel pozu | 45/75 cm engeller, yüksek duvar, reset; sabit kamera yüksekliği; görsel kanıt | Uygulanıyor |
| P1-01 kamera | 55° perspektif, yumuşak takip, en çok 4 m kenar kayması, merkezleme | Merkez ve dört kenar; farklı delta; oyuncu görünür | Uygulanıyor |
| P1-02 silah | Şok tabancası, pompalı, hafif tabanca, karabina; saçılma, geri tepme, doldurma, sınırlı mermi | Hedef tahtası; hareket/ateş dağılımı; boş şarjör | Planlandı |
| P1-02 hasar | Can/kalkan, sersemleme, siper, dost hasarı yok, namlu/vuruş geri bildirimi | Hasar kaynağı; kalkan önceliği; efekt azaltma | Planlandı |
| P1-03 Kilit | Hack, Sigorta Ağı, Kablo Gözü, hackte hareketsizlik | Kamera/terminal/elektrik hedefleri; kesilme/iptal | Planlandı |
| P1-03 Kırıcı | Omuz Darbesi/kırma, Kalkan Duvarı, Sağlam, gürültü zayıflığı | Kırılabilir kapı; kalkan ömrü; gürültü kıyası | Planlandı |
| P1-03 Yük | Atış yayı, çanta/çekirdek fırlatma, duman/yem, büyük çanta, çekirdekle kısıtlar | Yakalama/kaçırma; AI yem yönelimi; kapasite | Planlandı |
| P1-03 Göz | Drone kontrolü/görüşü, tarama, hızlı kaldırma, sessiz etkisizleştirme menzili | Drone sırasında gövde savunmasızlığı; bilgi süresi | Planlandı |   
| P1-04 imleç | Boş/silah/fırlatma/etkileşim/engelli/partner/terminal/kasa/düşman/ping/yetenek | Menzil ve öncelik değişimleri; kısa neden metni | Planlandı |
| P1-04 etkileşim | E kısa/uzun/iptal, envanter, slot, toplama/bırakma/aktarma | Dolu çanta; hedef kaybı; basılı tutma/toggle | Planlandı |
| P1-04 kasalar | Küçük/kilitli/ağır/tuzaklı/düşüş; anahtar/hack/kırma/ortak açma; dört nadirlik | Alarm/işaret/geri sayım; aynı kasaya çift istek | Planlandı |
| P1-04 eşya | Tüketim/saldırı/yardımcı/modül/garip davranışları | Her davranışa en az bir örnek; modül temizliği | Planlandı |
| P1-05 algı | Görüş/ses/ışık/iz, 0–100 şüphe, telsizle bilgi | Duvar arkası, kapı sönümleme, görünür/duyulur farkı | Planlandı |
| P1-05 AI | Devriye/inceleme/şüphe/çatışma/arama/dönüş; devriye/kalkan/telsiz/tarayıcı/çevre botu | Her durum geçişi ve karşı hamle; sessiz etkisizleştirme | Planlandı |
| P1-05 alarm/Şef | 0–4 alarm, düşme/terminal azaltma, kilitleme/takviye; fazlı Şef | Aşamaları tetikleme; tek oyuncuyla test edilebilir açık noktalar | Planlandı |
| P1-06 engel | lazer, kayganlık, sıkışan kapı, kamera/taret, elektrikli su, çöken raf, gaz odası | Her engelin karşı hamlesi; rol yokken alternatif bir şey| Planlandı |
| P1-06 mutatör | Karanlık, kaygan, yankı, küçülen, konveyör, sis, ağır çekim, tek yön, ayna, sessizlik | Tek tek ve izin verilen birleşimler; geri dönüşsüz kilit yok | Planlandı |
| P1-06 üretim | İskelet/kaplama/mutatör/engel/ödül/olay; seed, bütçe, uyumluluk, Garip Oda | Sonlu yeniden deneme; aynı seed aynı plan; ulaşılabilirlik | Planlandı |
| P1-06 Yönetmen | Gerilim/tepe/toparlanma; ilk 2 dk tepe yok; olay tekrarı/limit/ön belirti | Düşük can/toparlanma; el ile her olayı tetikleme | Planlandı |
| P1-06 olaylar | Yangın, devriye, kesinti, yanlış anons, kasa yağmuru, kapı, kayıp eşya, ısınma, ikiz, konfeti | Etki/ön belirti/karşı hamle/temizlik; hasarsız olay ayrımı | Planlandı |
| P1-07 ortak | İtme, at-yakala, yükselt, ortak kasa, kalkan arkası | Kontrollü yardımcı/rol değişimi; bırakma/iptal | Planlandı |
| P1-07 kurtarma | Sistem Çöktü, sürünme/ping, kaldırma, süreli yeniden doğma/eşya kaybı, haklar | Tek düşme ve toplu çökme; yerden izlemeye geçiş netliği | Planlandı |
| P1-07 takım | Altı kombo, 3 sn pencere, Uyum, Takım Hamlesi; ping tekeri ve hazır/oylama provası | Yardımcı üzerinden tetikleme; dolum sömürüsü ve cooldown | Planlandı |
| P1-07 sürtüşme | İtme/kayma/çarpışma; dost hasarı yok | Yardımcı üzerinde komik fakat softlock üretmeyen sonuç | Planlandı |
| P1-08 birleştirme | Kısa hedef/çekirdek/tahliye; güvenli nokta/reset; özet sayaçları | Bütün mekaniklerin bir arada denenmesi; tekrar üretilebilir senaryo | Planlandı |
| P1-08 erişilebilirlik | İmleç boyut/renk, sembol, altyazı/yön, hold-toggle, remap, efekt azaltma/zamanlama yardımı | Ayarları gerçekten değiştirerek test; yalnız renk bilgisi yok | Planlandı |
| P1-08 ayarlama | Dış veri, yeniden kurma, rol/eşya/düşman/olay seçme ve cooldown reset | Kullanıcının karşılaştırmalı his testi | Planlandı |

## Açık tasarım noktaları

- Mutatörlerde aynı etiketten tek öğe kuralı, kaygan+konveyör örneğiyle çelişiyor: izin verilen istisnalar açık veriyle tanımlanmalı; sessiz varsayım yapılmamalı.
- Yalnız Yük çekirdeği taşıyabilir ifadesi ile partnere çekirdek fırlatma/eksik rol desteği netleştirilmeli.
- Kurtarmada sürünme ve izleyici durumları ile yerde kalma süresi ayrı durumlar olarak tanımlanmalı.
- Aşırı ısınma açıklamasındaki “hack süresi kısalır” avantaj/risk anlamı belirsiz; uygulama öncesi netleştirilmeli.
- Space çakışması bu teslimde çözüldü: atılma Space, kamera merkezleme C.

Bu belirsizlikler hareket/kamera teslimini engellemez; ilgili mekanik gelmeden karar alınır.

## Faz 1'de doğrulanmayan / kapsam dışı alanlar

- Gerçek insanlarla co-op eğlencesi ve rol bağımlılığı: **NOT ASSESSED**, Faz 2'de gerçek takım gerekli.
- Ağ/Steam/gecikme/kopma: Faz 2 ve Faz 5; solo simülasyon kanıt değildir.
- Tam 20–25 dakikalık operasyon dengesi, 2/3/4 oyuncu ölçekleme: Faz 2–3.
- Kalıcı Parça/modül ağacı/kayıt/başarımlar, kozmetik ve günlük kontratlar: sonraki fazlar. Tur içi modül davranışı Faz 1'de kalır.
- Nihai sanat, bütün oda varyantları, sesli sohbet, oyuncu profili: sonraki fazlar.

## İlk teslimi çalıştırma

Godot 4.7.2 ile kökteki `project.godot` dosyasını içe aktar ve F5 ile çalıştır.
PowerShell alternatifi:

```powershell
& ".\godot-test\Godot_v4.7.2-stable_win64_console.exe" --path . --windowed --resolution 1280x720
& ".\godot-test\Godot_v4.7.2-stable_win64_console.exe" --headless --path . --script res://tests/unit/player/test_movement.gd
```

Çalışırken: WASD hareket; fare bakış; Shift yavaş; Space atıl; V zıpla; C basılı merkezle; F5 sıfırla; Esc duraklat. Hız/ivme/atılma/kamera ayarları `assets/data/movement_default.tres` kaynağında.

## Onay kapısı

Teknik doğrulama sonrasında kullanıcı şu soruları değerlendirir: hareket alışılabilir mi, durma/kayma kabul edilebilir mi, fare nişanı anlaşılır mı, atılma mesafesi/bekleme iyi mi, kamera rahatsız ediyor mu? Sonraki teslimlere bu geri bildirim taşınır. Bütün Faz 1 çıkışında ayrıca açık **Faz 2'ye geçiş onayı** gerekir.
