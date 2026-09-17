# godot-starter

Portföydeki bütün web oyunlarının başladığı şablon. Godot 4.7, GDScript, Compatibility renderer, CrazyGames SDK v3.

## Yeni oyun başlatmak

```bash
tools/new_game.sh sort-puzzle "Sort Puzzle"
```

Bu komut şablonu `../sort-puzzle` klasörüne kopyalar, oyunun adını ayarlar ve ilk git commit'ini atar. Ortak katmandaki bir düzeltme, oyunlara elle taşınır.

## Klasörler

| Yol | Ne işe yarar |
| --- | --- |
| `core/portal.gd` | `Portal`: CrazyGames SDK köprüsü. Editörde ve masaüstünde hiçbir şey yapmaz, oyun kodu bu farkı bilmek zorunda kalmaz. |
| `core/save.gd` | `Save`: anahtar-değer kaydı. CrazyGames'te SDK'nın data modülünü, başka yerde `user://save.json` dosyasını kullanır. |
| `core/settings.gd` | `Settings`: ses açık/kapalı. Reklam oynarken ya da portal sessizlik istediğinde sesi de keser. |
| `core/progress.gd` | `Progress`: koşular arasında kalan coin ve upgrade seviyeleri. |
| `core/theme.tres` | Proje genelindeki UI teması (font boyutu vb.). |
| `scenes/boot` | Açılış: SDK'yı başlatır, kaydı yükler, ana menüyü açar. |
| `scenes/main_menu` | Ana menü. |
| `scenes/game` | **Yer tutucu oyun** (10 saniyede olabildiğince çok tıkla). Gerçek oyun bunun yerine gelir. |
| `scenes/game_over` | Oyun sonu paneli: coin verir, ödüllü reklamla x2, Retry'dan önce ara reklam. |
| `tools/web.sh` | Web export alır ve `http://localhost:8000` adresinde açar. |

`Portal`, `Save`, `Settings` ve `Progress` autoload'dur, yani her script'ten doğrudan adıyla çağrılır.

## Oyun kodunun uyması gereken kurallar

- Oyuncu oynamaya başlayınca ya da devam edince `Portal.gameplay_start()` çağrılır. Menü, pause ya da oyun sonunda `Portal.gameplay_stop()` çağrılır.
- Reklam için `await Portal.show_ad("rewarded")` kullanılır. Reklam sonuna kadar izlendiyse `true` döner. Reklam süresince oyun durur ve ses kesilir.
- Kalıcı veriler `Save` üzerinden yazılır. CrazyGames `localStorage` ya da yerel dosya kullanılmasını kabul etmiyor.
- Editörde ya da masaüstünde reklam gösterilmez. Debug build'de `show_ad` her zaman `true` döner, böylece ödül akışı reklamsız test edilebilir.

## Çalıştırma

- **Editör:** Godot'yu aç → Import → bu klasördeki `project.godot` dosyasını seç → F5.
- **Web:** `tools/web.sh` komutunu çalıştır ve `http://localhost:8000` adresini aç. Localhost'ta SDK "local" modda çalışır: reklam yerine yazılı bir kutu çıkar ve SDK olayları tarayıcı konsoluna düşer.

## Web build ölçüleri (boş şablon)

`index.wasm` dosyası sıkıştırılmamış 39.5 MB, gzip ile ~10 MB. CrazyGames masaüstünde en fazla 50 MB, mobil ana sayfaya girebilmek için en fazla 20 MB ilk indirme istiyor. Asset eklerken bu sınırlar göz önünde tutulmalı.
