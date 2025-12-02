"use client";

import React, { useMemo } from "react";
import { useDropzone } from "react-dropzone";
import { Info, Loader2, Trash } from "lucide-react";
import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Switch } from "@/components/ui/switch";
import {
  Tooltip,
  TooltipTrigger,
  TooltipContent,
} from "@/components/ui/tooltip";
import {
  Select,
  SelectContent,
  SelectItem,
  SelectTrigger,
  SelectValue,
} from "@/components/ui/select";

import { SupportedFormatsDialog } from "@/components/SupportedFormatsDialog"
import { useTranslation } from "@/context/LanguageContext";

interface FileConversionFormProps {
  isLoading: boolean;
  error: { message: string; details?: string } | null;
  quality: string;
  setQuality: (val: string) => void;
  width: string;
  setWidth: (val: string) => void;
  resizeWidthEnabled: boolean;
  setResizeWidthEnabled: (val: boolean) => void;
  outputFormat: string;
  setOutputFormat: (val: string) => void;
  files: File[];
  removeFile: (name: string) => void;
  clearFileSelection: () => void;
  onSubmit: (e: React.FormEvent) => void;

  targetSizeMB: string;
  setTargetSizeMB: (val: string) => void;

  jpegMode: "quality" | "size";
  setJpegMode: (val: "quality" | "size") => void;
  
  // From useDropzone
  getRootProps: ReturnType<typeof useDropzone>["getRootProps"];
  getInputProps: ReturnType<typeof useDropzone>["getInputProps"];
  isDragActive: boolean;

  // ✅ Extended API data
  supportedExtensions: string[]
  verifiedExtensions: string[]
  extensionsLoading: boolean
  extensionsError: Error | null
}

const tooltipContent = {
  outputFormat:
  "PNG: Preserves transparency (alpha) and is best for images with transparent backgrounds.\nJPEG: Ideal for images without transparency and produces smaller file sizes.\nICO: Commonly used for favicons and application icons, supports transparency (alpha). Recommended to use PNG as the source when converting to ICO.",
  quality:
    "Adjust the JPEG quality (100 gives the best quality, lower values reduce file size).",
  resizeWidth:
    "Resizes the image(s) to the desired width while preserving the original aspect ratio.",
  targetSize:
    "Set an optional maximum output size (in MB). Applies to JPEG output only.",
};

