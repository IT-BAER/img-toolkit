"use client";

import React, { useState, useCallback, useEffect } from "react";
import { toast, ToastContainer } from "react-toastify";
import "react-toastify/dist/ReactToastify.css";
import { useDropzone } from "react-dropzone";
import { 
  Upload, 
  X,
  ImageIcon,
} from "lucide-react";
import { TooltipProvider } from "@/components/ui/tooltip";
import { Button } from "@/components/ui/button";
import {
  Drawer,
  DrawerContent,
  DrawerHeader,
  DrawerTitle,
  DrawerTrigger,
} from "@/components/ui/drawer";
import { VisuallyHidden } from "@/components/visually-hidden";

import BackendStatusBanner from "@/components/BackendStatusBanner";
import ErrorModal from "@/components/ErrorModal";
import FileManager from "@/components/StorageFileManager";
import CompressedFilesDrawer from "@/components/CompressedFilesDrawer";
import FileConversionForm from "@/components/FileConversionForm";
import { DownloadZipToast } from "@/components/CustomToast";
import { ErrorStoreProvider, useErrorStore } from "@/context/ErrorStore";
import { useBackendHealth } from "@/hooks/useBackendHealth";
import { useSupportedExtensions } from "@/hooks/useSupportedExtensions";
import { useTranslation, LanguageProvider } from "@/context/LanguageContext";

