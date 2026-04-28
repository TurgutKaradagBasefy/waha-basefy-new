# WAHA Core v2026.4.1 - Özellikler & Endpoint'ler

## 📊 Özet

- **Toplam Endpoint:** 92+
- **Çalışan:** 80+ ✅
- **Plus-Only (Çalışmayan):** 12+ ❌
- **Multi-Session:** ✅ Destekleniyor (Sınırsız)

---

## ✅ ÇALIŞAN ÖZELLİKLER

### 🔑 **Sessions Management**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions` | Tüm session'ları listele |
| POST | `/api/sessions` | Yeni session oluştur |
| GET | `/api/sessions/{session}` | Session detayı |
| PUT | `/api/sessions/{session}` | Session config güncelle |
| DELETE | `/api/sessions/{session}` | Session sil |
| POST | `/api/sessions/{session}/start` | Session başlat |
| POST | `/api/sessions/{session}/stop` | Session durdur |
| GET | `/api/sessions/{session}/qr` | QR kodu al (PNG) |
| POST | `/api/sessions/{session}/logout` | Logout yap |
| POST | `/api/sessions/{session}/unpair` | Device unpair et |

---

### 💬 **Messages**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/chats/{chatId}/messages` | Chat mesajları listele |
| POST | `/api/sessions/{session}/chats/{chatId}/messages` | Mesaj gönder |
| GET | `/api/sessions/{session}/messages/{messageId}` | Mesaj detayı |
| GET | `/api/sessions/{session}/messages/{messageId}/status` | Mesaj durumu (SENT/READ/PLAYED) |
| GET | `/api/sessions/{session}/chats/{chatId}/messages/search` | Mesaj ara |
| DELETE | `/api/sessions/{session}/messages/{messageId}` | Mesaj sil |
| PUT | `/api/sessions/{session}/messages/{messageId}` | Mesaj düzenle |

**Desteklenen Mesaj Türleri:**
- Text ✅
- Image ✅
- Video ✅
- Audio ✅
- Document ✅
- Link Preview ✅
- Contact ✅
- Location ✅

---

### 💬 **Messages (Eski Format - DEPRECIATED)**

> ⚠️ Eski format endpoint'ler - **Core'da Limited support** (yalnızca text, buttons, location)

| HTTP | Endpoint | Açıklama | Core | Plus |
|------|----------|---------|------|------|
| POST | `/api/sendText` | Metin mesajı gönder | ✅ | ✅ |
| POST | `/api/sendImage` | Resim gönder | ❌ | ✅ |
| POST | `/api/sendFile` | Dosya gönder | ❌ | ✅ |
| POST | `/api/sendVoice` | Ses mesajı gönder | ❌ | ✅ |
| POST | `/api/sendVideo` | Video gönder | ❌ | ✅ |
| POST | `/api/send/link-custom-preview` | Custom link preview | ❌ | ✅ |
| POST | `/api/sendButtons` | Interactive buton mesajı | ✅ | ✅ |
| POST | `/api/sendList` | List mesajı | ❌ | ✅ |
| POST | `/api/sendLocation` | Konum gönder | ✅ | ✅ |
| POST | `/api/sendPoll` | Poll gönder | ✅ | ✅ |
| POST | `/api/sendPollVote` | Poll vote gönder | ✅ | ✅ |
| POST | `/api/sendSeen` | Mesajı okundu olarak işaretle | ✅ | ✅ |

**Kullanım:**
```json
{
  "session": "account1",
  "chatId": "5491234567890@c.us",
  "text": "Merhaba"
}
```

---

### 📱 **Chats**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/chats` | Chat listesi |
| GET | `/api/sessions/{session}/chats/{chatId}` | Chat detayı |
| POST | `/api/sessions/{session}/chats/{chatId}/read` | Mesajı oku olarak işaretle |
| POST | `/api/sessions/{session}/chats/{chatId}/archive` | Chat arşivle |
| POST | `/api/sessions/{session}/chats/{chatId}/unarchive` | Chat arşivden çıkar |
| DELETE | `/api/sessions/{session}/chats/{chatId}` | Chat sil |
| POST | `/api/sessions/{session}/chats/{chatId}/pin` | Chat sabitle |
| POST | `/api/sessions/{session}/chats/{chatId}/unpin` | Chat sabitlemesini kaldır |
| POST | `/api/sessions/{session}/chats/{chatId}/mute` | Chat sessize al |
| POST | `/api/sessions/{session}/chats/{chatId}/unmute` | Chat sesini aç |

---

