// Real Chromium textTracks + the production hook, toolbar and MediaView.
// Run: npm install --no-save playwright; npx playwright install chromium
//      node test/subtitles-player.cjs
const assert = require("node:assert/strict");
const fs = require("node:fs/promises");
const path = require("node:path");
const os = require("node:os");
const http = require("node:http");
const { chromium } = require("playwright");
const frontend = path.resolve(__dirname, "..");
const webpackModule = require("next/dist/compiled/webpack/webpack");
webpackModule.init();

async function main() {
  const temporary = await fs.mkdtemp(path.join(os.tmpdir(), "e4-player-"));
  let browser, server;
  try {
    await fs.writeFile(path.join(temporary, "loader.cjs"), `
      const ts = require(${JSON.stringify(require.resolve("typescript"))});
      module.exports = function(source) {
        return ts.transpileModule(source, { compilerOptions: {
          jsx: ts.JsxEmit.ReactJSX, module: ts.ModuleKind.ESNext, target: ts.ScriptTarget.ES2020
        }}).outputText;
      };
    `);
    await fs.writeFile(path.join(temporary, "context.tsx"), `
      import {useQuery} from "@tanstack/react-query";
      export function useSession() { return { user: {_id: "owner", type: "free"}, token: "test" }; }
      export function useProjectInfo() { return useQuery({queryKey:["project","owner","project","test","owner",undefined], queryFn:()=>structuredClone(window.e4.project), initialData:{_id:"project",version:1,tools:[],imgs:[{_id:"video",media_type:"video"}]}}).data; }
      export function useCurrentImage() { return {_id:"video"}; }
      export function useCanEditProject() { return true; }
      export function useUnsavedChanges() { return {setHasUnsavedChanges: value => {window.e4.dirty=value;}}; }
      export function usePreview() { return {waiting:"",setWaiting:()=>{}}; }
      export function useSearchParams() { return new URLSearchParams(); }
      export function useRouter() { return {push:()=>{}}; }
      export function useGetSocket() { return {data:null}; }
      export function useUpdateSession() { return {mutate:()=>{}}; }
      export default function Image() { return null; }
    `);
    await fs.writeFile(path.join(temporary, "entry.tsx"), `
      import React, { useState } from "react";
      import { createRoot } from "react-dom/client";
      import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
      import MediaView from "@/components/media-view";
      import Controls from "@/components/toolbar/video-subtitles-tool";
      import { useVideoSubtitles } from "@/hooks/use-video-subtitles";
      import { api } from "@/lib/axios";
      import {useProcessProject} from "@/lib/mutations/projects";
      import {useProjectInfo} from "@/providers/project-provider";
      import {TooltipProvider} from "@/components/ui/tooltip";
      let state = { tracks: {}, job: null, error: null };
      let posts = 0, last = "original", delayed, release, sessionUpdates = 0;
      const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
      let project = {_id:"project",version:1,tools:[],imgs:[{_id:"video",media_type:"video"}]};
      let applies=0;
      api.defaults.adapter = async config => {
        let data=state, status=200;
        if(config.method === "post" && config.url.includes("/tool")) {
          const body=JSON.parse(config.data); const tool=body.tool || body;
          project.tools=[{...tool,_id:"tool",position:0}]; project.version++; data=project;
          window.e4.project=project;status=201;
        } else if(config.method === "put" && config.url.includes("/tool")) {
          const body=JSON.parse(config.data); project.tools[0].params=body.params || body; data=project;
        } else if(config.method === "post" && config.url.includes("/process")) {
          applies++; last=project.tools[0].params.language;
          if(!state.tracks[last]) {posts++; state={...state,job:{id:"job-"+posts,language:last}};}
          data={};status=201;
          await client.invalidateQueries({queryKey:["video-subtitles"]});
        } else if(!config.url.includes("/subtitles")) data=project;
        return {data:structuredClone(data),status,statusText:"OK",headers:{"x-project-version":String(project.version)},config};
      };
      window.e4 = {
        project,
        posts: () => posts,
        applies: () => applies,
        sessionUpdates: () => sessionUpdates,
        refreshSession: input => {
          if (input.userId !== "owner" || input.token !== "test") throw new Error("Wrong refund session");
          sessionUpdates++;
        },
        refresh: () => client.invalidateQueries({queryKey:["video-subtitles"]}),
        fail: async (refunded = false) => {
          state = { ...state, job: null, error: {
            code: 2304, message: "Sem fala", jobId: "job-" + posts,
            refundPending: !refunded, refunded,
          }};
          await client.invalidateQueries({queryKey:["video-subtitles"]});
        },
        prepareDelayed: async () => {
          state = {tracks:{}, job:null, error:null};
          await client.invalidateQueries({queryKey:["video-subtitles"]});
          delayed = new Promise(resolve => { release = resolve; });
        },
        release: () => { release(); delayed = null; },
        other: () => client.getQueriesData({queryKey:["video-subtitles"]})
          .find(([key]) => key[3] === "other" && key.at(-1) !== "selection")?.[1],
        finish: async () => {
          state = {...state, detectedLanguage: "pt", job: null,
            tracks: {...state.tracks, [last]: {key: last, language: last === "en" ? "en" : "pt", url: "/" + last + ".vtt"}}};
          await client.invalidateQueries({queryKey:["video-subtitles"]});
        },
        reopen: () => {
          root.unmount();
          client.clear();
          root = createRoot(document.getElementById("root"));
          render();
        }
      };
      function App() {
        const info=useProjectInfo();
        const run=useProcessProject("owner","project","test","owner");
        const subtitles=useVideoSubtitles("video");
        return <TooltipProvider><div style={{width:32}}><Controls disabled={false}/></div><button onClick={()=>run.mutate({projectVersion:info.version,tools:info.tools})}>Apply</button>
          <MediaView url="/fixture.webm" name="fixture.webm" mediaType="video" subtitle={subtitles.track}/></TooltipProvider>;
      }
      let root = createRoot(document.getElementById("root"));
      function render() { root.render(<QueryClientProvider client={client}><App/></QueryClientProvider>); }
      render();
    `);
    await new Promise((resolve, reject) => webpackModule.webpack({
      mode: "development", entry: path.join(temporary, "entry.tsx"), devtool: false,
      output: { path: temporary, filename: "bundle.js" },
      plugins: [new webpackModule.webpack.DefinePlugin({ "process.env": JSON.stringify({ NODE_ENV: "development" }) })],
      resolve: {
        extensions: [".tsx", ".ts", ".js"],
        modules: [path.join(frontend, "node_modules"), "node_modules"],
        alias: {
          "@/providers/session-provider": path.join(temporary, "context.tsx"),
          "@/providers/project-provider": path.join(temporary, "context.tsx"),
          "@/lib/mutations/session": path.join(temporary, "context.tsx"),
          "next/navigation": path.join(temporary, "context.tsx"),
          "@/lib/queries/projects": path.join(temporary, "context.tsx"),
          "next/image": path.join(temporary, "context.tsx"),
          "@": frontend,
        },
      },
      module: { rules: [{ test: /\.tsx?$/, use: path.join(temporary, "loader.cjs") }] },
    }, (error, stats) => {
      if (error || stats.hasErrors()) reject(error || new Error(stats.toString({ all: false, errors: true })));
      else resolve();
    }));
    const css = (await require("postcss")([require("tailwindcss")({content:[path.join(frontend,"components/**/*.tsx")],theme:{extend:{}},plugins:[]})]).process("@tailwind base;@tailwind components;@tailwind utilities;", {from:undefined})).css;
    server = http.createServer(async (req, res) => {
      try {
        if (req.url === "/bundle.js") { res.setHeader("Content-Type", "text/javascript"); res.end(await fs.readFile(path.join(temporary, "bundle.js"))); }
        else if (req.url === "/fixture.webm") { res.setHeader("Content-Type", "video/webm"); res.end(await fs.readFile(path.join(__dirname, "fixtures", "subtitles.webm"))); }
        else if (req.url.endsWith(".vtt")) { res.setHeader("Content-Type", "text/vtt"); res.end("WEBVTT\n\n00:00:00.000 --> 00:00:02.000\n" + (req.url.includes("en") ? "Hello" : "Olá") + "\n\n"); }
        else res.end('<style>'+css+'</style><style>svg{width:24px;height:24px}video{width:320px}.sr-only{position:absolute;width:1px;height:1px;overflow:hidden;clip:rect(0,0,0,0)}[role=menu]{background:white;width:320px}</style><div id="root"></div><script src="/bundle.js"></script>');
      } catch (error) { res.statusCode = 500; res.end(error.message); }
    }).listen(0, "127.0.0.1");
    await new Promise((resolve) => server.once("listening", resolve));
    browser = await chromium.launch({ headless: true, ...(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {}) });
    const page = await browser.newPage();
    const errors = [];
    page.on("pageerror", (error) => { errors.push(error.message); console.error(error.message); });
    await page.goto(`http://127.0.0.1:${server.address().port}`);
    await page.getByRole("button", {name:"Automatic subtitles",exact:true}).click();
    assert.equal(await page.getByRole("button",{name:"Original",exact:true}).count(),1);
    await page.getByRole("button",{name:"English",exact:true}).click();
    assert.equal(await page.evaluate(()=>window.e4.posts()),0,"configuration must not generate");
    await page.getByRole("button",{name:"Save",exact:true}).click();
    await page.waitForFunction(()=>window.e4.project.tools.length===1);
    assert.equal(await page.evaluate(()=>window.e4.posts()),0,"Save must not generate");
    await page.getByRole("button",{name:"Apply",exact:true}).click();
    await page.waitForFunction(()=>window.e4.posts()===1);
    await page.evaluate(()=>window.e4.finish());
    await page.getByRole("button",{name:"Automatic subtitles",exact:true}).click();
    await page.getByRole("button",{name:"Original (Português)",exact:true}).waitFor();
    const select=page.getByLabel("Show subtitles");
    assert.equal(await select.locator('option[value="original"]').count(),0,"Original label must exist before its track");
    await select.selectOption("en");
    await page.waitForFunction(()=>document.querySelector("video").textTracks[0]?.mode==="showing" && document.querySelector("video").textTracks[0]?.cues?.length===1);
    await select.selectOption("off");
    await page.waitForFunction(()=>document.querySelector("video").textTracks.length===0);
    await select.selectOption("en");
    assert.equal(await page.evaluate(()=>window.e4.posts()),1,"existing track selection must not generate");
    assert.deepEqual(errors, []);
    console.log("PASS Chromium: production toolbar Save and process mutation Apply, English first label before Original track, WebVTT cues, off and reuse. API simulated; dashboard socket orchestration is outside this harness.");
  } finally {
    if (browser) await browser.close();
    if (server) await new Promise((resolve) => server.close(resolve));
    await fs.rm(temporary, { recursive: true, force: true });
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
