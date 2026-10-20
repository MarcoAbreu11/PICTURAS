"use client";
import { useEffect } from "react";
import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { useSearchParams } from "next/navigation";
import { useSession } from "@/providers/session-provider";
import { useProjectInfo } from "@/providers/project-provider";
import { fetchSubtitles, generateSubtitles, SubtitleLanguage, subtitleLabel } from "@/lib/subtitles";

type Selection = { active: SubtitleLanguage | "off"; pending?: string; requested?: SubtitleLanguage };
export function useVideoSubtitles(video: string, enabled = true) {
  const session = useSession();
  const project = useProjectInfo();
  const params = useSearchParams();
  const client = useQueryClient();
  const access = {
    user: session.user._id, project: project._id, video, token: session.token,
    owner: params.get("owner") || session.user._id, share: params.get("share") || undefined,
  };
  const eligible = session.user.type === "free" || session.user.type === "premium";
  const key = ["video-subtitles", access.user, access.project, video, access.owner, access.share, access.token];
  const selectionKey = [...key, "selection"];
  const selection = useQuery<Selection>({
    queryKey: selectionKey, queryFn: () => ({ active: "off" }), enabled: false,
    initialData: { active: "off" },
  }).data!;
  const query = useQuery({
    queryKey: key, queryFn: () => fetchSubtitles(access), enabled: enabled && eligible && !!video,
    // Refresh signed URLs before expiry; poll an active job until persisted.
    refetchInterval: (q) => q.state.data?.job ? 2000 : 30 * 60 * 1000,
    retry: false,
  });
  const mutation = useMutation({
    mutationFn: (language: SubtitleLanguage) => generateSubtitles(access, language),
    onSuccess: (state, language) => {
      client.setQueryData(key, state);
      client.setQueryData<Selection>(selectionKey, state.tracks[language]
        ? { active: language }
        : { active: selection.active, pending: state.job?.id, requested: language });
      window.dispatchEvent(new Event("session-updated"));
    },
    onError: () => { query.refetch(); },
  });
  useEffect(() => {
    if (!selection.pending || query.data?.job) return;
    if (selection.requested && query.data?.tracks[selection.requested]) {
      client.setQueryData<Selection>(selectionKey, { active: selection.requested });
    } else if (query.data?.error) {
      client.setQueryData<Selection>(selectionKey, { active: selection.active });
    }
  }, [selection.pending, selection.requested, selection.active, query.data, client, JSON.stringify(selectionKey)]);

  function select(language: SubtitleLanguage | "off") {
    if (language === "off" || query.data?.tracks[language]) {
      client.setQueryData<Selection>(selectionKey, { active: language });
    } else {
      mutation.mutate(language);
    }
  }
  const track = enabled && eligible && selection.active !== "off"
    ? query.data?.tracks[selection.active] : undefined;
  return {
    ...query, eligible, select, selection: selection.active,
    generating: mutation.isPending || !!query.data?.job,
    requestError: mutation.error,
    track: track ? {
      ...track, label: selection.active === "original" || query.data?.detectedLanguage === "en"
        ? subtitleLabel(query.data?.detectedLanguage) : "English",
    } : undefined,
  };
}
