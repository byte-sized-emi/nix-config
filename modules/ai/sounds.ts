// Sounds Pi extension — plays a sound when the agent needs attention
// (blocking UI prompt, e.g. a confirmation) or when a run settles
// (completed / error; aborted stays silent since the user is present).
//
// Sounds: sound-theme-freedesktop, symlinked into ~/.local/share/sounds by
// ai.nix (the standard XDG sound-theme location), resolved via XDG_DATA_DIRS.
// Focus check (best effort): compare niri's focused window PID against this
// process's ancestry. If niri or paplay is missing/unreachable, the sound
// simply always plays (or never plays) — never fatal.

import { existsSync, readFileSync } from "node:fs";
import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";

const TIMEOUT_MS = 1_000;

function soundPath(name: string): string | null {
  const dirs = [
    "/run/current-system/sw/share",
    `${process.env.HOME}/.local/share`,
    ...(process.env.XDG_DATA_DIRS ?? "/usr/local/share:/usr/share").split(":"),
  ];
  for (const dir of dirs) {
    const path = `${dir}/sounds/freedesktop/stereo/${name}`;
    if (existsSync(path)) return path;
  }
  return null;
}

// Walk /proc ancestry of the current process, look for the given pid.
function pidIsAncestor(target: number): boolean {
  let pid: number | null = process.pid;
  for (let i = 0; pid !== null && i < 20; i++) {
    if (pid === target) return true;
    const status = readFileSync(`/proc/${pid}/status`, "utf8");
    const m = status.match(/^PPid:\s*(\d+)/m);
    pid = m ? parseInt(m[1], 10) : null;
  }
  return false;
}

// true = this pi's terminal window is focused (skip sound).
// false = unfocused, or focus unknown (play sound).
async function piIsFocused(pi: ExtensionAPI): Promise<boolean> {
  try {
    const res = await pi.exec("niri", ["msg", "--json", "focused-window"], {
      timeout: TIMEOUT_MS,
    });
    if (res.code !== 0) return false;
    const pid = JSON.parse(res.stdout)?.[0]?.pid;
    return typeof pid === "number" && pidIsAncestor(pid);
  } catch {
    return false;
  }
}

export default function (pi: ExtensionAPI) {
  const play = (file: string) => {
    const path = soundPath(file);
    if (path)
      pi.exec("paplay", [path], { timeout: TIMEOUT_MS }).catch(() => {});
  };
  const playUnlessFocused = async (file: string) => {
    if (!(await piIsFocused(pi))) play(file);
  };

  pi.on("ui_prompt_start", async () => {
    await playUnlessFocused("dialog-information.oga");
  });

  pi.on("agent_before_settle", async (event) => {
    if (event.outcome === "aborted") return;
    await playUnlessFocused(
      event.outcome === "error" ? "dialog-warning.oga" : "complete.oga",
    );
  });
}
