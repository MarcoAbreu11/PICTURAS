import { cn, isVideo } from "@/lib/utils";
import MediaView from "@/components/media-view";
import { Card } from "@/components/ui/card";
import { Download, Trash } from "lucide-react";
import { useState } from "react";
import { Button } from "@/components/ui/button";
import {
  Dialog,
  DialogTrigger,
  DialogContent,
  DialogHeader,
  DialogTitle,
  DialogDescription,
} from "@/components/ui/dialog";
import {
  ContextMenu,
  ContextMenuContent,
  ContextMenuItem,
  ContextMenuTrigger,
} from "@/components/ui/context-menu";
import { Skeleton } from "@/components/ui/skeleton";
import {
  useDeleteProjectImages,
  useDeleteProjectResult,
  useDownloadProjectImage,
} from "@/lib/mutations/projects";
import { useCanEditProject, useProjectInfo } from "@/providers/project-provider";
import { useSession } from "@/providers/session-provider";
import { useToast } from "@/hooks/use-toast";
import type { ProjectImage } from "@/lib/projects";
import { useSearchParams } from "next/navigation";
import { getErrorMessage } from "@/lib/error-messages";

interface ImageItemProps {
  image: ProjectImage;
  animation?: boolean;
}

function formatBytes(bytes: number) {
  if (bytes < 1024 * 1024) return `${(bytes / 1024).toFixed(0)} KB`;
  return `${(bytes / (1024 * 1024)).toFixed(1)} MB`;
}

