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
  static const neuralHack = 'Neural Hack';
  static const neuralHackDesc = 'Düşen kelimeleri yakala, firewall\'u koru';

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
  static String keepPracticing(double percent) => '%${percent.toStringAsFixed(1)} tamamlandı';
  static const backToDashboard = 'Ana Sayfaya Dön';
  static const wordJourneyTitle = '2000 Kelimelik Yolculuk';
  static String progressSubtitle(int learned, int total) => '$total kelimeden $learned tanesi öğrenildi';
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
}
