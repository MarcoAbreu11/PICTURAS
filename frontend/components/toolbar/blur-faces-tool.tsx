import { ToolbarButton } from "./toolbar-button";
import { ScanFace } from "lucide-react";
import { useEffect, useState } from "react";
import { Label } from "../ui/label";
import { Button } from "../ui/button";
import { Slider } from "../ui/slider";
import { useProjectInfo, useUnsavedChanges } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { BlurFacesToolParams } from "@/lib/tool-types";
import {
  DEFAULT_BLUR_PARAMS,
  MAX_PADDING,
  MAX_STRENGTH,
  MIN_PADDING,
  MIN_STRENGTH,
  blurParamsError,
} from "@/lib/blur-faces";

// UC-VID-004: tool de vídeo que desfoca (ou pixeliza) as caras detetadas
export default function BlurFacesTool({ disabled }: { disabled: boolean }) {
  const project = useProjectInfo();
  const session = useSession();
  const { setHasUnsavedChanges } = useUnsavedChanges();

  const [params, setParams] = useState<BlurFacesToolParams>(DEFAULT_BLUR_PARAMS);
  const [open, setOpen] = useState<boolean>(false);

  useEffect(() => {
    const tool = project.tools.find((t) => t.procedure === "blur_faces");
    setParams(
      tool ? { ...DEFAULT_BLUR_PARAMS, ...(tool.params as BlurFacesToolParams) } : DEFAULT_BLUR_PARAMS,
    );
  }, [project.tools, open]);

  function update(changes: Partial<BlurFacesToolParams>) {
    setParams((p) => ({ ...p, ...changes }));
    setHasUnsavedChanges(true);
  }

  const videos = project.imgs.filter((i) => i.media_type === "video");
  const otherTools = project.tools.some((t) => t.procedure !== "blur_faces");
  const paramsError = blurParamsError(params);

  return (
    <ToolbarButton
      open={open}
      setOpen={setOpen}
      tool={{ procedure: "blur_faces", params }}
      onDefault={() => {
        setParams(DEFAULT_BLUR_PARAMS);
        setHasUnsavedChanges(false);
      }}
      isDefault={false}
      invalid={paramsError !== null || otherTools}
      isPremium
      disabled={disabled}
      icon={ScanFace}
      label="Blur faces"
    >
      <div className="space-y-3 text-sm">
        {/* FA1: desfocagem ou pixelização */}
        <div className="flex gap-1">
          <Button
            variant={params.mode === "blur" ? "default" : "outline"}
            className="h-7 text-xs flex-1"
            onClick={() => update({ mode: "blur" })}
          >
            Blur
          </Button>
          <Button
            variant={params.mode === "pixelate" ? "default" : "outline"}
            className="h-7 text-xs flex-1"
            onClick={() => update({ mode: "pixelate" })}
          >
            Pixelate
          </Button>
        </div>

        <div className="space-y-1">
          <div className="flex justify-between text-gray-500">
            <Label>Intensity</Label>
            <span className="font-semibold">{params.strength}</span>
          </div>
          <Slider
            min={MIN_STRENGTH}
            max={MAX_STRENGTH}
            step={1}
            value={[params.strength]}
            onValueChange={(v) => update({ strength: v[0] })}
          />
        </div>

        <div className="space-y-1">
          <div className="flex justify-between text-gray-500">
            <Label>Margin around the face</Label>
            <span className="font-semibold">{params.padding} %</span>
          </div>
          <Slider
            min={MIN_PADDING}
            max={MAX_PADDING}
            step={5}
            value={[params.padding]}
            onValueChange={(v) => update({ padding: v[0] })}
          />
        </div>

        <div className="text-xs text-muted-foreground space-y-1 pt-1">
          <p>Preview shows one frame of this video with the faces anonymized.</p>
          <p>
            Applies to all {videos.length} video{videos.length === 1 ? "" : "s"} of the project
            {session.user.type === "premium"
              ? "."
              : ` · uses ${videos.length} daily operation${videos.length === 1 ? "" : "s"}.`}
          </p>
          {paramsError && <p className="text-red-500">{paramsError}</p>}
          {otherTools && (
            <p className="text-red-500">
              Face blurring cannot be combined with other tools. Remove them first.
            </p>
          )}
        </div>
      </div>
    </ToolbarButton>
  );
}
