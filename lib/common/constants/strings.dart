import 'dart:ui' show Locale;

import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:lizunemu/core/di/service_locator.dart';
import 'package:lizunemu/core/logging/app_log_level.dart';
import 'package:lizunemu/core/settings/app_settings_service.dart';

/// Central UI copy — backed by generated [AppLocalizations].
class Strings {
  Strings._();

  static const String feedbackUrl = 'https://github.com/yami-codes/LizuNemu/issues';
  static const String repoUrl = 'https://github.com/yami-codes/LizuNemu';
  static const String originalRepoUrl = 'https://github.com/asmroneapp/Yuro';
  static const String telegramChannelUrl = 'https://t.me/LizuNemu';

  static AppLocalizations get _l10n {
    try {
      return lookupAppLocalizations(getIt<AppSettingsService>().stringsLocale);
    } catch (_) {
      return lookupAppLocalizations(const Locale('zh'));
    }
  }

  static String get a11yUserAccount => _l10n.a11yUserAccount;
  static String get about => _l10n.about;
  static String get aboutAppDescription => _l10n.aboutAppDescription;
  static String get aboutAppName => _l10n.aboutAppName;
  static String get aboutFooter => _l10n.aboutFooter;
  static String get aboutUs => _l10n.aboutUs;
  static String get actionChecking => _l10n.actionChecking;
  static String get actionFavorite => _l10n.actionFavorite;
  static String get actionMark => _l10n.actionMark;
  static String get actionNoRecommend => _l10n.actionNoRecommend;
  static String get actionRate => _l10n.actionRate;
  static String get addToPlaylist => _l10n.addToPlaylist;
  static String get appName => _l10n.appName;
  static String get appearance => _l10n.appearance;
  static String get audioCache => _l10n.audioCache;
  static String get audioDownloadPrompt => _l10n.audioDownloadPrompt;
  static String get audioDownloadTitle => _l10n.audioDownloadTitle;
  static String get audioFormatHint => _l10n.audioFormatHint;
  static String get audioFormatPreference => _l10n.audioFormatPreference;
  static String get backgroundPlay => _l10n.backgroundPlay;
  static String get backgroundPlayDesc => _l10n.backgroundPlayDesc;
  static String get batchDownloadCancelled => _l10n.batchDownloadCancelled;
  static String get batchDownloadEmpty => _l10n.batchDownloadEmpty;
  static String get batchDownloadTitle => _l10n.batchDownloadTitle;
  static String get browseAllCircles => _l10n.browseAllCircles;
  static String get browseAllTags => _l10n.browseAllTags;
  static String get browseAllVoiceActors => _l10n.browseAllVoiceActors;
  static String get browseEmptyCircles => _l10n.browseEmptyCircles;
  static String get browseEmptyTags => _l10n.browseEmptyTags;
  static String get browseEmptyVoiceActors => _l10n.browseEmptyVoiceActors;
  static String get browseSearchCirclesHint => _l10n.browseSearchCirclesHint;
  static String get browseSearchTagsHint => _l10n.browseSearchTagsHint;
  static String get browseSearchVoiceActorsHint => _l10n.browseSearchVoiceActorsHint;
  static String get cacheClean => _l10n.cacheClean;
  static String get cacheCleanAll => _l10n.cacheCleanAll;
  static String get cacheExplainBody => _l10n.cacheExplainBody;
  static String get cacheExplainTitle => _l10n.cacheExplainTitle;
  static String get cacheManager => _l10n.cacheManager;
  static String get cancel => _l10n.cancel;
  static String get cannotOpenLink => _l10n.cannotOpenLink;
  static String get checkForUpdates => _l10n.checkForUpdates;
  static String get circles => _l10n.circles;
  static String get colorVariantBlue => _l10n.colorVariantBlue;
  static String get colorVariantDesc => _l10n.colorVariantDesc;
  static String get colorVariantGreen => _l10n.colorVariantGreen;
  static String get colorVariantMono => _l10n.colorVariantMono;
  static String get colorVariantTitle => _l10n.colorVariantTitle;
  static String get comingSoon => _l10n.comingSoon;
  static String get confirm => _l10n.confirm;
  static String get confirmLogout => _l10n.confirmLogout;
  static String get content => _l10n.content;
  static String get darkMode => _l10n.darkMode;
  static String get darkModeMenu => _l10n.darkModeMenu;
  static String get detail => _l10n.detail;
  static String get detailPlaceholder => _l10n.detailPlaceholder;
  static String get dialogConfirm => _l10n.dialogConfirm;
  static String get dialogHint => _l10n.dialogHint;
  static String get downloadAllTooltip => _l10n.downloadAllTooltip;
  static String get downloadCancel => _l10n.downloadCancel;
  static String get downloadCancelled => _l10n.downloadCancelled;
  static String get downloadConfirm => _l10n.downloadConfirm;
  static String get downloadIoError => _l10n.downloadIoError;
  static String get downloadNetworkError => _l10n.downloadNetworkError;
  static String get downloadOpenFailed => _l10n.downloadOpenFailed;
  static String get downloadSuccess => _l10n.downloadSuccess;
  static String get downloadToLocalTooltip => _l10n.downloadToLocalTooltip;
  static String get downloading => _l10n.downloading;
  static String get downloadsEmpty => _l10n.downloadsEmpty;
  static String downloadsFileCountSummary(int count, String size) =>
      _l10n.downloadsFileCountSummary(count, size);
  static String get downloadsPlayA11y => _l10n.downloadsPlayA11y;
  static String get downloadsTitle => _l10n.downloadsTitle;
  static String get equalizerDesc => _l10n.equalizerDesc;
  static String get equalizerEnable => _l10n.equalizerEnable;
  static String get equalizerTitle => _l10n.equalizerTitle;
  static String get equalizerUnsupported => _l10n.equalizerUnsupported;
  static String get dlsiteCookieHint => _l10n.dlsiteCookieHint;
  static String get dlsiteCookieSave => _l10n.dlsiteCookieSave;
  static String get dlsiteDisclaimer => _l10n.dlsiteDisclaimer;
  static String get dlsiteLibraryTitle => _l10n.dlsiteLibraryTitle;
  static String get dlsiteLoginRequired => _l10n.dlsiteLoginRequired;
  static String get dlsiteLoginTitle => _l10n.dlsiteLoginTitle;
  static String get dlsiteLogout => _l10n.dlsiteLogout;
  static String get librarySegmentBrowse => _l10n.librarySegmentBrowse;
  static String get librarySegmentLocal => _l10n.librarySegmentLocal;
  static String localLibraryTrackCount(int count) =>
      _l10n.localLibraryTrackCount(count);
  static String get localLibraryAddFolder => _l10n.localLibraryAddFolder;
  static String get localLibraryEmpty => _l10n.localLibraryEmpty;
  static String get localLibraryNoAlbums => _l10n.localLibraryNoAlbums;
  static String get localLibraryScan => _l10n.localLibraryScan;
  static String get localLibraryScanFolders => _l10n.localLibraryScanFolders;
  static String get playlistsTitle => _l10n.playlistsTitle;
  static String get drawerSectionContent => _l10n.drawerSectionContent;
  static String get drawerSectionDiscover => _l10n.drawerSectionDiscover;
  static String get drawerSectionSystem => _l10n.drawerSectionSystem;
  static String get error => _l10n.error;
  static String get favorites => _l10n.favorites;
  static String get feedback => _l10n.feedback;
  static String get fileList => _l10n.fileList;
  static String get filterOrderAllAges => _l10n.filterOrderAllAges;
  static String get filterOrderCreateDate => _l10n.filterOrderCreateDate;
  static String get filterOrderDefault => _l10n.filterOrderDefault;
  static String get filterOrderMyRating => _l10n.filterOrderMyRating;
  static String get filterOrderPrice => _l10n.filterOrderPrice;
  static String get filterOrderRandom => _l10n.filterOrderRandom;
  static String get filterOrderRating => _l10n.filterOrderRating;
  static String get filterOrderRelease => _l10n.filterOrderRelease;
  static String get filterOrderReview => _l10n.filterOrderReview;
  static String get filterOrderRj => _l10n.filterOrderRj;
  static String get filterOrderSales => _l10n.filterOrderSales;
  static String get filterMoreOptions => _l10n.filterMoreOptions;
  static String get filterTags => _l10n.filterTags;
  static String get filterTagInclude => _l10n.filterTagInclude;
  static String get filterTagExclude => _l10n.filterTagExclude;
  static String filterTagAddedInclude(String tag) =>
      _l10n.filterTagAddedInclude(tag);
  static String filterTagAddedExclude(String tag) =>
      _l10n.filterTagAddedExclude(tag);
  static String filterTagsSelected(int count) => _l10n.filterTagsSelected(count);
  static String get filterPickTags => _l10n.filterPickTags;
  static String get filterClearTags => _l10n.filterClearTags;
  static String filterApplyTags(int count) => _l10n.filterApplyTags(count);
  static String get filterAgeAny => _l10n.filterAgeAny;
  static String get filterAgeGeneral => _l10n.filterAgeGeneral;
  static String get filterAgeAdult => _l10n.filterAgeAdult;
  static String get filterPresetLatest => _l10n.filterPresetLatest;
  static String get filterPresetPrice => _l10n.filterPresetPrice;
  static String get filterPresetRating => _l10n.filterPresetRating;
  static String get filterPresetRelease => _l10n.filterPresetRelease;
  static String get filterPresetSales => _l10n.filterPresetSales;
  static String get followSystem => _l10n.followSystem;
  static String get goLogin => _l10n.goLogin;
  static String get gridEmpty => _l10n.gridEmpty;
  static String get hasSubtitle => _l10n.hasSubtitle;
  static String get haveAccountCta => _l10n.haveAccountCta;
  static String get home => _l10n.home;
  static String get homeSearchHint => _l10n.homeSearchHint;
  static String get homeTitlePopular => _l10n.homeTitlePopular;
  static String get homeTitleRecommend => _l10n.homeTitleRecommend;
  static String get imageCache => _l10n.imageCache;
  static String get imagePreviewError => _l10n.imagePreviewError;
  static String get imagePreviewLoading => _l10n.imagePreviewLoading;
  static String get imagePreviewTitle => _l10n.imagePreviewTitle;
  static String get importFileTooLarge => _l10n.importFileTooLarge;
  static String get importInvalidFormat => _l10n.importInvalidFormat;
  static String get importIoError => _l10n.importIoError;
  static String get importParseFailed => _l10n.importParseFailed;
  static String get importSubtitle => _l10n.importSubtitle;
  static String get importSuccess => _l10n.importSuccess;
  static String get languageChinese => _l10n.languageChinese;
  static String get languageEnglish => _l10n.languageEnglish;
  static String get languageSystem => _l10n.languageSystem;
  static String get languageThai => _l10n.languageThai;
  static String get languageTitle => _l10n.languageTitle;
  static String get lightMode => _l10n.lightMode;
  static String get loadFailed => _l10n.loadFailed;
  static String get loading => _l10n.loading;
  static String get logCaptureLevel => _l10n.logCaptureLevel;
  static String get logCaptureLevelDesc => _l10n.logCaptureLevelDesc;
  static String get logLevelDebug => _l10n.logLevelDebug;
  static String get logLevelError => _l10n.logLevelError;
  static String get logLevelInfo => _l10n.logLevelInfo;
  static String get logLevelVerbose => _l10n.logLevelVerbose;
  static String get logLevelWarning => _l10n.logLevelWarning;
  static String get logViewerClear => _l10n.logViewerClear;
  static String get logViewerClearConfirmBody => _l10n.logViewerClearConfirmBody;
  static String get logViewerClearConfirmTitle => _l10n.logViewerClearConfirmTitle;
  static String get logViewerCopied => _l10n.logViewerCopied;
  static String get logViewerCopyAll => _l10n.logViewerCopyAll;
  static String get logViewerCopyEntry => _l10n.logViewerCopyEntry;
  static String get logViewerCleared => _l10n.logViewerCleared;
  static String get logViewerEmpty => _l10n.logViewerEmpty;
  static String get logViewerFilterLevel => _l10n.logViewerFilterLevel;
  static String get logViewerIncludeStack => _l10n.logViewerIncludeStack;
  static String get logViewerNothingToCopy => _l10n.logViewerNothingToCopy;
  static String get logViewerSearchHint => _l10n.logViewerSearchHint;
  static String get logViewerSettingsDesc => _l10n.logViewerSettingsDesc;
  static String get logViewerTitle => _l10n.logViewerTitle;
  static String logViewerEntryCount(int shown, int total) =>
      _l10n.logViewerEntryCount(shown, total);
  static String logLevelLabel(AppLogLevel level) => switch (level) {
        AppLogLevel.verbose => logLevelVerbose,
        AppLogLevel.debug => logLevelDebug,
        AppLogLevel.info => logLevelInfo,
        AppLogLevel.warning => logLevelWarning,
        AppLogLevel.error => logLevelError,
      };
  static String get loggedInFallback => _l10n.loggedInFallback;
  static String get loggedInSubtitle => _l10n.loggedInSubtitle;
  static String get loginAction => _l10n.loginAction;
  static String get loginCta => _l10n.loginCta;
  static String get loginCtaSubtitle => _l10n.loginCtaSubtitle;
  static String get loginRequired => _l10n.loginRequired;
  static String get logout => _l10n.logout;
  static String get lyricOverlayEditEntered => _l10n.lyricOverlayEditEntered;
  static String get lyricOverlayEditExited => _l10n.lyricOverlayEditExited;
  static String get lyricOverlayEnterFirstHint => _l10n.lyricOverlayEnterFirstHint;
  static String get lyricOverlayPermContent => _l10n.lyricOverlayPermContent;
  static String get lyricOverlayPermTitle => _l10n.lyricOverlayPermTitle;
  static String get lyricOverlaySection => _l10n.lyricOverlaySection;
  static String get lyricOverlayTooltipEnable => _l10n.lyricOverlayTooltipEnable;
  static String get lyricOverlayTooltipExitEdit => _l10n.lyricOverlayTooltipExitEdit;
  static String get lyricOverlayTooltipLongPressHint => _l10n.lyricOverlayTooltipLongPressHint;
  static String get lyricOverlayUnlockDesc => _l10n.lyricOverlayUnlockDesc;
  static String get lyricOverlayUnlockTitle => _l10n.lyricOverlayUnlockTitle;
  static String get musicList => _l10n.musicList;
  static String get nameTooShort => _l10n.nameTooShort;
  static String get navPopular => _l10n.navPopular;
  static String get navRecommend => _l10n.navRecommend;
  static String get network => _l10n.network;
  static String get networkVpnHint => _l10n.networkVpnHint;
  static String get noLyrics => _l10n.noLyrics;
  static String get noWorks => _l10n.noWorks;
  static String get notPlaying => _l10n.notPlaying;
  static String get nowPlaying => _l10n.nowPlaying;
  static String get openSourceLicenses => _l10n.openSourceLicenses;
  static String get originalRepo => _l10n.originalRepo;
  static String get password => _l10n.password;
  static String get passwordConfirm => _l10n.passwordConfirm;
  static String get passwordMismatch => _l10n.passwordMismatch;
  static String get passwordTooShort => _l10n.passwordTooShort;
  static String get playback => _l10n.playback;
  static String get playerNextTrack => _l10n.playerNextTrack;
  static String get playerPlaceholder => _l10n.playerPlaceholder;
  static String get playerPrevTrack => _l10n.playerPrevTrack;
  static String get playerSeekBack10 => _l10n.playerSeekBack10;
  static String get playerSeekForward10 => _l10n.playerSeekForward10;
  static String get playlistEmpty => _l10n.playlistEmpty;
  static String get playlistLiked => _l10n.playlistLiked;
  static String get playlistMarked => _l10n.playlistMarked;
  static String get ranking => _l10n.ranking;
  static String get recentPlay => _l10n.recentPlay;
  static String get register => _l10n.register;
  static String get registerCta => _l10n.registerCta;
  static String get registerOkButLoginFailed => _l10n.registerOkButLoginFailed;
  static String get registerSuccess => _l10n.registerSuccess;
  static String get registerTitle => _l10n.registerTitle;
  static String get removeImportedSubtitle => _l10n.removeImportedSubtitle;
  static String get reset => _l10n.reset;
  static String get retry => _l10n.retry;
  static String get save => _l10n.save;
  static String get screenAwakeOff => _l10n.screenAwakeOff;
  static String get screenAwakeOn => _l10n.screenAwakeOn;
  static String get screenKeepAwake => _l10n.screenKeepAwake;
  static String get screenKeepAwakeDesc => _l10n.screenKeepAwakeDesc;
  static String get search => _l10n.search;
  static String get searchEmptyPrompt => _l10n.searchEmptyPrompt;
  static String get searchCommandHint => _l10n.searchCommandHint;
  static String get searchInputHint => _l10n.searchInputHint;
  static String get searchNoResults => _l10n.searchNoResults;
  static String get serverMain => _l10n.serverMain;
  static String get serverNode1 => _l10n.serverNode1;
  static String get serverNode2 => _l10n.serverNode2;
  static String get serverNode3 => _l10n.serverNode3;
  static String get settings => _l10n.settings;
  static String get similarWorks => _l10n.similarWorks;
  static String get sleepTimer => _l10n.sleepTimer;
  static String get sleepTimerOff => _l10n.sleepTimerOff;
  static String get sleepTimerFadeOut => _l10n.sleepTimerFadeOut;
  static String get sleepTimerFadeOutDesc => _l10n.sleepTimerFadeOutDesc;
  static String get sleepTimerDimScreen => _l10n.sleepTimerDimScreen;
  static String get sleepTimerDimScreenDesc => _l10n.sleepTimerDimScreenDesc;
  static String get playbackFade => _l10n.playbackFade;
  static String get playbackFadeDesc => _l10n.playbackFadeDesc;
  static String get playbackFadeDuration => _l10n.playbackFadeDuration;
  static String get playbackFadeDurationDesc => _l10n.playbackFadeDurationDesc;
  static String playbackFadeDurationMs(int ms) => _l10n.playbackFadeDurationMs(ms);
  static String get lyricAutoScrollResume => _l10n.lyricAutoScrollResume;
  static String get lyricAutoScrollResumeDesc => _l10n.lyricAutoScrollResumeDesc;
  static String lyricAutoScrollResumeSec(int seconds) =>
      _l10n.lyricAutoScrollResumeSec(seconds);
  static String get lyricJumpToCurrent => _l10n.lyricJumpToCurrent;
  static String sleepTimerActiveSummary(int preset, Duration remaining) =>
      _l10n.sleepTimerActiveSummary(
        preset,
        remaining.inMinutes,
        remaining.inSeconds % 60,
      );
  static String get smartPath => _l10n.smartPath;
  static String get smartPathDesc => _l10n.smartPathDesc;
  static String get sortAscending => _l10n.sortAscending;
  static String get sortDescending => _l10n.sortDescending;
  static String get sortLabel => _l10n.sortLabel;
  static String get sortLatest => _l10n.sortLatest;
  static String get sortOldest => _l10n.sortOldest;
  static String get sortPriceAsc => _l10n.sortPriceAsc;
  static String get sortPriceDesc => _l10n.sortPriceDesc;
  static String get sortRandom => _l10n.sortRandom;
  static String get sortRatingDesc => _l10n.sortRatingDesc;
  static String get sortReleaseAsc => _l10n.sortReleaseAsc;
  static String get sortReleaseDesc => _l10n.sortReleaseDesc;
  static String get sortReviewDesc => _l10n.sortReviewDesc;
  static String get sortRjAsc => _l10n.sortRjAsc;
  static String get sortRjDesc => _l10n.sortRjDesc;
  static String get sortSalesAsc => _l10n.sortSalesAsc;
  static String get sortSalesDesc => _l10n.sortSalesDesc;
  static String get sourceCode => _l10n.sourceCode;
  static String get storage => _l10n.storage;
  static String get subtitleCache => _l10n.subtitleCache;
  static String get subtitleChip => _l10n.subtitleChip;
  static String get subtitlePreviewEmpty => _l10n.subtitlePreviewEmpty;
  static String get subtitlePreviewError => _l10n.subtitlePreviewError;
  static String get subtitlePreviewLoading => _l10n.subtitlePreviewLoading;
  static String get subtitlePreviewRawNotice => _l10n.subtitlePreviewRawNotice;
  static String get subtitlePreviewTitle => _l10n.subtitlePreviewTitle;
  static String get subtitleRemoved => _l10n.subtitleRemoved;
  static String get tabFavorites => _l10n.tabFavorites;
  static String get tabHome => _l10n.tabHome;
  static String get tabHot => _l10n.tabHot;
  static String get tabLibrary => _l10n.tabLibrary;
  static String get tabPopular => _l10n.tabPopular;
  static String get tabRecommend => _l10n.tabRecommend;
  static String get tabSearch => _l10n.tabSearch;
  static String get tags => _l10n.tags;
  static String get telegramChannel => _l10n.telegramChannel;
  static String get themeAutoDesc => _l10n.themeAutoDesc;
  static String get themeModeDark => _l10n.themeModeDark;
  static String get themeModeLight => _l10n.themeModeLight;
  static String get themeModeSystem => _l10n.themeModeSystem;
  static String get totalCacheSize => _l10n.totalCacheSize;
  static String get unknownArtist => _l10n.unknownArtist;
  static String get unknownWork => _l10n.unknownWork;
  static String get unsupportedFileType => _l10n.unsupportedFileType;
  static String get updateChecking => _l10n.updateChecking;
  static String get updateCurrentVersionLabel => _l10n.updateCurrentVersionLabel;
  static String get updateDownload => _l10n.updateDownload;
  static String get updateErrorInvalidPayload => _l10n.updateErrorInvalidPayload;
  static String get updateErrorNetwork => _l10n.updateErrorNetwork;
  static String get updateErrorNoRelease => _l10n.updateErrorNoRelease;
  static String get updateErrorNotFound => _l10n.updateErrorNotFound;
  static String get updateErrorRateLimited => _l10n.updateErrorRateLimited;
  static String get updateErrorUnknown => _l10n.updateErrorUnknown;
  static String get updateLater => _l10n.updateLater;
  static String get updateNewVersionTitle => _l10n.updateNewVersionTitle;
  static String get updateOk => _l10n.updateOk;
  static String get updateUpToDate => _l10n.updateUpToDate;
  static String get username => _l10n.username;
  static String get versionInfo => _l10n.versionInfo;
  static String get versionLabel => _l10n.versionLabel;
  static String get videoNeedsDownloadPrompt => _l10n.videoNeedsDownloadPrompt;
  static String get videoNeedsDownloadTitle => _l10n.videoNeedsDownloadTitle;
  static String get videoPlayerError => _l10n.videoPlayerError;
  static String get videoPlayerLoading => _l10n.videoPlayerLoading;
  static String get videoPlayerTitle => _l10n.videoPlayerTitle;
  static String get videoSubtitlesToggle => _l10n.videoSubtitlesToggle;
  static String get voiceActors => _l10n.voiceActors;
  static String get markStatusTitle => _l10n.markStatusTitle;
  static String get markWantToListen => _l10n.markWantToListen;
  static String get markListening => _l10n.markListening;
  static String get markListened => _l10n.markListened;
  static String get markRelistening => _l10n.markRelistening;
  static String get markOnHold => _l10n.markOnHold;
  static String get cacheLoadFailed => _l10n.cacheLoadFailed;
  static String get cacheCleanFailed => _l10n.cacheCleanFailed;
  static String get networkErrorGeneric => _l10n.networkErrorGeneric;
  static String get networkErrorCancelled => _l10n.networkErrorCancelled;
  static String get networkErrorServer => _l10n.networkErrorServer;
  static String get networkErrorClient => _l10n.networkErrorClient;
  static String get loginFailedGeneric => _l10n.loginFailedGeneric;
  static String get registerFailedGeneric => _l10n.registerFailedGeneric;
  static String unsupportedVideoFile(String title) =>
      _l10n.unsupportedVideoFile(title);
  static String get fileUrlMissing => _l10n.fileUrlMissing;
  static String get fileListNotLoaded => _l10n.fileListNotLoaded;