function HomePageContent() {
  const { t } = useTranslation();

  const {
    supportedExtensions,
    verifiedExtensions,
    isLoading: extensionsLoading,
    error: extensionsError,
  } = useSupportedExtensions();

  const formattedSupportedExtensions = supportedExtensions.map((ext) =>
    ext.startsWith(".") ? ext : `.${ext}`
  );
  const formattedVerifiedExtensions = verifiedExtensions.map((ext) =>
    ext.startsWith(".") ? ext : `.${ext}`
  );

  const [quality, setQuality] = useState("85");
  const [width, setWidth] = useState("");
  const [resizeWidthEnabled, setResizeWidthEnabled] = useState(false);
  const [files, setFiles] = useState<File[]>([]);
  const [converted, setConverted] = useState<string[]>([]);
  const [destFolder, setDestFolder] = useState("");
  const [isLoading, setIsLoading] = useState(false);
  const [outputFormat, setOutputFormat] = useState("jpeg");
  const [targetSizeMB, setTargetSizeMB] = useState("");
  const [jpegMode, setJpegMode] = useState<"quality" | "size">("quality");
  const [drawerOpen, setDrawerOpen] = useState(false);
  const [fileManagerOpen, setFileManagerOpen] = useState(false);
  const [fileManagerRefresh, setFileManagerRefresh] = useState(0);

  const { error, setError, clearError } = useErrorStore();
  const backendDown = useBackendHealth();

  useEffect(() => {
    if (outputFormat !== "jpeg") {
      setJpegMode("quality");
      setTargetSizeMB("");
    }
  }, [outputFormat]);

  const onDrop = useCallback(
    (acceptedFiles: File[]) => {
      clearError();
      setConverted([]);
      setDestFolder("");

      const supportedFiles: File[] = [];
      const unsupportedFiles: string[] = [];

      acceptedFiles.forEach((file) => {
        const ext = file.name.split(".").pop()?.toLowerCase();
        if (ext && formattedSupportedExtensions.includes(`.${ext}`)) {
          supportedFiles.push(file);
        } else {
          unsupportedFiles.push(file.name);
        }
      });

      unsupportedFiles.forEach((fileName) => {
        toast.error(`Unsupported File Format: ${fileName}`);
      });

      if (unsupportedFiles.length > 0) {
        setError({
          message: `${unsupportedFiles.length} file(s) were rejected due to unsupported file types.`,
        });
      }

      setFiles((prev) => [...prev, ...supportedFiles]);
    },
    [clearError, setError, formattedSupportedExtensions]
  );

  const { getRootProps, getInputProps, isDragActive } = useDropzone({
    onDrop,
    disabled: isLoading,
    multiple: true,
  });

  const delay = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

  const handleSubmit = useCallback(
    async (e: React.FormEvent) => {
      e.preventDefault();

      if (files.length === 0) {
        setError({ message: "Please drop or select some files first." });
        toast.error("Please drop or select some files first.");
        return;
      }

      if (outputFormat === "jpeg" && jpegMode === "quality") {
        const qualityNum = parseInt(quality, 10);
        if (isNaN(qualityNum) || qualityNum < 1 || qualityNum > 100) {
          setError({ message: "Quality must be a number between 1 and 100." });
          toast.error("Quality must be a number between 1 and 100.");
          return;
        }
      }

      if (resizeWidthEnabled) {
        const widthNum = parseInt(width, 10);
        if (isNaN(widthNum) || widthNum <= 0) {
          setError({ message: "Width must be a positive number." });
          toast.error("Width must be a positive number.");
          return;
        }

        if (outputFormat === "ico" && widthNum > 256) {
          toast.info(
            "ICO format is limited to a max width of 256px. Your input has been clamped to 256."
          );
          setWidth("256");
        }
      }

      if (outputFormat === "jpeg" && jpegMode === "size") {
        const trimmed = (targetSizeMB || "").trim();
        const t = parseFloat(trimmed);
        if (!trimmed || isNaN(t) || t <= 0) {
          setError({ message: "Please set a positive Max file size (in MB)." });
          toast.error("Please set a positive Max file size (in MB).");
          return;
        }
      }

      setIsLoading(true);
      clearError();
      setConverted([]);
      setDestFolder("");

      const formData = new FormData();
      files.forEach((file) => formData.append("files[]", file));
      if (outputFormat === "jpeg" && jpegMode === "quality") {
        formData.append("quality", quality);
      }
      if (resizeWidthEnabled) {
        formData.append("width", width);
      }
      formData.append("format", outputFormat);
      if (outputFormat === "jpeg" && jpegMode === "size") {
        const kb = Math.round(parseFloat(targetSizeMB) * 1024);
        if (!isNaN(kb) && kb > 0) {
          formData.append("target_size_kb", String(kb));
        }
      }

      try {
        const res = await fetch("/api/compress", {
          method: "POST",
          body: formData,
        });
        if (!res.ok) {
          const err = await res.json();
          setError({
            message: err.error || "Error uploading files.",
            details: err.message || undefined,
            isApiError: true,
          });
          toast.error(err.error || "Error uploading files.");
          return;
        }
        const data = await res.json();
        setConverted(data.converted_files);
        setDestFolder(data.dest_folder);
        setDrawerOpen(true);
        await delay(600);
        toast.success(
          `${data.converted_files.length} Image${
            data.converted_files.length > 1 ? "s" : ""
          } compressed successfully!`
        );
      } catch (err) {
        console.error(err);
        setError({
          message: "Something went wrong. Please try again.",
          details: err instanceof Error ? err.message : undefined,
          isApiError: true,
        });
        toast.error("Something went wrong. Please try again.");
      } finally {
        setIsLoading(false);
      }
    },
    [
      files,
      outputFormat,
      quality,
      resizeWidthEnabled,
      width,
      clearError,
      setError,
      jpegMode,
      targetSizeMB,
    ]
  );

  const clearFileSelection = useCallback(() => {
    setFiles([]);
    if (files.length > 0) {
      toast.info(
        `${files.length} Image${files.length !== 1 ? "s" : ""} selection cleared! 🧹`
      );
    }
  }, [files]);

  const removeFile = useCallback((fileName: string) => {
    setFiles((prev) => prev.filter((f) => f.name !== fileName));
  }, []);

  const handleDownloadAll = useCallback(() => {
    window.location.href = `/api/download_all?folder=${encodeURIComponent(
      destFolder
    )}`;
    toast(<DownloadZipToast />);
  }, [destFolder]);

  const onForceCleanCallback = useCallback(async () => {
    try {
      const res = await fetch("/api/force_cleanup", { method: "POST" });
      const json = await res.json();
      if (json.status === "ok") {
        toast.success(
          "Deletion Complete. Your processed files have been permanently removed. 🧹🧹🧹"
        );
        setConverted([]);
        setDestFolder("");
        setDrawerOpen(false);
        setFileManagerRefresh((prev) => prev + 1);
      } else {
        toast.error(json.error || "Force cleanup failed.");
      }
    } catch (error) {
      toast.error("🚨 Cleanup failed.");
      console.error(error);
    }
  }, []);

  return (
    <div className="min-h-screen bg-background p-4 sm:p-6 lg:p-8">
      <BackendStatusBanner backendDown={backendDown} />
      <ToastContainer 
        position="top-right" 
        autoClose={3000}
        hideProgressBar
        newestOnTop
        closeOnClick
        theme="colored"
      />
      
      <div className="mx-auto max-w-3xl space-y-6">
        {/* Large Dropzone */}
        <div
          {...getRootProps()}
          className={`border-2 border-dashed rounded-2xl p-12 sm:p-16 lg:p-20 text-center cursor-pointer transition-all min-h-[280px] flex flex-col items-center justify-center ${
            isDragActive 
              ? "border-primary bg-primary/5" 
              : "border-border hover:border-primary/50 hover:bg-muted/30"
          } ${isLoading ? "opacity-50 cursor-not-allowed" : ""}`}
        >
          <input {...getInputProps()} data-testid="dropzone-input" />
          <Upload className={`h-12 w-12 mb-4 ${isDragActive ? "text-primary" : "text-muted-foreground"}`} />
          <p className="text-lg font-medium">
            {isDragActive ? t('dropImagesHere') : t('dropFilesHere')}
          </p>
        </div>

        {/* File List */}
        {files.length > 0 && (
          <div className="space-y-2">
            {files.map((file) => (
              <div
                key={file.name}
                className="flex items-center justify-between rounded-lg bg-muted/50 px-4 py-3"
                data-testid="dropzone-added-file-wrapper"
              >
                <div className="flex items-center gap-3 min-w-0">
                  <ImageIcon className="h-5 w-5 text-muted-foreground shrink-0" />
                  <span className="text-sm font-medium truncate" data-testid="dropzone-added-file">{file.name}</span>
                  <span className="text-xs text-muted-foreground">({(file.size / 1024 / 1024).toFixed(1)}MB)</span>
                </div>
                <Button
                  variant="ghost"
                  size="icon"
                  disabled={isLoading}
                  onClick={() => removeFile(file.name)}
                  className="h-8 w-8"
                  data-testid="dropzone-remove-file-btn"
                >
                  <X className="h-4 w-4" />
                </Button>
              </div>
            ))}
          </div>
        )}

        {/* Settings - Below */}
        <div className="pt-2">
          <FileConversionForm
            isLoading={isLoading}
            error={error}
            quality={quality}
            setQuality={setQuality}
            width={width}
            setWidth={setWidth}
            resizeWidthEnabled={resizeWidthEnabled}
            setResizeWidthEnabled={setResizeWidthEnabled}
            outputFormat={outputFormat}
            setOutputFormat={setOutputFormat}
            files={files}
            removeFile={removeFile}
            clearFileSelection={clearFileSelection}
            onSubmit={handleSubmit}
            targetSizeMB={targetSizeMB}
            setTargetSizeMB={setTargetSizeMB}
            jpegMode={jpegMode}
            setJpegMode={setJpegMode}
            getRootProps={getRootProps}
            getInputProps={getInputProps}
            isDragActive={isDragActive}
            supportedExtensions={formattedSupportedExtensions}
            verifiedExtensions={formattedVerifiedExtensions}
            extensionsLoading={extensionsLoading}
            extensionsError={extensionsError}
            hideDropzone
            hideFileList
          />
        </div>
      </div>

      {/* File Manager Drawer */}
      <Drawer open={fileManagerOpen} onOpenChange={setFileManagerOpen}>
        <DrawerTrigger asChild>
          <button className="hidden" />
        </DrawerTrigger>
        <DrawerContent className="border-0 max-h-[85vh]">
          <VisuallyHidden>
            <DrawerHeader>
              <DrawerTitle>Storage</DrawerTitle>
            </DrawerHeader>
          </VisuallyHidden>
          <div className="p-4 overflow-y-auto">
            <FileManager onForceClean={onForceCleanCallback} key={fileManagerRefresh} />
          </div>
        </DrawerContent>
      </Drawer>

      {converted.length > 0 && (
        <CompressedFilesDrawer
          converted={converted}
          destFolder={destFolder}
          isOpen={drawerOpen}
          onOpenChange={setDrawerOpen}
          onDownloadAll={handleDownloadAll}
        />
      )}

      <ErrorModal />
    </div>
  );
}

export default function HomePage() {
  return (
    <LanguageProvider>
      <ErrorStoreProvider>
        <TooltipProvider delayDuration={0}>
          <HomePageContent />
        </TooltipProvider>
      </ErrorStoreProvider>
    </LanguageProvider>
  );
}
