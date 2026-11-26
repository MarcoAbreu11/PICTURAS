import {
  Dialog,
  DialogContent,
  DialogFooter,
  DialogHeader,
  DialogTitle,
  DialogTrigger,
} from "@/components/ui/dialog";
import { Button } from "@/components/ui/button";
import { Label } from "../ui/label";
import { Input } from "../ui/input";
import { useEffect, useState } from "react";
import { useToast } from "@/hooks/use-toast";
import { useAddProject } from "@/lib/mutations/projects";
import { useUploadLimits } from "@/lib/queries/projects";
import { uploadLimitProblem } from "@/lib/projects";
import ImageSubmissionArea from "../image-submission-area";
import { Progress } from "@/components/ui/progress";
import { useSession } from "@/providers/session-provider";
import { LoaderCircle } from "lucide-react";
import { useRouter } from "next/navigation";
import { getErrorMessage } from "@/lib/error-messages";

export default function NewProjectDialog({
  files = [],
  setFiles,
  children,
}: {
  files?: File[];
  setFiles?: (files: File[]) => void;
  children: React.ReactNode;
}) {
  const { toast } = useToast();
  const router = useRouter();

  const [open, setOpen] = useState<boolean>(false);
  const [name, setName] = useState<string>("");
  const [imageFiles, setImageFiles] = useState<File[]>([]);
  const [uploadPercent, setUploadPercent] = useState<number>(0);

  const session = useSession();
  const addProject = useAddProject(session.user._id, session.token);

  const uploadLimits = useUploadLimits(session.token);

  function handleCreate() {
    // checked before the project is created, so no empty project is left behind
    const problem = uploadLimitProblem(imageFiles, session.user.type, uploadLimits.data);
    if (problem) {
      toast({ ...problem, variant: "destructive" });
      return;
    }
    setUploadPercent(0);
    addProject.mutate(
      {
        uid: session.user._id,
        token: session.token,
        name: name,
        images: imageFiles,
        onProgress: (fraction) => setUploadPercent(Math.round(fraction * 100)),
      },
      {
        onSuccess: (project) => {
          setOpen(false);
          toast({
              title: "Projeto criado com sucesso",
              description: "As imagens foram adicionadas ao novo projeto.",
          });
          if (project) router.push(`/dashboard/${project._id}`);
        },
        onError: (error) => {
          const { title, description } = getErrorMessage("project-create", error);
          toast({
            title,
            description,
            variant: "destructive",
          });
        },
      },
    );
  }

  useEffect(() => {
    if (files.length > 0) {
      setOpen(true);
    }
  }, [files]);

  useEffect(() => {
    setName("");
    setImageFiles([]);
    if (setFiles && open === false) setFiles([]);
  }, [open, setFiles]);

  return (
    <Dialog open={open} onOpenChange={setOpen}>
      <DialogTrigger asChild>{children}</DialogTrigger>
      <DialogContent>
        <DialogHeader>
          <DialogTitle>Create New Project</DialogTitle>
        </DialogHeader>
        <Label htmlFor="project-name">Project Name</Label>
        <Input
          id="project-name"
          placeholder="Enter project name"
          value={name}
          onChange={(e) => setName(e.target.value)}
        />
        <ImageSubmissionArea
          onFilesChange={setImageFiles}
          receivedFiles={files}
        />
        {addProject.isPending && (
          <div className="flex items-center gap-2" aria-live="polite">
            <Progress value={uploadPercent} aria-label="Upload progress" />
            <span className="w-12 text-right text-sm tabular-nums text-muted-foreground">
              {uploadPercent}%
            </span>
          </div>
        )}
        <DialogFooter>
          <Button
            onClick={() => handleCreate()}
            disabled={imageFiles.length <= 0 || name === "" || addProject.isPending}
            className="inline-flex items-center gap-1"
          >
            <span>Create</span>
            {addProject.isPending && (
              <LoaderCircle className="size-[1em] animate-spin" />
            )}
          </Button>
        </DialogFooter>
      </DialogContent>
    </Dialog>
  );
}
