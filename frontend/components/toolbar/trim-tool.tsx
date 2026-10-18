import { ToolbarButton } from "./toolbar-button";
import { Scissors, Play, Pause } from "lucide-react";
import { useEffect, useRef, useState } from "react";
import { Label } from "../ui/label";
import { Input } from "../ui/input";
import { Button } from "../ui/button";
import { Slider } from "../ui/slider";
import {
  useCurrentImage,
  useProjectInfo,
  useUnsavedChanges,
} from "@/providers/project-provider";
import { TrimToolParams } from "@/lib/tool-types";
import { MIN_EXCERPT_SECONDS, formatTime, parseTime } from "@/lib/trim";

// Campo hh:mm:ss: o texto só é aplicado quando é um tempo válido (TRIM-010)
function TimeInput({
  id,
  value,
  onChange,
}: {
  id: string;
  value: number;
  onChange: (seconds: number) => void;
}) {
  const [text, setText] = useState(formatTime(value));
  useEffect(() => setText(formatTime(value)), [value]);

  return (
    <Input
      id={id}
      value={text}
      className="h-7 w-28 text-xs"
      onChange={(e) => {
        setText(e.target.value);
        const s = parseTime(e.target.value);
        if (s !== null) onChange(s);
      }}
      onBlur={() => setText(formatTime(value))}
    />
  );
}

// UC-VID-002: tool de vídeo que mantém apenas o excerto entre dois instantes
export default function TrimTool({ disabled }: { disabled: boolean }) {
  const project = useProjectInfo();
  const currentImage = useCurrentImage();
  const { setHasUnsavedChanges } = useUnsavedChanges();

  // duração do vídeo aberto: guardada no upload, ou lida do leitor (vídeos antigos)
  const [loadedDuration, setLoadedDuration] = useState<number | undefined>(undefined);
  const duration = currentImage?.duration ?? loadedDuration ?? 0;

  const [params, setParams] = useState<TrimToolParams>({ start: 0, end: 0 });
  const [open, setOpen] = useState<boolean>(false);
  const [playing, setPlaying] = useState(false);
  const videoRef = useRef<HTMLVideoElement>(null);

  useEffect(() => {
    const tool = project.tools.find((t) => t.procedure === "trim");
    setParams(tool ? (tool.params as TrimToolParams) : { start: 0, end: duration });
  }, [project.tools, open, duration]);

  function update(changes: Partial<TrimToolParams>) {
    setParams((p) => ({ ...p, ...changes }));
    setHasUnsavedChanges(true);
  }

  // pré-visualização do excerto no leitor, sem processamento (FA1, TRIM-009)
  function togglePreview() {
    const v = videoRef.current;
    if (!v) return;
    if (playing) {
      v.pause();
      return;
    }
    v.currentTime = params.start;
    v.play();
  }

  const excerpt = params.end - params.start;
  const videos = project.imgs.filter((i) => i.media_type === "video");
  const tooShort = videos.filter((v) => v.duration !== undefined && params.end > v.duration + 0.05);
  const otherTools = project.tools.some((t) => t.procedure !== "trim");

  const startAfterEnd = params.start >= params.end;
  const excerptTooShort = !startAfterEnd && excerpt < MIN_EXCERPT_SECONDS;

  return (
    <ToolbarButton
      open={open}
      setOpen={setOpen}
      tool={{ procedure: "trim", params }}
      onDefault={() => {
        setParams({ start: 0, end: duration });
        setHasUnsavedChanges(false);
      }}
      isDefault={false}
      invalid={startAfterEnd || excerptTooShort || tooShort.length > 0 || otherTools}
      noPreview
      disabled={disabled}
      icon={Scissors}
      label="Trim video"
    >
      <div className="space-y-2 text-sm">
        {currentImage && (
          <video
            ref={videoRef}
            src={currentImage.url}
            className="w-full rounded-md bg-black max-h-36"
            preload="metadata"
            muted
            onLoadedMetadata={(e) => setLoadedDuration(e.currentTarget.duration)}
            onPlay={() => setPlaying(true)}
            onPause={() => setPlaying(false)}
            onTimeUpdate={(e) => {
              if (e.currentTarget.currentTime >= params.end) e.currentTarget.pause();
            }}
          />
        )}

        {/* linha temporal com os marcadores de início e fim (TRIM-002, TRIM-003) */}
        <Slider
          min={0}
          max={duration || 1}
          step={0.1}
          value={[params.start, params.end]}
          minStepsBetweenThumbs={1}
          onValueChange={([start, end]) => update({ start, end })}
          className="w-full py-1"
        />
        <div className="flex justify-between text-[10px] text-muted-foreground">
          <span>00:00:00</span>
          <span>{formatTime(duration)}</span>
        </div>

        <div className="flex justify-between items-center text-gray-500">
          <Label htmlFor="trim-start">Start</Label>
          <TimeInput id="trim-start" value={params.start} onChange={(start) => update({ start })} />
        </div>
        <div className="flex justify-between items-center text-gray-500">
          <Label htmlFor="trim-end">End</Label>
          <TimeInput id="trim-end" value={params.end} onChange={(end) => update({ end })} />
        </div>

        <div className="flex justify-between items-center">
          <span className="text-xs text-muted-foreground">
            Excerpt: <b>{formatTime(Math.max(0, excerpt))}</b>
          </span>
          <Button
            variant="outline"
            className="h-6 text-xs"
            onClick={togglePreview}
            disabled={startAfterEnd}
          >
            {playing ? <Pause className="h-3 w-3" /> : <Play className="h-3 w-3" />}
            Preview excerpt
          </Button>
        </div>

        <div className="text-xs text-muted-foreground space-y-1">
          <p>
            Applies the same excerpt to all {videos.length} video{videos.length === 1 ? "" : "s"} of
            the project.
          </p>
          {startAfterEnd && <p className="text-red-500">The start must be before the end.</p>}
          {excerptTooShort && (
            <p className="text-red-500">The excerpt must be at least {MIN_EXCERPT_SECONDS} s long.</p>
          )}
          {tooShort.length > 0 && (
            <p className="text-red-500">
              The end is beyond the end of: {tooShort.map((v) => v.name).join(", ")}
            </p>
          )}
          {otherTools && (
            <p className="text-red-500">
              Trimming cannot be combined with other tools. Remove them first.
            </p>
          )}
        </div>
      </div>
    </ToolbarButton>
  );
}
