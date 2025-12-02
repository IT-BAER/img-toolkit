"use client"

import React from "react"
import {Info} from "lucide-react"
import {
    Dialog,
    DialogContent,
    DialogHeader,
    DialogTitle,
    DialogDescription,
    DialogTrigger,
} from "@/components/ui/dialog"
import {Button} from "@/components/ui/button"
import { useTranslation } from "@/context/LanguageContext"

interface SupportedFormatsDialogProps {
    supportedExtensions: string[]
    verifiedExtensions: string[]
    extensionsLoading: boolean
    extensionsError: Error | null
}

export function SupportedFormatsDialog({
                                           supportedExtensions,
                                           verifiedExtensions,
                                           extensionsLoading,
                                           extensionsError,
                                       }: SupportedFormatsDialogProps) {
    const { t } = useTranslation()
    const total = supportedExtensions.length
    const unverified = supportedExtensions.filter(
        (ext) => !verifiedExtensions.includes(ext)
    )

    return (
        <Dialog>
            <DialogTrigger asChild>
                <Button variant="outline" size="sm" className="flex items-center gap-1">
                    <Info className="h-4 w-4"/>
                    {t('supportedFormats')}{" "}
                    {extensionsLoading ? "(…)" : total ? `(${total})` : ""}
                </Button>
            </DialogTrigger>

            <DialogContent
                className="max-w-[600px] rounded-xl border border-border bg-white dark:bg-zinc-900
                   text-zinc-900 dark:text-zinc-50 shadow-xl"
            >
                <DialogHeader>
                    <DialogTitle className="flex items-center gap-2 text-base sm:text-lg font-semibold">
                        <Info className="h-5 w-5 text-blue-500 dark:text-blue-400"/>
                        {t('supportedFormatsImagesPdfs')}
                    </DialogTitle>
                    <DialogDescription className="text-sm text-muted-foreground">
                        {t('verifiedExperimentalFormats')}
                    </DialogDescription>
                </DialogHeader>

                {extensionsLoading ? (
                    <p className="text-sm text-muted-foreground">{t('loading')}</p>
                ) : extensionsError ? (
                    <p className="text-sm text-destructive">
                        {t('errorLoadingFormats')} {extensionsError.message}
                    </p>
                ) : (
                    <div className="space-y-6 overflow-y-auto max-h-[65vh] pr-2">
                        {/* ✅ Verified Formats */}
                        <section>
                            <h3 className="font-semibold text-green-600 dark:text-green-400 text-base mb-1">
                                {t('verifiedFormatsTitle')}
                            </h3>
                            <p className="text-sm text-muted-foreground leading-relaxed">
                                {t('verifiedFormatsDesc')}
                            </p>
                            <p className="mt-2 text-sm font-mono break-words text-foreground">
                                {verifiedExtensions.length > 0
                                    ? verifiedExtensions.join(" · ")
                                    : t('noneListed')}
                            </p>
                        </section>

                        <hr className="border-border/40"/>

                        {/* 🧪 Experimental Formats */}
                        <section>
                            <h3 className="font-semibold text-yellow-600 dark:text-yellow-400 text-base mb-1">
                                {t('experimentalFormatsTitle')}
                            </h3>
                            <p className="text-sm text-muted-foreground leading-relaxed">
                                {t('experimentalFormatsDesc')}
                            </p>

                            <p className="mt-2 text-sm font-mono break-words text-foreground">
                                {unverified.length > 0 ? unverified.join(" · ") : t('noneListed')}
                            </p>
                            <p className="mt-3 text-xs text-muted-foreground leading-relaxed">
                                {t('experimentalIssueHint')}
                            </p>
                        </section>
                    </div>
                )}
           </DialogContent>
        </Dialog>
    )
}
