"use client";
import { Captions, Sparkles } from "lucide-react";
import { useState } from "react";
import axios from "axios";
import { useCurrentImage, useCanEditProject } from "@/providers/project-provider";
import { useVideoSubtitles } from "@/hooks/use-video-subtitles";
import { subtitleLabel } from "@/lib/subtitles";
import { Button } from "../ui/button";
import { Popover, PopoverContent, PopoverTrigger } from "../ui/popover";

export default function VideoSubtitlesTool({ disabled }: { disabled: boolean }) {
  const video = useCurrentImage();
  const canEdit = useCanEditProject();
  const subtitles = useVideoSubtitles(video?._id || "", !disabled);
  const [open, setOpen] = useState(false);
  const { data, generating, eligible, selection } = subtitles;
  const requestError = subtitles.requestError || subtitles.error;
  const message = axios.isAxiosError(requestError)
    ? requestError.response?.data?.message || "Não foi possível comunicar com o serviço de legendas"
    : data?.error?.message;
  return (
    <Popover open={open} onOpenChange={(value) => {
      setOpen(value);
      if (value && eligible) subtitles.refetch();
    }}>
      <PopoverTrigger asChild>
        <Button variant="outline" className="relative size-8" disabled={disabled}
          title="Legendas automáticas" aria-label="Legendas automáticas">
          <Captions className="size-4" /><Sparkles className="absolute -right-1 -top-1 size-3 text-yellow-500" />
        </Button>
      </PopoverTrigger>
      <PopoverContent side="right" className="w-72 space-y-3">
        <h3 className="font-medium">Legendas automáticas</h3>
        {!eligible ? <p>Inicie sessão com uma conta registada para usar legendas.</p> : (
          <>
            <label className="block text-sm" htmlFor="subtitle-language">Faixa de legendas</label>
            <select id="subtitle-language" className="w-full rounded border bg-background p-2"
              value={selection} disabled={subtitles.isLoading}
              onChange={(event) => subtitles.select(event.target.value as "off" | "original" | "en")}>
              <option value="off">Desativadas</option>
              <option value="original" disabled={!data?.tracks.original && (generating || !canEdit)}>
                {data?.tracks.original ? subtitleLabel(data.detectedLanguage) : `Gerar ${subtitleLabel(data?.detectedLanguage)}`}
              </option>
              {data?.detectedLanguage !== "en" && (
                <option value="en" disabled={!data?.tracks.en && (generating || !canEdit)}>
                  {data?.tracks.en ? "English" : "Gerar English"}
                </option>
              )}
            </select>
            {generating && <p role="status" className="text-sm">A gerar legendas. Este processo pode demorar.</p>}
            {message && <p role="alert" className="text-sm text-destructive">{message}</p>}
            {!canEdit && <p className="text-sm">Pode selecionar faixas existentes. Gerar requer permissão de edição.</p>}
          </>
        )}
      </PopoverContent>
    </Popover>
  );
}
