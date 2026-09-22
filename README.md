# godot-starter

Portföydeki bütün oyunların başladığı şablon. Godot 4.7, GDScript, Compatibility renderer, CrazyGames
SDK v3 (web) ve AdMob (Android/iOS). Hivebreaker'ın yayına giderken öğrettiği her şey burada.

## Yeni oyun başlatmak

```bash
tools/new_game.sh sort-puzzle "Sort Puzzle"
```

Şablonu `../sort-puzzle` klasörüne kopyalar, oyunun adını ve Android paket adını
(`com.recepozen.sortpuzzle`) ayarlar, ilk git commit'ini atar. **Paket adı Play'e ilk yüklemeden sonra
değiştirilemez.** Ortak katmandaki bir düzeltme oyunlara elle taşınır; oyunda bulunan bir düzeltme de
buraya elle geri taşınır.

Sonra sırayla:

1. `art/icon/source.png` dosyasını oyunun kendi simgesiyle değiştir (tek nesne, yazı yok, şeffaf
   zemin) ve `Godot --headless -s tools/make_icon.gd` çalıştır. Şablondaki sarı kare yer tutucudur.
2. Dikey telefon oyunuysa `project.godot` içinde `[display]`: 720×1280, `keep_width`,
   `window/handheld/orientation=1`. Şablon 1280×720 yatay (web).
3. AdMob'da uygulamayı ve iki reklam birimini (ödüllü, geçiş) oluştur; kimlikleri `core/admob.gd`
   `UNITS` ve `project.godot` `[admob] general/android/app_id` alanlarına yaz. Şablondakiler Google'ın
   test kimlikleri: değiştirmeden yayınlanan oyun para kazanmaz ama hesabı da kapattırmaz.

## Klasörler

| Yol | Ne işe yarar |
| --- | --- |
| `core/portal.gd` | `Portal`: CrazyGames SDK köprüsü. Editörde ve masaüstünde hiçbir şey yapmaz, oyun kodu bu farkı bilmek zorunda kalmaz. |
| `core/admob.gd` | `Admob`: telefonda reklamı gösteren taraf. Önce UMP onay formu, sonra SDK; bir ödüllü ve bir geçiş reklamı hep hazır bekler. Debug build hep test birimlerini ister. |
| `core/ads.gd` | `Ads`: reklamla ilgili **her kural** — geçiş reklamı ne zaman gösterilebilir (ilk oturumda asla, günün ilk koşularında asla, ödüllüden hemen sonra asla), koşu başına kaç ödüllü, reklamsız satın alındı mı. Ekranlar yalnızca `Ads.offer()` ve `Ads.run_finished()` çağırır; hangi ağın göstereceğini (Portal/Admob) `Ads` seçer. |
| `core/save.gd` | `Save`: anahtar-değer kaydı. CrazyGames'te SDK'nın data modülünü, başka yerde `user://save.json` dosyasını kullanır. **Her yazışta dosyanın tamamını yazar** — aşağıdaki tuzağa bak. |
| `core/settings.gd` | `Settings`: müzik, ses efekti, titreşim ve ekran sarsıntısı ayrı ayrı açılıp kapanır; Music ve SFX ses bus'larını açılışta kendisi kurar. Reklam oynarken ya da portal sessizlik istediğinde ana bus'ı keser. |
| `core/progress.gd` | `Progress`: koşular arasında kalan coin ve upgrade seviyeleri. |
| `core/theme.tres` | Proje genelindeki UI teması. |
| `scenes/boot` | Açılış: SDK'yı başlatır, kaydı yükler, **sonra** `Ads.reload()`, ana menüyü açar. Sıra önemli. |
| `scenes/main_menu` | Ana menü: oyna, müzik, ses. |
| `scenes/game` | **Yer tutucu oyun** (10 saniyede olabildiğince çok tıkla). Gerçek oyun bunun yerine gelir; `Ads.start_run()` ve `Portal.gameplay_start/stop` çağrıları kalır. |
| `scenes/game_over` | Oyun sonu paneli: coin verir, ödüllü reklamla x2 (`Ads.offer(&"double")`), Retry'dan önce `Ads.run_finished()`. |
| `tests/` | GUT testleri: reklam kuralları, ayarlar. Oyunun kendi testleri buraya eklenir. |
| `tools/web.sh` | Web export alır, `http://localhost:8000` adresinde açar. |
| `tools/android.sh` | Debug APK alıp bağlı telefona/emülatöre kurar; `release` argümanıyla gerçek anahtarla imzalı sürüm. Önce eski paketi kaldırır (aşağıdaki tuzağa bak). |
| `tools/make_icon.gd` | `art/icon/source.png`'den başlatıcı simgelerini üretir: adaptif ön/arka katman (432), düz (192), proje simgesi (128), Play mağaza simgesi (512, `build/covers/`). |
| `tools/make_preview.sh` | Godot'nun movie writer'ıyla alınan kayıttan portalın istediği dikey (1080×1920) ve yatay (1920×1080, bulanık dolgulu) 20 saniyelik tanıtım videolarını keser. |
| `addons/admob` | poingstudios godot-admob-plugin v5.1. `android/bin` ve `ios/bin` git'te yok; editör eklentiyi ilk açışta indirir (Project > Tools > AdMob). |
| `addons/gut` | Test çerçevesi. Android export'una girmez (`exclude_filter`). |

