/// Centralized Turkish UI strings for Neuro Word.
class AppStrings {
  AppStrings._();

  // ── App ─────────────────────────────────────────────────────────────
  static const appTitle = 'Neuro Word';
  static const appSubtitle = 'İngilizce Öğrenme Platformu';

  // ── Splash ──────────────────────────────────────────────────────────
  static const splashLoading = 'Sistem başlatılıyor...';

  // ── Dashboard ───────────────────────────────────────────────────────
  static const welcomeBack = 'Tekrar Hoş Geldin';
  static const heroDescription =
      'Kapsamlı İngilizce-Türkçe dil öğrenme platformun. '
      'Akıllı alıştırmalarla kelime, gramer ve konuşma becerilerini geliştir.';
  static const startLearning = 'Öğrenmeye Başla';
  static const exploreModules = 'Modülleri Keşfet';

  // Quick Stats
  static const wordsLearned = 'Öğrenilen\nKelime';
  static const totalWords = 'Toplam\nKelime';
  static const levelsAvailable = 'Mevcut\nSeviye';

  // Learning Modules
  static const learningModules = 'Öğrenme Modülleri';
  static const learningModulesSubtitle =
      'Etkileşimli, yapay zeka destekli alıştırmalarla İngilizce öğren.';
  static const flashcards = 'Kartlar';
  static const flashcardsDesc = 'Kaydırılabilir 3D holografik kartlar';
  static const cyberMatch = 'Cyber-Match';
  static const cyberMatchDesc = 'İngilizce-Türkçe eşleştirme';
  static const neonPulse = 'Neon Pulse';
  static const neonPulseDesc = 'Hızlı 10 saniyelik zamanlı quiz';
  static const grammar = 'Gramer';
  static const grammarDesc = 'Etkileşimli gramer kuralları ve pratik';
  static const listening = 'Dinleme';
  static const listeningDesc = 'Anlama için sesli alıştırmalar';
  static const progress = 'İlerleme';
  static const progressDesc = 'Gelişimini takip et ve analiz yap';
  static const soon = 'YAKINDA';

  // Neural Data Stream
  static const neuralDataStream = 'Kelime Veritabanı';
  static const dataStreamSubtitle = 'Yerel JSON dosyasından yüklenen veri.';
  static const shuffle = 'Karıştır';
  static const reload = 'Yenile';
  static const entries = 'kayıt';
  static const noWordsFound = 'Bu filtre için kelime bulunamadı.';
  static const loadMore = 'DAHA FAZLA YÜKLE';
  static const remaining = 'kalan';
  static const dataStreamError = 'VERİ HATASI';
  static const all = 'TÜMÜ';

  // ── Menu ─────────────────────────────────────────────────────────────
  static const supporters = 'Destek Verenler';
  static const contact = 'İletişim';

  // ── Profile ─────────────────────────────────────────────────────────
  static const profile = 'PROFİL';
  static const learner = 'ÖĞRENCİ';
  static const level = 'Seviye';
  static const learned = 'Öğrenilen';
  static const totalWordsLabel = 'Toplam Kelime';
  static const progressLabel = 'İlerleme';
  static const levelBreakdown = 'Seviye Dağılımı';
  static const categoryDistribution = 'Kategori Dağılımı';

  // ── Games ───────────────────────────────────────────────────────────
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

  // ── Session Summary ─────────────────────────────────────────────────
  static const sessionComplete = 'Oturum Tamamlandı!';
  static const wordsLearnedLabel = 'Öğrenilen Kelime';
  static const totalWordsInSession = 'Toplam Kelime';
  static const accuracyLabel = 'Başarı Oranı';
  static const greatJob = 'Harika iş!';
  static String keepPracticing(double percent) => '%${percent.toStringAsFixed(1)} tamamlandı';
  static const backToDashboard = 'Ana Sayfaya Dön';
  static const wordJourneyTitle = '2000 Kelimelik Yolculuk';
  static String progressSubtitle(int learned, int total) => '$total kelimeden $learned tanesi öğrenildi';
  static const missed = 'Bilinmeyen';

  // ── Contact ─────────────────────────────────────────────────────────
  static const contactTitle = 'İLETİŞİM';
  static const contactDescription =
      'Sorularınız ve destek için geliştiriciye ulaşın:';
  static const contactEmail = 'abdulselam4763@gmail.com';
  static const sendEmail = 'E-posta Gönder';
  static const contactNote =
      'Geri bildirimleriniz uygulamamızı geliştirmemize yardımcı olur. '
      'Teşekkür ederiz!';

  // ── Supporters ──────────────────────────────────────────────────────
  static const supportersTitle = 'DESTEK VERENLER';
  static const supportersDescription =
      'Bu uygulamanın geliştirilmesine katkıda bulunan herkese teşekkürler.';
  static const developerLabel = 'Geliştirici';
  static const developerName = 'Abdülselam Kaya';
  static const specialThanks = 'Özel Teşekkürler';
  static const communitySupport =
      'Tüm beta test kullanıcılarına ve geri bildirim sağlayan topluluğumuza teşekkür ederiz.';
}
