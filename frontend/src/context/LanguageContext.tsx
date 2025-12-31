"use client";

import React, { createContext, useContext, useState, useCallback, useEffect, ReactNode } from "react";

type Language = "en" | "de";

interface Translations {
  [key: string]: {
    en: string;
    de: string;
  };
}

const translations: Translations = {
  // Main page
  subtitle: {
    en: "Fast, Private Image Compression & Conversion",
    de: "Schnelle, private Bildkomprimierung & Konvertierung",
  },
  
  // Form labels
  outputFormat: {
    en: "Output Format",
    de: "Ausgabeformat",
  },
  jpegSettingsMode: {
    en: "JPEG settings mode",
    de: "JPEG-Einstellungsmodus",
  },
  setByQuality: {
    en: "Set by Quality",
    de: "Nach Qualität",
  },
  setByFileSize: {
    en: "Set by File Size",
    de: "Nach Dateigröße",
  },
  quality: {
    en: "Quality (for JPEG only)",
    de: "Qualität (nur für JPEG)",
  },
  maxFileSize: {
    en: "Max file size (for JPEG only)",
    de: "Max. Dateigröße (nur für JPEG)",
  },
  resizeWidth: {
    en: "Resize Width",
    de: "Breite ändern",
  },
  startConverting: {
    en: "Start Converting",
    de: "Konvertierung starten",
  },
  processing: {
    en: "Processing...",
    de: "Verarbeitung...",
  },
  clear: {
    en: "Clear",
    de: "Löschen",
  },
  remove: {
    en: "Remove",
    de: "Entfernen",
  },
  
  // Dropzone
  dropFilesHere: {
    en: "Drag & drop images or PDFs here, or click to select",
    de: "Bilder oder PDFs hierher ziehen oder klicken zum Auswählen",
  },
  dropImagesHere: {
    en: "Drop images or PDFs here...",
    de: "Bilder oder PDFs hier ablegen...",
  },
  cannotDropWhileProcessing: {
    en: "Cannot drop files while processing...",
    de: "Während der Verarbeitung können keine Dateien abgelegt werden...",
  },
  filesToConvert: {
    en: "Files to convert:",
    de: "Zu konvertierende Dateien:",
  },
  
  // Format options
  jpegSmaller: {
    en: "JPEG (smaller file size)",
    de: "JPEG (kleinere Dateigröße)",
  },
  pngTransparency: {
    en: "PNG (preserves transparency)",
    de: "PNG (erhält Transparenz)",
  },
  icoTransparency: {
    en: "ICO (preserves transparency)",
    de: "ICO (erhält Transparenz)",
  },
  
  // Quality presets
  smaller: {
    en: "Smaller",
    de: "Kleiner",
  },
  balanced: {
    en: "Balanced",
    de: "Ausgewogen",
  },
  high: {
    en: "High",
    de: "Hoch",
  },
  max: {
    en: "Max",
    de: "Maximum",
  },
  
  // Tooltips
  tooltipOutputFormat: {
    en: "PNG: Preserves transparency (alpha) and is best for images with transparent backgrounds.\nJPEG: Ideal for images without transparency and produces smaller file sizes.\nICO: Commonly used for favicons and application icons, supports transparency (alpha). Recommended to use PNG as the source when converting to ICO.",
    de: "PNG: Erhält Transparenz (Alpha) und eignet sich am besten für Bilder mit transparentem Hintergrund.\nJPEG: Ideal für Bilder ohne Transparenz und erzeugt kleinere Dateigrößen.\nICO: Wird häufig für Favicons und Anwendungssymbole verwendet, unterstützt Transparenz (Alpha). Es wird empfohlen, PNG als Quelle bei der Konvertierung in ICO zu verwenden.",
  },
  tooltipQuality: {
    en: "Adjust the JPEG quality (100 gives the best quality, lower values reduce file size).",
    de: "JPEG-Qualität anpassen (100 ergibt die beste Qualität, niedrigere Werte reduzieren die Dateigröße).",
  },
  tooltipResizeWidth: {
    en: "Resizes the image(s) to the desired width while preserving the original aspect ratio.",
    de: "Ändert die Größe der Bilder auf die gewünschte Breite unter Beibehaltung des ursprünglichen Seitenverhältnisses.",
  },
  tooltipTargetSize: {
    en: "Set an optional maximum output size (in MB). Applies to JPEG output only.",
    de: "Optionale maximale Ausgabegröße festlegen (in MB). Gilt nur für JPEG-Ausgabe.",
  },
  
  // Messages
  errorUnsupportedFormat: {
    en: "Unsupported File Format",
    de: "Nicht unterstütztes Dateiformat",
  },
  errorSelectFiles: {
    en: "Please drop or select some files first.",
    de: "Bitte zuerst Dateien ablegen oder auswählen.",
  },
  errorQualityRange: {
    en: "Quality must be a number between 1 and 100.",
    de: "Qualität muss eine Zahl zwischen 1 und 100 sein.",
  },
  errorWidthPositive: {
    en: "Width must be a positive number.",
    de: "Breite muss eine positive Zahl sein.",
  },
  errorFileSizePositive: {
    en: "Please set a positive Max file size (in MB).",
    de: "Bitte eine positive maximale Dateigröße (in MB) festlegen.",
  },
  successCompressed: {
    en: "Image(s) compressed successfully!",
    de: "Bild(er) erfolgreich komprimiert!",
  },
  errorSomethingWrong: {
    en: "Something went wrong. Please try again.",
    de: "Etwas ist schief gelaufen. Bitte versuchen Sie es erneut.",
  },
  selectionCleared: {
    en: "selection cleared!",
    de: "Auswahl gelöscht!",
  },
  deletionComplete: {
    en: "Deletion Complete. Your processed files have been permanently removed.",
    de: "Löschung abgeschlossen. Ihre verarbeiteten Dateien wurden dauerhaft entfernt.",
  },
  cleanupFailed: {
    en: "Cleanup failed.",
    de: "Bereinigung fehlgeschlagen.",
  },
  
  // Backend status
  backendUnavailable: {
    en: "Warning: Backend is currently unavailable.",
    de: "Warnung: Backend ist derzeit nicht verfügbar.",
  },
  
  // Footer
  openSource: {
    en: "Open Source & Free",
    de: "Open Source & Kostenlos",
  },
  footerDescription: {
    en: "This project is open source and freely available.",
    de: "Dieses Projekt ist Open Source und frei verfügbar.",
  },
  sourceCode: {
    en: "the Source Code",
    de: "den Quellcode",
  },
  checkOut: {
    en: "Check out",
    de: "Schauen Sie sich an",
  },
  featureIdeas: {
    en: "Got ideas for new features? Share them on",
    de: "Haben Sie Ideen für neue Funktionen? Teilen Sie sie auf",
  },
  
  // Compressed files drawer
  compressedFiles: {
    en: "Compressed Files",
    de: "Komprimierte Dateien",
  },
  downloadAll: {
    en: "Download All",
    de: "Alle herunterladen",
  },
  download: {
    en: "Download",
    de: "Herunterladen",
  },
  
  // Storage manager
  storageManagement: {
    en: "Storage Management",
    de: "Speicherverwaltung",
  },
  forceCleanup: {
    en: "Force Cleanup",
    de: "Bereinigung erzwingen",
  },
  
  // Supported formats dialog
  supportedFormats: {
    en: "Supported Formats",
    de: "Unterstützte Formate",
  },
  verifiedFormats: {
    en: "Verified Formats",
    de: "Verifizierte Formate",
  },
  allSupportedFormats: {
    en: "All Supported Formats",
    de: "Alle unterstützten Formate",
  },
  
  // Release notes
  releaseNotes: {
    en: "Release Notes",
    de: "Versionshinweise",
  },
  
  // Admin tools
  adminTools: {
    en: "Admin Tools",
    de: "Admin-Werkzeuge",
  },
  
  // ICO warning
  icoWarning: {
    en: "ICO format is limited to a max width of 256px. Your input has been clamped to 256.",
    de: "ICO-Format ist auf maximal 256px Breite begrenzt. Ihre Eingabe wurde auf 256 begrenzt.",
  },
  
  // File size hint
  fileSizeHint: {
    en: "It will try to keep each JPEG at or below this size by automatically adjusting quality.",
    de: "Es wird versucht, jedes JPEG auf oder unter dieser Größe zu halten, indem die Qualität automatisch angepasst wird.",
  },
  
  // Error modal
  error: {
    en: "Error",
    de: "Fehler",
  },
  details: {
    en: "Details",
    de: "Details",
  },
  close: {
    en: "Close",
    de: "Schließen",
  },
  
  // Compressed files drawer
  showCompressed: {
    en: "Show Compressed",
    de: "Komprimierte anzeigen",
  },
  compressedImages: {
    en: "Compressed Images",
    de: "Komprimierte Bilder",
  },
  downloadDescription: {
    en: "Download your compressed images individually or as a zip archive.",
    de: "Laden Sie Ihre komprimierten Bilder einzeln oder als ZIP-Archiv herunter.",
  },
  downloadAllZip: {
    en: "Download All as Zip",
    de: "Alle als ZIP herunterladen",
  },
  
  // Storage management additional
  totalStorage: {
    en: "Total Storage",
    de: "Gesamtspeicher",
  },
  used: {
    en: "Used",
    de: "Belegt",
  },
  available: {
    en: "Available",
    de: "Verfügbar",
  },
  storageUsage: {
    en: "Storage Usage",
    de: "Speichernutzung",
  },
  files: {
    en: "Files",
    de: "Dateien",
  },
  clearProcessedFiles: {
    en: "Clear Processed Files",
    de: "Verarbeitete Dateien löschen",
  },
  confirmFileDeletion: {
    en: "Confirm File Deletion",
    de: "Dateilöschung bestätigen",
  },
  deletionWarning: {
    en: "This action will permanently delete all processed files. Please ensure you have downloaded any necessary files before proceeding, as this action cannot be undone.",
    de: "Diese Aktion löscht alle verarbeiteten Dateien dauerhaft. Bitte stellen Sie sicher, dass Sie alle notwendigen Dateien heruntergeladen haben, da diese Aktion nicht rückgängig gemacht werden kann.",
  },
  cancel: {
    en: "Cancel",
    de: "Abbrechen",
  },
  yesDeleteFiles: {
    en: "Yes, Delete Files",
    de: "Ja, Dateien löschen",
  },
  totalFiles: {
    en: "Total Files",
    de: "Dateien gesamt",
  },
  totalSpaceUsed: {
    en: "Total Space Used",
    de: "Belegter Speicher",
  },
  noConvertedFiles: {
    en: "No converted files found.",
    de: "Keine konvertierten Dateien gefunden.",
  },
  fetchError: {
    en: "Failed to fetch data.",
    de: "Daten konnten nicht abgerufen werden.",
  },
  
  // Supported formats dialog
  supportedFormatsImagesPdfs: {
    en: "Supported Formats (Images & PDFs)",
    de: "Unterstützte Formate (Bilder & PDFs)",
  },
  verifiedExperimentalFormats: {
    en: "Verified and experimental upload formats available in this tool.",
    de: "Verifizierte und experimentelle Upload-Formate in diesem Tool.",
  },
  loading: {
    en: "Loading…",
    de: "Laden…",
  },
  errorLoadingFormats: {
    en: "Error loading formats:",
    de: "Fehler beim Laden der Formate:",
  },
  verifiedFormatsTitle: {
    en: "✅ Verified Formats",
    de: "✅ Verifizierte Formate",
  },
  verifiedFormatsDesc: {
    en: "These formats have been thoroughly tested and verified to work reliably within IMG-Toolkit. You can use them with confidence in their stability and output quality.",
    de: "Diese Formate wurden gründlich getestet und funktionieren zuverlässig mit IMG-Toolkit. Sie können sie bedenkenlos verwenden.",
  },
  noneListed: {
    en: "None listed",
    de: "Keine aufgelistet",
  },
  experimentalFormatsTitle: {
    en: "🧪 Supported but Experimental",
    de: "🧪 Unterstützt aber experimentell",
  },
  experimentalFormatsDesc: {
    en: "The formats listed below are supported by the Pillow library, which is used internally for image conversion. However, they have not yet undergone full automated testing in IMG-Toolkit. While they are expected to work correctly, they are considered experimental until officially verified.",
    de: "Die unten aufgeführten Formate werden von der Pillow-Bibliothek unterstützt, die intern für die Bildkonvertierung verwendet wird. Sie wurden jedoch noch nicht vollständig in IMG-Toolkit getestet. Sie gelten als experimentell.",
  },
  experimentalIssueHint: {
    en: "If you experience issues, please open an issue with a sample file — it helps improve test coverage and reliability.",
    de: "Bei Problemen öffnen Sie bitte ein Issue mit einer Beispieldatei — das hilft, die Testabdeckung zu verbessern.",
  },
  pillowLibrary: {
    en: "Pillow library",
    de: "Pillow-Bibliothek",
  },
  
  // Release notes
  releaseNotesTitle: {
    en: "Release Notes",
    de: "Versionshinweise",
  },
  releaseNotesInfo: {
    en: "Only the latest changes are listed here.",
    de: "Hier werden nur die neuesten Änderungen aufgeführt.",
  },
  noReleaseNotes: {
    en: "No release notes available.",
    de: "Keine Versionshinweise verfügbar.",
  },
  
  // Custom toast
  downloading: {
    en: "Downloading:",
    de: "Herunterladen:",
  },
  folder: {
    en: "Folder",
    de: "Ordner",
  },
};

