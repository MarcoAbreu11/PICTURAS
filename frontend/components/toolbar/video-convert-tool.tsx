import { useEffect, useState } from "react";
import Link from "next/link";
import { FileVideo2 } from "lucide-react";
import { Label } from "@/components/ui/label";
import { useCurrentImage, useProjectInfo, useUnsavedChanges } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import type { VideoConvertToolParams } from "@/lib/tool-types";
import { estimateVideoConversion } from "@/lib/projects";
import { ToolbarButton } from "./toolbar-button";

const DEFAULT_PARAMS: VideoConvertToolParams = {
  format: "mp4",
  resolution: "original",
  quality: "medium",
  allow_larger: false,
};

function formatBytes(bytes?: number) {
  if (!bytes || bytes < 0) return "unknown size";
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

// UC-VID-005: converts or compresses the selected video into a new file in the library.
export default function VideoConvertTool({ disabled }: { disabled: boolean }) {
  const project = useProjectInfo();
  const currentImage = useCurrentImage();
  const session = useSession();
  const { setHasUnsavedChanges } = useUnsavedChanges();
  const [open, setOpen] = useState(false);
  const [params, setParams] = useState<VideoConvertToolParams>(DEFAULT_PARAMS);
  const [preset, setPreset] = useState("custom");
  const [estimatedSize, setEstimatedSize] = useState<number>();
  const [estimateLoading, setEstimateLoading] = useState(false);
  const [estimateError, setEstimateError] = useState<string>();

  useEffect(() => {
    const saved = project.tools.find((tool) => tool.procedure === "video_convert");
    setParams(saved ? { ...DEFAULT_PARAMS, ...(saved.params as VideoConvertToolParams) } : DEFAULT_PARAMS);
  }, [project.tools, open]);

  const videos = project.imgs.filter((img) => img.media_type === "video");
  const otherTools = project.tools.some((tool) => tool.procedure !== "video_convert");
  // passo 2: o vídeo escolhido; por omissão o que está aberto, senão o primeiro
  const defaultVideoId = currentImage?.media_type === "video" ? currentImage._id : videos[0]?._id;
  const videoId = params.video_id && videos.some((v) => v._id === params.video_id)
    ? params.video_id
    : defaultVideoId;
  const selectedVideo = videos.find((v) => v._id === videoId);
  const currentSize = selectedVideo?.size_bytes;
  const sourceHeight = selectedVideo?.height ?? 0;
  const maxHeight = session.user.type === "premium" ? 1080 : 720;
  const targetHeight = params.resolution === "original"
    ? Math.min(sourceHeight || maxHeight, maxHeight)
    : Number(params.resolution);

  useEffect(() => {
    if (!videoId || session.user.type === "anonymous") {
      setEstimatedSize(undefined);
      setEstimateLoading(false);
      return;
    }

    let active = true;
    setEstimateLoading(true);
    setEstimateError(undefined);
    const timer = setTimeout(() => {
      estimateVideoConversion({
        uid: session.user._id,
        pid: project._id,
        imageId: videoId,
        token: session.token,
        ownerId: session.user._id,
        params: {
          format: params.format,
          resolution: params.resolution,
          quality: params.quality,
          allow_larger: params.allow_larger,
        },
      })
        .then((estimate) => {
          if (active) setEstimatedSize(estimate.estimatedSizeBytes);
        })
        .catch((error) => {
          if (!active) return;
          const message = error?.response?.data;
          setEstimateError(typeof message === "string" ? message : "Could not estimate the output size");
          setEstimatedSize(undefined);
        })
        .finally(() => {
          if (active) setEstimateLoading(false);
        });
    }, 600);

    return () => {
      active = false;
      clearTimeout(timer);
    };
  }, [
    videoId,
    params.format,
    params.quality,
    params.resolution,
    project._id,
    session.token,
    session.user._id,
    session.user.type,
  ]);

  const largerThanSource = estimatedSize !== undefined && currentSize !== undefined && estimatedSize > currentSize;
  const unsupportedVideo = !!selectedVideo && (() => {
    const ext = selectedVideo.name.split(".").pop()?.toLowerCase();
    return (ext !== "mp4" && ext !== "mov") ||
      (!!selectedVideo.video_codec && selectedVideo.video_codec !== "h264") ||
      (selectedVideo.size_bytes != null && selectedVideo.audio_codec !== "aac") ||
      (selectedVideo.duration !== undefined && selectedVideo.duration > 600) ||
      (selectedVideo.size_bytes !== undefined && selectedVideo.size_bytes > 500 * 1024 * 1024);
  })();

  function update(changes: Partial<VideoConvertToolParams>) {
    setParams((current) => ({ ...current, ...changes }));
    setPreset("custom");
    setHasUnsavedChanges(true);
  }

  const invalid = !selectedVideo || otherTools || unsupportedVideo ||
    (params.resolution !== "original" && Number(params.resolution) > maxHeight) ||
    (largerThanSource && !params.allow_larger);

  return (
    <ToolbarButton
      open={open}
      setOpen={setOpen}
      tool={{ procedure: "video_convert", params: { ...params, video_id: videoId } }}
      onDefault={() => {
        setParams(DEFAULT_PARAMS);
        setPreset("custom");
        setHasUnsavedChanges(false);
      }}
      isDefault={false}
      isPremium={session.user.type === "anonymous" || session.user.type === "premium"}
      invalid={invalid}
      noPreview
      disabled={disabled}
      icon={FileVideo2}
      label="Convert / compress video"
    >
      <div className="space-y-3 text-sm">
        <p className="text-xs text-muted-foreground">
          Creates a new video in this project and keeps the original unchanged.
        </p>

        <div className="space-y-1">
          <Label htmlFor="video-convert-source">Video</Label>
          <select
            id="video-convert-source"
            className="h-8 w-full rounded-md border bg-background px-2 text-xs"
            value={videoId ?? ""}
            onChange={(event) => update({ video_id: event.target.value })}
          >
            {videos.length === 0 && <option value="">No videos in this project</option>}
            {videos.map((video) => (
              <option key={video._id} value={video._id}>{video.name}</option>
            ))}
          </select>
        </div>

        <div className="space-y-1">
          <Label htmlFor="video-convert-preset">Preset</Label>
          <select
            id="video-convert-preset"
            className="h-8 w-full rounded-md border bg-background px-2 text-xs"
            value={preset}
            onChange={(event) => {
              setPreset(event.target.value);
              if (event.target.value === "web") setParams({ format: "mp4", resolution: 720, quality: "medium", allow_larger: false, video_id: videoId });
              if (event.target.value === "messages") setParams({ format: "mp4", resolution: 480, quality: "low", allow_larger: false, video_id: videoId });
              setHasUnsavedChanges(true);
            }}
          >
            <option value="custom">Custom</option>
            <option value="web">Web sharing · MP4 720p</option>
            <option value="messages">Messaging · MP4 480p</option>
          </select>
        </div>

        <div className="space-y-1">
          <Label htmlFor="video-convert-format">Output format</Label>
          <select
            id="video-convert-format"
            className="h-8 w-full rounded-md border bg-background px-2 text-xs"
            value={params.format}
            onChange={(event) => update({ format: event.target.value as VideoConvertToolParams["format"] })}
          >
            <option value="mp4">MP4 · H.264 / AAC</option>
            <option value="webm">WebM · VP9 / Opus</option>
          </select>
        </div>

        <div className="space-y-1">
          <Label htmlFor="video-convert-resolution">Maximum resolution</Label>
          <select
            id="video-convert-resolution"
            className="h-8 w-full rounded-md border bg-background px-2 text-xs"
            value={String(params.resolution)}
            onChange={(event) => update({ resolution: event.target.value === "original" ? "original" : Number(event.target.value) as 1080 | 720 | 480 | 360 })}
          >
            <option value="original">Original (maximum {maxHeight}p)</option>
            {session.user.type === "premium" && <option value="1080">1080p</option>}
            <option value="720">720p</option>
            <option value="480">480p</option>
            <option value="360">360p</option>
          </select>
          {session.user.type === "free" && (
            <p className="text-[11px] text-muted-foreground">
              Free accounts: up to 720p.{" "}
              <Link href="/dashboard/account/upgrade?ref=/dashboard" className="text-indigo-500 underline">
                Upgrade to Premium
              </Link>{" "}
              for 1080p.
            </p>
          )}
        </div>

        <div className="space-y-1">
          <Label htmlFor="video-convert-quality">Quality</Label>
          <select
            id="video-convert-quality"
            className="h-8 w-full rounded-md border bg-background px-2 text-xs"
            value={params.quality}
            onChange={(event) => update({ quality: event.target.value as VideoConvertToolParams["quality"] })}
          >
            <option value="high">High</option>
            <option value="medium">Medium</option>
            <option value="low">Low · smaller file</option>
          </select>
        </div>

        <div className="rounded border p-2 text-xs">
          <p>Source: {selectedVideo?.name ?? "—"} · {formatBytes(currentSize)}</p>
          {sourceHeight > 0 && <p>Source resolution: {selectedVideo?.width} × {sourceHeight}</p>}
          <p>Estimated output: {estimateLoading ? "calculating…" : estimatedSize ? formatBytes(estimatedSize) : "not available"}</p>
          <p className="text-muted-foreground">Estimated by sampling the video; actual size may differ.</p>
          {estimateError && <p className="text-red-500">{estimateError}</p>}
        </div>

        <label className={`flex items-start gap-2 text-xs ${largerThanSource ? "text-amber-600" : "text-muted-foreground"}`}>
          <input
            type="checkbox"
            checked={!!params.allow_larger}
            onChange={(event) => update({ allow_larger: event.target.checked })}
          />
          <span>{largerThanSource
            ? "The estimate is larger than the original. Confirm that you want to keep a larger result."
            : "Allow the result if the actual converted file ends up larger than the original."}</span>
        </label>

        {session.user.type === "free" && (
          <p className="text-xs text-muted-foreground">
            This conversion uses one daily operation after it succeeds.
            {session.user.remaining_operations != null && ` ${session.user.remaining_operations} remaining.`}
          </p>
        )}
        {session.user.type === "premium" && <p className="text-xs text-muted-foreground">Premium conversions do not use a daily operation.</p>}
        {session.user.type === "anonymous" && <p className="text-xs text-red-500">Sign in to convert or compress videos.</p>}
        {unsupportedVideo && <p className="text-xs text-red-500">Input must be MP4 or MOV with H.264 video and AAC audio, at most 500 MB and 10 minutes.</p>}
        {otherTools && <p className="text-xs text-red-500">Conversion cannot be combined with other tools.</p>}
      </div>
    </ToolbarButton>
  );
}