`Portal`, `Save`, `Settings`, `Progress`, `Admob` ve `Ads` autoload'dur, her script'ten adıyla çağrılır.

## Oyun kodunun uyması gereken kurallar

- Oyuncu oynamaya başlayınca `Ads.start_run()` ve `Portal.gameplay_start()`; menü, pause ya da oyun
  sonunda `Portal.gameplay_stop()`.
- Ödüllü reklam teklifi: düğmeyi `Ads.can_offer(&"kind")` ile aç/kapat, basınca
  `await Ads.offer(&"kind")`; sonuna kadar izlendiyse `true`. Telefonda yüklü reklam yoksa
  `can_offer` `false` der — tutulamayacak teklif yapılmaz. Yeni bir teklif türü `Ads._left`'e eklenir.
- Koşu bitince `await Ads.run_finished()`; geçiş reklamını kurallar izin verirse o gösterir.
- `Portal.show_ad` ve `Admob.show_ad` doğrudan çağrılmaz; `Ads` çağırır.
- Kalıcı veriler `Save` üzerinden. CrazyGames `localStorage` ya da yerel dosya kabul etmiyor.
- **Hiçbir autoload `_ready` içinde `Save`'e yazmaz.** `Save.load_data()` boot sahnesinde çalışır;
  ondan önce yapılan bir `set_value` tek anahtarlı bir dosyayı oyuncunun bütün ilerlemesinin üstüne
  yazar. Hivebreaker 0.6.0 bu hatayla Play'e gitti.
- Editörde ve masaüstünde reklam gösterilmez. Web debug build'de `show_ad` hep `true` döner;
  Android debug build'de Google'ın test reklamları oynar.

## Çalıştırma

- **Editör:** Godot'yu aç → Import → `project.godot` → F5.
- **Testler:** `Godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://tests -gexit`. Parse hatası
  olan bir test dosyasını GUT sessizce atlar: test **sayısına** bak, yalnızca "passed" yazısına değil.