interface LanguageContextType {
  language: Language;
  setLanguage: (lang: Language) => void;
  t: (key: string) => string;
}

const LanguageContext = createContext<LanguageContextType | undefined>(undefined);

interface LanguageProviderProps {
  children: ReactNode;
}

export function LanguageProvider({ children }: LanguageProviderProps) {
  const [language, setLanguage] = useState<Language>("en");
  const [mounted, setMounted] = useState(false);

  // Initialize language from localStorage on mount (client-side only)
  useEffect(() => {
    const saved = localStorage.getItem("img-toolkit-language");
    if (saved === "en" || saved === "de") {
      setLanguage(saved);
    } else {
      // Auto-detect browser language
      const browserLang = navigator.language.toLowerCase();
      if (browserLang.startsWith("de")) {
        setLanguage("de");
      }
    }
    setMounted(true);
  }, []);

  const handleSetLanguage = useCallback((lang: Language) => {
    setLanguage(lang);
    if (typeof window !== "undefined") {
      localStorage.setItem("img-toolkit-language", lang);
    }
  }, []);

  const t = useCallback(
    (key: string): string => {
      const translation = translations[key];
      if (!translation) {
        console.warn(`Translation missing for key: ${key}`);
        return key;
      }
      return language === "de" ? translation.de : translation.en;
    },
    [language]
  );

  return (
    <LanguageContext.Provider value={{ language, setLanguage: handleSetLanguage, t }}>
      {children}
    </LanguageContext.Provider>
  );
}

export function useTranslation() {
  const context = useContext(LanguageContext);
  if (context === undefined) {
    throw new Error("useTranslation must be used within a LanguageProvider");
  }
  return context;
}