export function ProjectImage({ image, animation = true }: ImageItemProps) {
  const searchParams = useSearchParams();
  const mode = searchParams.get("mode") ?? "edit";

  const [loaded, setLoaded] = useState<boolean>(false);
  const [open, setOpen] = useState<boolean>(false);

  const { _id: pid, version } = useProjectInfo();
  const session = useSession();
  const ownerId = searchParams.get("owner") ?? session.user._id;
  const shareId = searchParams.get("share") ?? undefined;

  const projectInfo = useProjectInfo(); // para ter version também
  const deleteImage = useDeleteProjectImages(
    session.user._id,
    pid as string,
    session.token,
    ownerId,
    shareId,
  );
  const downloadImage = useDownloadProjectImage(mode === "results");
  const deleteResult = useDeleteProjectResult(
    session.user._id,
    pid as string,
    session.token,
    ownerId,
    shareId,
  );
  const canEdit = useCanEditProject();
  // UC-VID-004, FA4: resultado de blur_faces sem caras detetadas
  const noFaces = mode === "results" && image.faces_detected === 0;
  const [keptNoFaces, setKeptNoFaces] = useState<boolean>(false);
  const { toast } = useToast();
  const video = image.media_type
    ? image.media_type === "video"
    : isVideo(image.name);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <ContextMenu>
        <ContextMenuTrigger>
          <Card className="group relative overflow-hidden size-full">
            {/* Image or video */}
            <div className="size-full relative grid z-0 grid-cols-1 grid-rows-1">
              <MediaView
                url={image.url}
                name={image.name}
                mediaType={video ? "video" : "image"}
                // na grelha (animation) o vídeo fica parado; no carrossel tem controlos
                controls={!animation}
                className={cn(
                  "size-full object-contain row-start-1 col-start-1 z-30",
                  animation && "transition-all group-hover:scale-105",
                )}
                priority
                onLoaded={() => setLoaded(true)}
              />
              {/* fundo desfocado só para imagens: num vídeo seria um 2.º download */}
              {!video && (
                <>
                  <MediaView
                    url={image.url}
                    name={image.name + " blurred"}
                    mediaType="image"
                    className="object-cover row-start-1 col-start-1 size-full z-10"
                  />
                  <div className="row-start-1 col-start-1 backdrop-blur-sm size-full bg-black/30 z-20" />
                </>
              )}
              {video && animation && (
                <span className="row-start-1 col-start-1 z-40 m-2 h-fit w-fit rounded bg-black/70 px-1.5 py-0.5 text-xs text-white">
                  {noFaces ? "Video · no faces detected" : "Video"}
                </span>
              )}
              {mode === "results" && video && image.original_size_bytes != null && image.output_size_bytes != null && (
                <span className="absolute bottom-2 left-2 z-40 rounded bg-black/75 px-2 py-1 text-[11px] text-white">
                  {formatBytes(image.original_size_bytes)} → {formatBytes(image.output_size_bytes)}
                </span>
              )}
              {/* no carrossel: manter ou descartar o resultado sem caras (BLUR-013, BLUR-014) */}
              {noFaces && !animation && !keptNoFaces && (
                <div className="row-start-1 col-start-1 z-40 m-2 h-fit self-start justify-self-center flex items-center gap-2 rounded-md bg-background/90 px-3 py-2 text-sm shadow">
                  <span>No faces were detected in this video.</span>
                  <Button
                    variant="outline"
                    className="h-7 text-xs"
                    onClick={(e) => {
                      e.stopPropagation();
                      setKeptNoFaces(true);
                    }}
                  >
                    Keep
                  </Button>
                  {canEdit && (
                    <Button
                      variant="destructive"
                      className="h-7 text-xs"
                      disabled={deleteResult.isPending}
                      onClick={(e) => {
                        e.stopPropagation();
                        deleteResult.mutate(
                          { resultId: image._id },
                          {
                            onSuccess: () => toast({ title: `Result ${image.name} discarded.` }),
                            onError: (error) => {
                              const { title, description } = getErrorMessage("project-delete", error);
                              toast({ title, description, variant: "destructive" });
                            },
                          },
                        );
                      }}
                    >
                      Discard
                    </Button>
                  )}
                </div>
              )}
              {!loaded && (
                <>
                  <div className="row-start-1 col-start-1 z-40 bg-background size-full" />
                  <Skeleton className="size-full row-start-1 col-start-1 z-50" />
                </>
              )}
            </div>
          </Card>
        </ContextMenuTrigger>
        <ContextMenuContent>
          <DialogTrigger asChild onClick={(e) => e.stopPropagation()}>
            {mode !== "results" && (
              <ContextMenuItem
                className="flex justify-between"
                onClick={(e) => e.stopPropagation()}
              >
                <span>Delete</span>
                <Trash className="size-4" />
              </ContextMenuItem>
            )}
          </DialogTrigger>
          <ContextMenuItem
            className="flex justify-between"
            onClick={(e) => {
              e.stopPropagation();
              downloadImage.mutate(
                {
                  imageUrl: image.url,
                  imageName: image.name,
                },
                {
                  onSuccess: () => {
                    toast({
                      title: `Image ${image.name} downloaded.`,
                    });
                  },
                  onError: (error) => {
                    const { title, description } = getErrorMessage("project-download", error);
                    toast({
                      title,
                      description,
                      variant: "destructive",
                    });
                  },
                },
              );
            }}
          >
            <span>Download</span>
            <Download className="size-4" />
          </ContextMenuItem>
        </ContextMenuContent>
      </ContextMenu>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Are you sure?</DialogTitle>
          <DialogDescription>This action cannot be undone.</DialogDescription>
        </DialogHeader>
        <div className="flex justify-end">
          <Button
            variant="destructive"
            onClick={(e) => {
              deleteImage.mutate(
                {
                  imageIds: [image._id],
                  projectVersion: projectInfo.version,
                },
                {
                  onSuccess: () => {
                    toast({
                      title: `Image ${image.name} deleted successfully.`,
                    });
                  },
                  onError: (error) => {
                    const { title, description } = getErrorMessage("project-delete", error);
                    toast({
                      title,
                      description,
                      variant: "destructive",
                    });
                  },
                },
              );
              setOpen(false);
              e.stopPropagation();
            }}
          >
            Permanently Delete
          </Button>
        </div>
      </DialogContent>
    </Dialog>
  );
}
