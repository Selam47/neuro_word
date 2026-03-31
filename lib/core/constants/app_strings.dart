class AppStrings {
  AppStrings._();

  static const appTitle = 'Neuro Word';

  static const learningModules = 'Öğrenme Modülleri';
  static const learningModulesSubtitle =
      'Etkileşimli, yapay zeka destekli alıştırmalarla İngilizce öğren.';
  static const flashcards = 'Kartlar';
  static const flashcardsDesc = 'Kaydırılabilir 3D holografik kartlar';
  static const cyberMatch = 'Cyber-Match';
  static const cyberMatchDesc = 'İngilizce-Türkçe eşleştirme';
  static const neonPulse = 'Neon Pulse';
  static const neonPulseDesc = 'Hızlı 10 saniyelik zamanlı quiz';
  static const flashMemory = 'Flash Memory';
  static const flashMemoryDesc = 'Kelimeyi hafızana kazı, zamanla yarış';

  static const neuralDataStream = 'Kelime Veritabanı';
  static const dataStreamSubtitle = 'Supabase veritabanından yüklenen veri.';
  static const loadMore = 'DAHA FAZLA YÜKLE';
  static const remaining = 'kalan';

  static const profile = 'PROFİL';
  static const learner = 'ÖĞRENCİ';
  static const level = 'Seviye';
  static const learned = 'Öğrenilen';
  static const totalWordsLabel = 'Toplam Kelime';
  static const progressLabel = 'İlerleme';
  static const levelBreakdown = 'Seviye Dağılımı';
  static const categoryDistribution = 'Kategori Dağılımı';

  static const savedCollection = 'HAFIZA BANKASI';
  static const savedCollectionEmpty =
      'Henüz kaydedilmiş bir veri bulunamadı.';
  static const masteredCollection = 'NÖRAL ARŞİV';
  static const masteredCollectionEmpty =
      'Nöral arşivde henüz veri yok.\nKelimelere tıklayarak öğrenildi olarak işaretle.';
  static const mastered = 'USTALAŞILDI';
  static const rankHierarchy = 'RANK HİYERARŞİSİ';

  static const correct = 'Doğru';
  static const wrong = 'Yanlış';
  static const score = 'Puan';
  static const timeUp = 'Süre Doldu!';
  static const nextWord = 'Sonraki Kelime';
  static const finish = 'Bitir';
  static const dashboard = 'Ana Sayfa';
  static const swipeRightToLearn = 'Öğrenmek için sağa kaydır';
  static const swipeLeftToSkip = 'Atlamak için sola kaydır';
  static const roundOf = 'Tur';
  static const matched = 'eşleşti';
  static const round = 'Tur';

  static const sessionComplete = 'Oturum Tamamlandı!';
  static const wordsLearnedLabel = 'Öğrenilen Kelime';
  static const totalWordsInSession = 'Toplam Kelime';
  static const accuracyLabel = 'Başarı Oranı';
  static const greatJob = 'Harika iş!';
  static String keepPracticing(double percent) =>
      '%${percent.toStringAsFixed(1)} tamamlandı';
  static const backToDashboard = 'Ana Sayfaya Dön';
  static const wordJourneyTitle = '2000 Kelimelik Yolculuk';
  static String progressSubtitle(int learned, int total) =>
      '$total kelimeden $learned tanesi öğrenildi';
  static const missed = 'Bilinmeyen';

  static const contactTitle = 'İLETİŞİM';
  static const contactDescription =
      'Sorularınız ve destek için geliştiriciye ulaşın:';
  static const contactEmail = 'abdulselam4763@gmail.com';
  static const sendEmail = 'E-posta Gönder';
  static const contactNote =
      'Geri bildirimleriniz uygulamamızı geliştirmemize yardımcı olur. '
      'Teşekkür ederiz!';

  static const supportersTitle = 'UYGULAMA HAKKINDA';

  static const legalDisclaimer =
      'Bu uygulama, Oxford University Press tarafından yayınlanan '
      'halka açık kelime listelerinden esinlenerek hazırlanmış '
      'bağımsız bir araçtır.';

  static const systemInitializing = 'SİSTEM BAŞLATILIYOR...';
  static const levelWarning =
      'Dikkat: Seviye seçiminize göre kişiselleştirilmiş '
      'kelime veri kümesi yükleniyor...';
  static const onboardingSubtitle = 'İngilizce öğrenmenin geleceği';
  static const usernamePrompt = 'KULLANICI ADIN NE?';
  static const usernamePlaceholder = 'Örn: Alex, Kaşif, Mira...';
  static const selectLevel = 'SEVİYENİ SEÇ';
  static const startButton = 'BAŞLA';
  static const skipButton = 'Şimdi değil, atla';
  static const continueButton = 'DEVAM ET';
  static const loginButton = 'GİRİŞ YAP';
  static const searchHint = 'Ara (Kelime veya Anlam)...';
  static const welcomeMessage = 'HOŞ GELDİNİZ';

  static const menuAbout = 'Uygulama Hakkında';
  static const menuContact = 'İletişim';
  static const menuExplore = 'Keşfet';
  static const retryButton = 'YENİDEN DENE';
  static const dataFlowError = 'Veri Akış Hatası';
  static const noDataFound = 'Sistemde böyle bir veri bulunamadı';
  static const allFilter = 'Tümü';
  static const savedFilter = 'Kaydedilenler';
  static const selectLevelSheet = 'SEVİYE SEÇ';
  static const selectLevelPrompt = 'Hangi seviyede pratik yapmak istiyorsun?';
  static const allLevels = 'Tüm Seviyeler';
  static const locked = 'KİLİTLİ';
  static const active = 'AKTİF';
  static const unlocked = 'KİLİT AÇIK';
  static String wordCount(int count) => '$count kelime';
  static const noWordsLoaded = 'Kelime yüklenmedi';
  static String unlockPrompt(String pct) =>
      'Kilidi aç: B2\'yi %$pct → %60 tamamla';
  static String masteryRequired(int pct) => '%$pct ustalık gerekli';

  static const statsTotal = 'Toplam';
  static const statsLearned = 'Öğrenilen';
  static const statsFavorite = 'Favori';

  static const developer = 'GELİŞTİRİCİ';
  static const supporter = 'DESTEK VEREN';
}
