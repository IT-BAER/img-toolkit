import { FileDown, FolderDown } from "lucide-react";
import React from "react";

interface DownloadFileToastProps {
  fileName: string;
  downloadingLabel?: string;
}

interface DownloadZipToastProps {
  downloadingLabel?: string;
  folderLabel?: string;
}

const DownloadFileToast: React.FC<DownloadFileToastProps> = ({ fileName, downloadingLabel = "Downloading:" }) => (
    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
      <FileDown style={{ fontSize: "24px", flexShrink: 0 }} />
      <span style={{ fontSize: "16px", fontWeight: "bold", wordBreak: "break-word" }}>
        {downloadingLabel} <strong>{fileName}</strong>...
      </span>
    </div>
  );


  const DownloadZipToast: React.FC<DownloadZipToastProps> = ({ downloadingLabel = "Downloading:", folderLabel = "Folder" }) => (
    <div style={{ display: "flex", alignItems: "center", gap: "10px" }}>
      <FolderDown style={{ fontSize: "24px", flexShrink: 0 }} />
      <span style={{ fontSize: "16px", fontWeight: "bold", wordBreak: "break-word" }}>
        {downloadingLabel} <strong>{folderLabel}</strong>...
      </span>
    </div>
  );

export{
    DownloadFileToast, DownloadZipToast
};