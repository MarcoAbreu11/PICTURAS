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
      export function useSession() { return { user: {_id: "owner", type: "free"}, token: "test" }; }
      export function useProjectInfo() { return { _id: "project" }; }
      export function useCurrentImage() { return { _id: window.e4?.video || "video" }; }
      export function useCanEditProject() { return true; }
      export function useSearchParams() { return new URLSearchParams(); }
      export function useUpdateSession() { return { mutate: input => window.e4.refreshSession(input) }; }
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
      let state = { tracks: {}, job: null, error: null };
      let posts = 0, last = "original", delayed, release, sessionUpdates = 0;
      const client = new QueryClient({ defaultOptions: { queries: { retry: false } } });
      api.defaults.adapter = async config => {
        if (config.url.includes("/img/other/"))
          return {data: {tracks:{}, job:null, error:null}, status:200, statusText:"OK", headers:{}, config};
        if (config.method === "post") {
          posts++; last = JSON.parse(config.data).language;
          state = { ...state, job: {id: "job-" + posts, language: last} };
          if (delayed) await delayed;
        }
        return {data: structuredClone(state), status: 200, statusText: "OK", headers: {}, config};
      };
      window.e4 = {
        posts: () => posts,
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
        const [video, setVideo] = useState("video");
        window.e4.changeVideo = value => { window.e4.video = value; setVideo(value); };
        const subtitles = useVideoSubtitles(video);
        return <><Controls disabled={false}/><MediaView url="/fixture.webm" name="fixture.webm"
          mediaType="video" subtitle={subtitles.track}/></>;
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
          "next/image": path.join(temporary, "context.tsx"),
          "@": frontend,
        },
      },
      module: { rules: [{ test: /\.tsx?$/, use: path.join(temporary, "loader.cjs") }] },
    }, (error, stats) => {
      if (error || stats.hasErrors()) reject(error || new Error(stats.toString({ all: false, errors: true })));
      else resolve();
    }));
    server = http.createServer(async (req, res) => {
      try {
        if (req.url === "/bundle.js") { res.setHeader("Content-Type", "text/javascript"); res.end(await fs.readFile(path.join(temporary, "bundle.js"))); }
        else if (req.url === "/fixture.webm") { res.setHeader("Content-Type", "video/webm"); res.end(await fs.readFile(path.join(__dirname, "fixtures", "subtitles.webm"))); }
        else if (req.url.endsWith(".vtt")) { res.setHeader("Content-Type", "text/vtt"); res.end("WEBVTT\n\n00:00:00.000 --> 00:00:02.000\n" + (req.url.includes("en") ? "Hello" : "Olá") + "\n\n"); }
        else res.end('<div id="root"></div><script src="/bundle.js"></script>');
      } catch (error) { res.statusCode = 500; res.end(error.message); }
    }).listen(0, "127.0.0.1");
    await new Promise((resolve) => server.once("listening", resolve));
    browser = await chromium.launch({ headless: true, ...(process.env.CHROME_PATH ? { executablePath: process.env.CHROME_PATH } : {}) });
    const page = await browser.newPage();
    const errors = [];
    page.on("pageerror", (error) => { errors.push(error.message); console.error(error.message); });
    await page.goto(`http://127.0.0.1:${server.address().port}`);
    await page.getByRole("button", { name: "Legendas automáticas" }).click();
    const select = page.getByLabel("Faixa de legendas");
    await select.selectOption("original");
    await page.getByRole("status").waitFor();
    assert.equal(await page.evaluate(() => window.e4.posts()), 1);
    await page.evaluate(() => window.e4.finish());
    await page.waitForFunction(() => document.querySelector("video").textTracks[0]?.mode === "showing");
    await page.waitForFunction(() => document.querySelector("video").textTracks[0]?.cues?.length === 1);
    assert.equal(await select.inputValue(), "original");
    await select.selectOption("off");
    await page.waitForFunction(() => document.querySelector("video").textTracks.length === 0);
    await select.selectOption("original");
    assert.equal(await page.evaluate(() => window.e4.posts()), 1);
    await select.selectOption("en");
    await page.getByRole("status").waitFor();
    await page.evaluate(() => window.e4.finish());
    await page.waitForFunction(() => document.querySelector("video").textTracks[0]?.language === "en" &&
      document.querySelector("video").textTracks[0]?.mode === "showing");
    await select.selectOption("original");
    await page.waitForFunction(() => document.querySelector("video").textTracks[0]?.language === "pt");
    assert.equal(await page.evaluate(() => window.e4.posts()), 2);
    await page.evaluate(() => window.e4.reopen());
    await page.getByRole("button", { name: "Legendas automáticas" }).click();
    await select.selectOption("en");
    await page.waitForFunction(() => document.querySelector("video").textTracks[0]?.mode === "showing");
    assert.equal(await page.evaluate(() => window.e4.posts()), 2);
    await select.selectOption("off");
    await page.evaluate(() => window.e4.prepareDelayed());
    await select.selectOption("original");
    await page.waitForFunction(() => window.e4.posts() === 3);
    await page.evaluate(() => window.e4.changeVideo("other"));
    await page.waitForFunction(() => window.e4.other()?.job === null);
    await page.evaluate(() => window.e4.release());
    await page.waitForFunction(() => !document.querySelector('[role="status"]'));
    assert.equal(await select.inputValue(), "off");
    assert.equal(await page.evaluate(() => window.e4.other()?.job), null);
    assert.equal(await page.locator("track").count(), 0);
    await page.evaluate(() => window.e4.changeVideo("video"));
    await page.getByRole("status").waitFor();
    const beforeRefund = await page.evaluate(() => window.e4.sessionUpdates());
    await page.evaluate(() => window.e4.fail(false));
    assert.equal(await page.evaluate(() => window.e4.sessionUpdates()), beforeRefund);
    await page.evaluate(() => window.e4.fail(true));
    await page.waitForFunction(count => window.e4.sessionUpdates() === count + 1, beforeRefund);
    await page.evaluate(() => window.e4.refresh());
    await page.evaluate(() => window.e4.refresh());
    assert.equal(await page.evaluate(() => window.e4.sessionUpdates()), beforeRefund + 1);
    assert.deepEqual(errors, []);
    console.log("PASS Chromium: generation, reuse, WebVTT, late response; confirmed refund refreshes the session once across both hook observers.");
  } finally {
    if (browser) await browser.close();
    if (server) await new Promise((resolve) => server.close(resolve));
    await fs.rm(temporary, { recursive: true, force: true });
  }
}
main().catch((error) => { console.error(error); process.exitCode = 1; });