### 👥 **Contacts**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/contacts` | Kontakt listesi |
| GET | `/api/sessions/{session}/contacts/{contactId}` | Kontakt detayı |
| POST | `/api/sessions/{session}/contacts` | Kontakt oluştur |
| PUT | `/api/sessions/{session}/contacts/{contactId}` | Kontakt güncelle |
| DELETE | `/api/sessions/{session}/contacts/{contactId}` | Kontakt sil |
| GET | `/api/sessions/{session}/contacts/check/{phone}` | Telefon WhatsApp'ta var mı? |
| POST | `/api/sessions/{session}/contacts/block` | Kontakt engelle |
| POST | `/api/sessions/{session}/contacts/unblock` | Kontakt engellemeyi kaldır |

---

### 👫 **Groups**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/groups` | Grup listesi |
| GET | `/api/sessions/{session}/groups/{groupId}` | Grup detayı |
| POST | `/api/sessions/{session}/groups` | Grup oluştur |
| PUT | `/api/sessions/{session}/groups/{groupId}` | Grup güncelle |
| DELETE | `/api/sessions/{session}/groups/{groupId}` | Grup sil |
| GET | `/api/sessions/{session}/groups/{groupId}/participants` | Grup üyeleri |
| POST | `/api/sessions/{session}/groups/{groupId}/participants` | Üye ekle |
| DELETE | `/api/sessions/{session}/groups/{groupId}/participants/{participantId}` | Üye çıkar |
| POST | `/api/sessions/{session}/groups/{groupId}/participants/promote` | Üyeyi yönetici yap |
| POST | `/api/sessions/{session}/groups/{groupId}/participants/demote` | Üyeyi sıradan üye yap |

---

### 📢 **Channels (NOWEB)**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/channels` | Channel'ları listele |
| POST | `/api/sessions/{session}/channels` | Channel oluştur |
| GET | `/api/sessions/{session}/channels/{channelId}` | Channel detayı |
| PUT | `/api/sessions/{session}/channels/{channelId}` | Channel güncelle |
| DELETE | `/api/sessions/{session}/channels/{channelId}` | Channel sil |
| GET | `/api/sessions/{session}/chats/{channelId}/members` | Channel üyeleri |
| POST | `/api/sessions/{session}/channels/{channelId}/invite` | Üye davet et |
| POST | `/api/sessions/{session}/channels/{channelId}/leave` | Channel'dan ayrıl |

---

### 📎 **Media**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/chats/{chatId}/messages/{messageId}/media` | Medya indir |
| POST | `/api/sessions/{session}/chats/{chatId}/messages` | Medya gönder (URL) |
| GET | `/api/sessions/{session}/chats/{chatId}/messages/{messageId}/thumbnail` | Thumbnail al |

**Desteklenen Format:**
- JPEG, PNG, GIF ✅
- MP4, MOV ✅
- MP3, M4A, OGG ✅
- PDF, DOCX, XLSX ✅
- ZIP ✅

---

### 🎭 **Status**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| POST | `/api/sessions/{session}/status/text` | Metin status gönder ✅ |
| POST | `/api/sessions/{session}/status/image` | Resim status gönder ❌ (Plus) |
| POST | `/api/sessions/{session}/status/video` | Video status gönder ❌ (Plus) |
| POST | `/api/sessions/{session}/status/voice` | Ses status gönder ❌ (Plus) |
| POST | `/api/sessions/{session}/status/delete` | Status sil ❌ (Plus) |
| GET | `/api/sessions/{session}/status/new-message-id` | Mesaj ID oluştur ✅ |

---

### 👤 **Profile**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/me` | Oturum bilgisi |
| POST | `/api/sessions/{session}/profile/name` | Profil adı değiştir |
| POST | `/api/sessions/{session}/profile/status` | Profil statusu değiştir |
| POST | `/api/sessions/{session}/profile/picture` | Profil resmi değiştir |

---

### 🔔 **Presence & Activity**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| POST | `/api/sessions/{session}/presence/online` | Online olarak işaretle |
| POST | `/api/sessions/{session}/presence/offline` | Offline olarak işaretle |
| POST | `/api/sessions/{session}/presence/typing` | Yazıyor göster |
| POST | `/api/sessions/{session}/presence/recording` | Kayıt yapıyor göster |

---

### 🏷️ **Labels**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/labels` | Etiket listesi |
| POST | `/api/sessions/{session}/labels` | Etiket oluştur |
| DELETE | `/api/sessions/{session}/labels/{labelId}` | Etiket sil |
| POST | `/api/sessions/{session}/labels/{labelId}/chats/{chatId}` | Etiket ekle |
| DELETE | `/api/sessions/{session}/labels/{labelId}/chats/{chatId}` | Etiket kaldır |

---

### 🆔 **LIDs (LinkedIn IDs)**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/lids` | LID listesi |
| GET | `/api/sessions/{session}/lids/{lid}` | LID detayı |

---

### 🪝 **Webhooks**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/sessions/{session}/webhooks` | Webhook'ları listele |
| POST | `/api/sessions/{session}/webhooks` | Webhook ekle |
| DELETE | `/api/sessions/{session}/webhooks/{webhookId}` | Webhook sil |