  static String get llmTranslationTitle => _l10n.llmTranslationTitle;
  static String get llmTranslationDesc => _l10n.llmTranslationDesc;
  static String get llmTranslationEnabled => _l10n.llmTranslationEnabled;
  static String get llmTranslationConfigure => _l10n.llmTranslationConfigure;
  static String get llmApiEndpoint => _l10n.llmApiEndpoint;
  static String get llmApiKey => _l10n.llmApiKey;
  static String get llmModel => _l10n.llmModel;
  static String get llmMainModel => _l10n.llmMainModel;
  static String get llmLiteModel => _l10n.llmLiteModel;
  static String get metadataTranslationTitle => _l10n.metadataTranslationTitle;
  static String get metadataTranslationDesc => _l10n.metadataTranslationDesc;
  static String get metadataTranslationEnabled =>
      _l10n.metadataTranslationEnabled;
  static String get metadataTranslationProvider =>
      _l10n.metadataTranslationProvider;
  static String get metadataTranslationProviderGoogle =>
      _l10n.metadataTranslationProviderGoogle;
  static String get metadataTranslationProviderLlm =>
      _l10n.metadataTranslationProviderLlm;
  static String get metadataTranslationMode => _l10n.metadataTranslationMode;
  static String get metadataTranslationModeAuto =>
      _l10n.metadataTranslationModeAuto;
  static String get metadataTranslationModeAutoDesc =>
      _l10n.metadataTranslationModeAutoDesc;
  static String get metadataTranslationModeManual =>
      _l10n.metadataTranslationModeManual;
  static String get metadataTranslationModeManualDesc =>
      _l10n.metadataTranslationModeManualDesc;
  static String get metadataTranslatePage => _l10n.metadataTranslatePage;
  static String get metadataTranslateTracks => _l10n.metadataTranslateTracks;
  static String get metadataTrackTranslationDone =>
      _l10n.metadataTrackTranslationDone;
  static String get metadataTrackTranslationFailed =>
      _l10n.metadataTrackTranslationFailed;
  static String get llmTargetLanguage => _l10n.llmTargetLanguage;
  static String get llmSystemPrompt => _l10n.llmSystemPrompt;
  static String get llmSystemPromptHint => _l10n.llmSystemPromptHint;
  static String get llmJailbreakPrompt => _l10n.llmJailbreakPrompt;
  static String get llmJailbreakPromptHint => _l10n.llmJailbreakPromptHint;
  static String get llmJailbreakAuto => _l10n.llmJailbreakAuto;
  static String get llmJailbreakAutoDesc => _l10n.llmJailbreakAutoDesc;
  static String get llmPresetOpenAi => _l10n.llmPresetOpenAi;
  static String get llmPresetOpenRouter => _l10n.llmPresetOpenRouter;
  static String get llmPresetGemini => _l10n.llmPresetGemini;
  static String get llmPresetCustom => _l10n.llmPresetCustom;
  static String get llmPresetCustomHint => _l10n.llmPresetCustomHint;
  static String get llmCustomEndpointHint => _l10n.llmCustomEndpointHint;
  static String llmProviderDetected(String provider) =>
      _l10n.llmProviderDetected(provider);
  static String get llmModelAutocompleteHint => _l10n.llmModelAutocompleteHint;
  static String get llmCustomModelHint => _l10n.llmCustomModelHint;
  static String get llmGeminiUsageHint => _l10n.llmGeminiUsageHint;
  static String get llmOpenRouterUsageHint => _l10n.llmOpenRouterUsageHint;
  static String get llmOpenAiUsageHint => _l10n.llmOpenAiUsageHint;
  static String get llmCustomUsageHint => _l10n.llmCustomUsageHint;
  static String get llmOpenRouterBalanceUnavailable =>
      _l10n.llmOpenRouterBalanceUnavailable;
  static String get llmTargetLangSystem => _l10n.llmTargetLangSystem;
  static String get llmTargetLangEn => _l10n.llmTargetLangEn;
  static String get llmTargetLangZh => _l10n.llmTargetLangZh;
  static String get llmTargetLangJa => _l10n.llmTargetLangJa;
  static String get llmTargetLangTh => _l10n.llmTargetLangTh;
  static String get llmTargetLangKo => _l10n.llmTargetLangKo;
  static String get llmSettingsSaved => _l10n.llmSettingsSaved;
  static String get llmErrorMissingApiKey => _l10n.llmErrorMissingApiKey;
  static String get llmErrorInvalidConfig => _l10n.llmErrorInvalidConfig;
  static String get llmErrorAuth => _l10n.llmErrorAuth;
  static String get llmErrorRateLimited => _l10n.llmErrorRateLimited;
  static String get llmErrorNetwork => _l10n.llmErrorNetwork;
  static String get llmErrorInvalidResponse => _l10n.llmErrorInvalidResponse;
  static String get llmErrorContentBlocked => _l10n.llmErrorContentBlocked;
  static String llmErrorUnknown(String message) => _l10n.llmErrorUnknown(message);
  static String get llmTranslateNow => _l10n.llmTranslateNow;
  static String get llmShowOriginal => _l10n.llmShowOriginal;
  static String get llmTranslationDone => _l10n.llmTranslationDone;
  static String get llmErrorNoSubtitles => _l10n.llmErrorNoSubtitles;
  static String get llmTranslationNoChange => _l10n.llmTranslationNoChange;
  static String get llmTranslationFromCache => _l10n.llmTranslationFromCache;
  static String get llmTranslationStatusStarting =>
      _l10n.llmTranslationStatusStarting;
  static String get llmTranslationStatusCheckingCache =>
      _l10n.llmTranslationStatusCheckingCache;
  static String llmTranslationStatusTranslating(int batch, int total) =>
      _l10n.llmTranslationStatusTranslating(batch, total);
  static String get llmTranslationStatusSaving =>
      _l10n.llmTranslationStatusSaving;
  static String llmTranslationStatusResuming(int done, int total) =>
      _l10n.llmTranslationStatusResuming(done, total);
  static String llmTranslationPartialSaved(int done, int total) =>
      _l10n.llmTranslationPartialSaved(done, total);
  static String llmTranslationStatusStreaming(
    int done,
    int total,
    int batch,
    int batches,
  ) =>
      _l10n.llmTranslationStatusStreaming(done, total, batch, batches);
  static String get llmBatchSplitMode => _l10n.llmBatchSplitMode;
  static String get llmBatchSplitNone => _l10n.llmBatchSplitNone;
  static String get llmBatchSplitProvider => _l10n.llmBatchSplitProvider;
  static String get llmBatchSplitManual => _l10n.llmBatchSplitManual;
  static String get llmManualBatchSize => _l10n.llmManualBatchSize;
  static String get llmTranslateRetryCount => _l10n.llmTranslateRetryCount;
  static String get llmTranslateRetryCountDesc =>
      _l10n.llmTranslateRetryCountDesc;
  static String get translationQueueTitle => _l10n.translationQueueTitle;
  static String get translationQueueEmpty => _l10n.translationQueueEmpty;
  static String translationQueueEnqueued(int count) =>
      _l10n.translationQueueEnqueued(count);
  static String translationQueueMiniProgress(
          int done, int total, String name) =>
      _l10n.translationQueueMiniProgress(done, total, name);
  static String translationQueueMiniIdle(int done, int total) =>
      _l10n.translationQueueMiniIdle(done, total);
  static String get translationQueueNotificationTitle =>
      _l10n.translationQueueNotificationTitle;
  static String translationQueueNotificationBody(
          int done, int total, String name) =>
      _l10n.translationQueueNotificationBody(done, total, name);
  static String translationQueueNotificationIdle(int done, int total) =>
      _l10n.translationQueueNotificationIdle(done, total);
  static String get translationQueueRetryFailed =>
      _l10n.translationQueueRetryFailed;
  static String get translationQueueCancelAll =>
      _l10n.translationQueueCancelAll;
  static String get translationQueueClearFinished =>
      _l10n.translationQueueClearFinished;
  static String get translationQueueRetry => _l10n.translationQueueRetry;
  static String get translationQueueStatusPending =>
      _l10n.translationQueueStatusPending;
  static String get translationQueueStatusDone =>
      _l10n.translationQueueStatusDone;
  static String get translationQueueStatusFailed =>
      _l10n.translationQueueStatusFailed;
  static String get translationQueueStatusCancelled =>
      _l10n.translationQueueStatusCancelled;
  static String translationQueueAttempts(int count) =>
      _l10n.translationQueueAttempts(count);
  static String get llmStreamingEnabled => _l10n.llmStreamingEnabled;
  static String get llmStreamingEnabledDesc => _l10n.llmStreamingEnabledDesc;
  static String get llmUsageHistory => _l10n.llmUsageHistory;
  static String get llmUsageHistoryTitle => _l10n.llmUsageHistoryTitle;
  static String llmUsageTotalTokens(int count) =>
      _l10n.llmUsageTotalTokens(count);
  static String llmUsageTotalCost(String amount) =>
      _l10n.llmUsageTotalCost(amount);
  static String get llmUsageClearHistory => _l10n.llmUsageClearHistory;
  static String get llmUsageHistoryEmpty => _l10n.llmUsageHistoryEmpty;
  static String llmUsageRecordLine(int tokens, String cost) =>
      _l10n.llmUsageRecordLine(tokens, cost);
  static String get llmOpenRouterBalance => _l10n.llmOpenRouterBalance;
  static String llmOpenRouterBalanceUsage(String amount) =>
      _l10n.llmOpenRouterBalanceUsage(amount);
  static String llmOpenRouterBalanceLimit(String amount) =>
      _l10n.llmOpenRouterBalanceLimit(amount);
  static String get llmUsageOperationSubtitle =>
      _l10n.llmUsageOperationSubtitle;
  static String get llmUsageOperationTitle => _l10n.llmUsageOperationTitle;
  static String get llmUsageOperationMetadata => _l10n.llmUsageOperationMetadata;
  static String get llmSubtitleDisplayMode => _l10n.llmSubtitleDisplayMode;
  static String get llmSubtitleDisplayDual => _l10n.llmSubtitleDisplayDual;
  static String get llmSubtitleDisplayDualDesc =>
      _l10n.llmSubtitleDisplayDualDesc;
  static String get llmSubtitleDisplayTranslationOnly =>
      _l10n.llmSubtitleDisplayTranslationOnly;
  static String get llmSubtitleDisplayTranslationOnlyDesc =>
      _l10n.llmSubtitleDisplayTranslationOnlyDesc;
  static String get batchTranslateTitle => _l10n.batchTranslateTitle;
  static String get batchTranslateTooltip => _l10n.batchTranslateTooltip;
  static String get batchTranslateEmpty => _l10n.batchTranslateEmpty;
  static String get batchTranslateLoading => _l10n.batchTranslateLoading;
  static String batchTranslateConfirm(int count) =>
      _l10n.batchTranslateConfirm(count);
  static String batchTranslateStart(int count) =>
      _l10n.batchTranslateStart(count);
  static String get batchTranslateSelectAll => _l10n.batchTranslateSelectAll;
  static String get batchTranslateDeselectAll =>
      _l10n.batchTranslateDeselectAll;
  static String get batchTranslateCachedBadge =>
      _l10n.batchTranslateCachedBadge;
  static String get batchTranslateNeedsTranslate =>
      _l10n.batchTranslateNeedsTranslate;
  static String batchTranslateCacheSummary(
    int cachedInList,
    int totalInList,
    int savedOnDisk,
  ) =>
      _l10n.batchTranslateCacheSummary(
        cachedInList,
        totalInList,
        savedOnDisk,
      );
  static String batchTranslateProgress(int index, int total, String name) =>
      _l10n.batchTranslateProgress(index, total, name);
  static String get batchTranslatePhaseLoading =>
      _l10n.batchTranslatePhaseLoading;
  static String get batchTranslatePhaseCheckingCache =>
      _l10n.batchTranslatePhaseCheckingCache;
  static String batchTranslatePhaseTranslating(int batch, int total) =>
      _l10n.batchTranslatePhaseTranslating(batch, total);
  static String get batchTranslatePhaseTranslatingSimple =>
      _l10n.batchTranslatePhaseTranslatingSimple;
  static String get batchTranslatePhaseCached =>
      _l10n.batchTranslatePhaseCached;
  static String get batchTranslatePhaseFailed =>
      _l10n.batchTranslatePhaseFailed;
  static String batchTranslateSummary(
    int translated,
    int cached,
    int failed,
  ) =>
      _l10n.batchTranslateSummary(translated, cached, failed);
  static String get batchTranslateCancelled =>
      _l10n.batchTranslateCancelled;
  static String get llmTranslateTitle => _l10n.llmTranslateTitle;
  static String get llmShowOriginalTitle => _l10n.llmShowOriginalTitle;
  static String get llmShowTranslatedTitle => _l10n.llmShowTranslatedTitle;
  static String get llmTitleTranslationDone => _l10n.llmTitleTranslationDone;
  static String get llmTitleFromCache => _l10n.llmTitleFromCache;
  static String get llmErrorNoTitle => _l10n.llmErrorNoTitle;
  static String get batchTranslateIncludeTitle =>
      _l10n.batchTranslateIncludeTitle;
  static String get playerVolume => _l10n.playerVolume;
  static String get playerBackdropClarity => _l10n.playerBackdropClarity;
  static String get playerBackdropClarityDesc => _l10n.playerBackdropClarityDesc;
  static String get playerSpeed => _l10n.playerSpeed;
  static String playerSpeedLabel(double speed) =>
      _l10n.playerSpeedLabel(_formatSpeedLabel(speed));

