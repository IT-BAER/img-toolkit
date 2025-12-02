import React from "react";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { LanguageToggle } from "@/components/LanguageToggle";
import { useTranslation } from "@/context/LanguageContext";

const PageFooter = (props: React.HTMLAttributes<HTMLDivElement>) => {
  const { t } = useTranslation();
  
  return (
    <Card className={`w-full max-w-xl mt-8`} {...props}>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>{t('openSource')}</CardTitle>
        <LanguageToggle />
      </CardHeader>
      <CardContent>
        <p className="text-sm text-gray-600 dark:text-gray-400">
          {t('footerDescription')} {t('checkOut')}{" "}
          <a
            href="https://github.com/IT-BAER/IMG-Toolkit"
            className="text-blue-400 hover:underline"
            target="_blank"
            rel="noopener noreferrer"
          >
            {t('sourceCode')}
          </a>.
        </p>
        <p className="text-sm text-gray-600 dark:text-gray-400 mt-2">
          {t('featureIdeas')}{" "}
          <a
            href="https://github.com/IT-BAER/IMG-Toolkit/issues"
            className="text-blue-400 hover:underline"
          >
            GitHub Issues
          </a>.
        </p>
      </CardContent>
    </Card>
  );
};

export default PageFooter;
