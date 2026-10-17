import Image from "next/image";
import { cn, isVideo } from "@/lib/utils";

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
}: MediaViewProps) {
  const video = mediaType ? mediaType === "video" : isVideo(name);

  if (video) {
    return (
      <video
        // #t=0.1 faz o browser mostrar o 1.º frame em vez de um ecrã preto
        src={controls ? url : `${url}#t=0.1`}
        controls={controls}
        muted={!controls}
        preload="metadata"
        playsInline
        className={cn("bg-black", !controls && "pointer-events-none", className)}
        onLoadedData={onLoaded}
      />
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
