"use client";

import { CircleAlert, Info, TriangleAlert } from "lucide-react";
import { isVideo } from "@/lib/projects";
import { useProjectInfo } from "@/providers/project-provider";

// Problems of the pipeline for the project's media, shown while it is being
// built, before any preview or processing. The rules and the texts come from
// the projects service (pipelineIssues / unavailableTools).
export function PipelineNotices() {
  const project = useProjectInfo();
  const issues = project.pipelineIssues ?? [];
  const hasVideos = project.imgs.some((i) => isVideo(i));
  // Only the tools hidden because of the videos need an explanation; video
  // tools in a project without videos are simply not relevant.
  const hidden = hasVideos ? (project.unavailableTools ?? []) : [];

  if (issues.length === 0 && hidden.length === 0) return null;

  return (
    <div className="flex flex-col gap-1 border-b border-sidebar-border px-4 py-2 text-sm">
      {issues.map((issue) => {
        const isError = issue.severity === "error";
        const Icon = isError ? CircleAlert : TriangleAlert;
        return (
          <div
            key={`${issue.toolId ?? issue.procedure}-${issue.code}`}
            role="alert"
            className={`flex items-start gap-2 ${
              isError ? "text-red-700 dark:text-red-400" : "text-amber-700 dark:text-amber-400"
            }`}
          >
            <Icon className="mt-0.5 size-4 shrink-0" aria-hidden />
            <span>
              <span className="font-medium">{issue.message}</span> {issue.fix}
            </span>
          </div>
        );
      })}
      {hidden.length > 0 && (
        <p role="note" className="flex items-start gap-2 text-xs text-muted-foreground">
          <Info className="mt-0.5 size-3.5 shrink-0" aria-hidden />
          <span>
            Not offered in this project: {hidden.map((t) => t.label).join(", ")}. {hidden[0].reason}{" "}
            {hidden[0].fix}
          </span>
        </p>
      )}
    </div>
  );
}
