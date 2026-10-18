import { ToolbarButton } from "./toolbar-button";
import { Film } from "lucide-react";
import { useEffect, useState } from "react";
import { Label } from "../ui/label";
import { Input } from "../ui/input";
import { Button } from "../ui/button";
import {
  useCurrentImage,
  useProjectInfo,
  useUnsavedChanges,
} from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { ExtractFramesToolParams } from "@/lib/tool-types";
import { DEFAULT_FRAME_PARAMS, MAX_FRAMES_PER_VIDEO, frameCount } from "@/lib/frames";

// UC-VID-003: tool de vídeo que extrai frames como imagens (resultados do projeto)
export default function ExtractFramesTool({ disabled }: { disabled: boolean }) {
  const project = useProjectInfo();
  const currentImage = useCurrentImage();
  const session = useSession();
  const { setHasUnsavedChanges } = useUnsavedChanges();

  const [params, setParams] = useState<ExtractFramesToolParams>(DEFAULT_FRAME_PARAMS);
  const [open, setOpen] = useState<boolean>(false);

  useEffect(() => {
    const tool = project.tools.find((t) => t.procedure === "extract_frames");
    setParams(tool ? (tool.params as ExtractFramesToolParams) : DEFAULT_FRAME_PARAMS);
  }, [project.tools, open]);

  function update(changes: Partial<ExtractFramesToolParams>) {
    setParams((p) => ({ ...p, ...changes }));
    setHasUnsavedChanges(true);
  }

  // estimativa antes de aplicar (FRAME-049)
  const videos = project.imgs.filter((i) => i.media_type === "video");
  const currentDuration = currentImage?.duration;
  const currentFrames =
    currentDuration !== undefined ? frameCount(params, currentDuration) : undefined;
  const overLimit = videos.some(
    (v) => v.duration !== undefined && frameCount(params, v.duration) > MAX_FRAMES_PER_VIDEO,
  );
  const tooShort =
    params.mode === "single"
      ? videos.filter((v) => v.duration !== undefined && params.instant >= v.duration)
      : [];
  const otherTools = project.tools.some((t) => t.procedure !== "extract_frames");

  const invalid =
    (params.mode === "interval" && !(params.interval > 0)) ||
    (params.mode === "single" && !(params.instant >= 0));

  return (
    <ToolbarButton
      open={open}
      setOpen={setOpen}
      tool={{ procedure: "extract_frames", params }}
      onDefault={() => {
        setParams(DEFAULT_FRAME_PARAMS);
        setHasUnsavedChanges(false);
      }}
      isDefault={false}
      invalid={invalid || otherTools || overLimit || tooShort.length > 0}
      isPremium
      disabled={disabled}
      icon={Film}
      label="Extract frames"
    >
      <div className="space-y-2 text-sm">
        <div className="flex gap-1">
          <Button
            variant={params.mode === "interval" ? "default" : "outline"}
            className="h-7 text-xs flex-1"
            onClick={() => update({ mode: "interval" })}
          >
            Every N seconds
          </Button>
          <Button
            variant={params.mode === "single" ? "default" : "outline"}
            className="h-7 text-xs flex-1"
            onClick={() => update({ mode: "single" })}
          >
            Single frame
          </Button>
        </div>

        {params.mode === "interval" ? (
          <div className="flex justify-between items-center text-gray-500">
            <Label htmlFor="frames-interval">Interval</Label>
            <div className="flex items-center space-x-2 w-1/2">
              <Input
                id="frames-interval"
                type="number"
                min={0.1}
                step={0.5}
                value={params.interval}
                onChange={(e) => update({ interval: Number(e.target.value) })}
              />
              <span>s</span>
            </div>
          </div>
        ) : (
          <div className="flex justify-between items-center text-gray-500">
            <Label htmlFor="frames-instant">Instant</Label>
            <div className="flex items-center space-x-2 w-1/2">
              <Input
                id="frames-instant"
                type="number"
                min={0}
                step={0.5}
                value={params.instant}
                onChange={(e) => update({ instant: Number(e.target.value) })}
              />
              <span>s</span>
            </div>
          </div>
        )}

        <div className="flex justify-between items-center text-gray-500">
          <Label>Format</Label>
          <div className="flex gap-1">
            {(["png", "jpeg"] as const).map((f) => (
              <Button
                key={f}
                variant={params.format === f ? "default" : "outline"}
                className="h-6 text-xs"
                onClick={() => update({ format: f })}
              >
                {f.toUpperCase()}
              </Button>
            ))}
          </div>
        </div>

        <div className="text-xs text-muted-foreground space-y-1 pt-1">
          {currentFrames !== undefined && (
            <p>
              This video: <b>{currentFrames}</b> image{currentFrames === 1 ? "" : "s"}
            </p>
          )}
          <p>
            Applies to all {videos.length} video{videos.length === 1 ? "" : "s"} of the project
            {session.user.type === "premium"
              ? "."
              : ` · uses ${videos.length} daily operation${videos.length === 1 ? "" : "s"}.`}
          </p>
          {overLimit && (
            <p className="text-red-500">
              Some videos would generate more than {MAX_FRAMES_PER_VIDEO} images. Increase the interval.
            </p>
          )}
          {tooShort.length > 0 && (
            <p className="text-red-500">
              The instant is beyond the end of: {tooShort.map((v) => v.name).join(", ")}
            </p>
          )}
          {otherTools && (
            <p className="text-red-500">
              Frame extraction cannot be combined with other tools. Remove them first.
            </p>
          )}
        </div>
      </div>
    </ToolbarButton>
  );
}