**Desteklenen Events:**
- `message.any` ✅
- `message.created` ✅
- `message.updated` ✅
- `message.media` ✅
- `session.status` ✅
- `presence.update` ✅

---

### 🔑 **API Keys**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/api-keys` | API Key listesi |
| POST | `/api/api-keys` | API Key oluştur |
| PUT | `/api/api-keys/{keyId}` | API Key güncelle |
| DELETE | `/api/api-keys/{keyId}` | API Key sil |

---

### ℹ️ **Server Info**
| HTTP | Endpoint | Açıklama |
|------|----------|---------|
| GET | `/api/version` | Sunucu versiyonu |
| GET | `/api/ping` | Sunucu canlı mı? |
| GET | `/api/health` | Sunucu sağlığı ❌ (Detaylı - Plus) |

---

---

## ❌ ÇALIŞMAYAN ÖZELLİKLER (Plus-Only)

### 🎬 **Status Features (Plus)**
| HTTP | Endpoint | Açıklama | Sebep |
|------|----------|---------|--------|
| POST | `/api/sessions/{session}/status/image` | Resim story gönder | Plus |
| POST | `/api/sessions/{session}/status/video` | Video story gönder | Plus |
| POST | `/api/sessions/{session}/status/voice` | Ses story gönder | Plus |
| DELETE | `/api/sessions/{session}/status/{statusId}` | Story sil | Plus |
| GET | `/api/sessions/{session}/status` | Status listesi | Plus |

---

### 📞 **Calls (Plus)**
| HTTP | Endpoint | Açıklama | Sebep |
|------|----------|---------|--------|
| GET | `/api/sessions/{session}/calls` | Çağrı listesi | Plus |
| GET | `/api/sessions/{session}/calls/{callId}` | Çağrı detayı | Plus |

---

### 📢 **Channel Admin Features (Plus)**
| HTTP | Endpoint | Açıklama | Sebep |
|------|----------|---------|--------|
| POST | `/api/sessions/{session}/channels/{channelId}/follow` | Channel takip et | Plus |
| POST | `/api/sessions/{session}/channels/{channelId}/unfollow` | Channel takip bırak | Plus |
| GET | `/api/sessions/{session}/channels/info` | Channel info (admin) | Plus |

---

### 🔍 **Advanced Search (Plus)**
| HTTP | Endpoint | Açıklama | Sebep |
|------|----------|---------|--------|
| POST | `/api/sessions/{session}/search` | Global mesaj ara | Plus |

---

### 🖼️ **Screenshot (Plus)**
| HTTP | Endpoint | Açıklama | Sebep |
|------|----------|---------|--------|
| POST | `/api/sessions/{session}/screenshot` | Sayfa ekran görüntüsü | Plus |

---

---

## 📈 Feature Comparison

| Feature | CORE | PLUS | 
|---------|------|------|
| Multi-Session (Sınırsız) | ✅ | ✅ |
| Messages | ✅ | ✅ |
| Contacts | ✅ | ✅ |
| Groups | ✅ | ✅ |
| Channels | ✅ | ✅ |
| Webhooks | ✅ | ✅ |
| Text Status | ✅ | ✅ |
| Image/Video/Voice Status | ❌ | ✅ |
| Calls | ❌ | ✅ |
| Global Search | ❌ | ✅ |
| Media Storage (Multi Backend) | ❌ | ✅ |
| Database (Mongo/Postgres) | ❌ | ✅ |

---

## 🚀 Örnek Kullanım

### Multi-Session Create
```bash
curl -X POST http://localhost:3000/api/sessions \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: YOUR_KEY" \
  -d '{
    "name": "account1",
    "start": true,
    "config": {
      "noweb": {
        "store": {
          "enabled": true,
          "fullSync": true
        }
      }
    }
  }'
```

### Text Status Gönder
```bash
curl -X POST http://localhost:3000/api/sessions/account1/status/text \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: YOUR_KEY" \
  -d '{
    "text": "Merhaba Dünya!"
  }'
```

### Mesaj Gönder
```bash
curl -X POST http://localhost:3000/api/sessions/account1/chats/5491234567890@c.us/messages \
  -H "Content-Type: application/json" \
  -H "X-Api-Key: YOUR_KEY" \
  -d '{
    "text": "Selam!"
  }'
```

---

## 📥 Excel/CSV Export

Bu dökümentasyonu Excel'e import etmek için:

1. Tabloları kopyala
2. Excel aç
3. Yapıştır (Paste Special → Values)
4. Filtreleri ekle (Data → AutoFilter)

---

**Son Güncelleme:** 20 Nisan 2026  
**WAHA Version:** 2026.4.1 Core  
**Multi-Session:** ✅ Aktif (Limitsiz)
