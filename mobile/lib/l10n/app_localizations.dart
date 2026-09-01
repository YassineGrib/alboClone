import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      // Common & App
      'appTitle': 'Later',
      'tagline': 'Save a link. Find it again.',
      'skip': 'Skip',
      'next': 'Next',
      'getStarted': 'Get Started',
      'cancel': 'Cancel',
      'save': 'Save',
      'delete': 'Delete',
      'edit': 'Edit',
      'search': 'Search links...',

      // Onboarding
      'onboarding1Title': 'Share From Any App',
      'onboarding1Desc': 'Save links, videos, recipes, or articles directly from TikTok, Instagram, YouTube, or your browser in one tap.',
      'onboarding2Title': 'AI Summaries & Tags',
      'onboarding2Desc': 'Automatic concise titles, AI summaries, and smart categorization powered by Gemini AI so you never lose context.',
      'onboarding3Title': 'Save Now, Read Calmly',
      'onboarding3Desc': 'A serene, offline-first home for your saved bookmarks with collections, instant search, and location map pins.',

      // Auth
      'login': 'Log in',
      'createAccount': 'Create account',
      'fullName': 'Full Name',
      'email': 'Email',
      'password': 'Password',
      'signInWithGoogle': 'Sign in with Google',
      'server': 'Server',
      'signingIn': 'Signing in...',
      'creatingAccount': 'Creating account...',
      'localSeedNotice': 'Local seed is you@local.test / password.',

      // Settings
      'settings': 'Settings',
      'general': 'General',
      'geminiAi': 'Gemini AI',
      'guide': 'Guide',
      'backupAndRestore': 'Backup & Restore',
      'backupAndRestoreSub': 'Export your collections and saved links to JSON, or restore from a backup file.',
      'exportBackup': 'Export',
      'exporting': 'Exporting...',
      'restoreFile': 'Restore',
      'restoring': 'Restoring...',
      'serverConnection': 'Server Connection',
      'serverConnectionSub': 'The phone talks to this backend API URL.',
      'apiUrl': 'API URL',
      'testConnection': 'Test Connection',
      'testing': 'Testing...',
      'syncStatusTitle': 'Sync Status & Diagnostics',
      'syncStatusSub': 'Local sqlite & server synchronization status',
      'syncEverythingNow': 'Sync Everything Now',
      'syncing': 'Syncing...',
      'synced': 'Synced',
      'pending': 'Pending',
      'failed': 'Failed',
      'appearance': 'Appearance',
      'appearanceSub': 'Follows the phone unless you pin Light or Dark.',
      'system': 'System',
      'light': 'Light',
      'dark': 'Dark',
      'language': 'Language',
      'languageSub': 'Choose the interface display language.',
      'auto': 'Auto',
      'cacheAndStorage': 'Cache & Storage',
      'cacheSub': 'Manage locally cached link previews and thumbnail images.',
      'clearImageCache': 'Clear Image Cache',
      'legalAndPrivacy': 'Legal & Privacy',
      'legalSub': 'Privacy policy, terms of service, and encryption',
      'privacyPolicy': 'Privacy Policy',
      'termsOfService': 'Terms of Service',
      'dataSafety': 'Data Safety & Encryption',
      'dataSafetySub': 'All data is transmitted via TLS / HTTPS',
      'sessionAndAccount': 'Session & Account',
      'sessionSub': 'Manage authentication and data removal',
      'logOut': 'Log out',
      'deleteAccountAndData': 'Delete Account & Data',
      'replayOnboarding': 'Replay Onboarding Carousel',
    },
    'ar': {
      // Common & App
      'appTitle': 'Later',
      'tagline': 'احفظ الرابط. اعثر عليه لاحقاً.',
      'skip': 'تخطي',
      'next': 'التالي',
      'getStarted': 'ابدأ الآن',
      'cancel': 'إلغاء',
      'save': 'حفظ',
      'delete': 'حذف',
      'edit': 'تعديل',
      'search': 'البحث في الروابط...',

      // Onboarding
      'onboarding1Title': 'مشاركة من أي تطبيق',
      'onboarding1Desc': 'احفظ الروابط والفيديوهات والوصفات والمقالات مباشرة من تيك توك، إنستغرام، يوتيوب، أو المتصفح بنقرة واحدة.',
      'onboarding2Title': 'ملخصات ووسوم بالذكاء الاصطناعي',
      'onboarding2Desc': 'عناوين مختصرة تلقائية وملخصات ذكية وتصنيف تلقائي مدعوم بـ Gemini AI حتى لا تفقد سياق المحتوى.',
      'onboarding3Title': 'احفظ الآن، واقرأ بهدوء',
      'onboarding3Desc': 'ملاذ هادئ بدون إنترنت لجميع روابطك المحفوظة مع المجموعات والبحث الفوري ودبابيس الخريطة.',

      // Auth
      'login': 'تسجيل الدخول',
      'createAccount': 'إنشاء حساب',
      'fullName': 'الاسم الكامل',
      'email': 'البريد الإلكتروني',
      'password': 'كلمة المرور',
      'signInWithGoogle': 'تسجيل الدخول عبر Google',
      'server': 'السيرفر',
      'signingIn': 'جاري الدخول...',
      'creatingAccount': 'جاري إنشاء الحساب...',
      'localSeedNotice': 'الحساب المحلي الافتراضي هو you@local.test / password.',

      // Settings
      'settings': 'الإعدادات',
      'general': 'عام',
      'geminiAi': 'ذكاء Gemini',
      'guide': 'الدليل',
      'backupAndRestore': 'النسخ الاحتياطي والاستعادة',
      'backupAndRestoreSub': 'تصدير مجموعاتك وروابطك إلى ملف JSON، أو استعادتها من ملف نسختك الاحتياطية.',
      'exportBackup': 'تصدير',
      'exporting': 'جاري التصدير...',
      'restoreFile': 'استعادة',
      'restoring': 'جاري الاستعادة...',
      'serverConnection': 'الاتصال بالسيرفر',
      'serverConnectionSub': 'عنوان API الخادم الخاص بالتطبيق.',
      'apiUrl': 'رابط الـ API',
      'testConnection': 'فحص الاتصال',
      'testing': 'جاري الفحص...',
      'syncStatusTitle': 'حالة المزامنة والتشخيص',
      'syncStatusSub': 'حالة المزامنة بين قاعدة البيانات المحلية والسيرفر',
      'syncEverythingNow': 'مزامنة كل شيء الآن',
      'syncing': 'جاري المزامنة...',
      'synced': 'تمت المزامنة',
      'pending': 'معلق',
      'failed': 'فشل',
      'appearance': 'المظهر',
      'appearanceSub': 'يتبع إعدادات الهاتف إلا إذا حددت الداكن أو الفاتح.',
      'system': 'النظام',
      'light': 'فاتح',
      'dark': 'داكن',
      'language': 'اللغة',
      'languageSub': 'اختر لغة عرض الواجهة للتطبيق.',
      'auto': 'تلقائي',
      'cacheAndStorage': 'الذاكرة المؤقتة والتخزين',
      'cacheSub': 'إدارة المعاينات والصور المخزنة مؤقتاً.',
      'clearImageCache': 'مسح الذاكرة المؤقتة للصور',
      'legalAndPrivacy': 'الخصوصية والشروط',
      'legalSub': 'سياسة الخصوصية وشروط الخدمة وأمان البيانات',
      'privacyPolicy': 'سياسة الخصوصية',
      'termsOfService': 'شروط الخدمة',
      'dataSafety': 'أمان البيانات والتشفير',
      'dataSafetySub': 'جميع البيانات مشفرة وتُنقل عبر TLS / HTTPS',
      'sessionAndAccount': 'الجلسة والحساب',
      'sessionSub': 'إدارة تسجيل الدخول وحذف البيانات',
      'logOut': 'تسجيل الخروج',
      'deleteAccountAndData': 'حذف الحساب والبيانات',
      'replayOnboarding': 'إعادة عرض شاشة الترحيب',
    },
    'fr': {
      // Common & App
      'appTitle': 'Later',
      'tagline': 'Enregistrez un lien. Retrouvez-le facilement.',
      'skip': 'Passer',
      'next': 'Suivant',
      'getStarted': 'Commencer',
      'cancel': 'Annuler',
      'save': 'Enregistrer',
      'delete': 'Supprimer',
      'edit': 'Modifier',
      'search': 'Rechercher des liens...',

      // Onboarding
      'onboarding1Title': 'Partagez depuis n’importe quelle application',
      'onboarding1Desc': 'Sauvegardez des liens, vidéos, recettes ou articles directement depuis TikTok, Instagram, YouTube ou votre navigateur en un tap.',
      'onboarding2Title': 'Résumés et tags par IA',
      'onboarding2Desc': 'Titres concis automatiques, résumés IA et catégorisation intelligente propulsés par Gemini IA.',
      'onboarding3Title': 'Sauvegardez maintenant, lisez sereinement',
      'onboarding3Desc': 'Un espace calme et hors-ligne pour vos favoris avec collections, recherche instantanée et carte interactive.',

      // Auth
      'login': 'Se connecter',
      'createAccount': 'Créer un compte',
      'fullName': 'Nom complet',
      'email': 'E-mail',
      'password': 'Mot de passe',
      'signInWithGoogle': 'Se connecter avec Google',
      'server': 'Serveur',
      'signingIn': 'Connexion en cours...',
      'creatingAccount': 'Création du compte...',
      'localSeedNotice': 'Compte local de test: you@local.test / password.',

      // Settings
      'settings': 'Paramètres',
      'general': 'Général',
      'geminiAi': 'IA Gemini',
      'guide': 'Guide',
      'backupAndRestore': 'Sauvegarde et Restauration',
      'backupAndRestoreSub': 'Exportez vos collections et liens au format JSON, ou restaurez depuis un fichier.',
      'exportBackup': 'Exporter',
      'exporting': 'Exportation...',
      'restoreFile': 'Restaurer',
      'restoring': 'Restauration...',
      'serverConnection': 'Connexion au serveur',
      'serverConnectionSub': 'Adresse API du serveur distant.',
      'apiUrl': 'URL de l’API',
      'testConnection': 'Tester la connexion',
      'testing': 'Test en cours...',
      'syncStatusTitle': 'Statut de synchronisation',
      'syncStatusSub': 'État de synchronisation entre la base locale et le serveur',
      'syncEverythingNow': 'Tout synchroniser maintenant',
      'syncing': 'Synchronisation...',
      'synced': 'Synchronisé',
      'pending': 'En attente',
      'failed': 'Échoué',
      'appearance': 'Apparence',
      'appearanceSub': 'Suit le système sauf si vous fixez Clair ou Sombre.',
      'system': 'Système',
      'light': 'Clair',
      'dark': 'Sombre',
      'language': 'Langue',
      'languageSub': 'Choisissez la langue d’affichage de l’interface.',
      'auto': 'Auto',
      'cacheAndStorage': 'Cache et Stockage',
      'cacheSub': 'Gérer les aperçus d’images enregistrés en cache.',
      'clearImageCache': 'Vider le cache d’images',
      'legalAndPrivacy': 'Confidentialité et Conditions',
      'legalSub': 'Politique de confidentialité, conditions et sécurité',
      'privacyPolicy': 'Politique de confidentialité',
      'termsOfService': 'Conditions d’utilisation',
      'dataSafety': 'Sécurité des données & Chiffrement',
      'dataSafetySub': 'Toutes les données sont transmises via TLS / HTTPS',
      'sessionAndAccount': 'Session et Compte',
      'sessionSub': 'Gérer l’authentification et la suppression du compte',
      'logOut': 'Se déconnecter',
      'deleteAccountAndData': 'Supprimer le compte et les données',
      'replayOnboarding': 'Revoir le carrousel d’accueil',
    },
  };

  String get(String key) {
    final lang = locale.languageCode;
    return _localizedValues[lang]?[key] ??
        _localizedValues['en']?[key] ??
        key;
  }
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      ['en', 'ar', 'fr'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(AppLocalizations(locale));
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

extension AppLocalizationsX on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
