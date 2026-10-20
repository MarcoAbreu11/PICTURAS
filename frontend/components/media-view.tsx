import Image from "next/image";
import { cn, isVideo } from "@/lib/utils";
import { useCallback, useEffect, useRef } from "react";

interface MediaViewProps {
  url: string;
  name: string;
  // se não vier do backend, deduz-se pela extensão do nome
  mediaType?: "image" | "video";
  className?: string;
  priority?: boolean;
  // false nas grelhas: o vídeo fica parado no 1.º frame e o clique abre o item
  controls?: boolean;
  onLoaded?: () => void;
  subtitle?: { key: string; url: string; language: string; label: string };
}

// Mostra uma imagem ou um vídeo consoante o tipo do ficheiro
export default function MediaView({
  url,
  name,
  mediaType,
  className,
  priority,
  controls = true,
  onLoaded,
  subtitle,
}: MediaViewProps) {
  const video = mediaType ? mediaType === "video" : isVideo(name);
  const videoRef = useRef<HTMLVideoElement>(null);
  const activeKey = subtitle?.key;
  const activateSubtitle = useCallback(() => {
    const tracks = videoRef.current?.textTracks;
    if (tracks) for (let i = 0; i < tracks.length; i++)
      tracks[i].mode = activeKey && i === 0 ? "showing" : "disabled";
  }, [activeKey]);
  useEffect(activateSubtitle, [activateSubtitle, subtitle?.url]);

  if (video) {
    return (
      <video
        ref={videoRef}
        // #t=0.1 faz o browser mostrar o 1.º frame em vez de um ecrã preto
        src={controls ? url : `${url}#t=0.1`}
        controls={controls}
        muted={!controls}
        preload="metadata"
        playsInline
        className={cn("bg-black", !controls && "pointer-events-none", className)}
        onLoadedData={onLoaded}
      >
        {subtitle && controls && (
          <track key={`${subtitle.key}:${subtitle.url}`} kind="subtitles"
            src={subtitle.url} srcLang={subtitle.language} label={subtitle.label}
            default onLoad={activateSubtitle} />
        )}
      </video>
    );
  }

  return (
    <Image
      src={url}
      unoptimized
      height={500}
      width={500}
      alt={name}
      className={className}
      priority={priority}
      onLoad={onLoaded}
    />
  );
}
