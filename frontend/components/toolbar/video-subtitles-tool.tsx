"use client";
import { Captions } from "lucide-react";
import { useEffect, useState } from "react";
import { ToolbarButton } from "./toolbar-button";
import { Button } from "../ui/button";
import { Label } from "../ui/label";
import {
  useCurrentImage,
  useProjectInfo,
  useUnsavedChanges,
} from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useVideoSubtitles } from "@/hooks/use-video-subtitles";
import { subtitleLabel } from "@/lib/subtitles";
import { VideoSubtitlesToolParams } from "@/lib/tool-types";

const DEFAULT_PARAMS: VideoSubtitlesToolParams = { language: "original" };

// UC-VID-001: legendas automáticas como ferramenta da pipeline. "Save" adiciona-a ao
// projeto e as legendas só são geradas quando o utilizador carrega em "Apply".
// O mesmo painel deixa mostrar ou esconder as faixas que já existem neste vídeo.
export default function VideoSubtitlesTool({ disabled }: { disabled: boolean }) {
  const project = useProjectInfo();
  const video = useCurrentImage();
  const session = useSession();
  const { setHasUnsavedChanges } = useUnsavedChanges();
  const subtitles = useVideoSubtitles(video?._id || "", !disabled);

  const [params, setParams] = useState<VideoSubtitlesToolParams>(DEFAULT_PARAMS);
  const [open, setOpen] = useState<boolean>(false);

  useEffect(() => {
    const tool = project.tools.find((t) => t.procedure === "video_subtitles");
    setParams(tool ? (tool.params as VideoSubtitlesToolParams) : DEFAULT_PARAMS);
  }, [project.tools, open]);

  const videos = project.imgs.filter((i) => i.media_type === "video");
  const otherTools = project.tools.some((t) => t.procedure !== "video_subtitles");
  const { data, selection } = subtitles;
  const english = data?.detectedLanguage === "en";

  return (
    <ToolbarButton
      open={open}
      setOpen={(value) => {
        setOpen(value);
        if (value && subtitles.eligible) subtitles.refetch();
      }}
      tool={{ procedure: "video_subtitles", params }}
      onDefault={() => {
        setParams(DEFAULT_PARAMS);
        setHasUnsavedChanges(false);
      }}
      isDefault={false}
      invalid={otherTools}
      noPreview
      isPremium
      disabled={disabled}
      icon={Captions}
      label="Automatic subtitles"
    >
      <div className="space-y-3 text-sm">
        <div className="space-y-1">
          <Label className="text-gray-500">Generate on Apply</Label>
          <div className="flex gap-1">
            {(["original", "en"] as const).map((language) => (
              <Button
                key={language}
                variant={params.language === language ? "default" : "outline"}
                className="h-7 text-xs flex-1"
                onClick={() => {
                  setParams({ language });
                  setHasUnsavedChanges(true);
                }}
              >
                {language === "original" ? "Original language" : "English"}
              </Button>
            ))}
          </div>
        </div>

        {subtitles.eligible && (
          <div className="space-y-1">
            <Label htmlFor="subtitle-track" className="text-gray-500">Show subtitles</Label>
            <select
              id="subtitle-track"
              className="w-full rounded border bg-background p-1 text-xs"
              value={selection}
              disabled={subtitles.isLoading}
              onChange={(e) => subtitles.select(e.target.value as "off" | "original" | "en")}
            >
              <option value="off">Off</option>
              {data?.tracks.original && (
                <option value="original">{subtitleLabel(data.detectedLanguage)}</option>
              )}
              {data?.tracks.en && !english && <option value="en">English</option>}
            </select>
            {subtitles.generating && (
              <p role="status" className="text-xs">Generating subtitles for this video…</p>
            )}
            {data?.error?.message && (
              <p role="alert" className="text-xs text-destructive">{data.error.message}</p>
            )}
          </div>
        )}

        <div className="text-xs text-muted-foreground space-y-1 pt-1">
          <p>
            Applies to all {videos.length} video{videos.length === 1 ? "" : "s"} of the project
            {session.user.type === "premium"
              ? "."
              : ` · uses up to ${videos.length} daily operation${videos.length === 1 ? "" : "s"} (videos that already have this track are free).`}
          </p>
          {otherTools && (
            <p className="text-red-500">
              Subtitles cannot be combined with other tools. Remove them first.
            </p>
          )}
        </div>
      </div>
    </ToolbarButton>
  );
}
