import React from "react";
import { Card, CardHeader, CardTitle, CardContent } from "@/components/ui/card";
import { LanguageToggle } from "@/components/LanguageToggle";
import { useTranslation } from "@/context/LanguageContext";

interface PageFooterProps extends React.HTMLAttributes<HTMLDivElement> {
  className?: string;
}

const PageFooter = ({ className, ...props }: PageFooterProps) => {
  const { t } = useTranslation();
  
  return (
    <Card className={`w-full mt-8 ${className || ''}`} {...props}>
      <CardHeader className="flex flex-row items-center justify-between">
        <CardTitle>{t('openSource')}</CardTitle>
        <LanguageToggle />
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted-foreground">
          {t('footerDescription')} {t('checkOut')}{" "}
          <a
            href="https://github.com/IT-BAER/IMG-Toolkit"
            className="text-primary hover:underline"
            target="_blank"
            rel="noopener noreferrer"
          >
            {t('sourceCode')}
          </a>.
        </p>
        <p className="text-sm text-muted-foreground mt-2">
          {t('featureIdeas')}{" "}
          <a
            href="https://github.com/IT-BAER/IMG-Toolkit/issues"
            className="text-primary hover:underline"
          >
            GitHub Issues
          </a>.
        </p>
      </CardContent>
    </Card>
  );
};

export default PageFooter;
