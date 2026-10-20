import { api } from "./axios";

export type SubtitleLanguage = "original" | "en";
export interface SubtitleTrack { key: string; language: string; url: string }
export interface SubtitleState {
  detectedLanguage?: string;
  tracks: Partial<Record<SubtitleLanguage, SubtitleTrack>>;
  job: { id: string; language: SubtitleLanguage } | null;
  error: { code: number; message: string; jobId?: string; refundPending?: boolean; refunded?: boolean } | null;
}
export interface SubtitleAccess {
  user: string; project: string; video: string; token: string; owner: string; share?: string;
}
export function subtitleLabel(language?: string) {
  if (!language) return "Original";
  let name = language;
  try { name = new Intl.DisplayNames(["pt"], { type: "language" }).of(language) || language; } catch {}
  return `Original (${name.charAt(0).toUpperCase()}${name.slice(1)})`;
}
function config(access: SubtitleAccess) {
  return {
    headers: { Authorization: `Bearer ${access.token}` },
    params: access.share ? { owner: access.owner, share: access.share } : undefined,
  };
}
function url(access: SubtitleAccess) {
  return `/projects/${access.user}/${access.project}/img/${access.video}/subtitles`;
}
export async function fetchSubtitles(access: SubtitleAccess): Promise<SubtitleState> {
  return (await api.get(url(access), config(access))).data;
}
export async function generateSubtitles(access: SubtitleAccess, language: SubtitleLanguage): Promise<SubtitleState> {
  return (await api.post(url(access), { language }, config(access))).data;
}
