"use client";

import React from "react";
import { Button } from "@/components/ui/button";
import { useTranslation } from "@/context/LanguageContext";

export function LanguageToggle() {
  const { language, setLanguage } = useTranslation();

  return (
    <Button
      variant="ghost"
      size="sm"
      onClick={() => setLanguage(language === "en" ? "de" : "en")}
      className="text-xs font-medium"
    >
      {language === "en" ? "DE" : "EN"}
    </Button>
  );
}
