# 🤖 AGENTS.md — Evrensel Çoklu Ajan ve Stüdyo Personel Şartnamesi
### *Claude Code Game Studios & Global AI-Native Multi-Agent Standartları*

> Bu belge; 49 uzman yapay zekâ personelinin rollerini, yetkilerini, iletişim kurallarını ve çalışma zamanı adaptasyonlarını tanımlayan tek ve evrensel doğruluk kaynağıdır (**Single Source of Truth**). Claude Code, DeepSeek Harness, OpenCode, Codex, Cursor veya herhangi bir LLM çalışma ortamında aynı kurallarla yorumlanır.

---

## 1. Stüdyo Mimarisi ve Hiyerarşi (Üç Katmanlı Model)

Sistem; bağımsız oyun stüdyosu operasyonlarını yürütmek üzere 3 ana kademede 49 uzman rol içerir.

```text
┌────────────────────────────────────────────────────────────────────────┐
│ TIER 1: DİREKTÖRLER (Strateji, Vizyon ve Kapsam)                       │
│ - creative-director   : Yaratıcı vizyon, tasarım ve ton uyumu          │
│ - technical-director  : Sistem mimarisi, motor seçimi, teknik sınırlar │
│ - producer            : Sprint yönetimi, risk, aşama geçişleri         │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼─────────────────────────────────────┐
│ TIER 2: DEPARTMAN LİDERLERİ (Koordinasyon ve Kalite Geçitleri)        │
│ - game-designer       : Mekanikler, ekonomi, sistem dengesi            │
│ - lead-programmer     : Kod mimarisi, API sınırları, refaktör          │
│ - art-director        : Görsel dil, stil rehberi, varlık kalitesi      │
│ - audio-director      : Ses paleti, müzik yönü, miksaj stratejisi      │
│ - narrative-director  : Hikaye, dünya inşası, diyalog akışı            │
│ - qa-lead             : Test stratejisi, regresyon, hata triajı        │
│ - release-manager     : Dağıtım boru hattı, sürümleme, geri alma       │
│ - localization-lead   : Yerelleştirme ve dil desteği                   │
└──────────────────────────────────┬─────────────────────────────────────┘
                                   │
┌──────────────────────────────────▼─────────────────────────────────────┐
│ TIER 3: UZMANLAR VE MOTOR ÖZELİ ROLLER (Uygulama ve Doğrulama)         │
│ - Gameplay & Sistem   : gameplay-programmer, systems-designer, ai-prog │
│ - Motor (Godot 4)     : godot-specialist, godot-gdscript-specialist,   │
│                         godot-shader-specialist, godot-gdextension-spec│
│ - Motor (Unity/UE5)   : unity-specialist, unreal-specialist (Opsiyonel)│
│ - Altyapı & Güvenlik  : devops-engineer, security-engineer, tools-prog │
│ - Kalite & Doğrulama  : qa-tester, performance-analyst                 │
│ - UI / UX & Ses       : ui-programmer, ux-designer, sound-designer     │
│ - Anlatı & Topluluk   : writer, world-builder, community-manager       │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Evrensel İşbirliği Protokolü (Collaboration Protocol)

Tüm ajanlar için temel kural: **Kullanıcı odaklı işbirliği, otonom kontrolsüz uygulama değil.**

Her görev şu döngüyü tavizsiz izler:
**Soru → Seçenekler → Karar → Taslak → Onay**

1. **Dosya Değişikliği Öncesi Onay:** Ajanlar dosya oluşturmadan veya değiştirmeden önce kullanıcıya açıkça sormalıdır:
   `"Bu değişikliği [dosya_yolu] dosyasına yazabilir miyim?"`
   *(İstisnalar: `active.md` oturum günlüğü ve geçici hafıza dosyaları).*
2. **Çoklu Dosya Onayı:** Birden fazla dosyayı kapsayan değişiklikler, tüm değişiklik listesi ve özeti sunularak **tek bir bütün olarak** kullanıcı onayına sunulmalıdır.
3. **Commit ve Push Kuralı:** Kullanıcının açık talimatı olmadan asla `git commit` veya `git push` yapılamaz.
4. **Geçilen Soru Cevap Değildir:** Yanıtlanmayan veya geçiştirilen soru onay sayılmaz; ajan hiçbir işlem yapmaz, soruyu yeniden sorup bekler.

---

## 3. 30+ Subagent Orkestrasyonu ve Ölçekleme (Swarm Execution)

Sistem, bağımsız görevleri aynı anda 30'un üzerinde paralel alt ajana dağıtacak kapasitede tasarlanmıştır. Bu yetenek şu disiplinlerle korunur:

### A. Görev Yönlü Döngüsüz Çizelgesi (Task DAG)
- Birbirinden bağımsız çalışan görevler (örneğin UI tasarımı, ses listesi hazırlama ve GDScript birim testi yazımı) **aynı anda eşzamanlı** başlatılır.
- Birbirinin çıktısına bağımlı işler (örneğin `spec.md` onaylanmadan kod yazımı) sıralı yürütülür.

### B. Yazma Kapsamı ve Dosya Kilidi (Write-Scope Isolation)
- Her çalışan subagent'a ayrık (disjoint) bir dosya/klasör yazma yetkisi atanır.
- İki alt ajanın aynı anda aynı dosyayı değiştirmesi kesinlikle engellenir.
- Okuma işlemleri (Read/Grep/Glob) tamamen eşzamanlıdır.

### C. Bütçe, Zaman Aşımı ve Güvenli İptal
- Uzun süre yanıt vermeyen veya döngüye giren subagent'lar zaman aşımı mekanizmasıyla güvenli şekilde durdurulur (`job_kill` / iptal sinyali).
- Alt ajanların yalnızca gerekli bağlamı tüketmesi için dar kapsamlı istemler verilir.

---

## 4. Yetenek Algılama ve Kademelendirme (Graceful Degradation)

Farklı yapay zekâ araçlarında çalışırken sistem şu yetenek seviyelerine göre adapte olur:

| Yetenek Seviyesi | Çalışma Ortamı Örnekleri | Yürütme Davranışı |
| :--- | :--- | :--- |
| **Tier A (Paralel Çoklu Ajan)** | DeepSeek Harness, Claude Teams | Görevler DAG grafiğine göre 30+ alt ajana paralel dağıtılır; ayrık çalışma ağaçları (worktrees) ve görev panosu kullanılır. |
| **Tier B (Sıralı / Sınırlı Subagent)**| Claude Code CLI, OpenCode | Görevler öncelik sırasına göre 1-3 alt ajanla adım adım yürütülür; sonuçlar ana oturuma toplanır. |
| **Tier C (Tekil Model / Düz Chat)** | OpenAI Codex Web, Cursor, Standart LLM | Model alt ajan açmak yerine kendisi sırayla rolleri canlandırır: Önce `lead-programmer` olarak analiz yapar, ardından `godot-gdscript-specialist` olarak kod önerir, son olarak `qa-tester` olarak test kontrolü sunar. |

---

## 5. Çapraz Platform Araç Seti

Tüm komutlar ve doğrulamalar işletim sisteminden bağımsız olarak çalıştırılır:
- **Test ve SDLC Denetimi:** `python tools/sdlc/runner.py test`
- **Orkestrasyon ve Dağıtım:** `python tools/sdlc/orchestrator.py`
- **Kilit ve Çakışma Yönetimi:** `python tools/sdlc/locks.py`
- **Oturum Başlangıç Kontrolü:** `python tools/sdlc/runner.py preflight`
- **Motor Çalıştırma (Godot 4.7.2):** `godot-test/Godot_v4.7.2-stable_win64_console.exe` veya sistem PATH'indeki `godot`.

---

## 6. Faz 1 — İki geliştiricili başlangıç

**2026-10-27 güncellemesi — aşağıdaki eski kilit örneklerinden önce bu akış uygulanır:**

- [Görev manifesti](<.sdlc/phase1_tasks.json>) ve [çalışma planı](<production/phase-1-workstreams.md>) sahiplik/bağımlılık/kapsam kaynağıdır. alicomert oyuncu/silah/hissiyat ve tek ortak entegratör; okanipk nesne/dünya/karşılaşmalar sahibidir.
- Her oturumda `python -B tools/sdlc/runner.py start` (`preflight` alias) çalıştır. Kimlik bir defa `git config --local sdlc.developer alicomert` veya `okanipk` ile açık seçilir. Git user.name/OS adı kullanılmaz; kimlik beyanı authentication değildir.
- Başlangıç salt okunurdur: görev/dal/kapsam/kabul ölçütlerini gösterir; otomatik ajan/kod/dal/Issue/commit/push üretmez. Kimlik çelişkisi, yanlış/korumalı dal, açık karar, eksik bağımlılık, ilgisiz dirty dosya veya bozuk kayıt durumunda oyun kaynaklarına yazma.
- `can_write` yalnız yerel ön kontroldür; tam dosya kapsamı onayı ve benzersiz session rezervasyonu ayrıca gerekir. Mevcut dirty main üzerinde önceki değişiklikler korunur; sıradaki oyun görevi için ortak baseline/dal gerekir.
- Yeni clone'da eksik yerel kayıt açıkça `python -B tools/sdlc/locks.py init` ile oluşturulur. Canlı kilit kaydı Git'ten hariçtir; var olan/bozuk dosyaya init uygulanmaz.
- Acquire/release örneklerine `--dev <handle> --session <unique-id>` eklemek zorunludur. Aynı kişinin farklı session'ları da çakışır; release yalnız tam dev+session sahibini bırakır. Stale mutex kendiliğinden kırılmaz.
- Kilitler **yalnız aynı checkout'ta advisory koordinasyondur**; editör yazma engeli, sıfır çakışma garantisi veya dağıtık kilit değildir. Ayrı clone güncelliği `unknown`; ortak baseline ve manifest revision partnerle doğrulanır. GitHub Issues görünürlük sağlar, transaction lock değildir.
- Ana laboratuvar/proje/girdi bağlantıları yalnız alicomert'in P1-I görevlerindedir. Çekme türü henüz açık karar, uygulanmaz. Manifest değişiminde revision artırılır ve incelenir.
- Claude Code mevcut SessionStart hook'una sınırlandırılmış çağrı eklenmiştir; diğer runtime'larda native hook varsayılmaz. Elle/ajan bootstrap'inde aynı komut kullanılır; routing hatasında recovery okunur ama oyun yazımı durur.
- Önceki 30+ paralellik/sıfır çakışma ifadeleri kanıtlanmış runtime garantisi değildir. [Orkestratör](<tools/sdlc/orchestrator.py>) statik planlayıcıdır, worker dispatch etmez.

### Eski örnekler (tek başına kullanılmaz; yukarıdaki session ve görev kontrolleri zorunlu)

Projeyi iki geliştirici ve yapay zekâ ajanları birlikte yürütürken çakışmaları sıfırlamak için şu kurallar bağlayıcıdır:

1. **Oturum Başlangıcı (Pre-Flight):** Her oturum başladığında `python tools/sdlc/runner.py preflight` çalıştırılarak diğer geliştiricinin kilitli alanları kontrol edilir.
2. **Yazma Alanı Kilitleme (Write-Scope Lock):** Bir özelliğe başlarken ilgili alan kilitlenir:
   `python tools/sdlc/locks.py acquire --scope "src/combat/" --issue "#12" --title "Combat Tuning"`
3. **Kilit Çakışması Yasağı:** Başka bir geliştiricinin kilitlediği dosyalar/klasörler serbest bırakılana kadar düzenlenemez; ajanlar kilitli alana yazma teklifinde bulunamaz.
4. **İş Bitimi Kilit Bırakma:** Görev tamamlanıp testler geçtikten sonra kilit kaldırılır:
   `python tools/sdlc/locks.py release`
