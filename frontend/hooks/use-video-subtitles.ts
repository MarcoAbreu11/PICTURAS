"use client";
import { useEffect, useMemo } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSearchParams } from "next/navigation";
import { useSession } from "@/providers/session-provider";
import { useProjectInfo } from "@/providers/project-provider";
import { useUpdateSession } from "@/lib/mutations/session";
import { fetchSubtitles, generateSubtitles, SubtitleAccess, SubtitleLanguage, subtitleLabel } from "@/lib/subtitles";

type Selection = { active: SubtitleLanguage | "off"; pending?: string; requested?: SubtitleLanguage };
type GenerationRequest = {
  access: SubtitleAccess; language: SubtitleLanguage; key: readonly unknown[];
  selectionKey: readonly unknown[]; active: Selection["active"];
};
export function useVideoSubtitles(video: string, enabled = true) {
  const session = useSession();
  const project = useProjectInfo();
  const params = useSearchParams();
  const client = useQueryClient();
  const updateSession = useUpdateSession();
  const access = {
    user: session.user._id, project: project._id, video, token: session.token,
    owner: params.get("owner") || session.user._id, share: params.get("share") || undefined,
  };
  const eligible = session.user.type === "free" || session.user.type === "premium";
  const key = ["video-subtitles", access.user, access.project, video, access.owner, access.share, access.token];
  const selectionKey = useMemo(() => [
    "video-subtitles", access.user, access.project, video, access.owner, access.share, access.token, "selection",
  ], [access.user, access.project, video, access.owner, access.share, access.token]);
  const selection = useQuery<Selection>({
    queryKey: selectionKey, queryFn: () => ({ active: "off" }), enabled: false,
    initialData: { active: "off" },
  }).data!;
  const query = useQuery({
    queryKey: key, queryFn: () => fetchSubtitles(access), enabled: enabled && eligible && !!video,
    // Refresh signed URLs before expiry; poll an active job until persisted.
    refetchInterval: (q) => q.state.data?.job || q.state.data?.error?.refundPending ? 2000 : 30 * 60 * 1000,
    retry: false,
  });
  const mutation = useMutation({
    mutationFn: (request: GenerationRequest) => generateSubtitles(request.access, request.language),
    onSuccess: (state, request) => {
      // A response still belongs to its original video if the carousel moved.
      client.setQueryData(request.key, state);
      client.setQueryData<Selection>(request.selectionKey, state.tracks[request.language]
        ? { active: state.detectedLanguage === "en" ? "original" : request.language }
        : { active: request.active, pending: state.job?.id, requested: request.language });
      window.dispatchEvent(new Event("session-updated"));
    },
    onError: (_error, request) => { client.invalidateQueries({ queryKey: request.key, exact: true }); },
  });
  useEffect(() => {
    if (!selection.pending || query.data?.job) return;
    if (selection.requested && query.data?.tracks[selection.requested]) {
      client.setQueryData<Selection>(selectionKey, {
        active: query.data.detectedLanguage === "en" ? "original" : selection.requested,
      });
    } else if (query.data?.error) {
      client.setQueryData<Selection>(selectionKey, { active: selection.active });
    }
  }, [selection.pending, selection.requested, selection.active, query.data, client, selectionKey]);
  useEffect(() => {
    const failure = query.data?.error;
    if (!enabled || !eligible || !failure?.refunded || !failure.jobId) return;
    // Toolbar and player share this marker: one refresh even with two observers,
    // repeated polls, track changes or a component remount.
    const noticeKey = [...selectionKey, "refunded"];
    if (client.getQueryData(noticeKey) === failure.jobId) return;
    client.setQueryData(noticeKey, failure.jobId);
    updateSession.mutate({ userId: session.user._id, token: session.token });
  }, [query.data?.error, enabled, eligible, client, selectionKey, updateSession, session.user._id, session.token]);

  function select(language: SubtitleLanguage | "off") {
    if (language === "off" || query.data?.tracks[language]) {
      client.setQueryData<Selection>(selectionKey, { active: language });
    } else {
      mutation.mutate({ language, access, key, selectionKey, active: selection.active });
    }
  }
  const track = enabled && eligible && selection.active !== "off"
    ? query.data?.tracks[selection.active] : undefined;
  const currentRequest = mutation.variables?.access.video === video &&
    mutation.variables?.access.project === project._id;
  return {
    ...query, eligible, select, selection: selection.active,
    generating: (currentRequest && mutation.isPending) || !!query.data?.job,
    requestError: currentRequest ? mutation.error : null,
    track: track ? {
      ...track, label: selection.active === "original" || query.data?.detectedLanguage === "en"
        ? subtitleLabel(query.data?.detectedLanguage) : "English",
    } : undefined,
  };
}