  static String _formatSpeedLabel(double speed) {
    final t = speed.toStringAsFixed(2);
    if (t.endsWith('00')) return speed.toStringAsFixed(1);
    if (t.endsWith('0')) return t.substring(0, t.length - 1);
    return t;
  }
  static String get playerViewCover => _l10n.playerViewCover;
  static String get playerViewSubtitles => _l10n.playerViewSubtitles;
  static String get playerViewLore => _l10n.playerViewLore;

  static String get loreTab => _l10n.loreTab;
  static String get loreGenerate => _l10n.loreGenerate;
  static String get loreGenerating => _l10n.loreGenerating;
  static String get loreGenerateNeedApiKey => _l10n.loreGenerateNeedApiKey;
  static String get loreEmptyHint => _l10n.loreEmptyHint;
  static String get loreSynopsis => _l10n.loreSynopsis;
  static String get loreCharacters => _l10n.loreCharacters;
  static String get loreTrackSummaries => _l10n.loreTrackSummaries;
  static String get loreTimeline => _l10n.loreTimeline;
  static String get loreSeedNotes => _l10n.loreSeedNotes;
  static String get loreSeedNotesHint => _l10n.loreSeedNotesHint;
  static String get loreAddSeedNote => _l10n.loreAddSeedNote;
  static String get loreRegenerateWork => _l10n.loreRegenerateWork;
  static String get loreRegenerateTrack => _l10n.loreRegenerateTrack;
  static String get loreRegenerateCharacter => _l10n.loreRegenerateCharacter;
  static String get loreGenerateSecrets => _l10n.loreGenerateSecrets;
  static String get loreGenerateSecretsDesc => _l10n.loreGenerateSecretsDesc;
  static String get loreRevealExplicit => _l10n.loreRevealExplicit;
  static String get loreHideExplicit => _l10n.loreHideExplicit;
  static String get loreFocusCharacter => _l10n.loreFocusCharacter;
  static String get loreHudPins => _l10n.loreHudPins;
  static String get loreHudPinsDesc => _l10n.loreHudPinsDesc;
  static String get loreEditCharacter => _l10n.loreEditCharacter;
  static String get loreConfirmVaLink => _l10n.loreConfirmVaLink;
  static String get loreRejectVaLink => _l10n.loreRejectVaLink;
  static String get loreVaProposed => _l10n.loreVaProposed;
  static String get loreExportPack => _l10n.loreExportPack;
  static String get loreImportPack => _l10n.loreImportPack;
  static String get loreExportCcv2 => _l10n.loreExportCcv2;
  static String get loreExportCcv2Batch => _l10n.loreExportCcv2Batch;
  static String get loreIncludeSpeculative => _l10n.loreIncludeSpeculative;
  static String get lorePromoteGlobal => _l10n.lorePromoteGlobal;
  static String get loreLinkGlobal => _l10n.loreLinkGlobal;
  static String get loreDelete => _l10n.loreDelete;
  static String get loreDeleteConfirm => _l10n.loreDeleteConfirm;
  static String get loreProgressCast => _l10n.loreProgressCast;
  static String get loreProgressTrack => _l10n.loreProgressTrack;
  static String loreProgressTrackN(int current, int total) =>
      _l10n.loreProgressTrackN(current, total);
  static String get loreProgressSecrets => _l10n.loreProgressSecrets;
  static String get loreProgressReconcile => _l10n.loreProgressReconcile;
  static String get loreProgressDone => _l10n.loreProgressDone;
  static String get loreProgressSubsResolve => _l10n.loreProgressSubsResolve;
  static String get loreProgressSubsTranslate =>
      _l10n.loreProgressSubsTranslate;
  static String get loreProgressWaitingLlm => _l10n.loreProgressWaitingLlm;
  static String get loreProgressStreamSummary =>
      _l10n.loreProgressStreamSummary;
  static String loreProgressStreamEvent(int count, String title) =>
      _l10n.loreProgressStreamEvent(count, title);
  static String loreProgressStreamEvents(int count) =>
      _l10n.loreProgressStreamEvents(count);
  static String loreProgressElapsed(int seconds) =>
      _l10n.loreProgressElapsed(seconds);
  static String get loreLowConfidence => _l10n.loreLowConfidence;
  static String get loreContentLevel => _l10n.loreContentLevel;
  static String get loreContentSfw => _l10n.loreContentSfw;
  static String get loreContentSuggestive => _l10n.loreContentSuggestive;
  static String get loreContentExplicit => _l10n.loreContentExplicit;
  static String get lorePlayerHud => _l10n.lorePlayerHud;
  static String get lorePlayerTimeline => _l10n.lorePlayerTimeline;
  static String get lorePlayerHudVisible => _l10n.lorePlayerHudVisible;
  static String get lorePlayerHudVisibleDesc => _l10n.lorePlayerHudVisibleDesc;
  static String get lorePlayerHudHide => _l10n.lorePlayerHudHide;
  static String get lorePlayerHudShow => _l10n.lorePlayerHudShow;
  static String get lorePlayerParamsTitle => _l10n.lorePlayerParamsTitle;
  static String get loreParamBaseline => _l10n.loreParamBaseline;
  static String get loreParamChangesByTrack => _l10n.loreParamChangesByTrack;
  static String get loreParamChangesByTrackDesc =>
      _l10n.loreParamChangesByTrackDesc;
  static String get loreNoEventsYet => _l10n.loreNoEventsYet;
  static String get loreSettingsTitle => _l10n.loreSettingsTitle;
  static String get loreLanguage => _l10n.loreLanguage;
  static String get loreLanguageDesc => _l10n.loreLanguageDesc;
  static String get loreLanguageFollowApp => _l10n.loreLanguageFollowApp;
  static String get loreMaxTracks => _l10n.loreMaxTracks;
  static String get loreMaxTracksDesc => _l10n.loreMaxTracksDesc;
  static String get loreLlmPaceMs => _l10n.loreLlmPaceMs;
  static String get loreLlmPaceMsDesc => _l10n.loreLlmPaceMsDesc;
  static String get loreQueueTitle => _l10n.loreQueueTitle;
  static String get loreQueueEmpty => _l10n.loreQueueEmpty;
  static String get loreQueueEnqueued => _l10n.loreQueueEnqueued;
  static String get loreQueueAlreadyQueued => _l10n.loreQueueAlreadyQueued;
  static String get loreQueueRetryFailed => _l10n.loreQueueRetryFailed;
  static String get loreQueueCancelAll => _l10n.loreQueueCancelAll;
  static String get loreQueueClearFinished => _l10n.loreQueueClearFinished;
  static String get loreQueueStatusPending => _l10n.loreQueueStatusPending;
  static String get loreQueueStatusRunning => _l10n.loreQueueStatusRunning;
  static String get loreQueueStatusDone => _l10n.loreQueueStatusDone;
  static String get loreQueueStatusFailed => _l10n.loreQueueStatusFailed;
  static String get loreQueueStatusCancelled => _l10n.loreQueueStatusCancelled;
  static String loreQueuePartialSummary(int done, int failed) =>
      _l10n.loreQueuePartialSummary(done, failed);
  static String get loreQueueKindFullGenerate =>
      _l10n.loreQueueKindFullGenerate;
  static String get loreQueueKindSecretsOnly =>
      _l10n.loreQueueKindSecretsOnly;
  static String get loreQueueKindRegenerateWork =>
      _l10n.loreQueueKindRegenerateWork;
  static String get loreQueueKindRegenerateTrack =>
      _l10n.loreQueueKindRegenerateTrack;
  static String get loreQueueKindRegenerateCharacter =>
      _l10n.loreQueueKindRegenerateCharacter;
  static String loreQueueActiveCount(int count) =>
      _l10n.loreQueueActiveCount(count);
  static String loreQueueMiniProgress(int done, int total, String name) =>
      _l10n.loreQueueMiniProgress(done, total, name);
  static String loreQueueMiniIdle(int done, int total) =>
      _l10n.loreQueueMiniIdle(done, total);
  static String get loreQueueNotificationTitle =>
      _l10n.loreQueueNotificationTitle;
  static String loreQueueNotificationBody(int done, int total, String name) =>
      _l10n.loreQueueNotificationBody(done, total, name);
  static String loreQueueNotificationIdle(int done, int total) =>
      _l10n.loreQueueNotificationIdle(done, total);
  static String get loreGlobalLibrary => _l10n.loreGlobalLibrary;
  static String get loreGlobalLibraryDesc => _l10n.loreGlobalLibraryDesc;
  static String get loreGlobalEmpty => _l10n.loreGlobalEmpty;
  static String get loreMergeTitle => _l10n.loreMergeTitle;
  static String get loreMergePreferLocal => _l10n.loreMergePreferLocal;
  static String get loreMergePreferGlobal => _l10n.loreMergePreferGlobal;
  static String get loreSaved => _l10n.loreSaved;
  static String get loreExported => _l10n.loreExported;
  static String get loreImported => _l10n.loreImported;
  static String get loreFailed => _l10n.loreFailed;
  static String get loreSpeculativeBadge => _l10n.loreSpeculativeBadge;
  static String get loreFilesTab => _l10n.loreFilesTab;
  static String get loreCancel => _l10n.loreCancel;

  static String playlistToggleResult(bool added, String name) =>
      added ? _l10n.playlistToggleResultAdded(name) : _l10n.playlistToggleResultRemoved(name);

  static String batchDownloadConfirm(int count) => _l10n.batchDownloadConfirm(count);
  static String batchDownloadProgress(int index, int total, String name) => _l10n.batchDownloadProgress(index, total, name);
  static String batchDownloadSummary(int ok, int skipped, int failed) => _l10n.batchDownloadSummary(ok, skipped, failed);
  static String markFailed(Object error) => _l10n.markFailed(error.toString());
  static String markedAs(String label) => _l10n.markedAs(label);
  static String operationFailed(Object error) => _l10n.operationFailed(error.toString());
  static String playFailed(Object error) => _l10n.playFailed(error.toString());
  static String sleepTimerMinutes(int minutes) => _l10n.sleepTimerMinutes(minutes);
  static String worksCountLabel(int count) => _l10n.worksCountLabel(count);
  static String workSalesCount(int count) => _l10n.workSalesCount(count);
  static String playbackError(String operation) => _l10n.playbackError(operation);
}