- **Web:** `tools/web.sh`. Localhost'ta SDK "local" modda çalışır: reklam yerine yazılı bir kutu.
- **Android:** `tools/android.sh`. İlk seferde editörden Project > Install Android Build Template
  (1 GB, git'e girmez) ve Editor Settings'te JDK 21 + Android SDK yolu gerekir. Gradle build şart:
  AdMob eklentisi onsuz pakete girmez.
- **Play için AAB:** "Android Play" preset'i. İmza için ortam değişkenleri
  `GODOT_ANDROID_KEYSTORE_RELEASE_PATH`, `_USER`, `_PASSWORD`; anahtar `~/keystores/` altında, şifre
  sende. Her yüklemede `version/code` bir artar (her iki Android preset'inde).

## Yayına giderken (Hivebreaker'dan, sırayla)

1. Simge (`make_icon.gd`) — yoksa Godot'nun robotu gider ve export bunu yalnızca uyarıyla söyler.
2. Gizlilik politikası: yayında bir URL şart (AdMob onay mesajı ve Play listesi ister). Şablon
   `hivebreaker-api`'nin `/privacy` sayfası; Cloudflare'in e-posta gizlemesi iletişim adresini
   `[email protected]` yapar, o alan adı için configuration rule ile kapatılır.
3. AdMob: uygulama + iki birim → kimlikler koda → **Privacy & messaging'de AB onay mesajını
   yayınla** (yayınlanmadan `consent failed`) → Play yayınlanınca "Mağazaya ekle" → AdMob incelemesi
   (~1 gün). O güne kadar gerçek birimler dolmaz; bu normaldir.
4. Play: Ad ID beyanı **"Reklam veya pazarlama"** (uygulama işlevselliği değil), izinler
   INTERNET / AD_ID / ACCESS_NETWORK_STATE, mağaza açıklamasında yalan olmasın (yerel skor tablosu
   yok, izin yok gibi). Play Console'a önce iç test, sonra üretim; **kademeli sunum** tercih et.
5. Kill rule: lansman + 60 gün. Tarihi plan belgesine yaz.

## Tuzaklar

- **Kendi canlı reklamını kendi cihazında yükleme.** AdMob hesabı kapatır ve geri alınamaz. Bu yüzden
  `Admob._unit` yalnızca release build'de gerçek kimlikleri ister; test için debug build.
- **Debug ve release APK'ları farklı anahtarla imzalı**; `adb install -r` biri üstüne diğerini
  sessizce reddeder, eski build kalır. `tools/android.sh` bu yüzden önce kaldırır.
- Release build Android'de GDScript'ten hiçbir şey loglamaz; debug build `godot` etiketiyle loglar.
- Export'taki `.gdc` dosyaları sıkıştırılmış: APK içinde string aramak hiçbir şeyi kanıtlamaz.
- Godot `.gitignore`'a bakmadan `res://` altındaki her şeyi import eder; `build/.gdignore` olmadan
  web build'in simgeleri Android paketine girer. `web.sh` ve `android.sh` dosyayı kendileri yaratır.
- AdMob eklentisinin `skills/` belgeleri var olmayan onay sınıfları anlatır; gerçek API
  `addons/admob/gdscript/sample/` altında. `update()`/`load()` singleton yoksa sessizce hiçbir şey
  yapmaz — debug build'de `Admob._trace` çıktısını izle.
- Bazı telefonlar (Hivebreaker'daki G702) test birimlerini bile hiç yüklemez; reklam testi Play
  Store imajlı emülatörde yapılır.
- CrazyGames zip kabul etmez, dosyalar tek tek yüklenir; tanıtım videosu en çok 20 saniye.
- `Progress`'e kalıcı bir alan eklerken kaydı sürümle ve eski kaydı eksik alanı ekleyerek yükselt;
  hiçbir anahtar silinmez. Örnek: Hivebreaker `core/progress.gd` `upgrades()`/`migrate()`.

## Web build ölçüleri (boş şablon)

`index.wasm` sıkıştırılmamış 39.5 MB, gzip ile ~10 MB. CrazyGames masaüstünde en fazla 50 MB, mobil
ana sayfaya girebilmek için en fazla 20 MB ilk indirme istiyor. Asset eklerken bu sınırlar göz
önünde tutulmalı.
