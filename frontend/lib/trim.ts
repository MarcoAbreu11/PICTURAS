// Espelho de projects/utils/trim.js (o backend valida sempre)
export const MIN_EXCERPT_SECONDS = 1;

// 90.5 -> "00:01:30.5"
export function formatTime(seconds: number) {
  const s = Math.max(0, seconds);
  const h = Math.floor(s / 3600);
  const m = Math.floor((s % 3600) / 60);
  const rest = Math.round((s % 60) * 10) / 10;
  const pad = (n: number) => String(n).padStart(2, "0");
  const sec = Number.isInteger(rest) ? pad(rest) : rest.toFixed(1).padStart(4, "0");
  return `${pad(h)}:${pad(m)}:${sec}`;
}

// "00:01:30", "1:30", "90" ou "90.5" -> segundos; null se inválido
export function parseTime(text: string): number | null {
  const parts = text.trim().split(":");
  if (parts.length === 0 || parts.length > 3 || parts.some((p) => p === "")) return null;

  const nums = parts.map(Number);
  if (nums.some((n) => !Number.isFinite(n) || n < 0)) return null;

  return nums.reduce((acc, n) => acc * 60 + n, 0);
}