const FileConversionForm: React.FC<FileConversionFormProps> = ({
  isLoading,
  error,
  quality,
  setQuality,
  width,
  setWidth,
  resizeWidthEnabled,
  setResizeWidthEnabled,
  outputFormat,
  setOutputFormat,
  files,
  removeFile,
  clearFileSelection,
  onSubmit,
  targetSizeMB,
  setTargetSizeMB,
  jpegMode,
  setJpegMode,
  getRootProps,
  getInputProps,
  isDragActive,
  supportedExtensions,
  verifiedExtensions,
  extensionsLoading,
  extensionsError,
}) => {
  const { t } = useTranslation();

  const renderError = useMemo(
    () =>
      error && (
        <div
          data-testid="error-holder"
          className="p-2 bg-red-600 text-white rounded-md"
        >
          <p data-testid="error-message-holder">
            <strong>{t('error')}:</strong> {error.message}
          </p>
          {error.details && (
            <p data-testid="error-details-holder">
              <strong>{t('details')}:</strong> {error.details}
            </p>
          )}
        </div>
      ),
    [error, t]
  );

  const renderFilesList = useMemo(
    () =>
      files.length > 0 && (
        <div className="mt-2 space-y-1">
          <Label>{t('filesToConvert')}</Label>
          {files.map((file) => (
            <div
              key={file.name}
              className="flex items-center justify-between bg-gray-800 rounded-md p-2 text-gray-100"
              data-testid="dropzone-added-file-wrapper"
            >
              <span className="text-sm" data-testid="dropzone-added-file">
                {file.name}
              </span>
              <Button
                variant="secondary"
                size="sm"
                disabled={isLoading}
                onClick={() => removeFile(file.name)}
                data-testid="dropzone-remove-file-btn"
              >
                {t('remove')}
              </Button>
            </div>
          ))}
        </div>
      ),
    [files, isLoading, removeFile, t]
  );

  const renderDropZone = useMemo(
    () => (
      <div
        {...getRootProps()}
        className={`border-2 border-dashed rounded-md p-6 text-center transition-colors ${
          isDragActive ? "border-blue-400" : "border-gray-700"
        } ${isLoading ? "opacity-50 cursor-not-allowed" : ""}`}
      >
        <input {...getInputProps()} data-testid="dropzone-input" />
        {isDragActive ? (
          <p className="text-blue-300">{t('dropImagesHere')}</p>
        ) : isLoading ? (
          <p>{t('cannotDropWhileProcessing')}</p>
        ) : (
          <p>{t('dropFilesHere')}</p>
        )}
      </div>
    ),
    [getInputProps, getRootProps, isDragActive, isLoading, t]
  );

  return (
    <form onSubmit={onSubmit} className="space-y-4">
      <div className="flex justify-end">
        <SupportedFormatsDialog
          supportedExtensions={supportedExtensions}
          verifiedExtensions={verifiedExtensions}
          extensionsLoading={extensionsLoading}
          extensionsError={extensionsError}
        />
      </div>

      {/* Output Format */}
      <div className="space-y-1">
        <div className="flex items-center gap-1">
          <Label htmlFor="outputFormat" className="text-sm">
            {t('outputFormat')}
          </Label>
          <Tooltip>
            <TooltipTrigger asChild>
              <span>
                <Info className="h-4 w-4 text-gray-400 cursor-pointer" />
              </span>
            </TooltipTrigger>
            <TooltipContent
              side="top"
              className="bg-gray-800 text-white p-2 rounded shadow-lg border-0 whitespace-pre-line"
            >
              {t('tooltipOutputFormat')}
            </TooltipContent>
          </Tooltip>
        </div>
        <Select value={outputFormat} onValueChange={setOutputFormat}>
          <SelectTrigger
            id="outputFormat"
            className="bg-gray-800 text-gray-300 border-gray-700 focus:border-blue-500"
          >
            <SelectValue placeholder="Select format" />
          </SelectTrigger>
          <SelectContent className="bg-gray-800 text-gray-300 border-gray-700">
            <SelectItem value="jpeg">{t('jpegSmaller')}</SelectItem>
            <SelectItem value="png">{t('pngTransparency')}</SelectItem>
            <SelectItem value="ico">{t('icoTransparency')}</SelectItem>
          </SelectContent>
        </Select>
      </div>

      {/* JPEG controls mode */}
      {outputFormat === "jpeg" && (
        <div className="space-y-2">
          <Label className="text-sm">{t('jpegSettingsMode')}</Label>
          <div className="grid grid-cols-2 gap-2">
            <Button
              type="button"
              variant={jpegMode === "quality" ? "default" : "outline"}
              disabled={isLoading}
              onClick={() => setJpegMode("quality")}
            >
              {t('setByQuality')}
            </Button>
            <Button
              type="button"
              variant={jpegMode === "size" ? "default" : "outline"}
              disabled={isLoading}
              onClick={() => setJpegMode("size")}
            >
              {t('setByFileSize')}
            </Button>
          </div>
        </div>
      )}

      {/* Quality for JPEG */}
      {outputFormat === "jpeg" && jpegMode === "quality" && (
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <Label
              htmlFor="quality"
              className="text-sm flex items-center gap-1"
            >
              {t('quality')}
              <Tooltip>
                <TooltipTrigger asChild>
                  <span>
                    <Info className="h-4 w-4 text-gray-400 cursor-pointer" />
                  </span>
                </TooltipTrigger>
                <TooltipContent
                  side="top"
                  className="bg-gray-800 text-white p-2 rounded shadow-lg border-0"
                >
                  <p className="text-sm">{t('tooltipQuality')}</p>
                </TooltipContent>
              </Tooltip>
            </Label>
            <span className="text-sm text-gray-400">{quality}</span>
          </div>
          <input
            id="quality"
            type="range"
            min="10"
            max="100"
            value={quality}
            onChange={(e) => setQuality(e.target.value)}
            disabled={isLoading}
            className="w-full accent-blue-500"
          />
          <div className="flex gap-2 pt-2 flex-wrap">
            <Button type="button" size="sm" variant="outline" disabled={isLoading} onClick={() => setQuality("60")}>
              {t('smaller')} (60)
            </Button>
            <Button type="button" size="sm" variant="outline" disabled={isLoading} onClick={() => setQuality("75")}>
              {t('balanced')} (75)
            </Button>
            <Button type="button" size="sm" variant="outline" disabled={isLoading} onClick={() => setQuality("85")}>
              {t('high')} (85)
            </Button>
            <Button type="button" size="sm" variant="outline" disabled={isLoading} onClick={() => setQuality("100")}>
              {t('max')} (100)
            </Button>
          </div>
        </div>
      )}

      {/* Max file size (MB) - only for JPEG in size mode */}
      {outputFormat === "jpeg" && jpegMode === "size" && (
        <div className="space-y-1">
          <div className="flex items-center gap-2">
            <Label
              htmlFor="targetSizeMBRange"
              className="text-sm flex items-center gap-1"
            >
              {t('maxFileSize')}
              <Tooltip>
                <TooltipTrigger asChild>
                  <span>
                    <Info className="h-4 w-4 text-gray-400 cursor-pointer" />
                  </span>
                </TooltipTrigger>
                <TooltipContent
                  side="top"
                  className="bg-gray-800 text-white p-2 rounded shadow-lg border-0"
                >
                  <p className="text-sm">{t('tooltipTargetSize')}</p>
                </TooltipContent>
              </Tooltip>
            </Label>
            {/* value next to label, like quality */}
            <span className="text-sm text-gray-400">
              {(targetSizeMB && targetSizeMB.trim() !== "" ? targetSizeMB : "0.50")} MB
            </span>
          </div>

          {/* slider first */}
          <input
            id="targetSizeMBRange"
            type="range"
            min="0.05"
            max="10"
            step="0.05"
            value={parseFloat(targetSizeMB || "0.50")}
            onChange={(e) => setTargetSizeMB(e.target.value)}
            disabled={isLoading}
            className="w-full accent-blue-500"
          />

          {/* optional number field */}
          <div className="relative">
            <Input
              data-testid="targetSizeMBInput"
              id="targetSizeMB"
              type="number"
              inputMode="decimal"
              step="0.01"
              min="0.01"
              placeholder="e.g., 0.50"
              value={targetSizeMB}
              onChange={(e) => setTargetSizeMB(e.target.value)}
              disabled={isLoading}
              className="bg-gray-800 text-gray-100 placeholder-gray-400 border border-gray-700 focus:border-blue-500 focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed pr-12"
            />
            <span className="absolute inset-y-0 right-3 flex items-center text-sm text-gray-400 pointer-events-none">
              MB
            </span>
          </div>

          <p className="text-xs text-gray-400">
            {t('fileSizeHint')}
          </p>
        </div>
      )}

      {/* Resize Width */}
      <div className="space-y-1">
        <div className="flex items-center gap-2">
          <Label
            htmlFor="resizeWidthToggle"
            className="text-sm flex items-center gap-1"
          >
            {t('resizeWidth')}
            <Tooltip>
              <TooltipTrigger asChild>
                <span>
                  <Info className="h-4 w-4 text-gray-400 cursor-pointer" />
                </span>
              </TooltipTrigger>
              <TooltipContent
                side="top"
                className="bg-gray-800 text-white p-2 rounded shadow-lg border-0"
              >
                <p className="text-sm">{t('tooltipResizeWidth')}</p>
              </TooltipContent>
            </Tooltip>
          </Label>
          <Switch
            data-testid="resize-width-switch"
            id="resizeWidthToggle"
            checked={resizeWidthEnabled}
            onCheckedChange={(checked) => {
              setResizeWidthEnabled(checked);
              if (checked && width === "") {
                setWidth("800");
              } else if (!checked) {
                setWidth("");
              }
            }}
            disabled={isLoading}
          />
        </div>
        {resizeWidthEnabled && (
          <Input
            data-testid="resize-width-input"
            itemProp="data-testid: convert-btn"
            id="width"
            type="number"
            placeholder="800"
            value={width}
            onChange={(e) => setWidth(e.target.value)}
            disabled={isLoading}
            className="bg-gray-800 text-gray-100 placeholder-gray-400 border border-gray-700 focus:border-blue-500 focus:ring-2 focus:ring-blue-500 disabled:opacity-50 disabled:cursor-not-allowed"
          />
        )}
      </div>

      {/* Error Alert (if any) */}
      {renderError}

      {/* Dropzone */}
      {renderDropZone}

      {/* Files List */}
      {renderFilesList}

      {/* Action Buttons */}
      <div className="flex items-center justify-between gap-4">
        <Button type="submit" variant="default" disabled={isLoading} data-testid="convert-btn">
          {isLoading ? (
            <div className="flex items-center gap-2">
              <Loader2 className="h-4 w-4 animate-spin" />
              {t('processing')}
            </div>
          ) : (
            t('startConverting')
          )}
        </Button>
        <Button
          type="button"
          variant="outline"
          onClick={clearFileSelection}
          disabled={isLoading}
          className="flex items-center gap-2 outline outline-1 outline-gray-700"
        >
          <Trash className="h-4 w-4" />
          {t('clear')}
        </Button>
      </div>
    </form>
  );
};

export default FileConversionForm;
