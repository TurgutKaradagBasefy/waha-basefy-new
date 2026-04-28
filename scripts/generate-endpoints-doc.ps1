param(
    [string]$OutputPath = "d:\Work\waha\WAHA_Endpoints_Core_vs_Plus.docx"
)

$ErrorActionPreference = 'Stop'

function Encode-Xml([string]$text) {
    if ($null -eq $text) { return '' }
    return $text.Replace('&','&amp;').Replace('<','&lt;').Replace('>','&gt;').Replace('"','&quot;')
}

function New-Heading([string]$text, [int]$level = 1) {
    $style = "Heading$level"
    $t = Encode-Xml $text
    return @"
<w:p><w:pPr><w:pStyle w:val="$style"/></w:pPr><w:r><w:t xml:space="preserve">$t</w:t></w:r></w:p>
"@
}

function New-Para([string]$text, [string]$style = '') {
    $t = Encode-Xml $text
    $stylePart = ''
    if ($style) { $stylePart = "<w:pPr><w:pStyle w:val=`"$style`"/></w:pPr>" }
    return "<w:p>$stylePart<w:r><w:t xml:space=`"preserve`">$t</w:t></w:r></w:p>"
}

function New-Cell([string]$text, [int]$widthDxa = 2400, [bool]$header = $false, [string]$shade = '') {
    $t = Encode-Xml $text
    $shadeXml = ''
    if ($shade) { $shadeXml = "<w:shd w:val=`"clear`" w:color=`"auto`" w:fill=`"$shade`"/>" }
    $bold = ''
    if ($header) { $bold = '<w:rPr><w:b/></w:rPr>' }
    return @"
<w:tc><w:tcPr><w:tcW w:w="$widthDxa" w:type="dxa"/>$shadeXml</w:tcPr><w:p><w:r>$bold<w:t xml:space="preserve">$t</w:t></w:r></w:p></w:tc>
"@
}

function New-Row([string[]]$cells, [int[]]$widths, [bool]$header = $false, [string]$shade = '') {
    $cellsXml = ''
    for ($i = 0; $i -lt $cells.Count; $i++) {
        $cellsXml += New-Cell $cells[$i] $widths[$i] $header $shade
    }
    $hdrXml = ''
    if ($header) { $hdrXml = '<w:trPr><w:tblHeader/></w:trPr>' }
    return "<w:tr>$hdrXml$cellsXml</w:tr>"
}

function New-Table([object[]]$rows, [int[]]$widths) {
    $colCount = $widths.Count
    $gridCols = ''
    foreach ($w in $widths) { $gridCols += "<w:gridCol w:w=`"$w`"/>" }

    $rowsXml = ''
    $isFirst = $true
    foreach ($row in $rows) {
        $isHeader = $isFirst
        $shade = ''
        if ($isHeader) { $shade = 'D9E2F3' }
        elseif ($row.Status -eq 'core') { $shade = 'E2EFDA' }
        elseif ($row.Status -eq 'plus') { $shade = 'FCE4D6' }
        elseif ($row.Status -eq 'partial') { $shade = 'FFF2CC' }
        elseif ($row.Status -eq 'missing') { $shade = 'F2F2F2' }
        $rowsXml += New-Row $row.Cells $widths $isHeader $shade
        $isFirst = $false
    }

    return @"
<w:tbl>
<w:tblPr>
  <w:tblStyle w:val="TableGrid"/>
  <w:tblW w:w="9000" w:type="dxa"/>
  <w:tblBorders>
    <w:top w:val="single" w:sz="4" w:space="0" w:color="999999"/>
    <w:left w:val="single" w:sz="4" w:space="0" w:color="999999"/>
    <w:bottom w:val="single" w:sz="4" w:space="0" w:color="999999"/>
    <w:right w:val="single" w:sz="4" w:space="0" w:color="999999"/>
    <w:insideH w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
    <w:insideV w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
  </w:tblBorders>
</w:tblPr>
<w:tblGrid>$gridCols</w:tblGrid>
$rowsXml
</w:tbl>
<w:p/>
"@
}

function Make-Row([string]$endpoint, [string]$desc, [string]$status, [string]$note = '') {
    $core = ''
    $plus = ''
    switch ($status) {
        'core' { $core = 'EVET'; $plus = 'EVET' }
        'plus' { $core = 'HAYIR'; $plus = 'EVET' }
        'partial' { $core = 'KISMEN'; $plus = 'EVET' }
        'missing' { $core = 'YOK'; $plus = 'YOK' }
    }
    return [PSCustomObject]@{
        Cells = @($endpoint, $desc, $core, $plus, $note)
        Status = $status
    }
}

$widths = @(2600, 2700, 700, 700, 2300)
$header = [PSCustomObject]@{ Cells = @('Endpoint','Aciklama','Core','Plus','Not'); Status = 'header' }

$tables = @()

# === MESAJLASMA ===
$mesajlasma = @(
    $header,
    Make-Row 'POST /api/sendText' 'Metin mesaji gonder' 'core'
    Make-Row 'POST /api/sendImage' 'Resim gonder (jpg/png)' 'core' 'NOWEB icin acildi'
    Make-Row 'POST /api/sendFile' 'Dokuman/dosya gonder' 'core' 'NOWEB icin acildi'
    Make-Row 'POST /api/sendVoice' 'Sesli mesaj (opus formatinda olmali)' 'core'
    Make-Row 'POST /api/sendVideo' 'Video gonder (mp4/H.264 olmali)' 'core' 'NOWEB icin acildi'
    Make-Row 'POST /api/send/link-custom-preview' 'Ozel onizlemeli link mesaji' 'core' 'NOWEB icin acildi'
    Make-Row 'POST /api/sendLinkPreview' 'Otomatik onizlemeli link' 'core'
    Make-Row 'POST /api/sendLocation' 'Konum gonder' 'core'
    Make-Row 'POST /api/sendContactVcard' 'Kartvizit gonder' 'core'
    Make-Row 'POST /api/sendButtons' 'Buton mesaji (quick reply)' 'core'
    Make-Row 'POST /api/send/buttons/reply' 'Butona tiklama cevabi' 'core'
    Make-Row 'POST /api/sendList' 'Liste mesaji' 'plus' 'Acilabilir (Baileys listMessage)'
    Make-Row 'POST /api/sendPoll' 'Anket gonder (sadece metin secenek)' 'core'
    Make-Row 'POST /api/sendPollVote' 'Ankete oy ver' 'core'
    Make-Row 'POST /api/forwardMessage' 'Mesaj iletme' 'core'
    Make-Row 'POST /api/reply' 'Bir mesaja cevap' 'core'
    Make-Row 'POST /api/sendSeen' 'Mesaji okundu yap' 'core'
    Make-Row 'POST /api/startTyping' 'Yaziyor durumu baslat' 'core'
    Make-Row 'POST /api/stopTyping' 'Yaziyor durumu bitir' 'core'
    Make-Row 'PUT /api/reaction' 'Mesaja emoji reaksiyonu' 'core'
    Make-Row 'PUT /api/star' 'Mesaji yildizla' 'core'
    Make-Row 'GET /api/messages' 'Sohbetin mesajlarini al' 'core'
    Make-Row 'GET /api/checkNumberStatus' 'Numara WhatsApp kullaniyor mu?' 'core'
    Make-Row 'POST /api/sendImageStatus (status/image)' 'Resim durumu (story)' 'plus'
    Make-Row 'POST /api/sendVoiceStatus (status/voice)' 'Sesli durum' 'plus'
    Make-Row 'POST /api/sendVideoStatus (status/video)' 'Video durumu' 'plus'
    Make-Row 'POST /api/sendTextStatus (status/text)' 'Metin durumu' 'core'
)
$tables += @{ Title = 'Mesajlasma'; Rows = $mesajlasma }

# === OTURUM ===
$oturum = @(
    $header,
    Make-Row 'POST /api/sessions' 'Yeni session olustur' 'core'
    Make-Row 'GET /api/sessions' 'Tum sessionlari listele' 'core'
    Make-Row 'GET /api/sessions/{name}' 'Session detayi' 'core'
    Make-Row 'PUT /api/sessions/{name}' 'Session config guncelle' 'core'
    Make-Row 'DELETE /api/sessions/{name}' 'Session sil' 'core'
    Make-Row 'POST /api/sessions/{name}/start' 'Session baslat' 'core'
    Make-Row 'POST /api/sessions/{name}/stop' 'Session durdur' 'core'
    Make-Row 'POST /api/sessions/{name}/restart' 'Session yeniden baslat' 'core'
    Make-Row 'POST /api/sessions/{name}/logout' 'Cikis yap' 'core'
    Make-Row 'GET /api/sessions/{name}/me' 'Aktif numara/profil bilgisi' 'core'
    Make-Row 'GET /api/{session}/auth/qr' 'QR kod' 'core'
    Make-Row 'POST /api/{session}/auth/request-code' 'Pairing code (telefonla)' 'core'
    Make-Row 'GET /api/screenshot' 'Web ekran goruntusu' 'core' 'WEBJS/WPP icin anlamli'
)
$tables += @{ Title = 'Oturum / Pairing'; Rows = $oturum }

# === PROFIL ===
$profil = @(
    $header,
    Make-Row 'GET /api/{session}/profile' 'Kendi profil bilgisi' 'core'
    Make-Row 'PUT /api/{session}/profile/name' 'Goruntulenen ad guncelle' 'core'
    Make-Row 'PUT /api/{session}/profile/status' 'Durum (about) guncelle' 'core'
    Make-Row 'PUT /api/{session}/profile/picture' 'Profil fotografi degistir' 'plus' 'Acilabilir'
    Make-Row 'DELETE /api/{session}/profile/picture' 'Profil fotografini sil' 'plus' 'Acilabilir'
)
$tables += @{ Title = 'Profil'; Rows = $profil }

# === SOHBETLER ===
$sohbet = @(
    $header,
    Make-Row 'GET /api/{session}/chats' 'Sohbet listesi' 'core'
    Make-Row 'GET /api/{session}/chats/overview' 'Ozet bilgi (son mesaj vb)' 'core'
    Make-Row 'GET /api/{session}/chats/{chatId}/messages' 'Sohbetin mesaj gecmisi' 'core'
    Make-Row 'DELETE /api/{session}/chats/{chatId}' 'Sohbeti sil' 'core'
    Make-Row 'POST /api/{session}/chats/{chatId}/archive' 'Arsivle' 'core'
    Make-Row 'POST /api/{session}/chats/{chatId}/unarchive' 'Arsivden cikar' 'core'
    Make-Row 'POST /api/{session}/chats/{chatId}/unread' 'Okunmadi yap' 'core'
    Make-Row 'POST /api/{session}/chats/{chatId}/messages/read' 'Tum mesajlari okundu yap' 'core'
    Make-Row 'DELETE /api/{session}/chats/{chatId}/messages' 'Tum mesajlari sil (lokal)' 'core'
    Make-Row 'PUT /api/{session}/chats/{chatId}/messages/{id}' 'Mesaj duzenle (edit)' 'core'
    Make-Row 'DELETE /api/{session}/chats/{chatId}/messages/{id}' 'Mesaj sil (revoke)' 'core'
    Make-Row 'POST /api/{session}/chats/{chatId}/messages/{id}/pin' 'Mesaj sabitle' 'core'
    Make-Row 'POST /api/{session}/chats/{chatId}/messages/{id}/unpin' 'Sabitlemeyi kaldir' 'core'
)
$tables += @{ Title = 'Sohbetler'; Rows = $sohbet }

# === GRUPLAR ===
$grup = @(
    $header,
    Make-Row 'GET /api/{session}/groups' 'Grup listesi' 'core'
    Make-Row 'POST /api/{session}/groups' 'Grup olustur' 'core'
    Make-Row 'GET /api/{session}/groups/{id}' 'Grup bilgisi' 'core'
    Make-Row 'DELETE /api/{session}/groups/{id}' 'Grubu sil' 'missing' 'NotImplementedByEngine'
    Make-Row 'POST /api/{session}/groups/{id}/leave' 'Gruptan cik' 'core'
    Make-Row 'GET /api/{session}/groups/{id}/participants' 'Katilimcilari listele' 'core'
    Make-Row 'POST /api/{session}/groups/{id}/participants/add' 'Katilimci ekle' 'core'
    Make-Row 'POST /api/{session}/groups/{id}/participants/remove' 'Katilimci cikar' 'core'
    Make-Row 'POST /api/{session}/groups/{id}/admin/promote' 'Admin yap' 'core'
    Make-Row 'POST /api/{session}/groups/{id}/admin/demote' 'Adminlikten dusur' 'core'
    Make-Row 'GET /api/{session}/groups/{id}/invite-code' 'Davet linki al' 'core'
    Make-Row 'POST /api/{session}/groups/{id}/invite-code/revoke' 'Davet linkini yenile' 'core'
    Make-Row 'PUT /api/{session}/groups/{id}/subject' 'Grup adini degistir' 'core'
    Make-Row 'PUT /api/{session}/groups/{id}/description' 'Grup aciklamasi degistir' 'core'
    Make-Row 'PUT /api/{session}/groups/{id}/picture' 'Grup fotografi' 'core'
    Make-Row 'GET/PUT /api/{session}/groups/{id}/settings/security/info-admin-only' 'Sadece adminler bilgi degistirir' 'core'
    Make-Row 'GET/PUT /api/{session}/groups/{id}/settings/security/messages-admin-only' 'Sadece adminler mesaj atar' 'core'
)
$tables += @{ Title = 'Gruplar'; Rows = $grup }

# === KONTAKLAR ===
$kontak = @(
    $header,
    Make-Row 'GET /api/{session}/contacts/all' 'Tum kontaklar' 'core'
    Make-Row 'GET /api/{session}/contacts' 'Kontak detayi' 'core'
    Make-Row 'GET /api/{session}/contacts/check-exists' 'Numara WhatsAppta var mi' 'core'
    Make-Row 'GET /api/{session}/contacts/about' 'Kontagin durumu' 'core'
    Make-Row 'GET /api/{session}/contacts/profile-picture' 'Kontagin fotografi' 'core'
    Make-Row 'POST /api/{session}/contacts/block-contact' 'Kontagi engelle' 'missing' 'NotImplementedByEngine'
    Make-Row 'POST /api/{session}/contacts/unblock-contact' 'Engeli kaldir' 'missing' 'NotImplementedByEngine'
    Make-Row 'GET /api/{session}/lids' 'LID -> telefon eslesme listesi' 'core'
    Make-Row 'GET /api/{session}/lids/count' 'LID sayisi' 'core'
    Make-Row 'GET /api/{session}/lids/{lid}' 'LID telefon karsiligi' 'core'
)
$tables += @{ Title = 'Kontaklar / LID'; Rows = $kontak }

# === KANALLAR ===
$kanal = @(
    $header,
    Make-Row 'GET /api/{session}/channels' 'Bilinen kanallar' 'core'
    Make-Row 'POST /api/{session}/channels' 'Kanal olustur' 'core' 'Picture acildi'
    Make-Row 'PUT /api/{session}/channels/{id}' 'Kanal guncelle (name/desc/picture)' 'core' 'Yeni eklendi'
    Make-Row 'DELETE /api/{session}/channels/{id}' 'Kanal sil' 'core'
    Make-Row 'GET /api/{session}/channels/{id}' 'Kanal bilgisi' 'core'
    Make-Row 'POST /api/{session}/channels/{id}/follow' 'Kanali takip et' 'core'
    Make-Row 'POST /api/{session}/channels/{id}/unfollow' 'Takipten cik' 'core'
    Make-Row 'POST /api/{session}/channels/{id}/mute' 'Bildirimleri sustur' 'core'
    Make-Row 'POST /api/{session}/channels/{id}/unmute' 'Sesi ac' 'core'
    Make-Row 'GET /api/{session}/channels/{id}/messages/preview' 'Kanalin son mesajlari (onizleme)' 'plus'
    Make-Row 'POST /api/{session}/channels/search/by-view' 'Kanal ara (view ile)' 'plus'
    Make-Row 'POST /api/{session}/channels/search/by-text' 'Kanal ara (metin ile)' 'plus'
    Make-Row 'GET /api/{session}/channels/search/views' 'Arama view listesi' 'plus'
    Make-Row 'GET /api/{session}/channels/search/countries' 'Arama icin ulke listesi' 'plus'
    Make-Row 'GET /api/{session}/channels/search/categories' 'Arama icin kategori listesi' 'plus'
)
$tables += @{ Title = 'Kanallar (Newsletter)'; Rows = $kanal }

# === ETIKETLER ===
$etiket = @(
    $header,
    Make-Row 'GET /api/{session}/labels' 'Tum etiketler' 'core'
    Make-Row 'POST /api/{session}/labels' 'Etiket olustur' 'core'
    Make-Row 'PUT /api/{session}/labels/{id}' 'Etiket guncelle' 'core'
    Make-Row 'DELETE /api/{session}/labels/{id}' 'Etiket sil' 'core'
    Make-Row 'GET /api/{session}/labels/{id}/chats' 'Etiketteki sohbetler' 'core'
    Make-Row 'GET /api/{session}/chats/{chatId}/labels' 'Sohbetin etiketleri' 'core'
    Make-Row 'PUT /api/{session}/chats/{chatId}/labels' 'Sohbete etiket ata' 'core'
)
$tables += @{ Title = 'Etiketler'; Rows = $etiket }

# === PRESENCE ===
$presence = @(
    $header,
    Make-Row 'GET /api/{session}/presence' 'Tum presence durumlari' 'core'
    Make-Row 'GET /api/{session}/presence/{chatId}' 'Bir kontak/grup presence' 'core'
    Make-Row 'POST /api/{session}/presence' 'Kendi presence ayarla (online/offline/typing)' 'partial' 'RECORDING/PAUSED yok'
    Make-Row 'POST /api/{session}/presence/{chatId}/subscribe' 'Bir kontagin presence abone ol' 'core'
)
$tables += @{ Title = 'Presence'; Rows = $presence }

# === MEDIA ===
$medya = @(
    $header,
    Make-Row 'POST /api/{session}/media/convert/voice' 'Ses dosyasini opus formatina cevir' 'plus' 'Disarida ffmpeg ile yapilabilir'
    Make-Row 'POST /api/{session}/media/convert/video' 'Video MP4 cevir (H.264/AAC)' 'plus' 'Disarida ffmpeg ile yapilabilir'
    Make-Row 'GET /api/files/...' 'Indirilmis medyayi statik servis' 'core'
)
$tables += @{ Title = 'Media'; Rows = $medya }

# === EVENTS / WEBHOOK ===
$webhook = @(
    $header,
    Make-Row 'GET /api/events (WebSocket)' 'Realtime event WebSocket' 'core'
    Make-Row 'Webhook (session config webhooks[])' 'HTTP POST event teslimi' 'core' 'Coklu URL, HMAC, retry'
    Make-Row 'Global webhook (env WHATSAPP_HOOK_URL)' 'Tum sessionlar icin tek webhook' 'core'
)
$tables += @{ Title = 'Events / Webhooks'; Rows = $webhook }

# === ARAMALAR ===
$call = @(
    $header,
    Make-Row 'POST /api/{session}/calls/reject' 'Gelen aramayi reddet' 'core'
    Make-Row 'POST /api/{session}/calls/accept' 'Aramayi kabul (sadece event)' 'partial' 'Engine destegine bagli'
)
$tables += @{ Title = 'Aramalar'; Rows = $call }

# === API KEY / SERVER ===
$server = @(
    $header,
    Make-Row 'GET /api/version' 'WAHA versiyon bilgisi' 'core'
    Make-Row 'GET /api/ping' 'Ping' 'core'
    Make-Row 'GET /api/health' 'Saglik kontrolu' 'core'
    Make-Row 'GET /api/server/status' 'Sunucu durumu' 'core'
    Make-Row 'POST /api/server/stop' 'Sunucuyu kapat' 'core'
    Make-Row 'GET /api/server/debug/info' 'Debug bilgisi' 'core'
    Make-Row 'GET /api/apikeys' 'API key listesi' 'core'
    Make-Row 'POST /api/apikeys' 'Yeni API key' 'core'
    Make-Row 'DELETE /api/apikeys/{id}' 'API key sil' 'core'
)
$tables += @{ Title = 'Sunucu / API Key'; Rows = $server }

# === STORAGE ===
$storage = @(
    $header,
    Make-Row 'SQLite session storage (default)' 'Lokal session veritabani' 'core'
    Make-Row 'PostgreSQL session storage' 'Postgres adapter' 'plus'
    Make-Row 'Local disk media storage' 'Indirilen medya disk uzerinde' 'core'
    Make-Row 'S3 media storage' 'Medyayi S3 buckete koy' 'plus'
    Make-Row 'Saglik metrikleri (advanced)' 'Detayli health check' 'plus'
)
$tables += @{ Title = 'Storage / Backend'; Rows = $storage }

# === BUILD DOCUMENT ===
$body = ''
$body += New-Heading 'WAHA Endpointleri - Core vs Plus Karsilastirmasi' 1
$body += New-Para "Olusturulma tarihi: $(Get-Date -Format 'yyyy-MM-dd')"
$body += New-Para 'Bu dokuman WAHA Core surumunde NOWEB engine ile hangi endpointlerin calistigini, hangilerinin Plus gerektirdigini ozetler.'
$body += New-Para 'Hucre renkleri:'
$body += New-Para '  Yesil = Core surumde calisir'
$body += New-Para '  Kirmizi = Sadece Plus surumde calisir'
$body += New-Para '  Sari = Kismen calisir (bazi alt durumlarda eksik)'
$body += New-Para '  Gri = Henuz hicbir surumde implement edilmedi (NotImplementedByEngine)'
$body += New-Para 'Bu projede NOWEB icin acilan ozellikler "Not" sutununda belirtilmistir.'

foreach ($t in $tables) {
    $body += New-Heading $t.Title 2
    $body += New-Table $t.Rows $widths
}

$body += New-Heading 'Engine Karsilastirmasi (kisa)' 2
$body += New-Para 'NOWEB - Baileys (TS, tarayicisiz). Hafif (~100MB/session). Cok session, dusuk maliyet.'
$body += New-Para 'WEBJS - whatsapp-web.js (Puppeteer). Agir (~400MB/session). En genis ozellik kapsami.'
$body += New-Para 'WPP - WPPConnect (Puppeteer). WEBJS alternatifi.'
$body += New-Para 'GOWS - whatsmeow (Go subprocess). NOWEB kadar hafif, multi-device edge case daha iyi.'

$body += New-Heading 'Notlar' 2
$body += New-Para 'sendImage, sendFile, sendVideo, send/link-custom-preview ve channels picture/update ozellikleri NOWEB engine icin bu projede acildi.'
$body += New-Para 'sendList, profile picture set/delete ve media converter de benzer yontemle acilabilir; istek halinde eklenir.'
$body += New-Para 'Webhook icin ayri endpoint yoktur; session config altinda webhooks[] dizisi olarak tanimlanir.'

$documentXml = @"
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:body>
    $body
    <w:sectPr>
      <w:pgSz w:w="11906" w:h="16838"/>
      <w:pgMar w:top="1134" w:right="1134" w:bottom="1134" w:left="1134" w:header="708" w:footer="708" w:gutter="0"/>
    </w:sectPr>
  </w:body>
</w:document>
"@

$contentTypesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>
  <Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>
</Types>
'@

$rootRelsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>
</Relationships>
'@

$documentRelsXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>
'@

$stylesXml = @'
<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">
  <w:style w:type="paragraph" w:default="1" w:styleId="Normal">
    <w:name w:val="Normal"/>
    <w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri"/><w:sz w:val="22"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading1">
    <w:name w:val="Heading 1"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:pPr><w:spacing w:before="240" w:after="120"/></w:pPr>
    <w:rPr><w:b/><w:color w:val="1F3864"/><w:sz w:val="36"/></w:rPr>
  </w:style>
  <w:style w:type="paragraph" w:styleId="Heading2">
    <w:name w:val="Heading 2"/>
    <w:basedOn w:val="Normal"/>
    <w:next w:val="Normal"/>
    <w:pPr><w:spacing w:before="200" w:after="100"/></w:pPr>
    <w:rPr><w:b/><w:color w:val="2E74B5"/><w:sz w:val="28"/></w:rPr>
  </w:style>
  <w:style w:type="table" w:styleId="TableGrid">
    <w:name w:val="Table Grid"/>
    <w:tblPr>
      <w:tblBorders>
        <w:top w:val="single" w:sz="4" w:space="0" w:color="999999"/>
        <w:left w:val="single" w:sz="4" w:space="0" w:color="999999"/>
        <w:bottom w:val="single" w:sz="4" w:space="0" w:color="999999"/>
        <w:right w:val="single" w:sz="4" w:space="0" w:color="999999"/>
        <w:insideH w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
        <w:insideV w:val="single" w:sz="4" w:space="0" w:color="CCCCCC"/>
      </w:tblBorders>
    </w:tblPr>
  </w:style>
</w:styles>
'@

# Build the docx (zip)
$tmp = Join-Path $env:TEMP ("waha_doc_" + [Guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Path $tmp -Force | Out-Null
New-Item -ItemType Directory -Path "$tmp\_rels" -Force | Out-Null
New-Item -ItemType Directory -Path "$tmp\word" -Force | Out-Null
New-Item -ItemType Directory -Path "$tmp\word\_rels" -Force | Out-Null

[System.IO.File]::WriteAllText("$tmp\[Content_Types].xml", $contentTypesXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText("$tmp\_rels\.rels", $rootRelsXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText("$tmp\word\document.xml", $documentXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText("$tmp\word\_rels\document.xml.rels", $documentRelsXml, [System.Text.UTF8Encoding]::new($false))
[System.IO.File]::WriteAllText("$tmp\word\styles.xml", $stylesXml, [System.Text.UTF8Encoding]::new($false))

if (Test-Path $OutputPath) { Remove-Item $OutputPath -Force }

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem
[System.IO.Compression.ZipFile]::CreateFromDirectory($tmp, $OutputPath, [System.IO.Compression.CompressionLevel]::Optimal, $false)

Remove-Item $tmp -Recurse -Force

Write-Host "Yazildi: $OutputPath"
Write-Host "Boyut: $((Get-Item $OutputPath).Length) bayt"
